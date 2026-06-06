# About this fork

`digitalby-me/AcknowList` is a maintained fork of
[`vtourraine/AcknowList`](https://github.com/vtourraine/AcknowList). It exists so
digitalby apps consume the acknowledgements library from a controlled, pinned
source rather than directly from a third-party repository.

## How it tracks upstream

The fork is a **snapshot of an upstream release plus a thin digitalby overlay**:

- `.github/upstream-version.txt` records the upstream release the current tree is
  based on.
- A daily workflow (`.github/workflows/upstream-sync.yml` →
  `scripts/upstream-sync.sh`) checks for a newer upstream release, re-applies the
  overlay on top of it, and opens a PR for review. When upstream changed something
  the overlay also touches it opens an `action-needed` PR instead. Nobody has to
  remember to sync. With a `SYNC_PAT` secret configured the sync PR triggers CI and
  auto-merges once green (the default `GITHUB_TOKEN` cannot trigger CI on the PRs it
  opens, so without the secret the PR waits for a human merge).

## What the digitalby overlay adds over upstream

- **Swift 6 language mode** (`swiftLanguageModes: [.v6]`) with explicit `Sendable`
  on the public value types and a main-actor-isolated GitHub license callback.
- **Multi-platform CI** (`.github/workflows/ci.yml`): SwiftPM build + test on
  macOS and iOS, compile checks on tvOS / watchOS / visionOS, under Swift 6.
- **Dependabot** for the GitHub Actions used by CI.
- Aligned the legacy `AcknowList.xcodeproj` deployment targets (iOS/tvOS) with
  `Package.swift` (13.0).

Functional changes belong upstream where possible, so the auto-sync brings them
back without divergence. Known upstream gaps are tracked in this repo's issues.
