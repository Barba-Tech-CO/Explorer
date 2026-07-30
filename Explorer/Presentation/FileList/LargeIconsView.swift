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
  @State private var cellFrames: [FSEntry.ID: CGRect] = [:]
  @State private var bandOrigin: CGPoint?
  @State private var band: CGRect?
  @State private var selectionBeforeBand: Set<FSEntry.ID> = []
  @State private var bandIsAdditive = false

  private static let gridSpace = "iconGrid"

  private let columns = [
    GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 12)
  ]

  var body: some View {
    // The grid area has to own the whole pane, not just the rows: everything
    // interactive about empty space — clearing the selection, starting a
    // band — happens below the last row, and a container sized to its rows
    // would leave that space to a second layer with different behaviour.
    GeometryReader { pane in
      ScrollView {
        ZStack(alignment: .topLeading) {
          LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(entries) { entry in
              LargeIconCell(
                entry: entry,
                isSelected: selection.contains(entry.id),
                onTap: { flags in handleTap(on: entry, flags: flags) },
                onOpen: { onOpen(entry) }
              )
              .background(frameReporter(for: entry))
            }
          }
          .padding(12)

          if let band {
            Rectangle()
              .fill(Color.accentColor.opacity(0.12))
              .overlay(
                Rectangle().stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
              )
              .frame(width: band.width, height: band.height)
              .offset(x: band.minX, y: band.minY)
              .allowsHitTesting(false)
          }
        }
        // `minHeight` stretches the grid to the bottom of the pane even when a
        // couple of rows would fit in a fraction of it.
        .frame(
          maxWidth: .infinity,
          minHeight: pane.size.height,
          alignment: .topLeading
        )
        .coordinateSpace(name: Self.gridSpace)
        // Without a shape the container only receives events where a cell
        // sits, so neither a click nor a band could land in the empty area.
        .contentShape(Rectangle())
        // Tap on empty space clears the selection, mirroring Finder's icon
        // view. Taps that land on a cell are consumed by the cell first, so
        // this only ever sees the gaps.
        .onTapGesture(perform: clearSelection)
        .gesture(bandGesture)
        .onPreferenceChange(CellFramesKey.self) { frames in
          cellFrames = frames
        }
      }
    }
  }

  private func clearSelection() {
    selection = []
    anchor = nil
  }

  private func frameReporter(for entry: FSEntry) -> some View {
    GeometryReader { proxy in
      Color.clear.preference(
        key: CellFramesKey.self,
        // Rounded to whole points: sub-pixel jitter in the reported frame
        // would re-fire the preference on every layout pass and churn state
        // for a value the hit-testing can't tell apart anyway.
        value: [entry.id: proxy.frame(in: .named(Self.gridSpace)).integral]
      )
    }
  }

  private var bandGesture: some Gesture {
    DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.gridSpace))
      .onChanged { value in
        if bandOrigin == nil {
          // A drag that begins on a cell is the user reaching for that file,
          // not sweeping the empty space around it.
          guard !cellFrames.values.contains(where: { $0.contains(value.startLocation) })
          else { return }
          bandOrigin = value.startLocation
          selectionBeforeBand = selection
          bandIsAdditive = NSEvent.modifierFlags.contains(.command)
        }
        guard let origin = bandOrigin else { return }
        let rect = MarqueeSelection.rect(from: origin, to: value.location)
        band = rect
        selection = MarqueeSelection.resolve(
          marquee: rect,
          frames: cellFrames,
          base: selectionBeforeBand,
          additive: bandIsAdditive
        )
      }
      .onEnded { _ in
        bandOrigin = nil
        band = nil
      }
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

/// Collects each cell's rect in the grid's coordinate space so the band can
/// be hit-tested without walking the view hierarchy.
private struct CellFramesKey: PreferenceKey {
  static var defaultValue: [FSEntry.ID: CGRect] { [:] }

  static func reduce(
    value: inout [FSEntry.ID: CGRect],
    nextValue: () -> [FSEntry.ID: CGRect]
  ) {
    value.merge(nextValue()) { _, newer in newer }
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
