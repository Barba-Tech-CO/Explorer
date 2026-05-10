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

  private let mountNotification = NSWorkspace.shared
    .notificationCenter.publisher(for: NSWorkspace.didMountNotification)
  private let unmountNotification = NSWorkspace.shared
    .notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)

  var body: some View {
    List(selection: navigationSelection) {
      Section("Quick Access") {
        SidebarRow(folder: sources.home, icon: "house")
          .tag(sources.home)
        ForEach(sources.quickAccess) { folder in
          SidebarRow(folder: folder, icon: icon(for: folder))
            .tag(folder)
        }
      }

      Section("This Mac") {
        ForEach(volumes) { volume in
          SidebarRow(folder: volume, icon: icon(forVolume: volume))
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

private struct SidebarRow: View {
  let folder: Folder
  let icon: String

  var body: some View {
    Label(folder.name, systemImage: icon)
      .help(folder.path)
  }
}
