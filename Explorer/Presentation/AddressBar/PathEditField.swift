//
//  PathEditField.swift
//  Explorer
//

import SwiftUI

struct PathEditField: View {
  @Binding var text: String
  let onCommit: () -> Void
  let onCancel: () -> Void

  @FocusState private var isFocused: Bool

  var body: some View {
    TextField("", text: $text)
      .textFieldStyle(.plain)
      .focused($isFocused)
      .onSubmit(onCommit)
      .onAppear {
        DispatchQueue.main.async {
          isFocused = true
        }
      }
      .onExitCommand(perform: onCancel)
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
  }
}
