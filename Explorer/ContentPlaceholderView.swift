//
//  ContentPlaceholderView.swift
//  Explorer
//
//  Temporary stand-in for the upcoming file list pane. Shows the current
//  navigation target so the address bar can be exercised end-to-end.
//

import SwiftUI

struct ContentPlaceholderView: View {
    let url: URL

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(url.path(percentEncoded: false))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("File list pane lands in a follow-up commit.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
