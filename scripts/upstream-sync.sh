#!/usr/bin/env bash
#
# Re-base the digitalby overlay (Swift 6 language mode, CI, automation) onto the
# latest upstream vtourraine/AcknowList release, and open a PR.
#
# The fork tracks upstream as a snapshot commit (tree-identical to an upstream
# release) plus a thin overlay of digitalby commits on top. This script:
#   1. finds the newest upstream semver release,
#   2. captures the overlay as the diff between the last-synced upstream tree and
#      the current fork HEAD,
#   3. snapshots the new upstream tree and re-applies the overlay on top,
#   4. opens a PR: auto-merge when the overlay applies cleanly, or an
#      `action-needed` PR when it conflicts (the only manual touch, and only on a
#      real conflict).
#
# Designed to run unattended from .github/workflows/upstream-sync.yml. Requires a
# full-history checkout and a GH_TOKEN with repo + PR scope (the workflow token).
set -euo pipefail

UPSTREAM_URL="https://github.com/vtourraine/AcknowList.git"
MARKER=".github/upstream-version.txt"
REPO="${GITHUB_REPOSITORY:-digitalby-me/AcknowList}"

log() { printf '>> %s\n' "$*"; }

git config user.name "digitalby"
git config user.email "yury@digitalby.me"

git remote add upstream "$UPSTREAM_URL" 2>/dev/null || git remote set-url upstream "$UPSTREAM_URL"

LAST_SYNCED="$(tr -d ' \n' < "$MARKER")"
# Newest upstream semver RELEASE tag (skip pre-releases like 2.0.0-beta.1).
LATEST="$(git ls-remote --tags --refs upstream \
  | awk -F/ '{print $NF}' \
  | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' \
  | sort -V | tail -1)"

log "last synced upstream: $LAST_SYNCED ; latest upstream release: $LATEST"

if [ "$LAST_SYNCED" = "$LATEST" ] || [ "$(printf '%s\n%s\n' "$LAST_SYNCED" "$LATEST" | sort -V | tail -1)" = "$LAST_SYNCED" ]; then
  log "already at or ahead of the latest upstream release; nothing to do."
  exit 0
fi

BRANCH="sync/upstream-$LATEST"
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  log "branch $BRANCH already exists on origin; a sync PR is already open. Exiting."
  exit 0
fi

# Bring both upstream tags into the local namespace.
git fetch --quiet upstream "refs/tags/$LAST_SYNCED:refs/tags/up-$LAST_SYNCED"
git fetch --quiet upstream "refs/tags/$LATEST:refs/tags/up-$LATEST"

git checkout -b "$BRANCH"

# The overlay = everything digitalby added on top of the last synced upstream tree.
git diff "up-$LAST_SYNCED" HEAD > /tmp/overlay.patch || true

# Snapshot the new upstream tree, then re-apply the overlay on top of it.
git read-tree -u --reset "up-$LATEST"
CONFLICT=0
if [ -s /tmp/overlay.patch ]; then
  git apply --3way --whitespace=nowarn /tmp/overlay.patch || CONFLICT=1
fi

# Advance the marker to the upstream version we just synced to.
printf '%s\n' "$LATEST" > "$MARKER"
git add -A
git commit -q -m "chore: sync to upstream vtourraine $LATEST"
git push -u origin "$BRANCH"

BODY_FILE="$(mktemp)"
if [ "$CONFLICT" -eq 0 ]; then
  cat > "$BODY_FILE" <<EOF
Automated sync to upstream vtourraine/AcknowList **$LATEST** (was $LAST_SYNCED).

The digitalby overlay (Swift 6 language mode, Sendable, CI, automation) re-applied
cleanly onto the new upstream snapshot. Auto-merge is enabled; it lands once CI is
green. Review the diff if you want, otherwise no action is needed.
EOF
  gh pr create --repo "$REPO" --base main --head "$BRANCH" \
    --title "chore: sync to upstream vtourraine $LATEST" --body-file "$BODY_FILE" --label automated
  gh pr merge --repo "$REPO" "$BRANCH" --rebase --auto --delete-branch || \
    log "could not enable auto-merge (will need a manual merge once CI is green)."
else
  cat > "$BODY_FILE" <<EOF
Automated sync to upstream vtourraine/AcknowList **$LATEST** (was $LAST_SYNCED).

The digitalby overlay did **not** apply cleanly: upstream changed lines the overlay
also touches. Conflict markers are committed on this branch. Resolve them, push, and
merge. This is the only manual step in the sync flow, and only happens on a real
conflict.
EOF
  gh pr create --repo "$REPO" --base main --head "$BRANCH" \
    --title "chore: sync to upstream vtourraine $LATEST (CONFLICTS)" --body-file "$BODY_FILE" \
    --label automated --label action-needed
fi
rm -f "$BODY_FILE"
log "opened sync PR for $LATEST (conflict=$CONFLICT)."
