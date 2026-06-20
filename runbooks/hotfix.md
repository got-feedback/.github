# Runbook: Hotfix

Step-by-step checklist for applying an urgent fix to an already-shipped version.

`vX.Y.Z` is the version being patched. The patch release will be `vX.Y.Z+1` (e.g. patching `v0.3.0` produces `v0.3.1`).

---

## Prerequisites

- A filed issue documenting the bug (`fix/*` branches always require an issue)
- The `release/vX.Y.Z` branch still exists on both repos (it is retained until the next version ships)

---

## Steps

### 1 — Branch from the release branch

```bash
# In got-feedback/feedBack
git fetch origin
git checkout release/vX.Y.Z
git checkout -b hotfix/<issue-number>-short-description
```

Do the same in `got-feedback/feedBack-desktop` if the fix touches desktop code.

### 2 — Fix and PR

- Implement the fix
- Open a PR targeting `release/vX.Y.Z` (not `main`)
- Link the PR to the issue
- Wait for CI to pass and get 1 approval

### 3 — Update the changelog

In the PR, add the fix to the `[Unreleased]` section of `CHANGELOG.md`. It will be renamed to `vX.Y.Z+1` when the patch ships.

### 4 — Merge and tag core

```bash
# After the PR merges to release/vX.Y.Z on core
git checkout release/vX.Y.Z && git pull
git tag vX.Y.Z+1
git push origin vX.Y.Z+1
```

Monitor `release.yml` — Docker image should appear on GHCR as `:vX.Y.Z+1`.

### 5 — Tag desktop

```bash
# In got-feedback/feedBack-desktop, on release/vX.Y.Z
git tag vX.Y.Z+1
git push origin vX.Y.Z+1
```

Monitor `release.yml` — patch installers attached to GitHub Release.

### 6 — Apply to the next version branch (if applicable)

If `release/vX.Y+1.0` already exists and the fix applies there too:

```bash
git checkout release/vX.Y+1.0
git cherry-pick <commit-sha>
# Or open a second PR if the fix needs adjustment
```

This is the only case where a cherry-pick is needed in this model.

### 7 — Update the changelog in the release section

Rename `[Unreleased]` to `[vX.Y.Z+1] - YYYY-MM-DD` and open a new empty `[Unreleased]` section. PR to `release/vX.Y.Z`.

### 8 — Update bug report form version dropdown

Add `X.Y.Z+1` to the options list in `.github/ISSUE_TEMPLATE/bug_report.yml`. PR to `release/vX.Y.Z`.

### 9 — Merge to main

Once `vX.Y.Z+1` is stable, open `release/vX.Y.Z` → `main` PRs on both repos and merge. `main` now reflects `vX.Y.Z+1`.

---

## Note on plugin pins

If the hotfix requires an updated org plugin commit (e.g. a bug in a plugin contributed to the issue), update `plugin-lock.json` on `release/vX.Y.Z` via a PR before tagging. Desktop's `release.yml` will use the updated pins.
