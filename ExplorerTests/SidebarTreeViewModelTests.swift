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

  /// Latch so the hook only hijacks the first listing.
  private final class Latch {
    var fired = false
  }

  @Test func aListingSupersededByAReopenDoesNotOverwriteTheFresherOne() async {
    let (tree, repository) = makeTree(subfolders: .success([childA]))
    let latch = Latch()

    repository.onSubfolders = { [weak tree] in
      guard !latch.fired else { return }
      latch.fired = true
      // The user closes and immediately reopens the node. The reopen runs to
      // completion right here, so the first listing resumes afterwards and
      // tries to write a result that is already obsolete.
      tree?.collapse(self.parent)
      repository.stubbedSubfolders[self.parent.path] = .success([self.childB])
      await tree?.expand(self.parent)
    }

    await tree.expand(parent)

    #expect(tree.children[parent] == [childB])
    #expect(tree.loading.isEmpty)
  }

  @Test func collapsingABranchForgetsItsExpandedDescendants() async {
    let (tree, repository) = makeTree(subfolders: .success([childA]))
    repository.stubbedSubfolders[childA.path] = .success([childB])

    await tree.expand(parent)
    await tree.expand(childA)
    #expect(tree.isExpanded(childA))

    tree.collapse(parent)

    // Reopening the branch must re-read every level, so no descendant may
    // survive the collapse holding a listing from before it.
    #expect(tree.isExpanded(childA) == false)
    #expect(tree.children[childA] == nil)
  }

  @Test func anUnreadableFolderExpandsToNothing() async {
    let (tree, _) = makeTree(subfolders: .failure(.denied))

    await tree.setExpanded(true, for: parent)

    #expect(tree.isExpanded(parent))
    #expect(tree.children[parent] == [])
  }
}
