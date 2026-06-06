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
  overlay on top of it, and opens a PR. It auto-merges when the overlay applies
  cleanly and opens an `action-needed` PR only when upstream changed something the
  overlay also touches. Nobody has to remember to sync.

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
