//
//  FSEntry.swift
//  Explorer
//
//  Domain entity for a single filesystem entry (file or directory) returned
//  by a directory listing. Carries the metadata the file list pane needs to
//  render rows without going back to disk for each cell.
//

import Foundation

struct FSEntry: Hashable, Identifiable, Sendable {
  let url: URL
  let name: String
  let isDirectory: Bool
  let size: Int64?
  let modificationDate: Date?
  let typeIdentifier: String?

  init(
    url: URL,
    name: String,
    isDirectory: Bool,
    size: Int64? = nil,
    modificationDate: Date? = nil,
    typeIdentifier: String? = nil
  ) {
    self.url = url
    self.name = name
    self.isDirectory = isDirectory
    self.size = size
    self.modificationDate = modificationDate
    self.typeIdentifier = typeIdentifier
  }

  var id: URL { url }
}
