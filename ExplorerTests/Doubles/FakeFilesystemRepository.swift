//
//  FakeFilesystemRepository.swift
//  ExplorerTests
//

import Foundation
@testable import Explorer

final class FakeFilesystemRepository: FilesystemRepository, @unchecked Sendable {
  var stubbedHome: Folder
  var stubbedKinds: [String: FilesystemEntryKind] = [:] {
    didSet { stubbedKinds = stubbedKinds.reduce(into: [:]) { $0[Self.normalize($1.key)] = $1.value } }
  }
  var stubbedSubfolders: [String: [Folder]] = [:]

  init(home: Folder = Folder(path: "/Users/test")) {
    self.stubbedHome = home
  }

  var home: Folder { stubbedHome }

  func entryKind(at url: URL) async -> FilesystemEntryKind {
    stubbedKinds[Self.normalize(url.path(percentEncoded: false))] ?? .missing
  }

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemRepositoryError> {
    .success(stubbedSubfolders[Self.normalize(folder.path)] ?? [])
  }

  private static func normalize(_ path: String) -> String {
    var p = path
    while p.count > 1 && p.hasSuffix("/") { p.removeLast() }
    return p
  }
}
