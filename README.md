# Explorer

A native **macOS** file manager with a UX inspired by **Windows Explorer**.

> Status: active development — v1.0 in progress.

## What it is

Explorer is a SwiftUI app that brings the Windows Explorer (Win10/11) mental model to macOS: paneled layout, sidebar with Quick Access and drives, file list with multiple view modes, and — the centerpiece of the product — a **hybrid address bar** that switches between clickable breadcrumbs and an editable text input (with `⌘+L` parity, paste-an-absolute-path, navigate on Enter).

The goal is not pixel-perfect parity with Windows; it is fidelity to the **interactions** that set Explorer apart from Finder.

## Why

Users migrating from Windows to macOS often hit friction with Finder over small things: no real editable address bar, no breadcrumb dropdowns for sibling folders, less flexible view modes. Explorer is built for that audience.

## Highlights

- **Hybrid address bar**: clickable breadcrumbs with a chevron per segment (lists sibling folders); edit mode via click, `⌘+L`, or paste. Accepts absolute paths, `~`, and relative paths.
- **Sidebar** with Quick Access + This Mac + external drives (mount/unmount detected at runtime).
- **File list** in Details (sortable table) and Large icons modes for v1.0.
- **Windows-parity shortcuts**: `⌘+L`, `⌘+←/→`, `⌘+↑`, F5, F2, etc.
- **Status bar** showing item count, selection, and free disk space.

## Requirements

- macOS 14+ (Sonoma or later).
- Xcode 15+ with Swift 5.9+ toolchain.

## Running locally

```bash
git clone https://github.com/<user>/Explorer.git
cd Explorer
open Explorer.xcodeproj
```

Then run the `Explorer` target from Xcode (`⌘+R`). Local builds **do not require code signing** or notarization — only public releases go through that pipeline.

## Distribution

- **Not published on the Mac App Store** (deliberate decision — no sandbox).
- Releases ship via [GitHub Releases](../../releases) as **signed (Developer ID) + notarized + stapled** builds, so they open cleanly on first launch without a Gatekeeper warning.
- Homebrew Cask distribution is planned for later.

## Roadmap at a glance

- **v1.0** — Full UI shell (address bar, sidebar, file list in Details + Large icons, status bar, shortcuts, read-only navigation).
- **v1.1** — Tabs, address bar autocomplete, preview pane, additional view modes, file operations (copy/move/rename/delete), drag & drop.
- **v1.2+** — Advanced search, recents, persistent favorites, i18n, Preferences.

## Contributing

Open source project — issues and PRs are welcome. See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for setup, branching, commit conventions, and the PR checklist.

## License

Licensed under the [Apache License 2.0](./LICENSE).
