//
//  MarqueeSelection.swift
//  Explorer
//
//  Pure geometry for rubber-band selection in the icon grid. Kept free of
//  SwiftUI so the hit-testing can be unit tested with plain rects instead of
//  a rendered view and a synthetic drag.
//

import Foundation
import CoreGraphics

enum MarqueeSelection {
  /// Rect spanned by a drag between two points, normalized so dragging up or
  /// to the left produces the same rect as dragging down-right.
  static func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
    CGRect(
      x: min(start.x, end.x),
      y: min(start.y, end.y),
      width: abs(end.x - start.x),
      height: abs(end.y - start.y)
    )
  }

  /// Entries the band currently covers.
  ///
  /// - Parameters:
  ///   - marquee: the band, in the same coordinate space as `frames`.
  ///   - frames: each entry's cell rect.
  ///   - base: the selection held when the drag started. Only meaningful when
  ///     `additive` is true — a plain drag replaces the selection outright,
  ///     matching a plain click.
  ///   - additive: true while ⌘ is held, so a band can extend a selection
  ///     built up by earlier clicks or drags instead of discarding it.
  static func resolve(
    marquee: CGRect,
    frames: [FSEntry.ID: CGRect],
    base: Set<FSEntry.ID>,
    additive: Bool
  ) -> Set<FSEntry.ID> {
    // A band that hasn't moved covers nothing: a press with no drag must not
    // sweep up whatever sits under the cursor, or clicking empty space would
    // select a neighbouring cell. Guarded explicitly rather than leaning on
    // `CGRect.intersects`, whose handling of degenerate rects would also
    // reject a perfectly horizontal or vertical band that does cross cells.
    guard marquee.width > 0 || marquee.height > 0 else {
      return additive ? base : []
    }
    let hits = frames.reduce(into: Set<FSEntry.ID>()) { result, pair in
      if overlaps(pair.value, marquee) { result.insert(pair.key) }
    }
    return additive ? base.union(hits) : hits
  }

  /// Edge-inclusive overlap, so a band with no thickness on one axis still
  /// catches the cells it sweeps across.
  private static func overlaps(_ frame: CGRect, _ band: CGRect) -> Bool {
    frame.minX <= band.maxX && frame.maxX >= band.minX
      && frame.minY <= band.maxY && frame.maxY >= band.minY
  }
}
