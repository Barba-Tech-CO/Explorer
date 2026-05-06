//
//  FilesystemService.swift
//  Explorer
//
//  Reads directory contents and sibling folders for the address bar.
//

import Foundation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "Filesystem")

enum FilesystemError: Error {
    case unreadable(URL)
    case underlying(Error)
}

struct FilesystemService {
    let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func subdirectories(of url: URL) -> Result<[URL], FilesystemError> {
        do {
            let entries = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            let dirs = entries.filter { entry in
                (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            return .success(dirs.sorted { lhs, rhs in
                lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
            })
        } catch {
            log.error("Failed to read \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return .failure(.underlying(error))
        }
    }
}
