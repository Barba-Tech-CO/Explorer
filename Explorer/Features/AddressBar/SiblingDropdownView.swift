//
//  SiblingDropdownView.swift
//  Explorer
//
//  Popover content listing sibling folders for a given breadcrumb segment.
//

import SwiftUI

struct SiblingDropdownView: View {
    let parent: URL
    let onSelect: (URL) -> Void

    @State private var siblings: [URL] = []
    @State private var loadFailed = false

    private let service = FilesystemService()

    var body: some View {
        Group {
            if loadFailed {
                Text("Unable to read folder")
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else if siblings.isEmpty {
                Text("No subfolders")
                    .foregroundStyle(.secondary)
                    .padding(8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(siblings, id: \.self) { url in
                            Button {
                                onSelect(url)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder")
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 320)
            }
        }
        .frame(minWidth: 200)
        .task(id: parent) {
            switch service.subdirectories(of: parent) {
            case .success(let dirs):
                siblings = dirs
                loadFailed = false
            case .failure:
                siblings = []
                loadFailed = true
            }
        }
    }
}
