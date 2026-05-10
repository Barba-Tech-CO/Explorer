//
//  FileListViewMode.swift
//  Explorer
//
//  How the file list pane renders the current folder. Owned by ContentView
//  (per-window) and consumed by FileListView and the toolbar's segmented
//  picker.
//

import Foundation

enum FileListViewMode: String, CaseIterable, Hashable, Sendable {
  case details
  case largeIcons
}
