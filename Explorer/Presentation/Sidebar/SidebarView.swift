//
//  SidebarView.swift
//  Explorer
//
//  Placeholder sidebar pane. Quick Access (Desktop, Documents, Downloads,
//  …) and This Mac (root + /Volumes) come in a follow-up — for now we just
//  surface Home so the split view has a meaningful entry point.
//

import SwiftUI

struct SidebarView: View {
  @Bindable var navigation: NavigationState
  let home: Folder

  var body: some View {
    List(selection: navigationSelection) {
      Section("Quick Access") {
        Label(home.name, systemImage: "house")
          .tag(home)
      }
    }
    .listStyle(.sidebar)
  }

  private var navigationSelection: Binding<Folder?> {
    Binding(
      get: { navigation.current },
      set: { folder in
        guard let folder, folder != navigation.current else { return }
        navigation.navigate(to: folder)
      }
    )
  }
}
