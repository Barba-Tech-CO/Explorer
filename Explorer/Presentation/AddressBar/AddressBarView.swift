//
//  AddressBarView.swift
//  Explorer
//
//  Hybrid address bar: breadcrumbs by default, switches to an editable text
//  field on click, ⌘+L, or paste. Mirrors the Windows Explorer behavior.
//

import SwiftUI
import AppKit

struct AddressBarView: View {
  @Bindable var navigation: NavigationState
  let listSubfolders: ListSubfoldersUseCase
  let resolvePath: ResolvePathUseCase

  @State private var viewModel: AddressBarViewModel
  @State private var shakeOffset: CGFloat = 0
  @State private var barFrame: CGRect = .zero
  @State private var mouseMonitor: Any?
  @Environment(\.controlActiveState) private var controlActiveState

  init(
    navigation: NavigationState,
    listSubfolders: ListSubfoldersUseCase,
    resolvePath: ResolvePathUseCase
  ) {
    self.navigation = navigation
    self.listSubfolders = listSubfolders
    self.resolvePath = resolvePath
    self._viewModel = State(
      initialValue: AddressBarViewModel(resolvePath: resolvePath)
    )
  }

  var body: some View {
    VStack(spacing: 6) {
      bar
      if viewModel.showPermissionHint {
        PermissionHintBanner(
          onOpenSettings: openTCCSettings,
          onDismiss: viewModel.dismissPermissionHint
        )
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.18), value: viewModel.showPermissionHint)
    .onChange(of: navigation.current) { _, _ in
      viewModel.dismissPermissionHint()
    }
  }

  private var bar: some View {
    ZStack {
      Button("Edit address bar", action: enterEditMode)
        .keyboardShortcut("l", modifiers: .command)
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)

      Button("Paste path", action: pastePath)
        .keyboardShortcut("v", modifiers: .command)
        .disabled(viewModel.mode != .editing)
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
            .strokeBorder(
              viewModel.showInvalid ? Color.red : Color.secondary.opacity(0.25)
            )
        )
        .background(
          GeometryReader { proxy in
            Color.clear.preference(
              key: BarFrameKey.self,
              value: proxy.frame(in: .global)
            )
          }
        )
        .onPreferenceChange(BarFrameKey.self) { newValue in
          // Round and skip sub-pixel deltas so layout-driven jitter doesn't
          // re-fire state writes mid-crossfade.
          let rounded = CGRect(
            x: newValue.minX.rounded(),
            y: newValue.minY.rounded(),
            width: newValue.width.rounded(),
            height: newValue.height.rounded()
          )
          if barFrame != rounded { barFrame = rounded }
        }
        .offset(x: shakeOffset)
        .animation(.easeInOut(duration: 0.18), value: viewModel.mode)
    }
    .onChange(of: viewModel.mode) { _, mode in
      if mode == .editing {
        installOutsideClickMonitor()
      } else {
        removeOutsideClickMonitor()
      }
    }
    .onDisappear { removeOutsideClickMonitor() }
    .onChange(of: controlActiveState) { _, state in
      if state != .key, viewModel.mode == .editing { viewModel.cancel() }
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.mode {
    case .breadcrumbs:
      breadcrumbs
        .transition(.opacity)
    case .editing:
      PathEditField(
        text: Binding(
          get: { viewModel.draft },
          set: { viewModel.draft = $0 }
        ),
        onCommit: commitDraft,
        onCancel: viewModel.cancel
      )
      .transition(.opacity)
    }
  }

  private var breadcrumbs: some View {
    HStack(spacing: 0) {
      BreadcrumbsBarView(
        segments: PathSegment.segments(for: navigation.current),
        listSubfolders: listSubfolders,
        onSelect: { navigation.navigate(to: $0) }
      )
      Spacer(minLength: 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: enterEditMode)
    }
    .contentShape(Rectangle())
    .onTapGesture(count: 1, perform: enterEditMode)
  }

  private func enterEditMode() {
    viewModel.enterEditMode(currentPath: navigation.current.path)
  }

  private func pastePath() {
    guard viewModel.mode == .editing,
          let pasted = NSPasteboard.general.string(forType: .string)
    else { return }
    let trimmed = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    viewModel.draft = trimmed
  }

  private func openTCCSettings() {
    if let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    ) {
      NSWorkspace.shared.open(url)
    }
    viewModel.dismissPermissionHint()
  }

  private func commitDraft() {
    Task { @MainActor in
      if let folder = await viewModel.commit(relativeTo: navigation.current) {
        navigation.navigate(to: folder)
      } else {
        NSSound.beep()
        triggerShake()
      }
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

  private func installOutsideClickMonitor() {
    guard mouseMonitor == nil else { return }
    mouseMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown]
    ) { event in
      // Convert AppKit's bottom-left origin window coords to SwiftUI's
      // top-left .global space so containment matches the captured bar frame.
      guard let contentHeight = event.window?.contentView?.frame.height else {
        return event
      }
      let p = event.locationInWindow
      let inSwiftUI = CGPoint(x: p.x, y: contentHeight - p.y)
      if !barFrame.contains(inSwiftUI) {
        DispatchQueue.main.async { viewModel.cancel() }
      }
      return event
    }
  }

  private func removeOutsideClickMonitor() {
    if let monitor = mouseMonitor {
      NSEvent.removeMonitor(monitor)
      mouseMonitor = nil
    }
  }
}

private struct BarFrameKey: PreferenceKey {
  static let defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}
