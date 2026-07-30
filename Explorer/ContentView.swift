//
//  ContentView.swift
//  Explorer
//
//  Root window layout: NavigationSplitView with the sidebar on the left and
//  the address bar + file list on the right.
//

import SwiftUI

struct ContentView: View {
  let dependencies: AppDependencies

  @State private var navigation: NavigationState
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var viewMode: FileListViewMode = .details
  @State private var searchQuery: String = ""
  @State private var searchFocusRequest: Bool = false
  @State private var refreshRequest: Bool = false

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
    self._navigation = State(
      initialValue: NavigationState(initial: dependencies.repository.home)
    )
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      SidebarView(
        navigation: navigation,
        sources: dependencies.sidebarSources,
        listSubfolders: dependencies.listSubfolders
      )
      .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
    } detail: {
      detail
    }
    .toolbar {
      NavigationToolbar(
        navigation: navigation,
        viewMode: $viewMode,
        searchQuery: $searchQuery,
        searchFocusRequest: $searchFocusRequest,
        refreshRequest: $refreshRequest,
        folder: navigation.current
      )
    }
    .background(keyboardShortcutSink)
    .onChange(of: navigation.current) { _, _ in
      searchQuery = ""
    }
    .frame(minWidth: 820, minHeight: 520)
  }

  // Hidden buttons that own the toolbar's keyboard shortcuts. Kept out of
  // `.toolbar` so they don't reserve trailing space that would push the
  // search field away from the window edge.
  private var keyboardShortcutSink: some View {
    Group {
      Button("Details view") { viewMode = .details }
        .keyboardShortcut("1", modifiers: .command)
      Button("Large icons view") { viewMode = .largeIcons }
        .keyboardShortcut("2", modifiers: .command)
      Button("Focus search") { searchFocusRequest = true }
        .keyboardShortcut("f", modifiers: .command)
      // Second binding for the same action: the toolbar button owns ⌘+R,
      // and macOS also expects F5 (0xF708 in the private-use area, matching
      // NSF5FunctionKey). A view can only carry one shortcut, so F5 lives
      // here rather than on the button.
      Button("Refresh") { refreshRequest = true }
        .keyboardShortcut(KeyEquivalent("\u{F708}"), modifiers: [])
    }
    .opacity(0)
    .frame(width: 0, height: 0)
    .accessibilityHidden(true)
  }

  private var detail: some View {
    VStack(spacing: 0) {
      AddressBarView(
        navigation: navigation,
        listSubfolders: dependencies.listSubfolders,
        resolvePath: dependencies.resolvePath
      )
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider()

      FileListView(
        navigation: navigation,
        listContents: dependencies.listContents,
        viewMode: viewMode,
        searchQuery: searchQuery,
        refreshRequest: $refreshRequest,
        volumeCapacity: dependencies.volumeCapacity
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

#Preview {
  ContentView(dependencies: .live())
}
