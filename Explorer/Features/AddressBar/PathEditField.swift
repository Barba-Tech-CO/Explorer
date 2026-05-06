//
//  PathEditField.swift
//  Explorer
//
//  Text field used by the address bar's edit mode.
//

import SwiftUI

struct PathEditField: View {
    @Binding var text: String
    let isInvalid: Bool
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
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isInvalid ? Color.red : Color.secondary.opacity(0.3))
            )
    }
}
