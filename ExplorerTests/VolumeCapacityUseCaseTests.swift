//
//  VolumeCapacityUseCaseTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct VolumeCapacityUseCaseTests {
  @Test func returnsBytesFromRepositoryWhenStubbed() async {
    let folder = Folder(path: "/Users/test")
    let repo = FakeFilesystemRepository(home: folder)
    repo.stubbedVolumeFreeBytes[folder.path] = 12_345
    let useCase = VolumeCapacityUseCase(repository: repo)

    let bytes = await useCase.freeBytes(at: folder)

    #expect(bytes == 12_345)
  }

  @Test func returnsNilWhenRepositoryHasNoStubForPath() async {
    let folder = Folder(path: "/Users/test/Downloads")
    let repo = FakeFilesystemRepository()
    let useCase = VolumeCapacityUseCase(repository: repo)

    let bytes = await useCase.freeBytes(at: folder)

    #expect(bytes == nil)
  }

  @Test func returnsNilWhenStubExplicitlyHoldsNil() async {
    let folder = Folder(path: "/Volumes/Detached")
    let repo = FakeFilesystemRepository()
    // updateValue avoids the dict-subscript ambiguity around erasing vs.
    // storing an explicit `nil` under an Optional-valued dict.
    repo.stubbedVolumeFreeBytes.updateValue(nil, forKey: folder.path)
    let useCase = VolumeCapacityUseCase(repository: repo)

    let bytes = await useCase.freeBytes(at: folder)

    #expect(bytes == nil)
  }

  @Test func passesThroughFolderToRepository() async {
    let alpha = Folder(path: "/Users/test/alpha")
    let beta = Folder(path: "/Users/test/beta")
    let repo = FakeFilesystemRepository()
    repo.stubbedVolumeFreeBytes[alpha.path] = 1_000
    repo.stubbedVolumeFreeBytes[beta.path] = 2_000
    let useCase = VolumeCapacityUseCase(repository: repo)

    let alphaBytes = await useCase.freeBytes(at: alpha)
    let betaBytes = await useCase.freeBytes(at: beta)

    #expect(alphaBytes == 1_000)
    #expect(betaBytes == 2_000)
  }
}
