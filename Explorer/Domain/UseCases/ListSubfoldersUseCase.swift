//
//  ListSubfoldersUseCase.swift
//  Explorer
//

import Foundation

struct ListSubfoldersUseCase: Sendable {
  private let repository: FilesystemRepository

  init(repository: FilesystemRepository) {
    self.repository = repository
  }

  func execute(parent: Folder) async -> Result<[Folder], FilesystemRepositoryError> {
    await repository.subfolders(of: parent)
  }
}
