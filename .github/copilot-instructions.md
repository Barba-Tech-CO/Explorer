# Copilot Instructions — Explorer

Explorer is a native macOS file manager (SwiftUI, macOS 14+) inspired by Windows Explorer. The hybrid address bar (breadcrumbs + editable path with `Cmd+L`) is a release-critical surface.

## Read First (Link, Do Not Duplicate)

- Core project guidance: [CLAUDE.md](../CLAUDE.md)
- Continuously curated runbook/pitfalls: [\.claude/napkin.md](../.claude/napkin.md)
- Public repo context: [README.md](../README.md)
- Contribution workflow: [CONTRIBUTING.md](../CONTRIBUTING.md)

When guidance conflicts, prioritize `CLAUDE.md` and `.claude/napkin.md`.

## Non-Negotiable Rules

- Keep architecture boundaries strict: `Domain <- Data` and `Domain <- Presentation`.
- Keep composition root at app root in `Explorer/AppDependencies.swift`.
- Presentation must use `Folder` / `FSEntry`, never raw `URL`.
- Preserve `Folder.path` canonical behavior (no trailing slash except `/`).
- Use `@Observable` + `@Bindable` for state; avoid `@StateObject` / `@ObservedObject`.
- Use `os.Logger`; never commit `print(...)`.
- One top-level type per file (except tightly-coupled private view helpers).

## Build And Test

- Open/run in Xcode: `open Explorer.xcodeproj`, then `Cmd+R`.
- Run tests in Xcode: `Cmd+U`.
- CLI test (CI equivalent): use the command documented in [CLAUDE.md](../CLAUDE.md).
- For CLI reliability, redirect `xcodebuild` output to a log file and grep results; avoid background execution for test commands.

## Testing Contracts

- Use `ExplorerTests/Doubles/FakeFilesystemRepository.swift` for use-case tests; never rely on real filesystem state.
- Use synthetic paths under `/Users/test` in tests; avoid `/etc`, `/var`, `/tmp` because symlink resolution breaks stub matching.

## Address Bar / SwiftUI Pitfalls

- `NSPopover` + `ScrollView` needs explicit computed frame sizing; otherwise popovers can render clipped.
- `PreferenceKey` emitted inside `ScrollView` is not reliable for outer sizing updates.
- Guard width preference updates against sub-pixel jitter (`delta > 0.5`) to prevent layout oscillation.

Reference implementations:

- `Explorer/Presentation/AddressBar/BreadcrumbsLayout.swift`
- `Explorer/Presentation/AddressBar/BreadcrumbsBarView.swift`

## Git And PR Rules

- Default branch is `develop`.
- Use Conventional Commits, single-line, English, no generated/co-author trailers.
- Stage files explicitly (never `git add -A` or `git add .`).
- Do not include a "Test plan" section in PR descriptions.
- Update `CHANGELOG.md` under `[Unreleased]` for user-visible changes.

## Scope Guardrails

- v1.0 focus is read-only navigation shell.
- Defer tabs/autocomplete/file operations/drag-and-drop to v1.1+.
- Sandbox remains disabled; do not design around sandbox-only access patterns.
