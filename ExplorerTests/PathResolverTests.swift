//
//  PathResolverTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct PathResolverTests {
    let resolver = PathResolver()
    let home = FileManager.default.homeDirectoryForCurrentUser

    @Test func emptyInputFails() {
        let result = resolver.resolve("   ", relativeTo: home)
        #expect(result == .failure(.empty))
    }

    @Test func absolutePathToExistingDirectoryResolves() {
        let result = resolver.resolve("/", relativeTo: home)
        if case .success(let url) = result {
            #expect(url.path(percentEncoded: false) == "/")
        } else {
            Issue.record("expected success for /")
        }
    }

    @Test func tildeExpandsToHome() {
        let result = resolver.resolve("~", relativeTo: home)
        if case .success(let url) = result {
            #expect(url.standardizedFileURL.path == home.standardizedFileURL.resolvingSymlinksInPath().path)
        } else {
            Issue.record("expected success for ~")
        }
    }

    @Test func nonExistentPathFails() {
        let result = resolver.resolve("/this/does/not/exist/Explorer-test-\(UUID().uuidString)", relativeTo: home)
        #expect(result == .failure(.notFound))
    }

    @Test func filePathFailsAsNotADirectory() throws {
        let tmp = FileManager.default.temporaryDirectory.appending(path: "explorer-test-\(UUID().uuidString).txt")
        try "hi".write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let result = resolver.resolve(tmp.path(percentEncoded: false), relativeTo: home)
        #expect(result == .failure(.notADirectory))
    }
}
