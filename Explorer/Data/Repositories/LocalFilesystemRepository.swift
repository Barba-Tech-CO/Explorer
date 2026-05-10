//
//  LocalFilesystemRepository.swift
//  Explorer
//
//  Implements FilesystemRepository against the local disk via FileManager.
//

import Foundation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "Filesystem")

final class LocalFilesystemRepository: FilesystemRepository, @unchecked Sendable {
  private let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  var home: Folder {
    Folder(url: fileManager.homeDirectoryForCurrentUser)
  }

  func entryKind(at url: URL) async -> FilesystemEntryKind {
    var isDir: ObjCBool = false
    let exists = fileManager.fileExists(
      atPath: url.path(percentEncoded: false),
      isDirectory: &isDir
    )
    guard exists else { return .missing }
    return isDir.boolValue ? .directory : .file
  }

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemError> {
    await readDirectory(folder).map { urls in
      urls
        .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
        .sorted { lhs, rhs in
          lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
        }
        .map(Folder.init(url:))
    }
  }

  func listContents(of folder: Folder) async -> Result<[FSEntry], FilesystemError> {
    await readDirectory(folder).map { urls in
      urls
        .map(makeEntry(from:))
        .sorted { lhs, rhs in
          if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
          return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
  }

  func volumeFreeBytes(at folder: Folder) async -> Int64? {
    let values = try? folder.url.resourceValues(
      forKeys: [.volumeAvailableCapacityKey]
    )
    return values?.volumeAvailableCapacity.map { Int64($0) }
  }

  // MARK: - Private

  private static let listingResourceKeys: Set<URLResourceKey> = [
    .isDirectoryKey,
    .fileSizeKey,
    .contentModificationDateKey,
    .typeIdentifierKey,
    .nameKey,
  ]

  private func readDirectory(_ folder: Folder) async -> Result<[URL], FilesystemError> {
    do {
      let entries = try fileManager.contentsOfDirectory(
        at: folder.url,
        includingPropertiesForKeys: Array(Self.listingResourceKeys),
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      )
      return .success(entries)
    } catch {
      let mapped = FilesystemErrorMapper.map(error)
      log.error(
        "readDirectory failed at \(folder.path, privacy: .public) → \(String(describing: mapped), privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      return .failure(mapped)
    }
  }

  private func makeEntry(from url: URL) -> FSEntry {
    let values = try? url.resourceValues(forKeys: Self.listingResourceKeys)
    let isDirectory = values?.isDirectory ?? false
    let size = values?.fileSize.map { Int64($0) }
    return FSEntry(
      url: url,
      name: values?.name ?? url.lastPathComponent,
      isDirectory: isDirectory,
      size: isDirectory ? nil : size,
      modificationDate: values?.contentModificationDate,
      typeIdentifier: values?.typeIdentifier
    )
  }
}
