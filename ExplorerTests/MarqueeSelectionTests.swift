//
//  MarqueeSelectionTests.swift
//  ExplorerTests
//

import Testing
import Foundation
import CoreGraphics
@testable import Explorer

struct MarqueeSelectionTests {
  private let a = URL(filePath: "/Users/test/a")
  private let b = URL(filePath: "/Users/test/b")
  private let c = URL(filePath: "/Users/test/c")

  /// Three cells laid out in a row, 100pt wide with a 20pt gutter.
  private var frames: [URL: CGRect] {
    [
      a: CGRect(x: 0, y: 0, width: 100, height: 100),
      b: CGRect(x: 120, y: 0, width: 100, height: 100),
      c: CGRect(x: 240, y: 0, width: 100, height: 100),
    ]
  }

  @Test func draggingUpAndLeftProducesTheSameRectAsDownAndRight() {
    let downRight = MarqueeSelection.rect(
      from: CGPoint(x: 10, y: 20),
      to: CGPoint(x: 110, y: 220)
    )
    let upLeft = MarqueeSelection.rect(
      from: CGPoint(x: 110, y: 220),
      to: CGPoint(x: 10, y: 20)
    )
    #expect(downRight == upLeft)
    #expect(downRight == CGRect(x: 10, y: 20, width: 100, height: 200))
  }

  @Test func bandSelectsEveryCellItTouches() {
    // Spans the first two cells and stops inside the gutter before the third.
    let band = CGRect(x: 50, y: 10, width: 120, height: 20)

    let selected = MarqueeSelection.resolve(
      marquee: band,
      frames: frames,
      base: [],
      additive: false
    )

    #expect(selected == [a, b])
  }

  @Test func aPlainBandReplacesTheExistingSelection() {
    let band = CGRect(x: 240, y: 0, width: 10, height: 10)

    let selected = MarqueeSelection.resolve(
      marquee: band,
      frames: frames,
      base: [a, b],
      additive: false
    )

    #expect(selected == [c])
  }

  @Test func anAdditiveBandKeepsWhatWasAlreadySelected() {
    let band = CGRect(x: 240, y: 0, width: 10, height: 10)

    let selected = MarqueeSelection.resolve(
      marquee: band,
      frames: frames,
      base: [a],
      additive: true
    )

    #expect(selected == [a, c])
  }

  @Test func aBandThatHasNotMovedSelectsNothing() {
    // Press without drag: a zero-area rect must not sweep up the cell under
    // the cursor, otherwise a click in empty space would select a neighbour.
    let band = MarqueeSelection.rect(
      from: CGPoint(x: 50, y: 50),
      to: CGPoint(x: 50, y: 50)
    )

    let selected = MarqueeSelection.resolve(
      marquee: band,
      frames: frames,
      base: [],
      additive: false
    )

    #expect(selected.isEmpty)
  }

  @Test func aBandInEmptySpaceSelectsNothing() {
    // Entirely inside the gutter between the first and second cells.
    let band = CGRect(x: 104, y: 10, width: 10, height: 10)

    let selected = MarqueeSelection.resolve(
      marquee: band,
      frames: frames,
      base: [],
      additive: false
    )

    #expect(selected.isEmpty)
  }
}
