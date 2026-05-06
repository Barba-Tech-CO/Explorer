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

  func listSubfolders(of parent: Folder) async -> Result<[Folder], FilesystemError> {
    await repository.subfolders(of: parent)
  }
}
