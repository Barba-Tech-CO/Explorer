//
//  BreadcrumbSegmentView.swift
//  Explorer
//
//  A single clickable breadcrumb segment with an inline chevron that lists
//  sibling folders in a popover.
//

import SwiftUI

struct BreadcrumbSegmentView: View {
    let segment: PathSegment
    let isFirst: Bool
    let onSelect: (URL) -> Void

    @State private var dropdownPresented = false

    var body: some View {
        HStack(spacing: 2) {
            Button {
                onSelect(segment.url)
            } label: {
                HStack(spacing: 4) {
                    if isFirst {
                        Image(systemName: "internaldrive")
                            .imageScale(.small)
                    }
                    Text(segment.title)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(segment.url.path(percentEncoded: false))

            Button {
                dropdownPresented.toggle()
            } label: {
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $dropdownPresented, arrowEdge: .bottom) {
                SiblingDropdownView(parent: segment.url) { url in
                    dropdownPresented = false
                    onSelect(url)
                }
            }
        }
    }
}
