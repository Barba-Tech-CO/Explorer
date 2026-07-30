//
//  FileListView.swift
//  Explorer
//
//  Main content pane: renders the entries of the current folder as a
//  sortable Details table (Name / Modified / Type / Size). Double-click on
//  a directory navigates into it.
//

import SwiftUI
import AppKit

struct FileListView: View {
  @Bindable var navigation: NavigationState
  let viewMode: FileListViewMode
  let searchQuery: String
  @Binding var refreshRequest: Bool
  let volumeCapacity: VolumeCapacityUseCase

  @State private var viewModel: FileListViewModel
  @State private var sortOrder: [KeyPathComparator<FSEntry>] = [
    KeyPathComparator(\.directorySortKey, order: .forward),
    KeyPathComparator(\.name, order: .forward),
  ]
  @State private var volumeFreeBytes: Int64?
  @State private var selectionAnchor: FSEntry.ID?
  @FocusState private var paneFocused: Bool

  init(
    navigation: NavigationState,
    listContents: ListContentsUseCase,
    viewMode: FileListViewMode,
    searchQuery: String,
    refreshRequest: Binding<Bool>,
    volumeCapacity: VolumeCapacityUseCase
  ) {
    self.navigation = navigation
    self.viewMode = viewMode
    self.searchQuery = searchQuery
    self._refreshRequest = refreshRequest
    self.volumeCapacity = volumeCapacity
    self._viewModel = State(
      initialValue: FileListViewModel(listContents: listContents)
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      Divider()

      StatusBarView(
        entries: viewModel.entries,
        selection: viewModel.selection,
        volumeFreeBytes: volumeFreeBytes
      )
    }
    .task(id: navigation.current) {
      await viewModel.load(navigation.current)
    }
    .task(id: navigation.current) {
      // Reset before awaiting so the previous folder's value isn't shown
      // alongside the new folder while the new lookup is in flight.
      volumeFreeBytes = nil
      let requested = navigation.current
      let bytes = await volumeCapacity.freeBytes(at: requested)
      // Guard against a stale write: `URL.resourceValues` isn't cancellable,
      // so a fast back-and-forth navigation can let the previous fetch
      // resolve after the task was cancelled and overwrite the new folder's
      // value.
      guard !Task.isCancelled, requested == navigation.current else { return }
      volumeFreeBytes = bytes
    }
    .task(id: refreshRequest) {
      // Consume the one-shot request raised by the toolbar button / ⌘+R / F5.
      // Driven by `.task` rather than `.onChange` so the work is tied to the
      // view's lifetime and gets cancelled if the pane goes away mid-listing.
      // Re-pressing while a refresh is in flight writes `true` over `true`,
      // which leaves the id untouched and is deliberately swallowed: the
      // listing already running is the one the user wants.
      guard refreshRequest else { return }
      await viewModel.load(navigation.current, refreshing: true)
      refreshRequest = false
    }
    .background(shortcutSink)
    .focusable()
    .focused($paneFocused)
    // The pane is focusable only so arrow keys / Enter / Backspace route
    // here — it isn't a control the user tabs onto. Without this, macOS
    // draws its focus ring around the whole VStack and the user sees a blue
    // line framing the file list whenever they click a row.
    .focusEffectDisabled()
    // Any tap inside the pane (rows, empty area, status bar) claims keyboard
    // focus so arrow keys / Enter / Backspace land here instead of staying on
    // the sidebar that triggered the navigation. `simultaneousGesture` shares
    // the click with the cell handlers so single-/double-click still fire.
    .simultaneousGesture(
      TapGesture().onEnded { paneFocused = true }
    )
    .onKeyPress(.return) {
      openFocusedSelection() ? .handled : .ignored
    }
    .onKeyPress(.delete) {
      // Only swallow Backspace when there's actually a parent to navigate to.
      // Returning .ignored at the root lets the key event propagate so other
      // handlers (or the system beep) can take it instead of silently no-op.
      guard navigation.canGoUp else { return .ignored }
      navigation.goUp()
      return .handled
    }
    .onKeyPress(.upArrow) {
      moveSelection(by: -1) ? .handled : .ignored
    }
    .onKeyPress(.downArrow) {
      moveSelection(by: +1) ? .handled : .ignored
    }
  }

  // Hidden buttons own ⌘+A and ⌘+Shift+C so the shortcuts work whenever the
  // file list pane is in the responder chain. Kept off `.toolbar` to avoid
  // reserving slot space (same pattern as `keyboardShortcutSink` in
  // ContentView for the toolbar shortcuts).
  private var shortcutSink: some View {
    Group {
      Button("Select All", action: selectAll)
        .keyboardShortcut("a", modifiers: .command)
      Button("Copy Path", action: copySelectedPaths)
        .keyboardShortcut("c", modifiers: [.command, .shift])
    }
    .opacity(0)
    .frame(width: 0, height: 0)
    .accessibilityHidden(true)
  }

  @discardableResult
  private func openFocusedSelection() -> Bool {
    guard viewModel.selection.count == 1,
          let id = viewModel.selection.first,
          let entry = viewModel.entries.first(where: { $0.id == id })
    else { return false }
    open(entry)
    return true
  }

  private func selectAll() {
    viewModel.selection = Set(sortedEntries.map(\.id))
    selectionAnchor = sortedEntries.first?.id
  }

  @discardableResult
  private func moveSelection(by delta: Int) -> Bool {
    let ids = sortedEntries.map(\.id)
    guard !ids.isEmpty else { return false }
    let currentIdx: Int
    if let anchor = selectionAnchor, let i = ids.firstIndex(of: anchor) {
      currentIdx = i
    } else if let only = viewModel.selection.first,
              viewModel.selection.count == 1,
              let i = ids.firstIndex(of: only) {
      currentIdx = i
    } else {
      currentIdx = -1
    }
    let nextIdx: Int
    if currentIdx < 0 {
      nextIdx = delta > 0 ? 0 : ids.count - 1
    } else {
      nextIdx = max(0, min(ids.count - 1, currentIdx + delta))
    }
    let target = ids[nextIdx]
    viewModel.selection = [target]
    selectionAnchor = target
    return true
  }

  private func handleTableTap(on entry: FSEntry) {
    let flags = NSEvent.modifierFlags
    let gesture: MultiSelection.Gesture
    if flags.contains(.command) {
      gesture = .toggle
    } else if flags.contains(.shift) {
      gesture = .range
    } else {
      gesture = .plain
    }
    let result = MultiSelection.resolve(
      click: entry.id,
      gesture: gesture,
      current: viewModel.selection,
      anchor: selectionAnchor,
      orderedIds: sortedEntries.map(\.id)
    )
    viewModel.selection = result.selection
    selectionAnchor = result.anchor
  }

  private func copySelectedPaths() {
    let selected = sortedEntries.filter { viewModel.selection.contains($0.id) }
    guard !selected.isEmpty else { return }
    // For directories prefer `Folder.path` — it strips the trailing slash
    // consistently across macOS versions, where `URL.path(percentEncoded:)`
    // disagrees on whether to keep it. Plain files have no `Folder`
    // projection, so we fall back to the URL form for them.
    let payload = selected
      .map { $0.folder?.path ?? $0.url.path(percentEncoded: false) }
      .joined(separator: "\n")
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(payload, forType: .string)
  }

  private var trimmedQuery: String {
    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var hasActiveSearch: Bool { !trimmedQuery.isEmpty }

  private var filteredEntries: [FSEntry] {
    guard hasActiveSearch else { return viewModel.entries }
    return viewModel.entries.filter {
      $0.name.localizedCaseInsensitiveContains(trimmedQuery)
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .failed(let error):
      FileListFailureView(error: error)
    case .loaded:
      loadedContent
    }
  }

  @ViewBuilder
  private var loadedContent: some View {
    if sortedEntries.isEmpty {
      emptyState
    } else {
      switch viewMode {
      case .details:
        table
      case .largeIcons:
        LargeIconsView(
          entries: sortedEntries,
          selection: $viewModel.selection,
          onOpen: open
        )
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 6) {
      Image(systemName: hasActiveSearch ? "magnifyingglass" : "tray")
        .font(.system(size: 32, weight: .light))
        .foregroundStyle(.secondary)
      Text(hasActiveSearch ? "No matches" : "This folder is empty")
        .font(.headline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var table: some View {
    Table(
      sortedEntries,
      selection: $viewModel.selection,
      sortOrder: $sortOrder
    ) {
      TableColumn("Name", value: \.name) { entry in
        Label {
          Text(entry.name).lineLimit(1)
        } icon: {
          Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
            .foregroundStyle(entry.isDirectory ? Color.accentColor : .secondary)
        }
        .help(entry.name)
        // Extend the hit area across the cell so a click anywhere on the row
        // (not only on the icon/text) drives both single- and double-click
        // handlers. We bypass NSTableView's own click-to-select and drive the
        // selection ourselves via `MultiSelection`, which keeps the
        // single-click hit + double-click open + ⌘/Shift behavior in sync
        // with the Large icons grid.
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // count: 2 takes priority — when it fires, the count: 1 handler is
        // suppressed. Drive the selection ourselves before opening so a
        // double-click on a previously unselected row still highlights it
        // (matches Finder's behavior).
        .onTapGesture(count: 2) {
          handleTableTap(on: entry)
          open(entry)
        }
        .onTapGesture { handleTableTap(on: entry) }
      }

      TableColumn("Modified", value: \.modificationSortKey) { entry in
        Text(formatted(date: entry.modificationDate))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .width(min: 140, ideal: 180)

      TableColumn("Type", value: \.typeSortKey) { entry in
        Text(typeLabel(for: entry))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .width(min: 100, ideal: 140)

      TableColumn("Size", value: \.sizeSortKey) { entry in
        Text(formatted(size: entry))
          .foregroundStyle(.secondary)
          .monospacedDigit()
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
      .width(min: 80, ideal: 100)
    }
  }

  private var sortedEntries: [FSEntry] {
    filteredEntries.sorted(using: sortOrder)
  }

  private func open(_ entry: FSEntry) {
    if let folder = entry.folder {
      navigation.navigate(to: folder)
    } else {
      NSWorkspace.shared.open(entry.url)
    }
  }

  private func formatted(date: Date?) -> String {
    guard let date else { return "—" }
    return Self.dateFormatter.string(from: date)
  }

  private func formatted(size entry: FSEntry) -> String {
    if entry.isDirectory { return "—" }
    guard let size = entry.size else { return "—" }
    return Self.sizeFormatter.string(fromByteCount: size)
  }

  private func typeLabel(for entry: FSEntry) -> String {
    if entry.isDirectory { return "Folder" }
    let ext = (entry.name as NSString).pathExtension
    return ext.isEmpty ? "File" : ext.uppercased()
  }

  private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f
  }()

  private static let sizeFormatter: ByteCountFormatter = {
    let f = ByteCountFormatter()
    f.countStyle = .file
    return f
  }()
}

private extension FSEntry {
  // Folders before files in default ordering. Reversing the column toggles the
  // grouping naturally because 0 < 1.
  var directorySortKey: Int { isDirectory ? 0 : 1 }
  var modificationSortKey: Date { modificationDate ?? .distantPast }
  var typeSortKey: String { isDirectory ? "" : (typeIdentifier ?? "") }
  var sizeSortKey: Int64 { isDirectory ? -1 : (size ?? 0) }
}
