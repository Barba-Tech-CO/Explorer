//
//  PermissionHintBanner.swift
//  Explorer
//
//  Surfaced under the address bar after a failed commit on an absolute-looking
//  path, suggesting Full Disk Access as a possible cause. macOS' TCC layer
//  reports protected paths as not-found, so this is advisory, never a
//  guaranteed diagnosis.
//

import SwiftUI

struct PermissionHintBanner: View {
  let onOpenSettings: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "lock.shield")
        .imageScale(.large)
        .foregroundStyle(.orange)
        .padding(.top, 1)

      VStack(alignment: .leading, spacing: 2) {
        Text("Couldn't open that path.")
          .font(.callout)
          .fontWeight(.semibold)
        Text("If it exists, this app may need Full Disk Access in System Settings → Privacy & Security.")
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button("Open Settings", action: onOpenSettings)
        .buttonStyle(.borderedProminent)
        .controlSize(.small)

      Button(action: onDismiss) {
        Image(systemName: "xmark")
          .imageScale(.small)
          .padding(4)
          .contentShape(Rectangle())
      }
      .buttonStyle(.borderless)
      .help("Dismiss")
      .accessibilityLabel("Dismiss permission hint")
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.orange.opacity(0.10))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(Color.orange.opacity(0.40))
    )
  }
}
