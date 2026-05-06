//
//  FilesystemError.swift
//  Explorer
//
//  Domain-level error surface for filesystem reads. Concrete repositories
//  translate platform errors (NSError/CocoaError/POSIX) into one of these
//  cases so the UI can react with targeted messaging (TCC prompt vs. toast).
//

import Foundation

enum FilesystemError: Error, Equatable {
  /// The current process lacks ACL/TCC permission to read the target.
  case denied
  /// The target does not exist (or was unmounted between calls).
  case notFound
  /// I/O failure or any other unexpected condition.
  case io
}
