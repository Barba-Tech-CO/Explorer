# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project documentation: `README.md`, `CHANGELOG.md`.
- Address bar specification as the product's centerpiece (clickable breadcrumbs + edit mode via `⌘+L`, support for absolute paths, `~`, and relative paths).
- Roadmap split into v1.0 (core UI), v1.1 (tabs, autocomplete, preview pane, file operations, drag & drop), and v1.2+ (advanced search, recents, persistent favorites, i18n).
- Release pipeline decision: public builds signed with Developer ID + notarized + stapled, distributed via GitHub Releases.
- `FSEntry` domain entity carrying name, URL, isDirectory, size, modification date and type identifier for file list rendering.
- `FilesystemRepository.listContents(of:)` returning sorted `[FSEntry]` (directories first, localized name comparison) with hidden files and package descendants skipped.
- `FilesystemError` with `denied`, `notFound`, and `io` cases; `LocalFilesystemRepository` maps `NSCocoaErrorDomain`/`NSPOSIXErrorDomain` failures to the appropriate case.
- Address bar breadcrumbs now collapse responsively when the bar runs out of room: the root segment and the current folder stay visible while middle ancestors fold behind a `…` button that opens a popover listing the omitted folders for direct navigation. Layout reacts to window resizes and path changes.

### Changed
- App Sandbox disabled on Debug and Release configurations; the app now reads the filesystem directly via `FileManager` (matches the chosen non-Mac-App-Store distribution path).
- `FilesystemRepository.subfolders(of:)` now fails with `FilesystemError` instead of the removed `FilesystemRepositoryError.unreadable`.
- Address bar exits edit mode and restores breadcrumbs when the path field loses focus (clicking outside the bar or switching apps), discarding the draft. Previously the field stayed in edit mode until Esc or Enter.

### Removed
- `FilesystemRepositoryError` (replaced by `FilesystemError`).

### Fixed
- Sibling-folders popover now sizes to its content: width adapts to the longest folder name (clamped 180–480pt) and height adapts to the row count (clamped to 320pt with scrolling beyond that). Previously it stayed clipped at a fixed minimum regardless of how many entries were listed.

---

## [0.0.1] — 2026-05-06

### Added
- Initial Xcode project scaffold (SwiftUI + SwiftData).
- `ExplorerApp.swift`, `ContentView.swift`, `Item.swift` from the template.
- Scheme management plist for user state configuration.

[Unreleased]: https://github.com/<user>/Explorer/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/<user>/Explorer/releases/tag/v0.0.1
