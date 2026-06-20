#!/usr/bin/env bash
# apply-ruleset-core-checks.sh
#
# Applies the core-only CI checks to got-feedback/feedBack:
#   ci / tailwind-fresh
#   ci / manifest-validation
#
# These checks don't exist on slopsmith-desktop so they live in a
# separate ruleset from apply-ruleset-core.sh.
#
# Status check enforcement is controlled by ENFORCE_CHECKS (default: false).
# In evaluate mode GitHub tracks compliance but never blocks a merge.
#
# Safe to re-run — updates the ruleset in place if it already exists.
#
# Usage:
#   bash scripts/apply-ruleset-core-checks.sh                     # evaluate
#   ENFORCE_CHECKS=true bash scripts/apply-ruleset-core-checks.sh # active

set -euo pipefail

ORG="slopsmith"
REPO="slopsmith"
RULESET_NAME="core-ci-checks"
CHECKS_ENFORCEMENT=$( [ "${ENFORCE_CHECKS:-false}" = "true" ] && echo "active" || echo "evaluate" )

echo "Status check enforcement: $CHECKS_ENFORCEMENT"

RULESET_JSON=$(cat <<EOF
{
  "name": "$RULESET_NAME",
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
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          { "context": "ci / tailwind-fresh" },
          { "context": "ci / manifest-validation" }
        ]
      }
    }
  ]
}
EOF
)

full="$ORG/$REPO"
echo ""
echo "=== $full ==="

existing_id=$(gh api "repos/$full/rulesets" \
  --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>/dev/null || true)

if [ -n "$existing_id" ]; then
  echo "  '$RULESET_NAME' exists (id: $existing_id) — updating"
  gh api --method PUT "repos/$full/rulesets/$existing_id" \
    --input - <<< "$RULESET_JSON" > /dev/null
else
  echo "  '$RULESET_NAME' not found — creating"
  gh api --method POST "repos/$full/rulesets" \
    --input - <<< "$RULESET_JSON" > /dev/null
fi

echo ""
echo "Done."
if [ "$CHECKS_ENFORCEMENT" = "evaluate" ]; then
  echo ""
  echo "Status checks are in EVALUATE mode — they are tracked but will not block merges."
  echo "Once CI is running, promote to active:"
  echo "  ENFORCE_CHECKS=true bash scripts/apply-ruleset-core-checks.sh"
fi
