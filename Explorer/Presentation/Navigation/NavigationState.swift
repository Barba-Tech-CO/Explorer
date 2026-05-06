//
//  NavigationState.swift
//  Explorer
//
//  Window-scoped navigation state: current Folder + back/forward history.
//

import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "Navigation")

@Observable
final class NavigationState {
  private(set) var current: Folder
  private(set) var backStack: [Folder] = []
  private(set) var forwardStack: [Folder] = []

  init(initial: Folder) {
    self.current = initial
  }

  var canGoBack: Bool { !backStack.isEmpty }
  var canGoForward: Bool { !forwardStack.isEmpty }
  var canGoUp: Bool { current.parent != nil }

  func navigate(to folder: Folder) {
    guard folder != current else { return }
    backStack.append(current)
    forwardStack.removeAll()
    current = folder
    log.debug("navigate -> \(folder.path, privacy: .public)")
  }

  func goBack() {
    guard let previous = backStack.popLast() else { return }
    forwardStack.append(current)
    current = previous
  }

  func goForward() {
    guard let next = forwardStack.popLast() else { return }
    backStack.append(current)
    current = next
  }

  func goUp() {
    guard let parent = current.parent else { return }
    navigate(to: parent)
  }
}
