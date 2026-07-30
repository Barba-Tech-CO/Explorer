//
//  NavigationToolbar.swift
//  Explorer
//
//  Window-level toolbar group: back / forward, view-mode segmented picker,
//  and a native NSSearchField. Search is rendered inline (instead of via
//  `.searchable`) so we can keep the picker glued to it inside the same
//  ToolbarItemGroup — `.searchable` lands in its own zone and macOS pushes
//  unrelated toolbar items away from it.
//

import SwiftUI

struct NavigationToolbar: ToolbarContent {
  @Bindable var navigation: NavigationState
  @Binding var viewMode: FileListViewMode
  @Binding var searchQuery: String
  @Binding var searchFocusRequest: Bool
  @Binding var refreshRequest: Bool
  let folder: Folder

  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .navigation) {
      Button(action: navigation.goBack) {
        Image(systemName: "chevron.backward")
      }
      .help("Back")
      .disabled(!navigation.canGoBack)
      .keyboardShortcut(.leftArrow, modifiers: .command)

      Button(action: navigation.goForward) {
        Image(systemName: "chevron.forward")
      }
      .help("Forward")
      .disabled(!navigation.canGoForward)
      .keyboardShortcut(.rightArrow, modifiers: .command)

      Button { refreshRequest = true } label: {
        Image(systemName: "arrow.clockwise")
      }
      .help("Refresh")
      .keyboardShortcut("r", modifiers: .command)
    }

    ToolbarItemGroup(placement: .primaryAction) {
      Picker("View mode", selection: $viewMode) {
        Image(systemName: "list.bullet")
          .tag(FileListViewMode.details)
        Image(systemName: "square.grid.2x2")
          .tag(FileListViewMode.largeIcons)
      }
      .pickerStyle(.segmented)
      .help("Switch between Details and Large icons")

      SearchField(
        text: $searchQuery,
        focusRequest: $searchFocusRequest,
        placeholder: "Search in \(folder.name)"
      )
      .frame(width: 220)
    }

    // Tiny trailing spacer so the search field doesn't kiss the window edge.
    // Empty Color is cheaper than a hidden Button and reliably reserves width.
    ToolbarItem(placement: .primaryAction) {
      Color.clear.frame(width: 4, height: 1)
    }
  }
}
