//
//  AddressBarView.swift
//  Explorer
//
//  Hybrid address bar: breadcrumbs by default, switches to an editable text
//  field on click, ⌘+L, or paste. Mirrors the Windows Explorer behavior.
//

import SwiftUI
import OSLog

private let log = Logger(subsystem: "Explorer", category: "AddressBar")

struct AddressBarView: View {
    @Bindable var navigation: NavigationState

    @State private var mode: AddressBarMode = .breadcrumbs
    @State private var draftPath: String = ""
    @State private var showInvalid: Bool = false
    @State private var shakeOffset: CGFloat = 0

    private let resolver = PathResolver()

    var body: some View {
        ZStack {
            Button("Edit address bar", action: enterEditMode)
                .keyboardShortcut("l", modifiers: .command)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)

            content
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(showInvalid ? Color.red : Color.secondary.opacity(0.25))
                )
                .offset(x: shakeOffset)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .breadcrumbs:
            breadcrumbs
        case .editing:
            PathEditField(
                text: $draftPath,
                isInvalid: showInvalid,
                onCommit: commitDraft,
                onCancel: cancelEdit
            )
        }
    }

    private var breadcrumbs: some View {
        let segments = PathSegment.segments(for: navigation.currentURL)
        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                BreadcrumbSegmentView(
                    segment: segment,
                    isFirst: index == 0,
                    onSelect: { navigation.navigate(to: $0) }
                )
            }
            Spacer(minLength: 12)
                .contentShape(Rectangle())
                .onTapGesture(perform: enterEditMode)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 1, perform: handleBackgroundTap)
    }

    private func handleBackgroundTap() {
        // The breadcrumb segments swallow taps via Buttons; this fires only for
        // hits on the bar background, which behaves like clicking empty space.
        enterEditMode()
    }

    private func enterEditMode() {
        draftPath = navigation.currentURL.path(percentEncoded: false)
        showInvalid = false
        mode = .editing
    }

    private func cancelEdit() {
        mode = .breadcrumbs
        showInvalid = false
    }

    private func commitDraft() {
        switch resolver.resolve(draftPath, relativeTo: navigation.currentURL) {
        case .success(let url):
            navigation.navigate(to: url)
            mode = .breadcrumbs
            showInvalid = false
        case .failure(let error):
            log.notice("address bar reject: \(String(describing: error), privacy: .public)")
            triggerShake()
            showInvalid = true
        }
    }

    private func triggerShake() {
        let amplitude: CGFloat = 6
        withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = -amplitude }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = amplitude }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = 0 }
            }
        }
    }
}
