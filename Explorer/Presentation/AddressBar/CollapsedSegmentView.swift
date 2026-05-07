//
//  CollapsedSegmentView.swift
//  Explorer
//
//  The "…" slot rendered in place of breadcrumbs that don't fit the bar.
//  Tapping reveals a popover listing the omitted ancestor folders so the user
//  can still jump to any of them.
//

import SwiftUI

struct CollapsedSegmentView: View {
  let omitted: [PathSegment]
  let onSelect: (Folder) -> Void

  @State private var isPresented = false

  var body: some View {
    Button {
      isPresented.toggle()
    } label: {
      Image(systemName: "ellipsis")
        .imageScale(.small)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .help(tooltip)
    .accessibilityLabel("Show hidden folders")
    .accessibilityHint(tooltip)
    .popover(isPresented: $isPresented, arrowEdge: .bottom) {
      VStack(alignment: .leading, spacing: 0) {
        ForEach(omitted) { segment in
          SiblingDropdownRow(folder: segment.folder) {
            isPresented = false
            onSelect(segment.folder)
          }
        }
      }
      .padding(.vertical, 4)
      .frame(minWidth: 180)
    }
  }

  private var tooltip: String {
    omitted.map(\.folder.name).joined(separator: " › ")
  }
}
