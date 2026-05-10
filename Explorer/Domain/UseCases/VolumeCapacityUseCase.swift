//
//  VolumeCapacityUseCase.swift
//  Explorer
//
//  Reports the available capacity of the volume hosting a given folder, so
//  the status bar can show "<free> free" without the presentation layer
//  reaching into the repository directly.
//

import Foundation

struct VolumeCapacityUseCase: Sendable {
  private let repository: FilesystemRepository

  init(repository: FilesystemRepository) {
    self.repository = repository
  }

  func freeBytes(at folder: Folder) async -> Int64? {
    await repository.volumeFreeBytes(at: folder)
  }
}
