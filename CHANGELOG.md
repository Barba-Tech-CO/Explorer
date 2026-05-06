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

### Changed
- App Sandbox disabled on Debug and Release configurations; the app now reads the filesystem directly via `FileManager` (matches the chosen non-Mac-App-Store distribution path).
- `FilesystemRepository.subfolders(of:)` now fails with `FilesystemError` instead of the removed `FilesystemRepositoryError.unreadable`.

### Removed
- `FilesystemRepositoryError` (replaced by `FilesystemError`).

---

## [0.0.1] — 2026-05-06

### Added
- Initial Xcode project scaffold (SwiftUI + SwiftData).
- `ExplorerApp.swift`, `ContentView.swift`, `Item.swift` from the template.
- Scheme management plist for user state configuration.

[Unreleased]: https://github.com/<user>/Explorer/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/<user>/Explorer/releases/tag/v0.0.1
