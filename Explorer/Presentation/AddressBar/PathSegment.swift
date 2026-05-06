//
//  PathSegment.swift
//  Explorer
//

import Foundation

struct PathSegment: Identifiable, Hashable {
  let id: Int
  let folder: Folder

  var title: String { folder.name }

  static func segments(for folder: Folder) -> [PathSegment] {
    let components = folder.url.pathComponents
    guard !components.isEmpty else { return [] }

    var accumulated = URL(filePath: "/", directoryHint: .isDirectory)
    var result: [PathSegment] = []

    for (index, component) in components.enumerated() {
      if component == "/" {
        result.append(PathSegment(id: index, folder: Folder(url: accumulated)))
      } else {
        accumulated.append(component: component, directoryHint: .isDirectory)
        result.append(PathSegment(id: index, folder: Folder(url: accumulated)))
      }
    }
    return result
  }
}
