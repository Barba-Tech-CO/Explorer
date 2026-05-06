//
//  FakeFilesystemRepository.swift
//  ExplorerTests
//

import Foundation
@testable import Explorer

final class FakeFilesystemRepository: FilesystemRepository, @unchecked Sendable {
  var stubbedHome: Folder
  var stubbedKinds: [String: FilesystemEntryKind] = [:]
  var stubbedSubfolders: [String: [Folder]] = [:]

  init(home: Folder = Folder(path: "/Users/test")) {
    self.stubbedHome = home
  }

  var home: Folder { stubbedHome }

  func entryKind(at url: URL) async -> FilesystemEntryKind {
    stubbedKinds[url.path(percentEncoded: false)] ?? .missing
  }

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemRepositoryError> {
    .success(stubbedSubfolders[folder.path] ?? [])
  }
}
