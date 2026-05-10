//
//  SearchField.swift
//  Explorer
//
//  Thin NSViewRepresentable wrapper around `NSSearchField`. SwiftUI's stock
//  TextField doesn't carry the native macOS search look (capsule, magnifier
//  glyph, built-in clear button), and `.searchable` lands in a separate
//  toolbar zone we don't control. The wrapper restores both: native chrome
//  plus an explicit focus request channel so ⌘+F can move first responder.
//

import SwiftUI
import AppKit

struct SearchField: NSViewRepresentable {
  @Binding var text: String
  /// Set to `true` to request first-responder. The wrapper flips it back to
  /// `false` once focus has been claimed, so the next `true` is observed as
  /// a fresh edge.
  @Binding var focusRequest: Bool
  let placeholder: String

  func makeNSView(context: Context) -> NSSearchField {
    let field = NSSearchField()
    field.placeholderString = placeholder
    field.delegate = context.coordinator
    field.target = context.coordinator
    field.action = #selector(Coordinator.searchAction(_:))
    field.sendsSearchStringImmediately = true
    field.sendsWholeSearchString = false
    return field
  }

  func updateNSView(_ nsView: NSSearchField, context: Context) {
    if nsView.stringValue != text {
      nsView.stringValue = text
    }
    if nsView.placeholderString != placeholder {
      nsView.placeholderString = placeholder
    }
    if focusRequest {
      DispatchQueue.main.async {
        // Only consume the request when first responder actually moved.
        // A request that lands before the field is attached to a window
        // would otherwise be silently dropped, forcing the user to press
        // ⌘F a second time after the toolbar finishes installing.
        guard let window = nsView.window else { return }
        if window.makeFirstResponder(nsView) {
          focusRequest = false
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  final class Coordinator: NSObject, NSSearchFieldDelegate {
    private let text: Binding<String>

    init(text: Binding<String>) {
      self.text = text
    }

    func controlTextDidChange(_ note: Notification) {
      guard let field = note.object as? NSSearchField else { return }
      text.wrappedValue = field.stringValue
    }

    @objc func searchAction(_ sender: NSSearchField) {
      text.wrappedValue = sender.stringValue
    }
  }
}
