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

  /// Lists `folder` into the pane.
  ///
  /// - Parameter refreshing: `true` when re-listing the folder the user is
  ///   already in (⌘+R / F5). A refresh keeps the current rows and selection
  ///   on screen while the new listing is in flight — swapping to `.loading`
  ///   would flash the spinner over content that is almost always identical.
  ///   Navigation (`false`) resets both, since the old folder's rows are
  ///   meaningless in the new one.
  func load(_ folder: Folder, refreshing: Bool = false) async {
    let token = UUID()
    loadToken = token
    // Skipping the spinner is only earned when there are rows on screen worth
    // preserving. Refreshing out of `.idle`/`.failed` has nothing to keep, and
    // sitting on the error view for the whole retry hides that the retry is
    // even running — the one moment the user most needs the feedback.
    let preservesRows = refreshing && state == .loaded
    if !preservesRows {
      state = .loading
      selection = []
    }
    let result = await listContents.listContents(of: folder)
    guard token == loadToken else { return }
    switch result {
    case .success(let items):
      entries = items
      if preservesRows {
        // `lazy` so a 10k-entry folder doesn't materialize a second array of
        // URLs just to be walked once by the intersection.
        selection = MultiSelection.reconcile(
          selection: selection,
          against: items.lazy.map(\.id)
        )
      }
      state = .loaded
    case .failure(let error):
      log.notice("file list load failed at \(folder.path, privacy: .public): \(String(describing: error), privacy: .public)")
      entries = []
      // Also on the refresh path, which skipped the reset up top: dropping the
      // rows without dropping the selection would leave ids pointing at rows
      // that are no longer on screen, and a later successful refresh would
      // silently resurrect a selection the user hasn't seen since the failure.
      selection = []
      state = .failed(error)
    }
  }
}
