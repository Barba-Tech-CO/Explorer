//
//  AddressBarView.swift
//  Explorer
//
//  Hybrid address bar: breadcrumbs by default, switches to an editable text
//  field on click, ⌘+L, or paste. Mirrors the Windows Explorer behavior.
//

import SwiftUI

struct AddressBarView: View {
  @Bindable var navigation: NavigationState
  let listSubfolders: ListSubfoldersUseCase
  let resolvePath: ResolvePathUseCase

  @State private var viewModel: AddressBarViewModel
  @State private var shakeOffset: CGFloat = 0

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
            .strokeBorder(
              viewModel.showInvalid ? Color.red : Color.secondary.opacity(0.25)
            )
        )
        .offset(x: shakeOffset)
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.mode {
    case .breadcrumbs:
      breadcrumbs
    case .editing:
      PathEditField(
        text: Binding(
          get: { viewModel.draft },
          set: { viewModel.draft = $0 }
        ),
        isInvalid: viewModel.showInvalid,
        onCommit: commitDraft,
        onCancel: viewModel.cancel
      )
    }
  }

  private var breadcrumbs: some View {
    let segments = PathSegment.segments(for: navigation.current)
    return HStack(spacing: 0) {
      ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
        BreadcrumbSegmentView(
          segment: segment,
          isFirst: index == 0,
          listSubfolders: listSubfolders,
          onSelect: { navigation.navigate(to: $0) }
        )
      }
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

  private func commitDraft() {
    Task {
      if let folder = await viewModel.commit(relativeTo: navigation.current) {
        navigation.navigate(to: folder)
      } else {
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
}
