//
//  FileListViewModel.swift
//  Explorer
//
//  Drives the file list pane: holds the entries for the current folder, the
//  loading state, and any failure surfaced by the listing use case.
//

import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "FileList")

@MainActor
@Observable
final class FileListViewModel {
  enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(FilesystemError)
  }

  private(set) var entries: [FSEntry] = []
  private(set) var state: LoadState = .idle
  var selection: Set<FSEntry.ID> = []

  private let listContents: ListContentsUseCase
  private var loadToken: UUID = UUID()

  init(listContents: ListContentsUseCase) {
    self.listContents = listContents
  }

  func load(_ folder: Folder) async {
    let token = UUID()
    loadToken = token
    state = .loading
    selection = []
    let result = await listContents.listContents(of: folder)
    guard token == loadToken else { return }
    switch result {
    case .success(let items):
      entries = items
      state = .loaded
    case .failure(let error):
      log.notice("file list load failed at \(folder.path, privacy: .public): \(String(describing: error), privacy: .public)")
      entries = []
      state = .failed(error)
    }
  }
}
