//
//  LargeIconsView.swift
//  Explorer
//
//  Alternative renderer for the file list pane: a grid of large icons with
//  the entry name underneath. Single-click selects, double-click opens
//  (matching the Details `Table` semantics).
//

import SwiftUI

struct LargeIconsView: View {
  let entries: [FSEntry]
  @Binding var selection: Set<FSEntry.ID>
  let onOpen: (FSEntry) -> Void

  private let columns = [
    GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 12)
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
        ForEach(entries) { entry in
          LargeIconCell(
            entry: entry,
            isSelected: selection.contains(entry.id),
            onSelect: { selection = [entry.id] },
            onOpen: { onOpen(entry) }
          )
        }
      }
      .padding(12)
    }
    .background(
      // Tap on empty space clears selection, mirroring Finder's icon view.
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture { selection = [] }
    )
  }
}

private struct LargeIconCell: View {
  let entry: FSEntry
  let isSelected: Bool
  let onSelect: () -> Void
  let onOpen: () -> Void

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
        .font(.system(size: 56, weight: .light))
        .foregroundStyle(entry.isDirectory ? Color.accentColor : .secondary)
        .frame(width: 96, height: 96)

      Text(entry.name)
        .font(.callout)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .truncationMode(.middle)
        .frame(maxWidth: 110)
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
    )
    .contentShape(Rectangle())
    .onTapGesture { onSelect() }
    .simultaneousGesture(
      TapGesture(count: 2).onEnded { onOpen() }
    )
    .help(entry.name)
  }
}
