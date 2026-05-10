//
//  AppDependencies.swift
//  Explorer
//
//  Composition root container — wires repositories and use cases once at
//  startup and hands them to views via init parameters.
//

import Foundation

struct AppDependencies {
  let repository: FilesystemRepository
  let listSubfolders: ListSubfoldersUseCase
  let listContents: ListContentsUseCase
  let resolvePath: ResolvePathUseCase
  let volumeCapacity: VolumeCapacityUseCase

  static func live() -> AppDependencies {
    let repository = LocalFilesystemRepository()
    return AppDependencies(
      repository: repository,
      listSubfolders: ListSubfoldersUseCase(repository: repository),
      listContents: ListContentsUseCase(repository: repository),
      resolvePath: ResolvePathUseCase(repository: repository),
      volumeCapacity: VolumeCapacityUseCase(repository: repository)
    )
  }
}
