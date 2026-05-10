//
//  SidebarSourcesUseCaseTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct SidebarSourcesUseCaseTests {
  @Test func homePassesThroughRepository() {
    let home = Folder(path: "/Users/somebody")
    let repo = FakeFilesystemRepository(home: home)
    let useCase = SidebarSourcesUseCase(repository: repo)

    #expect(useCase.home.path == "/Users/somebody")
  }

  @Test func quickAccessReturnsRepositoryListInOrder() {
    let repo = FakeFilesystemRepository()
    let desktop = Folder(path: "/Users/test/Desktop")
    let documents = Folder(path: "/Users/test/Documents")
    let downloads = Folder(path: "/Users/test/Downloads")
    repo.stubbedQuickAccessLocations = [desktop, documents, downloads]
    let useCase = SidebarSourcesUseCase(repository: repo)

    #expect(useCase.quickAccess.map(\.path) == [
      "/Users/test/Desktop",
      "/Users/test/Documents",
      "/Users/test/Downloads",
    ])
  }

  @Test func quickAccessIsEmptyWhenRepositoryReportsNoLocations() {
    let repo = FakeFilesystemRepository()
    let useCase = SidebarSourcesUseCase(repository: repo)

    #expect(useCase.quickAccess.isEmpty)
  }

  @Test func mountedVolumesPassesThroughRepositoryResult() async {
    let repo = FakeFilesystemRepository()
    let boot = Folder(path: "/")
    let external = Folder(path: "/Volumes/Backup")
    repo.stubbedMountedVolumes = [boot, external]
    let useCase = SidebarSourcesUseCase(repository: repo)

    let volumes = await useCase.mountedVolumes()

    #expect(volumes.map(\.path) == ["/", "/Volumes/Backup"])
  }

  @Test func mountedVolumesReflectsRepositoryUpdatesBetweenCalls() async {
    let repo = FakeFilesystemRepository()
    let useCase = SidebarSourcesUseCase(repository: repo)

    repo.stubbedMountedVolumes = [Folder(path: "/")]
    let before = await useCase.mountedVolumes()

    repo.stubbedMountedVolumes = [
      Folder(path: "/"),
      Folder(path: "/Volumes/Drive"),
    ]
    let after = await useCase.mountedVolumes()

    #expect(before.map(\.path) == ["/"])
    #expect(after.map(\.path) == ["/", "/Volumes/Drive"])
  }
}
