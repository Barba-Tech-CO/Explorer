//
//  MultiSelectionTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct MultiSelectionTests {
  // Synthetic ids backed by a stable URL set; order matches a 5-row list.
  private let ids: [URL] = [
    URL(filePath: "/Users/test/a"),
    URL(filePath: "/Users/test/b"),
    URL(filePath: "/Users/test/c"),
    URL(filePath: "/Users/test/d"),
    URL(filePath: "/Users/test/e"),
  ]

  @Test func plainClickReplacesSelectionAndAnchors() {
    let r = MultiSelection.resolve(
      click: ids[2],
      gesture: .plain,
      current: [ids[0], ids[1]],
      anchor: ids[0],
      orderedIds: ids
    )
    #expect(r.selection == [ids[2]])
    #expect(r.anchor == ids[2])
  }

  @Test func toggleAddsWhenMissingMovesAnchor() {
    let r = MultiSelection.resolve(
      click: ids[3],
      gesture: .toggle,
      current: [ids[1]],
      anchor: ids[1],
      orderedIds: ids
    )
    #expect(r.selection == [ids[1], ids[3]])
    #expect(r.anchor == ids[3])
  }

  @Test func toggleRemovesWhenPresent() {
    let r = MultiSelection.resolve(
      click: ids[1],
      gesture: .toggle,
      current: [ids[0], ids[1], ids[2]],
      anchor: ids[2],
      orderedIds: ids
    )
    #expect(r.selection == [ids[0], ids[2]])
    #expect(r.anchor == ids[1])
  }

  @Test func rangeSelectsContiguousSliceFromAnchor() {
    let r = MultiSelection.resolve(
      click: ids[3],
      gesture: .range,
      current: [ids[1]],
      anchor: ids[1],
      orderedIds: ids
    )
    #expect(r.selection == Set(ids[1...3]))
    #expect(r.anchor == ids[1])
  }

  @Test func rangeWorksBackwardsWhenClickIsAboveAnchor() {
    let r = MultiSelection.resolve(
      click: ids[0],
      gesture: .range,
      current: [ids[3]],
      anchor: ids[3],
      orderedIds: ids
    )
    #expect(r.selection == Set(ids[0...3]))
    #expect(r.anchor == ids[3])
  }

  @Test func rangeFallsBackToPlainWhenAnchorMissing() {
    let r = MultiSelection.resolve(
      click: ids[2],
      gesture: .range,
      current: [],
      anchor: nil,
      orderedIds: ids
    )
    #expect(r.selection == [ids[2]])
    #expect(r.anchor == ids[2])
  }

  @Test func rangeFallsBackWhenAnchorNotInVisibleSlice() {
    // Mimics filtering: anchor was visible before, now isn't in `orderedIds`.
    let visible = [ids[2], ids[3], ids[4]]
    let r = MultiSelection.resolve(
      click: ids[3],
      gesture: .range,
      current: [ids[3]],
      anchor: ids[0], // out of visible
      orderedIds: visible
    )
    #expect(r.selection == [ids[3]])
    #expect(r.anchor == ids[3])
  }
}
