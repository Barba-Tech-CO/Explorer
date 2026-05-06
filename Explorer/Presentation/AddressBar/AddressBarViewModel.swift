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

  private let resolvePath: ResolvePathUseCase

  init(resolvePath: ResolvePathUseCase) {
    self.resolvePath = resolvePath
  }

  func enterEditMode(currentPath: String) {
    draft = currentPath
    showInvalid = false
    mode = .editing
  }

  func cancel() {
    mode = .breadcrumbs
    showInvalid = false
  }

  func commit(relativeTo base: Folder) async -> Folder? {
    switch await resolvePath.resolvePath(rawInput: draft, relativeTo: base) {
    case .success(let folder):
      mode = .breadcrumbs
      showInvalid = false
      return folder
    case .failure(let error):
      log.notice("address bar reject: \(String(describing: error), privacy: .public)")
      showInvalid = true
      return nil
    }
  }
}
