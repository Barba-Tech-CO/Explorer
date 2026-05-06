//
//  FSEntryTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct FSEntryTests {
  @Test func entriesAreIdentifiedByURL() {
    let url = URL(filePath: "/tmp/example.txt")
    let entry = FSEntry(url: url, name: "example.txt", isDirectory: false)
    #expect(entry.id == url)
  }

  @Test func directoriesIgnoreSizeMetadata() {
    let url = URL(filePath: "/tmp/folder")
    let entry = FSEntry(url: url, name: "folder", isDirectory: true)
    #expect(entry.size == nil)
    #expect(entry.isDirectory)
  }

  @Test func equatableComparesAllStoredFields() {
    let url = URL(filePath: "/tmp/a.txt")
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let lhs = FSEntry(url: url, name: "a.txt", isDirectory: false, size: 10, modificationDate: date, typeIdentifier: "public.text")
    let rhs = FSEntry(url: url, name: "a.txt", isDirectory: false, size: 10, modificationDate: date, typeIdentifier: "public.text")
    let other = FSEntry(url: url, name: "a.txt", isDirectory: false, size: 11, modificationDate: date, typeIdentifier: "public.text")
    #expect(lhs == rhs)
    #expect(lhs != other)
  }
}
