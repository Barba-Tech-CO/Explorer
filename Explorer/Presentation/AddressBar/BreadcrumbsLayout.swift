//
//  BreadcrumbsLayout.swift
//  Explorer
//
//  Pure layout decision for the breadcrumb bar: given measured widths and the
//  available container width, decide which segments stay visible and which
//  collapse behind an ellipsis. Lives in Presentation but has no SwiftUI
//  dependency, so it can be unit-tested without rendering.
//

import CoreGraphics

enum BreadcrumbsLayout {
  /// Decide what to render in the bar.
  ///
  /// - Parameters:
  ///   - segments: full ordered list (root first, current folder last).
  ///   - widths: measured intrinsic width per `segment.id`. If any segment is
  ///     missing a width (first frame, before measurement settles), we fall
  ///     back to rendering everything uncollapsed.
  ///   - available: container width budget.
  ///   - ellipsisWidth: measured width of the "…" button. Counted toward the
  ///     budget when collapsing.
  /// - Returns: items to render in order.
  static func collapse(
    segments: [PathSegment],
    widths: [Int: CGFloat],
    available: CGFloat,
    ellipsisWidth: CGFloat
  ) -> [BreadcrumbsItem] {
    guard !segments.isEmpty else { return [] }
    if segments.count <= 2 { return segments.map { .segment($0) } }

    // Without all measurements we can't make a safe decision; render all and
    // let the next frame collapse once widths arrive.
    let allMeasured = segments.allSatisfy { widths[$0.id] != nil }
    guard allMeasured else { return segments.map { .segment($0) } }

    let totalWidth = segments.reduce(0) { $0 + (widths[$1.id] ?? 0) }
    if totalWidth <= available {
      return segments.map { .segment($0) }
    }

    // Pinned: first segment always visible. Walk from the end toward the
    // middle, including segments while there's room for them plus the
    // ellipsis. Anything left over is omitted.
    let first = segments[0]
    let firstWidth = widths[first.id] ?? 0
    var budget = available - firstWidth - ellipsisWidth
    var tail: [PathSegment] = []
    var omitted: [PathSegment] = []
    var stoppedAdding = false

    for segment in segments.dropFirst().reversed() {
      let w = widths[segment.id] ?? 0
      if !stoppedAdding, (budget - w >= 0 || tail.isEmpty) {
        // Always keep at least one tail segment (the current folder) even if
        // the budget is exhausted; better to overflow the last label than to
        // hide the user's location.
        tail.append(segment)
        budget -= w
      } else {
        // Once we skip a segment we can't include earlier ones — the
        // collapsed range must be contiguous.
        stoppedAdding = true
        omitted.append(segment)
      }
    }

    let visibleTail = Array(tail.reversed())
    let omittedInOrder = Array(omitted.reversed())

    var items: [BreadcrumbsItem] = [.segment(first)]
    if !omittedInOrder.isEmpty {
      items.append(.ellipsis(omitted: omittedInOrder))
    }
    items.append(contentsOf: visibleTail.map { .segment($0) })
    return items
  }
}
