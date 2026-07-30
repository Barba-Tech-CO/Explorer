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
    expanded.insert(folder)
    loading.insert(folder)
    let result = await listSubfolders.listSubfolders(of: folder)
    loading.remove(folder)
    // The user can collapse while the listing is in flight; writing the
    // children then would repopulate a node they already closed, and the
    // rows would appear on the next expand without being re-read.
    guard expanded.contains(folder) else { return }
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

  func collapse(_ folder: Folder) {
    expanded.remove(folder)
    children[folder] = nil
  }
}
