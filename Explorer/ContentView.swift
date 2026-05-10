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
        home: dependencies.repository.home
      )
      .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
    } detail: {
      detail
    }
    .frame(minWidth: 820, minHeight: 520)
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
        listContents: dependencies.listContents
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

#Preview {
  ContentView(dependencies: .live())
}
