//
//  SiblingDropdownRow.swift
//  Explorer
//
//  Single row inside the sibling-folders popover.
//

import SwiftUI

struct SiblingDropdownRow: View {
  let folder: Folder
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 6) {
        Image(systemName: "folder")
        Text(folder.name)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
