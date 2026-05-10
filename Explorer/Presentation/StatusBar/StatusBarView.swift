//
//  StatusBarView.swift
//  Explorer
//
//  Bottom strip of the file list pane: total item count on the left, the
//  selection summary in the middle when there's a selection, and the free
//  bytes on the current volume on the right.
//

import SwiftUI

struct StatusBarView: View {
  let entries: [FSEntry]
  let selection: Set<FSEntry.ID>
  let volumeFreeBytes: Int64?

  var body: some View {
    HStack(spacing: 8) {
      Text(itemsLabel)
      if let summary = selectionSummary {
        separator
        Text(summary)
      }
      Spacer(minLength: 8)
      if let free = volumeFreeBytes {
        Text("\(format(bytes: free)) free")
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.bar)
  }

  private var itemsLabel: String {
    entries.count == 1 ? "1 item" : "\(entries.count) items"
  }

  private var selectionSummary: String? {
    guard !selection.isEmpty else { return nil }
    let selected = entries.filter { selection.contains($0.id) }
    guard !selected.isEmpty else { return nil }
    let count = selected.count == 1
      ? "1 selected"
      : "\(selected.count) selected"
    let totalBytes = selected.reduce(Int64(0)) { $0 + ($1.size ?? 0) }
    guard totalBytes > 0 else { return count }
    return "\(count) · \(format(bytes: totalBytes))"
  }

  private var separator: some View {
    Text("·").foregroundStyle(.secondary.opacity(0.6))
  }

  private func format(bytes: Int64) -> String {
    Self.byteFormatter.string(fromByteCount: bytes)
  }

  private static let byteFormatter: ByteCountFormatter = {
    let f = ByteCountFormatter()
    f.countStyle = .file
    return f
  }()
}
