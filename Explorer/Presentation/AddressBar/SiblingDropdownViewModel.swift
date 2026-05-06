//
//  SiblingDropdownViewModel.swift
//  Explorer
//

import Foundation
import Observation

@Observable
final class SiblingDropdownViewModel {
  enum LoadState: Equatable {
    case idle
    case loaded([Folder])
    case empty
    case failed
  }

  private(set) var state: LoadState = .idle
  private let useCase: ListSubfoldersUseCase

  init(useCase: ListSubfoldersUseCase) {
    self.useCase = useCase
  }

  func load(parent: Folder) async {
    switch await useCase.execute(parent: parent) {
    case .success(let folders) where folders.isEmpty:
      state = .empty
    case .success(let folders):
      state = .loaded(folders)
    case .failure:
      state = .failed
    }
  }
}
