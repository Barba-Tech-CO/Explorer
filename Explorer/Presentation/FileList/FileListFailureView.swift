//
//  FileListFailureView.swift
//  Explorer
//
//  Shown in place of the table when listing the current folder fails. The
//  copy is tuned to the FilesystemError case so the user sees a hint
//  matching the actual failure (TCC, missing path, generic I/O).
//

import SwiftUI

struct FileListFailureView: View {
  let error: FilesystemError

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 36, weight: .light))
        .foregroundStyle(.secondary)
      Text(title)
        .font(.headline)
      Text(message)
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 360)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var icon: String {
    switch error {
    case .denied: return "lock.shield"
    case .notFound: return "questionmark.folder"
    case .io: return "exclamationmark.triangle"
    }
  }

  private var title: String {
    switch error {
    case .denied: return "Permission denied"
    case .notFound: return "Folder not found"
    case .io: return "Couldn't read this folder"
    }
  }

  private var message: String {
    switch error {
    case .denied:
      return "This app may need Full Disk Access in System Settings → Privacy & Security to read this location."
    case .notFound:
      return "The folder may have been moved, removed, or unmounted."
    case .io:
      return "An unexpected error happened while reading the contents."
    }
  }
}
