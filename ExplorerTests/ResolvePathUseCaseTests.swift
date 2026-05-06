//
//  ResolvePathUseCaseTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct ResolvePathUseCaseTests {
  let home = Folder(path: "/Users/test")

  private func makeSUT(
    kinds: [String: FilesystemEntryKind] = [:]
  ) -> (ResolvePathUseCase, FakeFilesystemRepository) {
    let repo = FakeFilesystemRepository(home: home)
    repo.stubbedKinds = kinds
    return (ResolvePathUseCase(repository: repo), repo)
  }

  @Test func emptyInputFails() async {
    let (useCase, _) = makeSUT()
    let result = await useCase.resolvePath(rawInput: "   ", relativeTo: home)
    #expect(result == .failure(.empty))
  }

  @Test func absoluteDirectoryResolves() async {
    let target = "/Users/test/Documents"
    let (useCase, _) = makeSUT(kinds: [target: .directory])
    let result = await useCase.resolvePath(rawInput: target, relativeTo: home)
    if case .success(let folder) = result {
      #expect(folder.path == target)
    } else {
      Issue.record("expected success, got \(result)")
    }
  }

  @Test func tildeExpandsToHome() async {
    let (useCase, _) = makeSUT(kinds: [home.path: .directory])
    let result = await useCase.resolvePath(rawInput: "~", relativeTo: home)
    if case .success(let folder) = result {
      #expect(folder.path == home.path)
    } else {
      Issue.record("expected success, got \(result)")
    }
  }

  @Test func tildeWithSuffixAppendsToHome() async {
    let target = "/Users/test/Documents"
    let (useCase, _) = makeSUT(kinds: [target: .directory])
    let result = await useCase.resolvePath(rawInput: "~/Documents", relativeTo: home)
    if case .success(let folder) = result {
      #expect(folder.path == target)
    } else {
      Issue.record("expected success, got \(result)")
    }
  }

  @Test func missingPathFails() async {
    let (useCase, _) = makeSUT()
    let result = await useCase.resolvePath(rawInput: "/no-such-place", relativeTo: home)
    #expect(result == .failure(.notFound))
  }

  @Test func filePathFailsAsNotADirectory() async {
    let target = "/Users/test/note.txt"
    let (useCase, _) = makeSUT(kinds: [target: .file])
    let result = await useCase.resolvePath(rawInput: target, relativeTo: home)
    #expect(result == .failure(.notADirectory))
  }
}
