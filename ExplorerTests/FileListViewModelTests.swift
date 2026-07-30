//
//  FileListViewModelTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

@MainActor
struct FileListViewModelTests {
  private let folder = Folder(path: "/Users/test/Documents")

  private func entry(_ name: String, size: Int64? = nil) -> FSEntry {
    FSEntry(
      url: URL(filePath: "/Users/test/Documents/\(name)"),
      name: name,
      isDirectory: false,
      size: size
    )
  }

  private func makeViewModel(
    contents: Result<[FSEntry], FilesystemError>
  ) -> (FileListViewModel, FakeFilesystemRepository) {
    let repository = FakeFilesystemRepository()
    repository.stubbedContents[folder.path] = contents
    let viewModel = FileListViewModel(
      listContents: ListContentsUseCase(repository: repository)
    )
    return (viewModel, repository)
  }

  @Test func navigationLoadClearsAnyPreviousSelection() async {
    let (viewModel, _) = makeViewModel(contents: .success([entry("a"), entry("b")]))
    await viewModel.load(folder)
    viewModel.selection = [entry("a").id]

    await viewModel.load(folder)

    #expect(viewModel.selection.isEmpty)
    #expect(viewModel.state == .loaded)
  }

  @Test func refreshKeepsSelectionForRowsThatStillExist() async {
    let (viewModel, _) = makeViewModel(contents: .success([entry("a"), entry("b")]))
    await viewModel.load(folder)
    viewModel.selection = [entry("a").id, entry("b").id]

    await viewModel.load(folder, refreshing: true)

    #expect(viewModel.selection == [entry("a").id, entry("b").id])
  }

  @Test func refreshDropsSelectedRowsThatVanishedFromDisk() async {
    let (viewModel, repository) = makeViewModel(
      contents: .success([entry("a"), entry("b")])
    )
    await viewModel.load(folder)
    viewModel.selection = [entry("a").id, entry("b").id]

    // `b` was deleted between the two listings.
    repository.stubbedContents[folder.path] = .success([entry("a")])
    await viewModel.load(folder, refreshing: true)

    #expect(viewModel.selection == [entry("a").id])
    #expect(viewModel.entries.map(\.name) == ["a"])
  }

  @Test func refreshThatFailsClearsRowsAndSelection() async {
    let (viewModel, repository) = makeViewModel(contents: .success([entry("a")]))
    await viewModel.load(folder)
    viewModel.selection = [entry("a").id]

    repository.stubbedContents[folder.path] = .failure(.denied)
    await viewModel.load(folder, refreshing: true)

    #expect(viewModel.state == .failed(.denied))
    #expect(viewModel.entries.isEmpty)
    // The rows are gone from the screen, so the selection must go with them.
    #expect(viewModel.selection.isEmpty)
  }

  @Test func refreshOutOfAFailedListingDoesNotKeepTheFailureState() async {
    let (viewModel, repository) = makeViewModel(contents: .failure(.denied))
    await viewModel.load(folder)
    #expect(viewModel.state == .failed(.denied))

    // Retrying after the user grants access: the pane must end up showing the
    // rows, not the stale error.
    repository.stubbedContents[folder.path] = .success([entry("a")])
    await viewModel.load(folder, refreshing: true)

    #expect(viewModel.state == .loaded)
    #expect(viewModel.entries.map(\.name) == ["a"])
  }

  @Test func refreshPicksUpRowsAddedSinceTheLastListing() async {
    let (viewModel, repository) = makeViewModel(contents: .success([entry("a")]))
    await viewModel.load(folder)

    repository.stubbedContents[folder.path] = .success([entry("a"), entry("c")])
    await viewModel.load(folder, refreshing: true)

    #expect(viewModel.entries.map(\.name) == ["a", "c"])
    #expect(viewModel.state == .loaded)
  }
}
