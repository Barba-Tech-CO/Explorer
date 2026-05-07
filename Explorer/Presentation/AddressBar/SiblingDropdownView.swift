//
//  SiblingDropdownView.swift
//  Explorer
//
//  Popover content listing sibling folders for a given breadcrumb segment.
//

import AppKit
import SwiftUI

struct SiblingDropdownView: View {
  let parent: Folder
  let useCase: ListSubfoldersUseCase
  let onSelect: (Folder) -> Void

  @State private var viewModel: SiblingDropdownViewModel

  private let minWidth: CGFloat = 180
  private let maxWidth: CGFloat = 480
  private let maxHeight: CGFloat = 320
  private let rowHeight: CGFloat = 24      // body text + 4+4 vertical padding
  private let verticalPadding: CGFloat = 8 // VStack .padding(.vertical, 4) on both sides

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
              SiblingDropdownRow(folder: folder) {
                onSelect(folder)
              }
            }
          }
          .padding(.vertical, 4)
        }
        .frame(height: height(for: folders))
      }
    }
    .frame(width: dropdownWidth)
    .task(id: parent) {
      await viewModel.load(parent: parent)
    }
  }

  private var dropdownWidth: CGFloat {
    if case .loaded(let folders) = viewModel.state {
      return width(for: folders)
    }
    return minWidth
  }

  private func height(for folders: [Folder]) -> CGFloat {
    let intrinsic = CGFloat(folders.count) * rowHeight + verticalPadding
    return min(intrinsic, maxHeight)
  }

  private func width(for folders: [Folder]) -> CGFloat {
    let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let widestName = folders
      .map { ($0.name as NSString).size(withAttributes: attrs).width }
      .max() ?? 0
    let chrome: CGFloat = 16  // folder icon
      + 6                     // icon → text spacing
      + 16                    // horizontal padding (8 + 8)
      + 12                    // breathing room on the right
    return min(max(ceil(widestName) + chrome, minWidth), maxWidth)
  }
}
