# Scripts

gh CLI scripts for propagating repository rulesets across the slopsmith org.

Rulesets can be applied two ways:
- **GitHub Actions** — trigger the [Propagate rulesets](.github/workflows/propagate-rulesets.yml) workflow from the Actions tab. No local tooling required.
- **Local** — run the scripts directly. Requires `gh` authenticated as an org admin.

---

## Ruleset structure

Each script creates **two rulesets** per repo to allow independent enforcement levels:

| Ruleset | Enforcement | Rules |
|---|---|---|
| `branch-protection` | always **active** | No force push/delete, PR + 1 approval |
| `core-status-checks` | **evaluate** → active | `ci / test` |
| `core-ci-checks` | **evaluate** → active | `ci / tailwind-fresh`, `ci / manifest-validation` |
| `plugin-branch-protection` | always **active** | No force push/delete |
| `plugin-status-checks` | **evaluate** → active | `ci / plugin-lint` |

**evaluate** means GitHub tracks compliance and reports it on PRs but never blocks a merge. Use this until CI workflows are in place. Promote to **active** once checks are running reliably by re-running with `ENFORCE_CHECKS=true`.

---

## Setup order

Run once when setting up the org, and again when adding a new plugin repo.

```bash
# 1. Core and desktop repos
bash scripts/apply-ruleset-core.sh

# 2. Core repo only (extra CI checks)
bash scripts/apply-ruleset-core-checks.sh

# 3a. All org plugin repos
bash scripts/apply-ruleset-plugins.sh

# 3b. Single plugin repo (when onboarding a new plugin)
bash scripts/apply-ruleset-plugins.sh slopsmith-plugin-<name>
```

All scripts are idempotent — safe to re-run.

---

## Promoting status checks to active

Once CI workflows are live and have run at least once in each repo, promote status checks from evaluate to active:

```bash
ENFORCE_CHECKS=true bash scripts/apply-ruleset-core.sh
ENFORCE_CHECKS=true bash scripts/apply-ruleset-core-checks.sh
ENFORCE_CHECKS=true bash scripts/apply-ruleset-plugins.sh
```

Or use the workflow dispatch with `enforce_checks: true`.

---

## Required token for the GitHub Actions workflows

Workflows use a `PROPAGATION_TOKEN` to make changes to other repositories. Add this as a secret on the `.github` repo (or as an org secret).

**Fine-grained PAT** (recommended): select each target repo and grant `Administration: Read and write`.

**Classic PAT**: `repo` scope (full repository control).

---

## Notes

**-bak repos** are automatically skipped by `apply-ruleset-plugins.sh`.

**admins team** must exist before running `apply-ruleset-core.sh` or the bypass actor will be omitted. Create it at `github.com/slopsmith/settings/teams`.

**Status check names** must match exactly what the CI workflow produces. `ci / test` means a workflow with `name: ci` and a job with `id: test`. GitHub only recognises check names it has seen in a completed run — the rule exists but has no effect until the first CI run registers the name. This is exactly why status checks default to evaluate mode.
