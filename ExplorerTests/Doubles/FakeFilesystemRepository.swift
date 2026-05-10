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
  var stubbedSubfolders: [String: Result<[Folder], FilesystemError>] = [:]
  var stubbedContents: [String: Result<[FSEntry], FilesystemError>] = [:]
  var stubbedVolumeFreeBytes: [String: Int64?] = [:]

  init(home: Folder = Folder(path: "/Users/test")) {
    self.stubbedHome = home
  }

  var home: Folder { stubbedHome }

  func entryKind(at url: URL) async -> FilesystemEntryKind {
    stubbedKinds[Self.normalize(url.path(percentEncoded: false))] ?? .missing
  }

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemError> {
    stubbedSubfolders[Self.normalize(folder.path)] ?? .success([])
  }

  func listContents(of folder: Folder) async -> Result<[FSEntry], FilesystemError> {
    stubbedContents[Self.normalize(folder.path)] ?? .success([])
  }

  func volumeFreeBytes(at folder: Folder) async -> Int64? {
    stubbedVolumeFreeBytes[Self.normalize(folder.path)] ?? nil
  }

  private static func normalize(_ path: String) -> String {
    var p = path
    while p.count > 1 && p.hasSuffix("/") { p.removeLast() }
    return p
  }
}
