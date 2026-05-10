//
//  LocalFilesystemRepositoryTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct LocalFilesystemRepositoryTests {
  // MARK: - listContents

  @Test func listContentsReturnsDirectoriesFirstThenFiles() async throws {
    let tmp = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tmp) }

    try FileManager.default.createDirectory(at: tmp.appending(path: "alpha"), withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: tmp.appending(path: "zeta"), withIntermediateDirectories: false)
    try Data("hello".utf8).write(to: tmp.appending(path: "a.txt"))
    try Data("hi".utf8).write(to: tmp.appending(path: "m.txt"))

    let repo = LocalFilesystemRepository()
    let result = await repo.listContents(of: Folder(url: tmp))

    guard case .success(let entries) = result else {
      Issue.record("expected success, got \(result)")
      return
    }
    #expect(entries.map(\.name) == ["alpha", "zeta", "a.txt", "m.txt"])
    #expect(entries[0].isDirectory == true)
    #expect(entries[2].isDirectory == false)
  }

  @Test func listContentsExposesSizeAndModificationDateForFiles() async throws {
    let tmp = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tmp) }

    let payload = Data("12345".utf8)
    let file = tmp.appending(path: "note.txt")
    try payload.write(to: file)

    let repo = LocalFilesystemRepository()
    let result = await repo.listContents(of: Folder(url: tmp))

    guard case .success(let entries) = result, let entry = entries.first(where: { $0.name == "note.txt" }) else {
      Issue.record("expected note.txt in listing, got \(result)")
      return
    }
    #expect(entry.size == Int64(payload.count))
    #expect(entry.modificationDate != nil)
    #expect(entry.isDirectory == false)
  }

  @Test func listContentsSkipsHiddenFiles() async throws {
    let tmp = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tmp) }

    try Data().write(to: tmp.appending(path: ".hidden"))
    try Data().write(to: tmp.appending(path: "visible.txt"))

    let repo = LocalFilesystemRepository()
    let result = await repo.listContents(of: Folder(url: tmp))

    guard case .success(let entries) = result else {
      Issue.record("expected success, got \(result)")
      return
    }
    #expect(entries.map(\.name) == ["visible.txt"])
  }

  @Test func listContentsMapsMissingPathToNotFound() async {
    let bogus = URL(filePath: "/var/folders/__explorer_does_not_exist__/\(UUID().uuidString)")
    let repo = LocalFilesystemRepository()
    let result = await repo.listContents(of: Folder(url: bogus))
    #expect(result == .failure(.notFound))
  }

  // MARK: - volumeFreeBytes

  @Test func volumeFreeBytesReportsAvailableCapacityForTempVolume() async throws {
    let tmp = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: tmp) }

    let repo = LocalFilesystemRepository()
    let free = await repo.volumeFreeBytes(at: Folder(url: tmp))

    // The boot volume always reports a non-nil, positive value; the test is
    // pinned to a temp directory under it so we don't depend on the host's
    // exact disk state.
    #expect(free != nil)
    #expect((free ?? 0) > 0)
  }

  // MARK: - helpers

  private func makeTempDirectory() throws -> URL {
    let url = URL(filePath: NSTemporaryDirectory())
      .appending(path: "ExplorerTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}
