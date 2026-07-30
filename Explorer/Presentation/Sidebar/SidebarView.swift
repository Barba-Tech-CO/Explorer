//
//  SidebarView.swift
//  Explorer
//
//  Left pane of the window split view. Renders two sections:
//   - Quick Access: well-known user folders, resolved synchronously at
//     startup since the OS doesn't relocate them in the user's session.
//   - This Mac: mounted volumes (boot drive + externals), refreshed
//     whenever the workspace posts mount/unmount notifications.
//

import SwiftUI
import AppKit

struct SidebarView: View {
  @Bindable var navigation: NavigationState
  let sources: SidebarSourcesUseCase

  @State private var volumes: [Folder] = []
  @State private var tree: SidebarTreeViewModel

  init(
    navigation: NavigationState,
    sources: SidebarSourcesUseCase,
    listSubfolders: ListSubfoldersUseCase
  ) {
    self.navigation = navigation
    self.sources = sources
    self._tree = State(
      initialValue: SidebarTreeViewModel(listSubfolders: listSubfolders)
    )
  }

  private let mountNotification = NSWorkspace.shared
    .notificationCenter.publisher(for: NSWorkspace.didMountNotification)
  private let unmountNotification = NSWorkspace.shared
    .notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)

  var body: some View {
    List(selection: navigationSelection) {
      Section("Quick Access") {
        SidebarNodeView(folder: sources.home, icon: "house", tree: tree)
          .tag(sources.home)
        ForEach(sources.quickAccess) { folder in
          SidebarNodeView(folder: folder, icon: icon(for: folder), tree: tree)
            .tag(folder)
        }
      }

      Section("This Mac") {
        ForEach(volumes) { volume in
          SidebarNodeView(folder: volume, icon: icon(forVolume: volume), tree: tree)
            .tag(volume)
        }
      }
    }
    .listStyle(.sidebar)
    .task { await reloadVolumes() }
    .onReceive(mountNotification) { _ in Task { await reloadVolumes() } }
    .onReceive(unmountNotification) { _ in Task { await reloadVolumes() } }
  }

  @MainActor
  private func reloadVolumes() async {
    // @MainActor because `volumes` is `@State` — the unstructured `Task {}`
    // we kick off from `.onReceive` doesn't inherit the View's main-actor
    // isolation, so the assignment after `await` could otherwise resume on
    // a background executor and trip SwiftUI's "publishing changes from
    // background" runtime warning.
    volumes = await sources.mountedVolumes()
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

  private func icon(for folder: Folder) -> String {
    switch folder.name {
    case "Desktop": return "menubar.dock.rectangle"
    case "Documents": return "doc"
    case "Downloads": return "arrow.down.circle"
    case "Pictures": return "photo"
    case "Music": return "music.note"
    case "Movies": return "film"
    default: return "folder"
    }
  }

  private func icon(forVolume folder: Folder) -> String {
    folder.path == "/" ? "internaldrive" : "externaldrive"
  }
}
