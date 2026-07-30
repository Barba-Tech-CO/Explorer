//
//  SidebarRow.swift
//  Explorer
//
//  A single row in the sidebar: folder name with its icon, tooltipped with
//  the absolute path.
//

import SwiftUI

struct SidebarRow: View {
  let folder: Folder
  let icon: String

  var body: some View {
    Label(folder.name, systemImage: icon)
      .help(folder.path)
  }
}
