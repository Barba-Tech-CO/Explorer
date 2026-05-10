//
//  ListContentsUseCase.swift
//  Explorer
//
//  Returns the entries that should populate the file list pane for a folder.
//  Pure delegation to the repository today; kept as its own type so the
//  presentation layer never depends on the repository protocol directly.
//

import Foundation

struct ListContentsUseCase: Sendable {
  private let repository: FilesystemRepository

  init(repository: FilesystemRepository) {
    self.repository = repository
  }

  func listContents(of folder: Folder) async -> Result<[FSEntry], FilesystemError> {
    await repository.listContents(of: folder)
  }
}
