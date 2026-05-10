//
//  SidebarSourcesUseCase.swift
//  Explorer
//
//  Feeds the sidebar with the two static groups it needs at startup: the
//  Quick Access shortcuts (well-known user folders, deterministic) and the
//  set of mounted volumes (boot volume + externals, dynamic — refreshed
//  whenever the host gets a mount/unmount notification).
//

import Foundation

struct SidebarSourcesUseCase: Sendable {
  private let repository: FilesystemRepository

  init(repository: FilesystemRepository) {
    self.repository = repository
  }

  var home: Folder {
    repository.home
  }

  var quickAccess: [Folder] {
    repository.quickAccessLocations
  }

  func mountedVolumes() async -> [Folder] {
    await repository.mountedVolumes()
  }
}
