//
//  FilesystemErrorMapper.swift
//  Explorer
//
//  Translates platform-level errors (NSError under NSCocoaErrorDomain or
//  NSPOSIXErrorDomain) into the domain `FilesystemError` cases the UI
//  reasons about. Lives in the Data layer because it depends on platform
//  error domains; Domain only sees the resulting `FilesystemError`.
//

import Foundation

enum FilesystemErrorMapper {
  static func map(_ error: Error) -> FilesystemError {
    let nsError = error as NSError
    if nsError.domain == NSCocoaErrorDomain {
      switch nsError.code {
      case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
        return .denied
      case NSFileReadNoSuchFileError, NSFileNoSuchFileError:
        return .notFound
      default:
        break
      }
    }
    if nsError.domain == NSPOSIXErrorDomain {
      switch Int32(nsError.code) {
      case EACCES, EPERM:
        return .denied
      case ENOENT:
        return .notFound
      default:
        break
      }
    }
    return .io
  }
}
