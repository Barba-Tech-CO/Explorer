//
//  BreadcrumbsItem.swift
//  Explorer
//
//  One slot in the rendered breadcrumb bar: either a real path segment or a
//  collapsed group of segments hidden behind an ellipsis button.
//

import Foundation

enum BreadcrumbsItem: Identifiable, Equatable {
  case segment(PathSegment)
  case ellipsis(omitted: [PathSegment])

  var id: String {
    switch self {
    case .segment(let segment):
      return "s:\(segment.id)"
    case .ellipsis(let omitted):
      let ids = omitted.map { String($0.id) }.joined(separator: ",")
      return "e:\(ids)"
    }
  }
}
