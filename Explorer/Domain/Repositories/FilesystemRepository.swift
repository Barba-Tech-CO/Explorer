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

  /// Well-known user folders (Desktop, Documents, Downloads, Pictures, Music,
  /// Movies). Order is intentional and meant to be rendered as-is by the
  /// Quick Access section of the sidebar. Excludes folders the host system
  /// can't resolve.
  var quickAccessLocations: [Folder] { get }

  func entryKind(at url: URL) async -> FilesystemEntryKind

  func subfolders(of folder: Folder) async -> Result<[Folder], FilesystemError>

  func listContents(of folder: Folder) async -> Result<[FSEntry], FilesystemError>

  /// Bytes still writable on the volume that hosts `folder`. `nil` when the
  /// information isn't available (unmounted volume, transient I/O failure).
  func volumeFreeBytes(at folder: Folder) async -> Int64?

  /// Currently mounted volumes — boot volume first, then external drives in
  /// the order macOS reports them.
  func mountedVolumes() async -> [Folder]
}
