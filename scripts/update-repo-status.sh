#!/usr/bin/env bash
# Updates one repo's STATUS.md "Today's CI" block in place.
# - If the repo has STATUS.md and the BEGIN: ci-today / END: ci-today
#   markers are already present: replace the block content.
# - If the repo has STATUS.md but no markers: prepend a new "Today" h2
#   section with the markers right after the title line (first H1).
# - If the repo has no STATUS.md: skip (no-op exit 0).
#
# Commits + pushes via gh-cli auth. Skips the commit if the block
# content is byte-identical to what's already in the repo (idempotent).
#
# Usage:
#   ORG=erphq scripts/update-repo-status.sh REPO_NAME

set -euo pipefail

ORG="${ORG:-erphq}"
REPO="${1:?usage: ORG=erphq $0 REPO_NAME}"

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Bail early if the repo doesn't have STATUS.md at the root.
if ! gh api "repos/$ORG/$REPO/contents/STATUS.md" -q .name >/dev/null 2>&1; then
  echo "[$REPO] no STATUS.md at root — skip"
  exit 0
fi

# Build the block, write to a temp file (safer than bash-interpolating
# arbitrary content into a python heredoc — content includes backticks,
# pipes, brackets, and could later include quote characters).
block_file=$(mktemp)
trap 'rm -f "$block_file"' EXIT
ORG="$ORG" "$HERE/build-repo-status.sh" "$REPO" > "$block_file"
export BLOCK_FILE="$block_file"
export REPO_NAME="$REPO"

# Clone shallow; .git stays for the commit.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
gh repo clone "$ORG/$REPO" "$work" -- --depth=1 --quiet
cd "$work"

python3 "$HERE/inject-ci-today.py"
status=$?
if [[ $status -eq 42 ]]; then
  echo "[$REPO] no change — skip commit"
  exit 0
fi
if [[ $status -ne 0 ]]; then
  echo "[$REPO] inject failed"
  exit "$status"
fi

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git add STATUS.md
if git diff --cached --quiet; then
  echo "[$REPO] no change after stage — skip"
  exit 0
fi
git commit -m "chore(status): refresh today's CI block"
# Race-safe: if push loses, re-pull and re-inject. We can do that here
# because no human edits the marker block between BEGIN/END.
for attempt in 1 2 3; do
  if git push; then
    echo "[$REPO] pushed"
    exit 0
  fi
  echo "[$REPO] push raced (attempt $attempt) — pulling and retrying"
  git fetch origin --quiet
  git reset --hard origin/HEAD --quiet || git reset --hard "origin/$(git rev-parse --abbrev-ref HEAD)" --quiet
  # Re-run the same inject path on the new base.
  python3 "$HERE/inject-ci-today.py" || true
  if git diff --quiet STATUS.md; then
    echo "[$REPO] no diff after rebase — done"
    exit 0
  fi
  git add STATUS.md
  git commit --amend --no-edit >/dev/null
done
echo "::error::[$REPO] push failed after 3 attempts"
exit 1
