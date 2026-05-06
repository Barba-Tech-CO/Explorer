//
//  FilesystemEntryKind.swift
//  Explorer
//

import Foundation

enum FilesystemEntryKind: Sendable, Equatable {
  case directory
  case file
  case missing
}
