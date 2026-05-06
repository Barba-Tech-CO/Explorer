//
//  Folder.swift
//  Explorer
//
//  Domain entity representing a directory in the filesystem.
//

import Foundation

struct Folder: Hashable, Identifiable, Sendable {
  let url: URL

  init(url: URL) {
    self.url = url
  }

  init(path: String) {
    self.url = URL(filePath: path, directoryHint: .isDirectory)
  }

  var id: URL { url }
  var path: String { url.path(percentEncoded: false) }
  var isRoot: Bool { url.pathComponents == ["/"] }

  var name: String {
    isRoot ? "Macintosh HD" : url.lastPathComponent
  }

  var parent: Folder? {
    guard !isRoot else { return nil }
    return Folder(url: url.deletingLastPathComponent())
  }
}
