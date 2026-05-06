//
//  SiblingDropdownView.swift
//  Explorer
//
//  Popover content listing sibling folders for a given breadcrumb segment.
//

import SwiftUI

struct SiblingDropdownView: View {
  let parent: Folder
  let useCase: ListSubfoldersUseCase
  let onSelect: (Folder) -> Void

  @State private var viewModel: SiblingDropdownViewModel

  init(
    parent: Folder,
    useCase: ListSubfoldersUseCase,
    onSelect: @escaping (Folder) -> Void
  ) {
    self.parent = parent
    self.useCase = useCase
    self.onSelect = onSelect
    self._viewModel = State(initialValue: SiblingDropdownViewModel(useCase: useCase))
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle:
        ProgressView()
          .padding(8)
      case .empty:
        Text("No subfolders")
          .foregroundStyle(.secondary)
          .padding(8)
      case .failed:
        Text("Unable to read folder")
          .foregroundStyle(.secondary)
          .padding(8)
      case .loaded(let folders):
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(folders) { folder in
              Button {
                onSelect(folder)
              } label: {
                HStack(spacing: 6) {
                  Image(systemName: "folder")
                  Text(folder.name)
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
      await viewModel.load(parent: parent)
    }
  }
}
