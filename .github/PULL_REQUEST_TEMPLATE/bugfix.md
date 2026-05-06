<!--
PR title: fix: <short imperative description>
Example: fix: prevent crash when listing /private/var
-->

## Summary

<!-- What bug does this fix? -->

## Root cause

<!-- Briefly: what was wrong and why? -->

## Fix

<!-- What did you change to address the root cause? -->

## Linked issue

<!-- "Closes #123" — bug fixes should always reference the bug report. -->

## How to verify

<!-- Steps a reviewer can follow to confirm the fix locally. -->

## Regression risk

<!-- Areas that could be affected. "Low / isolated to address bar edit mode" or "Medium — touches navigation history". -->

## Checklist

- [ ] Branch is rebased on the latest `main`.
- [ ] Commit messages follow Conventional Commits (`fix:` prefix, single line, English, no co-author trailers).
- [ ] Code builds and tests pass locally (`⌘+U` in Xcode).
- [ ] No new compiler warnings introduced.
- [ ] `CHANGELOG.md` updated under `[Unreleased] → Fixed`.
- [ ] Regression test added when possible.
