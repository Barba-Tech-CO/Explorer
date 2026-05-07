# Copilot Instructions — Explorer

Native macOS file manager (SwiftUI, macOS 14+) modeled on Windows Explorer. Distributed outside the Mac App Store, sandbox disabled, reads the filesystem directly via `FileManager`. The hybrid address bar (clickable breadcrumbs + editable text input via `⌘+L`) is the centerpiece feature — regressions there are release-blockers.

## Architecture (Clean light)

Strict layering with deps `Domain ← Data` and `Domain ← Presentation`:

- `Explorer/Domain/` — entities (`Folder`, `FSEntry`), repository protocols (`FilesystemRepository`), use cases (`ResolvePathUseCase`, `ListSubfoldersUseCase`). Use cases are concrete `struct`s, not protocols — fake the repository in tests, never the use case.
- `Explorer/Data/` — concrete repositories. Only this layer (and entities) touches raw `URL`. `final class` impls need `@unchecked Sendable` because `FileManager` isn't formally Sendable. Filesystem error translation lives in `FilesystemErrorMapper` (Data), not in repositories.
- `Explorer/Presentation/` — SwiftUI views and view models, organized by feature (`AddressBar/`, `Navigation/`). Talks in `Folder` / `FSEntry`, never `URL`.
- `Explorer/AppDependencies.swift` — composition root. Wires repository + use cases at startup. MUST live at app root, never under `Presentation/`.

`Folder.path` is canonical: never trailing slash (except root `/`). Use `Folder.path` for comparisons — `URL.path(percentEncoded:)` is inconsistent across macOS versions.

## Conventions

- **Indentation**: 2 spaces (enforced via `.editorconfig`).
- **One top-level type per file**, except tightly-coupled `View` helpers like private `PreferenceKey` structs.
- **No deprecated SwiftUI APIs**. Prefer `Table`, `NavigationSplitView`, `LazyVGrid`.
- **State management**: `@Observable` + `@Bindable` (macOS 14+). Never `@StateObject` / `@ObservedObject`.
- **Logging**: `os.Logger` only — `import OSLog` and `private let log = Logger(subsystem: "Explorer", category: "<Category>")` per file. Never `print(...)`.
- **Use case method names**: descriptive `verb+noun`, never `execute` / `run` / `call` / `invoke`. Example: `ListSubfoldersUseCase.listSubfolders(of:)`.
- **Deployment target**: `MACOSX_DEPLOYMENT_TARGET = 14.0`. Newer-OS APIs require `if #available(macOS X, *) { … } else { fallback }`. Don't raise without product approval.

## Testing

- Use cases are tested via `ExplorerTests/Doubles/FakeFilesystemRepository` — never real disk. Stub maps use `Result<...>`.
- Use synthetic paths (`Folder(path: "/Users/test")`). Real OS paths like `/etc`, `/var`, `/tmp` get rewritten by `resolvingSymlinksInPath()` (e.g. `/etc` → `/private/etc`) and won't match stub keys.
- Pure layout / decision logic (e.g. `BreadcrumbsLayout`) lives in `Presentation/` but has no SwiftUI dependency and is unit-testable in isolation.

## SwiftUI / macOS gotchas

- **`NSPopover` + `ScrollView`**: `ScrollView` reports `ideal = 0` on both axes; popover renders truncated. Compute explicit `.frame(width:height:)` from data (e.g. `count * rowHeight + padding`, clamped) BEFORE the popover hosts the view.
- **`PreferenceKey` from inside `ScrollView`**: doesn't propagate reliably. Measure outside the ScrollView via a separate ruler view, or compute the size synchronously without rendering.
- **Measure SwiftUI `Text` width**: use `(string as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]).width`. Deterministic, no view trickery, no async preference races. Add `import AppKit`.
- **Responsive bars**: split a pure `Layout.collapse(items, widths, available, …)` (no SwiftUI deps, testable) from the SwiftUI measurement+render view. The View captures container width via `.background(GeometryReader { Color.clear.preference(...) })` and intrinsic widths via a hidden `.background(measurementBar.fixedSize().allowsHitTesting(false).accessibilityHidden(true).hidden())`. See `BreadcrumbsLayout` + `BreadcrumbsBarView`.
- **`onPreferenceChange` for floating-point widths**: round to integer points and only update when `delta > 0.5pt`. Without this guard, sub-pixel jitter (60.5 ↔ 61.0) re-fires preferences and oscillates layout.
- **`@FocusState` on macOS**: doesn't track first-responder loss when the click target isn't focusable, and doesn't fire on app deactivation. For "click outside" or "app/window switch" cancellation, combine `NSEvent.addLocalMonitorForEvents` (mouse-down outside the captured frame) with either `@Environment(\.controlActiveState)` (per-window, preferred) or `NSWindow.didResignKeyNotification` filtered by the `object:` parameter (multi-window safe).
- **SwiftUI `.global` ↔ AppKit `event.locationInWindow`**: `.global` is top-left origin (SwiftUI), `locationInWindow` is bottom-left (AppKit). For a standard `NSHostingView`-as-`contentView` setup, convert via `y_swiftui = contentView.frame.height - locationInWindow.y`. For non-trivial chrome (full-size content view, custom window styles), prefer a named `coordinateSpace`.
- **Console noise to ignore**: `fopen failed for data file: errno = 2`, `FileIDTreeGetVRefNumForDevice(...) returned -36`, `Unable to obtain a task name port right`, `ViewBridge to RemoteViewService Terminated`. All benign system framework chatter, not app bugs.

## Product guardrails

- **v1.0** = static UI shell with read-only navigation. Tabs, autocomplete, preview pane, file operations, and drag & drop are deferred to v1.1+.
- **Sandbox is disabled** in both Debug and Release. Don't propose features that hinge on `NSOpenPanel`-only access or sandbox bookmarks. TCC (Full Disk Access) is the only permission boundary that still matters.
- **Public releases** ship `codesign` (Developer ID) → `xcrun notarytool submit --wait` → `xcrun stapler staple` → upload to GitHub Releases. Local dev builds skip all of that.

## Git, commits, PRs

- **Default branch is `develop`**, not `main`. Target PRs at `develop` (`gh pr create --base develop`).
- **Conventional Commits**, English, single descriptive line, no body unless strictly necessary, **no** `Co-authored-by` / `Generated by` trailers. Allowed types: `feat fix refactor perf style docs chore ci build test`.
- Stage files explicitly — never `git add -A` or `git add .`.
- PR titles validated by `pr-title.yml` (semantic-pull-request action); subject must start with lowercase.
- Multiple PR templates exist under `.github/PULL_REQUEST_TEMPLATE/` (`feature.md`, `bugfix.md`, `improvement.md`, `chore.md`, `docs.md`). When linking a PR-create URL, append `?template=<name>.md`.
- PR descriptions: Summary + Motivation + type-specific fields. **Do not** add a "Test plan" section.
- Update `CHANGELOG.md` under `[Unreleased]` (`Added` / `Changed` / `Fixed` / `Removed`) for user-visible changes. **Wording must match what's actually triggered**, not a broader user-mental-model phrasing (e.g. don't say "loses focus" if the implementation only reacts to outside clicks + app deactivation).
- `PRD.md`, `TODO.md`, and `linkedin/` are local-only (gitignored) — never commit them.
