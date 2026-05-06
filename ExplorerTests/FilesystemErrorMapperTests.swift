//
//  FilesystemErrorMapperTests.swift
//  ExplorerTests
//

import Testing
import Foundation
@testable import Explorer

struct FilesystemErrorMapperTests {
  @Test func cocoaNoPermissionMapsToDenied() {
    let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError)
    #expect(FilesystemErrorMapper.map(error) == .denied)
  }

  @Test func cocoaNoSuchFileMapsToNotFound() {
    let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)
    #expect(FilesystemErrorMapper.map(error) == .notFound)
  }

  @Test func posixEaccesMapsToDenied() {
    let error = NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES))
    #expect(FilesystemErrorMapper.map(error) == .denied)
  }

  @Test func posixEnoentMapsToNotFound() {
    let error = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
    #expect(FilesystemErrorMapper.map(error) == .notFound)
  }

  @Test func unknownErrorFallsBackToIO() {
    let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError)
    #expect(FilesystemErrorMapper.map(error) == .io)
  }
}
