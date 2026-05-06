//
//  NavigationState.swift
//  Explorer
//
//  Holds the current location and back/forward history for a window.
//

import Foundation
import Observation
import OSLog

private let log = Logger(subsystem: "Explorer", category: "Navigation")

@Observable
final class NavigationState {
    private(set) var currentURL: URL
    private(set) var backStack: [URL] = []
    private(set) var forwardStack: [URL] = []

    init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentURL = initialURL
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }
    var canGoUp: Bool { currentURL.pathComponents.count > 1 }

    func navigate(to url: URL) {
        guard url != currentURL else { return }
        backStack.append(currentURL)
        forwardStack.removeAll()
        currentURL = url
        log.debug("navigate -> \(url.path, privacy: .public)")
    }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(currentURL)
        currentURL = previous
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentURL)
        currentURL = next
    }

    func goUp() {
        let parent = currentURL.deletingLastPathComponent()
        guard parent != currentURL else { return }
        navigate(to: parent)
    }
}
