//
//  MultiSelection.swift
//  Explorer
//
//  Pure state machine for multi-select clicks on the file list pane. Kept
//  AppKit-free so it can be unit tested without modifier-flag plumbing —
//  the view layer translates NSEvent flags to a `Gesture` before calling.
//

import Foundation

enum MultiSelection {
  /// Click intent derived from the modifier keys held when the user clicked.
  enum Gesture {
    /// No modifier — replace selection with just this id, anchor it.
    case plain
    /// Cmd held — toggle membership without resetting other ids; anchor
    /// moves to the clicked id so a follow-up Shift-click ranges from here.
    case toggle
    /// Shift held — extend the selection to a contiguous range between the
    /// previous anchor and the clicked id (inclusive). Anchor stays put.
    case range
  }

  struct Result: Equatable {
    let selection: Set<FSEntry.ID>
    let anchor: FSEntry.ID
  }

  /// Apply the click on `id` to `current`/`anchor` and return the new
  /// selection plus the new anchor. `orderedIds` MUST reflect the entries in
  /// the same order they're rendered, so `range` selects the visible slice.
  static func resolve(
    click id: FSEntry.ID,
    gesture: Gesture,
    current: Set<FSEntry.ID>,
    anchor: FSEntry.ID?,
    orderedIds: [FSEntry.ID]
  ) -> Result {
    switch gesture {
    case .plain:
      return Result(selection: [id], anchor: id)

    case .toggle:
      var next = current
      if next.contains(id) {
        next.remove(id)
      } else {
        next.insert(id)
      }
      return Result(selection: next, anchor: id)

    case .range:
      guard
        let start = anchor.flatMap({ orderedIds.firstIndex(of: $0) }),
        let end = orderedIds.firstIndex(of: id)
      else {
        // Anchor missing or not in current visible order — fall back to
        // plain selection so the user isn't left with stale state.
        return Result(selection: [id], anchor: id)
      }
      let range = start <= end ? start...end : end...start
      let next = Set(orderedIds[range])
      return Result(selection: next, anchor: anchor ?? id)
    }
  }
}
