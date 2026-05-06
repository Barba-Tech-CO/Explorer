//
//  FilesystemRepository.swift
//  Explorer
//
//  Domain contract for any backend that can answer filesystem questions
//  the use cases need (local disk in v1.0; remote in the future).
//

import Foundation

protocol FilesystemRepository: Sendable {
  var home: Folder { get }

  func entryKind(at url: URL) async -> FilesystemEntryKind

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemError>

  func listContents(of folder: Folder) async -> Result<[FSEntry], FilesystemError>
}
