//
//  SidebarTreeViewModel.swift
//  Explorer
//
//  Expansion state for the sidebar tree. Subfolders are listed the moment a
//  node is expanded and dropped again when it collapses, so re-expanding a
//  node always shows what is on disk now instead of a snapshot from earlier
//  in the session.
//

import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "Sidebar")

@MainActor
@Observable
final class SidebarTreeViewModel {
  private(set) var expanded: Set<Folder> = []
  private(set) var children: [Folder: [Folder]] = [:]
  private(set) var loading: Set<Folder> = []

  private let listSubfolders: ListSubfoldersUseCase
  /// Identifies the expansion a listing belongs to. Collapsing clears the
  /// token and re-expanding mints a new one, so a listing that lands after
  /// either event can tell it has been superseded and drop its result.
  private var expansionToken: [Folder: UUID] = [:]

  init(listSubfolders: ListSubfoldersUseCase) {
    self.listSubfolders = listSubfolders
  }

  func isExpanded(_ folder: Folder) -> Bool {
    expanded.contains(folder)
  }

  func setExpanded(_ isExpanded: Bool, for folder: Folder) async {
    isExpanded ? await expand(folder) : collapse(folder)
  }

  func expand(_ folder: Folder) async {
    guard !expanded.contains(folder) else { return }
    let token = UUID()
    expansionToken[folder] = token
    expanded.insert(folder)
    loading.insert(folder)
    let result = await listSubfolders.listSubfolders(of: folder)
    // Checked before touching any state: collapsing clears the token and a
    // quick collapse-then-reopen mints a new one, so an older listing must
    // not write its rows — nor clear the `loading` flag now owned by the
    // newer expansion — just because the node happens to be open again.
    guard expansionToken[folder] == token else { return }
    loading.remove(folder)
    switch result {
    case .success(let subfolders):
      children[folder] = subfolders
    case .failure(let error):
      // An unreadable node expands to nothing rather than an error row: the
      // file list already explains the failure when the user navigates in.
      log.notice("sidebar expand failed at \(folder.path, privacy: .public): \(String(describing: error), privacy: .public)")
      children[folder] = []
    }
  }

  /// Closes `folder` and forgets everything cached beneath it. Dropping only
  /// the node itself would leave expanded descendants holding listings from
  /// whenever they were first opened, and reopening the branch would restore
  /// that stale subtree instead of re-reading it.
  func collapse(_ folder: Folder) {
    forgetSubtree(of: folder)
    forget(folder)
  }

  private func forgetSubtree(of folder: Folder) {
    for child in children[folder] ?? [] {
      forgetSubtree(of: child)
      forget(child)
    }
  }

  private func forget(_ folder: Folder) {
    expanded.remove(folder)
    children[folder] = nil
    loading.remove(folder)
    expansionToken[folder] = nil
  }
}
