//
//  BreadcrumbsBarView.swift
//  Explorer
//
//  Renders the breadcrumb trail with responsive collapsing: when the bar
//  doesn't have enough room, middle segments fold behind a "…" button.
//
//  Layout strategy:
//   - A hidden measurement HStack renders every segment plus a sample
//     ellipsis at intrinsic size, capturing each width via PreferenceKey.
//   - A separate PreferenceKey captures the container's available width.
//   - `BreadcrumbsLayout.collapse` (pure, tested) decides which items survive.
//

import SwiftUI

struct BreadcrumbsBarView: View {
  let segments: [PathSegment]
  let listSubfolders: ListSubfoldersUseCase
  let onSelect: (Folder) -> Void

  @State private var widths: [Int: CGFloat] = [:]
  @State private var ellipsisWidth: CGFloat = 0
  @State private var availableWidth: CGFloat = 0

  var body: some View {
    let items = BreadcrumbsLayout.collapse(
      segments: segments,
      widths: widths,
      available: availableWidth,
      ellipsisWidth: ellipsisWidth
    )
    return HStack(spacing: 0) {
      ForEach(items) { item in
        switch item {
        case .segment(let segment):
          BreadcrumbSegmentView(
            segment: segment,
            isFirst: segment.id == 0,
            listSubfolders: listSubfolders,
            onSelect: onSelect
          )
        case .ellipsis(let omitted):
          CollapsedSegmentView(omitted: omitted, onSelect: onSelect)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      GeometryReader { proxy in
        Color.clear.preference(
          key: AvailableWidthKey.self,
          value: proxy.size.width
        )
      }
    )
    .background(measurementBar)
    .onPreferenceChange(SegmentWidthKey.self) { newValue in
      // Guard against sub-pixel jitter so width updates don't oscillate the
      // layout decision on every frame.
      var merged = widths
      var changed = false
      for (id, value) in newValue {
        let rounded = value.rounded()
        if abs((merged[id] ?? -1) - rounded) > 0.5 {
          merged[id] = rounded
          changed = true
        }
      }
      if changed { widths = merged }
    }
    .onPreferenceChange(EllipsisWidthKey.self) { newValue in
      let rounded = newValue.rounded()
      if abs(ellipsisWidth - rounded) > 0.5 { ellipsisWidth = rounded }
    }
    .onPreferenceChange(AvailableWidthKey.self) { newValue in
      let rounded = newValue.rounded()
      if abs(availableWidth - rounded) > 0.5 { availableWidth = rounded }
    }
    .onChange(of: segments) { _, _ in
      widths = [:]
    }
  }

  private var measurementBar: some View {
    HStack(spacing: 0) {
      ForEach(segments) { segment in
        BreadcrumbSegmentView(
          segment: segment,
          isFirst: segment.id == 0,
          listSubfolders: listSubfolders,
          onSelect: { _ in }
        )
        .background(
          GeometryReader { proxy in
            Color.clear.preference(
              key: SegmentWidthKey.self,
              value: [segment.id: proxy.size.width]
            )
          }
        )
      }
      CollapsedSegmentView(omitted: [], onSelect: { _ in })
        .background(
          GeometryReader { proxy in
            Color.clear.preference(
              key: EllipsisWidthKey.self,
              value: proxy.size.width
            )
          }
        )
    }
    .fixedSize()
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .hidden()
  }
}

// MARK: - PreferenceKeys

private struct SegmentWidthKey: PreferenceKey {
  static let defaultValue: [Int: CGFloat] = [:]
  static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
    value.merge(nextValue()) { _, new in new }
  }
}

private struct EllipsisWidthKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

private struct AvailableWidthKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}
