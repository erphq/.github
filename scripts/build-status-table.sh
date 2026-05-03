#!/usr/bin/env bash
# Builds the org-wide CI status table that lives in profile/README.md
# between the BEGIN/END status-table markers. Pulls live data from
# the GitHub API:
#
#   - test count: parsed from each repo's README "tests-NNN passing"
#     shields.io badge (the source of truth — keep the badge fresh
#     when test counts change and this table follows along)
#   - runs today: workflow runs created since 00:00 UTC today
#   - pass / fail: conclusion field per run
#
# Run from anywhere; writes to stdout. The companion workflow
# (.github/workflows/refresh-status.yml) commits the result back
# into profile/README.md once a day.
#
# Requires: gh (authed), jq.

set -euo pipefail

ORG="${ORG:-erphq}"
SINCE="$(date -u +%Y-%m-%dT00:00:00Z)"

# Public, non-archived repos in the org, sorted alphabetically. The
# org profile README is publicly visible at https://github.com/erphq —
# listing private repo names here would leak the private surface area
# to anyone visiting the page. Internal triage uses a separate dashboard.
REPOS=$(gh api "orgs/$ORG/repos" --paginate -q '.[] | select(.archived | not) | select(.private | not) | select(.name != ".github") | .name' | sort)

print_row() {
  local repo="$1" tests="$2" runs="$3" pass="$4" fail="$5" other="$6"
  printf '| [`%s`](https://github.com/%s/%s) | %s | %s | %s | %s | %s |\n' \
    "$repo" "$ORG" "$repo" "$tests" "$runs" "$pass" "$fail" "$other"
}

# Pull the "tests-N passing" badge from a repo's README — returns
# the integer N, or "—" if the badge is missing / malformed. Each
# repo was badged in the earlier pass; missing means the repo never
# got one (private personal projects, neo-releases, …).
fetch_test_count() {
  local repo="$1"
  local body
  body=$(gh api "repos/$ORG/$repo/readme" -q .content 2>/dev/null | base64 -d 2>/dev/null || true)
  if [[ -z "$body" ]]; then
    echo "—"
    return
  fi
  # Extract the N from "tests-N%20passing". The %20 is the URL-escaped
  # space and contains "20" — without anchoring to the leading "tests-"
  # the second number-extract would always find "20" first.
  local n
  n=$(printf '%s' "$body" | sed -nE 's|.*tests-([0-9]+)%20passing.*|\1|p' | head -1)
  if [[ -z "$n" ]]; then
    echo "—"
  else
    echo "$n"
  fi
}

# Tally run conclusions for one repo since 00:00 UTC today.
# Outputs: "<runs> <pass> <fail> <other>"
fetch_run_tally() {
  local repo="$1"
  local runs_json
  runs_json=$(gh api "repos/$ORG/$repo/actions/runs?created=>=$SINCE&per_page=100" 2>/dev/null || echo '{"workflow_runs":[]}')
  local total pass fail other
  total=$(printf '%s' "$runs_json" | jq '.workflow_runs | length')
  pass=$(printf '%s' "$runs_json" | jq '[.workflow_runs[] | select(.conclusion == "success")] | length')
  fail=$(printf '%s' "$runs_json" | jq '[.workflow_runs[] | select(.conclusion == "failure")] | length')
  other=$((total - pass - fail))
  echo "$total $pass $fail $other"
}

cat <<EOF
_Last refreshed: $(date -u +"%Y-%m-%d %H:%M UTC"). Window: runs created since 00:00 UTC today (\`$SINCE\`)._

| Repo | Tests | Runs today | ✅ pass | ❌ fail | ⚠️ other |
|---|---:|---:|---:|---:|---:|
EOF

# Roll-up totals across all repos.
sum_tests=0; sum_runs=0; sum_pass=0; sum_fail=0; sum_other=0
known_tests=0
while IFS= read -r repo; do
  tests=$(fetch_test_count "$repo")
  read -r runs pass fail other < <(fetch_run_tally "$repo")
  print_row "$repo" "$tests" "$runs" "$pass" "$fail" "$other"
  if [[ "$tests" =~ ^[0-9]+$ ]]; then
    sum_tests=$((sum_tests + tests))
    known_tests=$((known_tests + 1))
  fi
  sum_runs=$((sum_runs + runs))
  sum_pass=$((sum_pass + pass))
  sum_fail=$((sum_fail + fail))
  sum_other=$((sum_other + other))
done <<< "$REPOS"

cat <<EOF
| **Total** | **$sum_tests** *(across $known_tests badged repos)* | **$sum_runs** | **$sum_pass** | **$sum_fail** | **$sum_other** |

> "Other" covers cancelled / skipped / in-progress / neutral runs. "Tests" is read from each repo's README \`tests-N passing\` badge — repos without a badge show \`—\`.
EOF
