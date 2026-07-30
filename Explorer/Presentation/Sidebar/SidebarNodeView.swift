//
//  SidebarNodeView.swift
//  Explorer
//
//  One expandable node of the sidebar tree, recursing into its subfolders.
//  The disclosure triangle only expands; navigation stays on the row itself,
//  so opening a branch never moves the user out of the current folder.
//

import SwiftUI

struct SidebarNodeView: View {
  let folder: Folder
  let icon: String
  let tree: SidebarTreeViewModel

  var body: some View {
    DisclosureGroup(isExpanded: expansion) {
      // `children` is only populated once the listing lands; until then the
      // group renders empty rather than a spinner, matching how Finder opens
      // a branch without a placeholder row.
      ForEach(tree.children[folder] ?? []) { subfolder in
        SidebarNodeView(folder: subfolder, icon: "folder", tree: tree)
          .tag(subfolder)
      }
    } label: {
      SidebarRow(folder: folder, icon: icon)
    }
  }

  private var expansion: Binding<Bool> {
    Binding(
      get: { tree.isExpanded(folder) },
      // The setter can't await, so the listing is kicked off in a task. The
      // view model guards against a collapse landing before the listing does.
      // Pinned to the main actor like `AddressBarView`'s commit task: an
      // unstructured `Task {}` doesn't inherit the View's isolation, so it
      // would start off the main actor and hop only on the first `await`.
      set: { isExpanded in
        Task { @MainActor in
          await tree.setExpanded(isExpanded, for: folder)
        }
      }
    )
  }
}
