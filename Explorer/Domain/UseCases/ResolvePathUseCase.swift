//
//  ResolvePathUseCase.swift
//  Explorer
//
//  Resolves a user-typed path to an existing Folder. Pure parsing logic
//  combined with a filesystem existence check via the repository.
//

import Foundation

enum ResolvePathError: Error, Equatable {
  case empty
  case notFound
  case notADirectory
}

struct ResolvePathUseCase: Sendable {
  private let repository: FilesystemRepository

  init(repository: FilesystemRepository) {
    self.repository = repository
  }

  func resolvePath(rawInput: String, relativeTo base: Folder) async -> Result<Folder, ResolvePathError> {
    let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .failure(.empty) }

    let candidate = computeCandidate(trimmed, base: base.url)
    let normalized = candidate.standardizedFileURL.resolvingSymlinksInPath()

    switch await repository.entryKind(at: normalized) {
    case .directory:
      return .success(Folder(url: normalized))
    case .file:
      return .failure(.notADirectory)
    case .missing:
      return .failure(.notFound)
    }
  }

  private func computeCandidate(_ input: String, base: URL) -> URL {
    if input.hasPrefix("~") {
      let home = repository.home.url
      let suffix = String(input.dropFirst()).trimmingCharacters(
        in: CharacterSet(charactersIn: "/")
      )
      return suffix.isEmpty
        ? home
        : home.appending(path: suffix, directoryHint: .checkFileSystem)
    }
    if input.hasPrefix("/") {
      return URL(filePath: input, directoryHint: .checkFileSystem)
    }
    return URL(filePath: input, directoryHint: .checkFileSystem, relativeTo: base)
  }
}
