//
//  LargeIconsView.swift
//  Explorer
//
//  Alternative renderer for the file list pane: a grid of large icons with
//  the entry name underneath. Single-click selects, double-click opens
//  (matching the Details `Table` semantics). Shift+click ranges from the
//  last anchor; ⌘+click toggles membership.
//

import SwiftUI
import AppKit

struct LargeIconsView: View {
  let entries: [FSEntry]
  @Binding var selection: Set<FSEntry.ID>
  let onOpen: (FSEntry) -> Void

  @State private var anchor: FSEntry.ID?

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
            onTap: { flags in handleTap(on: entry, flags: flags) },
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
        .onTapGesture {
          selection = []
          anchor = nil
        }
    )
  }

  private func handleTap(on entry: FSEntry, flags: NSEvent.ModifierFlags) {
    let gesture: MultiSelection.Gesture
    if flags.contains(.command) {
      gesture = .toggle
    } else if flags.contains(.shift) {
      gesture = .range
    } else {
      gesture = .plain
    }
    let result = MultiSelection.resolve(
      click: entry.id,
      gesture: gesture,
      current: selection,
      anchor: anchor,
      orderedIds: entries.map(\.id)
    )
    selection = result.selection
    anchor = result.anchor
  }
}

private struct LargeIconCell: View {
  let entry: FSEntry
  let isSelected: Bool
  let onTap: (NSEvent.ModifierFlags) -> Void
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
    .onTapGesture { onTap(NSEvent.modifierFlags) }
    .simultaneousGesture(
      TapGesture(count: 2).onEnded { onOpen() }
    )
    .help(entry.name)
  }
}
