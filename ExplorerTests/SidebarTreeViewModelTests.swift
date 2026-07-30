//
//  SidebarTreeViewModelTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

@MainActor
struct SidebarTreeViewModelTests {
  private let parent = Folder(path: "/Users/test/Documents")
  private let childA = Folder(path: "/Users/test/Documents/Reports")
  private let childB = Folder(path: "/Users/test/Documents/Invoices")

  private func makeTree(
    subfolders: Result<[Folder], FilesystemError>
  ) -> (SidebarTreeViewModel, FakeFilesystemRepository) {
    let repository = FakeFilesystemRepository()
    repository.stubbedSubfolders[parent.path] = subfolders
    let tree = SidebarTreeViewModel(
      listSubfolders: ListSubfoldersUseCase(repository: repository)
    )
    return (tree, repository)
  }

  @Test func expandingListsTheSubfolders() async {
    let (tree, _) = makeTree(subfolders: .success([childA, childB]))

    await tree.setExpanded(true, for: parent)

    #expect(tree.isExpanded(parent))
    #expect(tree.children[parent] == [childA, childB])
    #expect(tree.loading.isEmpty)
  }

  @Test func collapsingDropsTheCachedSubfolders() async {
    let (tree, repository) = makeTree(subfolders: .success([childA]))
    await tree.setExpanded(true, for: parent)

    await tree.setExpanded(false, for: parent)
    #expect(tree.isExpanded(parent) == false)
    #expect(tree.children[parent] == nil)

    // Re-expanding must hit the filesystem again rather than replay the old
    // listing, so a folder created while the node was closed shows up.
    repository.stubbedSubfolders[parent.path] = .success([childA, childB])
    await tree.setExpanded(true, for: parent)
    #expect(tree.children[parent] == [childA, childB])
  }

  @Test func collapsingWhileLoadingDiscardsTheListing() async {
    let (tree, repository) = makeTree(subfolders: .success([childA, childB]))
    repository.onSubfolders = { [weak tree] in
      // The user closes the node before the listing lands.
      tree?.collapse(self.parent)
    }

    await tree.setExpanded(true, for: parent)

    #expect(tree.isExpanded(parent) == false)
    #expect(tree.children[parent] == nil)
  }

  @Test func anUnreadableFolderExpandsToNothing() async {
    let (tree, _) = makeTree(subfolders: .failure(.denied))

    await tree.setExpanded(true, for: parent)

    #expect(tree.isExpanded(parent))
    #expect(tree.children[parent] == [])
  }
}
