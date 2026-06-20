#!/usr/bin/env bash
# apply-ruleset-core.sh
#
# Applies branch protection to got-feedback/feedBack and got-feedback/feedBack-desktop.
#
# Two rulesets per repo:
#   branch-protection    (always active)  — no force push/delete, PR + 1 approval
#   core-status-checks   (evaluate until CI is live, then active) — ci / test
#
# Status check enforcement is controlled by ENFORCE_CHECKS (default: false).
# In evaluate mode GitHub tracks compliance but never blocks a merge.
#
# Safe to re-run — updates rulesets in place if they already exist.
#
# Usage:
#   bash scripts/apply-ruleset-core.sh                     # status checks: evaluate
#   ENFORCE_CHECKS=true bash scripts/apply-ruleset-core.sh # status checks: active

set -euo pipefail

ORG="slopsmith"
REPOS=("slopsmith" "slopsmith-desktop")
CHECKS_ENFORCEMENT=$( [ "${ENFORCE_CHECKS:-false}" = "true" ] && echo "active" || echo "evaluate" )

echo "Status check enforcement: $CHECKS_ENFORCEMENT"

# ── Bypass actor: admins team ────────────────────────────────────────────────
echo "Looking up admins team..."
TEAM_ID=$(gh api "orgs/$ORG/teams/admins" --jq '.id' 2>/dev/null || true)

if [ -z "$TEAM_ID" ]; then
  echo "  WARNING: admins team not found in $ORG."
  echo "           Ruleset will be created WITHOUT a bypass actor."
  echo "           Create the team at github.com/$ORG/settings/teams, then re-run."
  BYPASS_ACTORS="[]"
else
  echo "  Found team ID: $TEAM_ID"
  BYPASS_ACTORS=$(printf '[{"actor_id":%s,"actor_type":"Team","bypass_mode":"always"}]' "$TEAM_ID")
fi

# ── Helper ───────────────────────────────────────────────────────────────────
upsert_ruleset() {
  local full="$1"    # org/repo
  local name="$2"    # ruleset name
  local json="$3"    # ruleset payload

  existing_id=$(gh api "repos/$full/rulesets" \
    --jq ".[] | select(.name == \"$name\") | .id" 2>/dev/null || true)

  if [ -n "$existing_id" ]; then
    echo "    '$name' exists (id: $existing_id) — updating"
    gh api --method PUT "repos/$full/rulesets/$existing_id" \
      --input - <<< "$json" > /dev/null
  else
    echo "    '$name' not found — creating"
    gh api --method POST "repos/$full/rulesets" \
      --input - <<< "$json" > /dev/null
  fi
}

# ── Ruleset: hard protection (always active) ─────────────────────────────────
hard_ruleset() {
  local bypass="$1"
  cat <<EOF
{
  "name": "branch-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/release/**"],
      "exclude": []
    }
  },
  "bypass_actors": $bypass,
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
EOF
}

# ── Ruleset: status checks (evaluate until CI is live) ───────────────────────
checks_ruleset() {
  local check_name="$1"
  cat <<EOF
{
  "name": "core-status-checks",
  "target": "branch",
  "enforcement": "$CHECKS_ENFORCEMENT",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main", "refs/heads/release/**"],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "$check_name" }
        ]
      }
    }
  ]
}
EOF
}

# ── Apply to each repo ────────────────────────────────────────────────────────
# Check names must match the workflow name / job id produced by each repo's CI.
declare -A REPO_CHECK
REPO_CHECK["slopsmith"]="ci / test"
REPO_CHECK["slopsmith-desktop"]="CI / check"

for repo in "${REPOS[@]}"; do
  full="$ORG/$repo"
  echo ""
  echo "=== $full ==="
  upsert_ruleset "$full" "branch-protection"   "$(hard_ruleset "$BYPASS_ACTORS")"
  upsert_ruleset "$full" "core-status-checks"  "$(checks_ruleset "${REPO_CHECK[$repo]}")"
done

echo ""
echo "Done."
if [ "$CHECKS_ENFORCEMENT" = "evaluate" ]; then
  echo ""
  echo "Status checks are in EVALUATE mode — they are tracked but will not block merges."
  echo "Once CI is running, promote to active:"
  echo "  ENFORCE_CHECKS=true bash scripts/apply-ruleset-core.sh"
fi
