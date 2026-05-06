//
//  PathResolver.swift
//  Explorer
//
//  Resolves user-typed path strings to absolute URLs.
//

import Foundation

enum PathResolverError: Error, Equatable {
    case empty
    case notFound
    case notADirectory
}

struct PathResolver {
    let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func resolve(_ raw: String, relativeTo base: URL) -> Result<URL, PathResolverError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        let candidate = absoluteURL(for: trimmed, relativeTo: base)
        let resolved = candidate.standardizedFileURL.resolvingSymlinksInPath()

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: resolved.path(percentEncoded: false), isDirectory: &isDir) else {
            return .failure(.notFound)
        }
        guard isDir.boolValue else {
            return .failure(.notADirectory)
        }
        return .success(resolved)
    }

    private func absoluteURL(for input: String, relativeTo base: URL) -> URL {
        if input.hasPrefix("~") {
            let home = fileManager.homeDirectoryForCurrentUser
            let suffix = String(input.dropFirst()).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return suffix.isEmpty ? home : home.appending(path: suffix, directoryHint: .checkFileSystem)
        }
        if input.hasPrefix("/") {
            return URL(filePath: input, directoryHint: .checkFileSystem)
        }
        return URL(filePath: input, directoryHint: .checkFileSystem, relativeTo: base)
    }
}
