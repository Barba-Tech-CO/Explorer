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
  var isRoot: Bool { url.pathComponents == ["/"] }

  /// Canonical filesystem path: never carries a trailing slash (except for the
  /// root "/"). Stable across macOS versions, where `URL.path(percentEncoded:)`
  /// disagrees on whether to keep the trailing slash for directory URLs.
  var path: String {
    let raw = url.path(percentEncoded: false)
    if raw.count > 1, raw.hasSuffix("/") {
      return String(raw.dropLast())
    }
    return raw
  }

  var name: String {
    isRoot ? "Macintosh HD" : url.lastPathComponent
  }

  var parent: Folder? {
    guard !isRoot else { return nil }
    return Folder(url: url.deletingLastPathComponent())
  }
}
