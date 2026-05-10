# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Sidebar split into two sections: **Quick Access** with the canonical user folders (Desktop, Documents, Downloads, Pictures, Music, Movies) plus Home, and **This Mac** listing currently mounted volumes (boot drive first, then external drives in OS order). The This Mac list refreshes automatically on `NSWorkspace.didMountNotification` / `didUnmountNotification`, so plugging or ejecting an external drive updates the sidebar without restarting the app.
- `FilesystemRepository.quickAccessLocations` and `FilesystemRepository.mountedVolumes()` plus a new `SidebarSourcesUseCase` exposing both to the presentation layer.
- Initial project documentation: `README.md`, `CHANGELOG.md`.
- Address bar specification as the product's centerpiece (clickable breadcrumbs + edit mode via `⌘+L`, support for absolute paths, `~`, and relative paths).
- Roadmap split into v1.0 (core UI), v1.1 (tabs, autocomplete, preview pane, file operations, drag & drop), and v1.2+ (advanced search, recents, persistent favorites, i18n).
- Release pipeline decision: public builds signed with Developer ID + notarized + stapled, distributed via GitHub Releases.
- `FSEntry` domain entity carrying name, URL, isDirectory, size, modification date and type identifier for file list rendering.
- `FilesystemRepository.listContents(of:)` returning sorted `[FSEntry]` (directories first, localized name comparison) with hidden files and package descendants skipped.
- `FilesystemError` with `denied`, `notFound`, and `io` cases; `LocalFilesystemRepository` maps `NSCocoaErrorDomain`/`NSPOSIXErrorDomain` failures to the appropriate case.
- Address bar breadcrumbs now collapse responsively when the bar runs out of room: the root segment and the current folder stay visible while middle ancestors fold behind a `…` button that opens a popover listing the omitted folders for direct navigation. Layout reacts to window resizes and path changes.
- Address bar now intercepts `⌘+V` while in edit mode: the clipboard text replaces the current draft so a pasted path is always editable before navigating with Enter. The shortcut is inactive in breadcrumbs mode.
- Permission hint banner under the address bar: when an absolute-looking path (`/...` or `~/...`) fails to resolve, an advisory banner appears with a deep link to System Settings → Privacy & Security → Full Disk Access. Banner auto-clears on successful navigation, on re-entering edit mode, when dismissed, or after opening Settings. Worded as a hint rather than a verdict because macOS' TCC layer reports protected paths as not-found rather than denied, so explicit detection isn't possible.
- Window shell migrated to `NavigationSplitView`: a sidebar (Quick Access stub with Home) sits next to a detail pane carrying the address bar and a new Details file list. The list renders the current folder's entries in a sortable `Table` with Name, Modified, Type, and Size columns; double-clicking a folder navigates into it, double-clicking a file opens it via `NSWorkspace`. Listing failures show a typed empty state (permission / not-found / I/O).
- `ListContentsUseCase` exposing the existing repository listing to the presentation layer without leaking the repository protocol.
- Window toolbar with Back / Forward buttons bound to `NavigationState`. Buttons disable themselves when their respective stacks are empty. Keyboard shortcuts: ⌘+← back, ⌘+→ forward.
- Toolbar search field that filters the current folder's entries by name (case-insensitive, substring) without leaving the file list. Placeholder reads "Search in <folder>", and the query clears automatically when navigation moves to another folder. Empty result shows a "No matches" placeholder instead of a blank table; an empty folder with no active search shows "This folder is empty".
- Toolbar segmented picker to switch the file list between Details and Large icons. Large icons mode renders entries as a `LazyVGrid` of 96×96 cells with the entry name underneath; single-click selects, double-click opens, and clicking an empty area clears the selection. Keyboard shortcuts: ⌘+1 Details, ⌘+2 Large icons.
- Status bar at the bottom of the file list pane: total item count, summary of the current selection (count + total size when sizes are known), and free bytes available on the volume hosting the current folder.
- `FilesystemRepository.volumeFreeBytes(at:)` and `VolumeCapacityUseCase` exposing volume capacity to the presentation layer through the existing repository abstraction.

### Changed
- App Sandbox disabled on Debug and Release configurations; the app now reads the filesystem directly via `FileManager` (matches the chosen non-Mac-App-Store distribution path).
- `FilesystemRepository.subfolders(of:)` now fails with `FilesystemError` instead of the removed `FilesystemRepositoryError.unreadable`.
- Address bar exits edit mode and restores breadcrumbs when clicking outside the bar's chrome or when its window stops being the key window (app switch, another window taking key), discarding the draft. Previously the field stayed in edit mode until Esc or Enter.
- Invalid path commits in the address bar now play the system alert beep alongside the existing shake + red border feedback.

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
