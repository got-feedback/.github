#!/usr/bin/env bash
# apply-ruleset-plugins.sh
#
# Applies branch protection to org plugin repos (got-feedback/feedBack-plugin-*).
#
# Two rulesets per repo:
#   plugin-branch-protection  (always active)  — no force push/delete
#   plugin-status-checks      (evaluate until CI is live, then active) — ci / plugin-lint
#
# Status check enforcement is controlled by ENFORCE_CHECKS (default: false).
# In evaluate mode GitHub tracks compliance but never blocks a merge.
#
# By default targets all slopsmith-plugin-* repos.
# Pass a repo name to target a single repo (useful when onboarding a new plugin).
# -bak repos are always skipped.
#
# Safe to re-run — updates rulesets in place if they already exist.
#
# Usage:
#   bash scripts/apply-ruleset-plugins.sh                          # all plugins, evaluate
#   bash scripts/apply-ruleset-plugins.sh slopsmith-plugin-tuner   # single repo, evaluate
#   ENFORCE_CHECKS=true bash scripts/apply-ruleset-plugins.sh      # all plugins, active

set -euo pipefail

ORG="slopsmith"
CHECKS_ENFORCEMENT=$( [ "${ENFORCE_CHECKS:-false}" = "true" ] && echo "active" || echo "evaluate" )

echo "Status check enforcement: $CHECKS_ENFORCEMENT"

# ── Target repos ─────────────────────────────────────────────────────────────
if [ -n "${1:-}" ]; then
  REPOS=("$1")
  echo "Targeting single repo: $ORG/$1"
else
  echo "Fetching all slopsmith-plugin-* repos from $ORG..."
  mapfile -t REPOS < <(
    gh api "orgs/$ORG/repos?per_page=100&type=public" \
      --jq '.[].name | select(startswith("slopsmith-plugin-"))' \
      | sort
  )
  echo "  Found ${#REPOS[@]} plugin repos."
fi

if [ ${#REPOS[@]} -eq 0 ]; then
  echo "No repos found. Exiting."
  exit 1
fi

# ── Helper ───────────────────────────────────────────────────────────────────
upsert_ruleset() {
  local full="$1"
  local name="$2"
  local json="$3"

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
HARD_RULESET=$(cat <<'EOF'
{
  "name": "plugin-branch-protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" }
  ]
}
EOF
)

# ── Ruleset: status checks (evaluate until CI is live) ───────────────────────
checks_ruleset() {
  cat <<EOF
{
  "name": "plugin-status-checks",
  "target": "branch",
  "enforcement": "$CHECKS_ENFORCEMENT",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          { "context": "ci / plugin-lint" }
        ]
      }
    }
  ]
}
EOF
}

# ── Apply to each repo ────────────────────────────────────────────────────────
echo ""
for repo in "${REPOS[@]}"; do
  if [[ "$repo" == *-bak ]]; then
    echo "  Skipping $repo (-bak fork)"
    continue
  fi

  full="$ORG/$repo"
  echo "=== $full ==="
  upsert_ruleset "$full" "plugin-branch-protection" "$HARD_RULESET"
  upsert_ruleset "$full" "plugin-status-checks"     "$(checks_ruleset)"
done

echo ""
echo "Done."
if [ "$CHECKS_ENFORCEMENT" = "evaluate" ]; then
  echo ""
  echo "Status checks are in EVALUATE mode — they are tracked but will not block merges."
  echo "Once CI is running, promote to active:"
  echo "  ENFORCE_CHECKS=true bash scripts/apply-ruleset-plugins.sh"
fi
