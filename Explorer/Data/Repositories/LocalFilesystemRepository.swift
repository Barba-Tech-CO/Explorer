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

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemRepositoryError> {
    do {
      let entries = try fileManager.contentsOfDirectory(
        at: folder.url,
        includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      )
      let dirs = entries.filter { entry in
        (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
      }
      let sorted = dirs.sorted { lhs, rhs in
        lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
      }
      return .success(sorted.map(Folder.init(url:)))
    } catch {
      log.error(
        "subfolders failed at \(folder.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      return .failure(.unreadable)
    }
  }
}
