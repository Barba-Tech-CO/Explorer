//
//  NavigationStateTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

@MainActor
struct NavigationStateTests {
  @Test func cannotGoUpFromTheFilesystemRoot() {
    let navigation = NavigationState(initial: Folder(path: "/"))
    #expect(navigation.canGoUp == false)
  }

  @Test func goUpFromAMountedVolumeRootLandsInVolumes() {
    // Pinned on purpose: `/Volumes` is a real directory the app lists like any
    // other, so a volume root is not a navigation boundary. Finder hides this
    // behind a synthetic "Computer" view; matching that would be a product
    // decision, not a side effect of changing `Folder.parent`.
    let navigation = NavigationState(initial: Folder(path: "/Volumes/BarbaExt"))
    #expect(navigation.canGoUp)

    navigation.goUp()

    #expect(navigation.current.path == "/Volumes")
  }

  @Test func goUpPushesOntoTheBackStack() {
    let navigation = NavigationState(initial: Folder(path: "/Users/test/Documents"))
    navigation.goUp()

    #expect(navigation.current.path == "/Users/test")
    #expect(navigation.canGoBack)

    navigation.goBack()
    #expect(navigation.current.path == "/Users/test/Documents")
  }
}
