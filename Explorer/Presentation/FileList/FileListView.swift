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
  let volumeCapacity: VolumeCapacityUseCase

  @State private var viewModel: FileListViewModel
  @State private var sortOrder: [KeyPathComparator<FSEntry>] = [
    KeyPathComparator(\.directorySortKey, order: .forward),
    KeyPathComparator(\.name, order: .forward),
  ]
  @State private var volumeFreeBytes: Int64?

  init(
    navigation: NavigationState,
    listContents: ListContentsUseCase,
    viewMode: FileListViewMode,
    searchQuery: String,
    volumeCapacity: VolumeCapacityUseCase
  ) {
    self.navigation = navigation
    self.viewMode = viewMode
    self.searchQuery = searchQuery
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
      volumeFreeBytes = await volumeCapacity.freeBytes(at: navigation.current)
    }
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // Table eats plain `onTapGesture(count: 2)` for its own row-selection
        // handling. A simultaneous gesture runs alongside selection instead of
        // racing with it, so double-click reliably reaches us on macOS.
        .simultaneousGesture(
          TapGesture(count: 2).onEnded { open(entry) }
        )
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
