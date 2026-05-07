//
//  BreadcrumbsLayoutTests.swift
//  ExplorerTests
//

import Testing
import CoreGraphics
@testable import Explorer

struct BreadcrumbsLayoutTests {

  // MARK: - Helpers

  private func segments(_ paths: [String]) -> [PathSegment] {
    paths.enumerated().map { index, path in
      PathSegment(id: index, folder: Folder(path: path))
    }
  }

  private func widths(_ values: [CGFloat]) -> [Int: CGFloat] {
    Dictionary(uniqueKeysWithValues: values.enumerated().map { ($0.offset, $0.element) })
  }

  // MARK: - Tests

  @Test func allFitReturnsAllSegments() {
    let segs = segments(["/", "/Users", "/Users/test", "/Users/test/Documents"])
    let items = BreadcrumbsLayout.collapse(
      segments: segs,
      widths: widths([60, 60, 80, 100]),
      available: 1000,
      ellipsisWidth: 30
    )
    #expect(items.count == 4)
    for (i, item) in items.enumerated() {
      guard case .segment(let s) = item else {
        Issue.record("expected segment at \(i), got \(item)")
        return
      }
      #expect(s.id == i)
    }
  }

  @Test func tightFitCollapsesMiddle() {
    // Total = 60+60+80+80+100+120 = 500. Available = 280, ellipsis = 30.
    // Pinned first(60) + ellipsis(30). Remaining = 190.
    // Walk from end: 120 (tail, budget 70), 100 (tail, budget -30 → still kept? no).
    // Tail-fits check: 120 fits (budget=70), 100 needs 100 but budget=70 → omit.
    // Result: first / ellipsis(2..3) / 120
    let segs = segments(["/a", "/a/b", "/a/b/c", "/a/b/c/d", "/a/b/c/d/e", "/a/b/c/d/e/f"])
    let items = BreadcrumbsLayout.collapse(
      segments: segs,
      widths: widths([60, 60, 80, 80, 100, 120]),
      available: 280,
      ellipsisWidth: 30
    )
    guard items.count == 3 else {
      Issue.record("expected 3 items, got \(items)")
      return
    }
    if case .segment(let s) = items[0] { #expect(s.id == 0) } else { Issue.record("first not segment") }
    if case .ellipsis(let omitted) = items[1] {
      #expect(omitted.map(\.id) == [1, 2, 3, 4])
    } else {
      Issue.record("middle not ellipsis: \(items[1])")
    }
    if case .segment(let s) = items[2] { #expect(s.id == 5) } else { Issue.record("last not segment") }
  }

  @Test func extremelyNarrowKeepsFirstAndLast() {
    let segs = segments(["/a", "/a/b", "/a/b/c", "/a/b/c/d"])
    // available smaller than even first + ellipsis + last; must still keep first + ellipsis + last.
    let items = BreadcrumbsLayout.collapse(
      segments: segs,
      widths: widths([100, 100, 100, 100]),
      available: 10,
      ellipsisWidth: 30
    )
    #expect(items.count == 3)
    if case .segment(let s) = items[0] { #expect(s.id == 0) } else { Issue.record("first not segment") }
    if case .ellipsis(let omitted) = items[1] {
      #expect(omitted.map(\.id) == [1, 2])
    } else {
      Issue.record("middle not ellipsis")
    }
    if case .segment(let s) = items[2] { #expect(s.id == 3) } else { Issue.record("last not segment") }
  }

  @Test func singleSegmentNeverCollapses() {
    let one = segments(["/"])
    let oneItems = BreadcrumbsLayout.collapse(
      segments: one,
      widths: widths([5000]),
      available: 10,
      ellipsisWidth: 30
    )
    #expect(oneItems.count == 1)

    let two = segments(["/", "/Users"])
    let twoItems = BreadcrumbsLayout.collapse(
      segments: two,
      widths: widths([5000, 5000]),
      available: 10,
      ellipsisWidth: 30
    )
    #expect(twoItems.count == 2)
    if case .ellipsis = twoItems[0] {
      Issue.record("two segments should never produce an ellipsis")
    }
  }

  @Test func missingWidthsFallbackToAll() {
    let segs = segments(["/a", "/a/b", "/a/b/c", "/a/b/c/d"])
    // Only 2 of 4 measured.
    let items = BreadcrumbsLayout.collapse(
      segments: segs,
      widths: [0: 60, 2: 80],
      available: 100,
      ellipsisWidth: 30
    )
    #expect(items.count == 4)
    for item in items {
      if case .ellipsis = item {
        Issue.record("should not collapse when widths are incomplete")
      }
    }
  }
}
