#!/usr/bin/env bash
# Builds the "Today's CI" status block for a single repo. Goes between
# the BEGIN: ci-today / END: ci-today markers in that repo's STATUS.md.
# Companion to scripts/build-status-table.sh (which builds the org-wide
# table that lives in this repo's profile/README.md).
#
# Usage:
#   ORG=erphq scripts/build-repo-status.sh REPO_NAME > /tmp/repo-status.md
#
# Pulls live from the GitHub API:
#   - test count: from README's "tests-N passing" shields.io badge
#   - run tally since 00:00 UTC today, by conclusion
#   - the latest failed workflow run (with URL) — what an agent landing
#     in this repo each morning needs to start triaging
#   - open PRs whose head SHA has a failed check — the work to do
#
# Requires: gh (authed with cross-repo read), jq.

set -euo pipefail

ORG="${ORG:-erphq}"
REPO="${1:?usage: ORG=erphq $0 REPO_NAME}"
SINCE="$(date -u +%Y-%m-%dT00:00:00Z)"
TODAY="$(date -u +%Y-%m-%d)"

# Test count from the README badge. Returns "—" if the repo has no
# badge (e.g. neo-releases, skills — repos that don't ship code tests).
fetch_test_count() {
  local body
  body=$(gh api "repos/$ORG/$REPO/readme" -q .content 2>/dev/null | base64 -d 2>/dev/null || true)
  if [[ -z "$body" ]]; then
    echo "—"
    return
  fi
  local n
  n=$(printf '%s' "$body" | sed -nE 's|.*tests-([0-9]+)%20passing.*|\1|p' | head -1)
  if [[ -z "$n" ]]; then
    echo "—"
  else
    echo "$n"
  fi
}

# Pull all workflow runs created since 00:00 UTC today, then summarise.
runs_json=$(gh api "repos/$ORG/$REPO/actions/runs?created=>=$SINCE&per_page=100" 2>/dev/null || echo '{"workflow_runs":[]}')

total=$(printf '%s' "$runs_json" | jq '.workflow_runs | length')
pass=$(printf '%s' "$runs_json" | jq '[.workflow_runs[] | select(.conclusion == "success")] | length')
fail=$(printf '%s' "$runs_json" | jq '[.workflow_runs[] | select(.conclusion == "failure")] | length')
other=$((total - pass - fail))
tests=$(fetch_test_count)

# Latest failed run today (if any), for the "where to look first" link.
latest_fail_url=$(printf '%s' "$runs_json" | jq -r '[.workflow_runs[] | select(.conclusion == "failure")] | sort_by(.created_at) | reverse | .[0].html_url // ""')
latest_fail_name=$(printf '%s' "$runs_json" | jq -r '[.workflow_runs[] | select(.conclusion == "failure")] | sort_by(.created_at) | reverse | .[0].name // ""')
latest_fail_branch=$(printf '%s' "$runs_json" | jq -r '[.workflow_runs[] | select(.conclusion == "failure")] | sort_by(.created_at) | reverse | .[0].head_branch // ""')

# Open PRs with at least one failing check. Cap at 5 so the block stays
# tight; if there are more, the link to the org PR list covers the rest.
prs_json=$(gh pr list -R "$ORG/$REPO" --state open --limit 30 --json number,title,headRefOid,statusCheckRollup 2>/dev/null || echo '[]')
red_prs=$(printf '%s' "$prs_json" | jq -r '
  [.[] | select(
     (.statusCheckRollup // []) | map(
       (.conclusion // .status // "") | ascii_downcase
     ) | any(. == "failure" or . == "fail")
  )] | .[0:5] | .[] |
  "  - [#" + (.number | tostring) + "](https://github.com/'"$ORG"'/'"$REPO"'/pull/" + (.number | tostring) + ") — " + .title
')

# Render. Trailing newline-free so the marker block stays compact.
cat <<EOF
_Auto-refreshed by [\`erphq/.github/refresh-status.yml\`](https://github.com/erphq/.github/blob/main/.github/workflows/refresh-status.yml). Window: runs created since 00:00 UTC on $TODAY (\`$SINCE\`)._

| Tests | Runs today | ✅ pass | ❌ fail | ⚠️ other |
|---:|---:|---:|---:|---:|
| **$tests** | **$total** | **$pass** | **$fail** | **$other** |
EOF

if [[ -n "$latest_fail_url" ]]; then
  echo
  echo "**Latest failed run:** [$latest_fail_name on \`$latest_fail_branch\`]($latest_fail_url)"
fi

if [[ -n "$red_prs" ]]; then
  echo
  echo "**Open PRs with failing checks:**"
  echo "$red_prs"
fi
