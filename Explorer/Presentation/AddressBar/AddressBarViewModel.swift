//
//  AddressBarViewModel.swift
//  Explorer
//
//  Drives the address bar: holds mode, draft text, and error state, and
//  delegates path resolution to the use case.
//

import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "AddressBar")

@Observable
final class AddressBarViewModel {
  var mode: AddressBarMode = .breadcrumbs
  var draft: String = ""
  var showInvalid: Bool = false
  var showPermissionHint: Bool = false

  private let resolvePath: ResolvePathUseCase

  init(resolvePath: ResolvePathUseCase) {
    self.resolvePath = resolvePath
  }

  func enterEditMode(currentPath: String) {
    draft = currentPath
    showInvalid = false
    showPermissionHint = false
    mode = .editing
  }

  func cancel() {
    mode = .breadcrumbs
    showInvalid = false
  }

  func dismissPermissionHint() {
    showPermissionHint = false
  }

  func commit(relativeTo base: Folder) async -> Folder? {
    let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    let isAbsoluteLooking = trimmed.hasPrefix("/") || trimmed.hasPrefix("~")

    switch await resolvePath.resolvePath(rawInput: draft, relativeTo: base) {
    case .success(let folder):
      mode = .breadcrumbs
      showInvalid = false
      showPermissionHint = false
      return folder
    case .failure(let error):
      log.notice("address bar reject: \(String(describing: error), privacy: .public)")
      showInvalid = true
      // TCC is opaque: macOS reports protected paths as not-found rather than
      // denied, so we surface the hint whenever an absolute-looking path
      // can't be resolved. Reset first so unrelated failures (.empty,
      // .notADirectory, or .notFound on a relative draft) clear a stale
      // banner from a previous attempt.
      showPermissionHint = false
      if case .notFound = error, isAbsoluteLooking {
        showPermissionHint = true
      }
      return nil
    }
  }
}
