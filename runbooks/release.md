# Runbook: Release

Step-by-step checklist for cutting a Slopsmith release. Follow in order — steps have dependencies.

`vX.Y.Z` below refers to the version being released (e.g. `v0.3.0`). Substitute accordingly.

---

## Phase 1 — Start the release cycle

Do this at the beginning of a development cycle, not just before shipping.

- [ ] Open a milestone tracking issue: **"vX.Y.Z milestone"** in `got-feedback/feedBack` listing all planned features. Link relevant issues to it.
- [ ] Cut `release/vX.Y.Z` from `main` on **core**:
  ```bash
  git checkout main && git pull
  git checkout -b release/vX.Y.Z
  git push origin release/vX.Y.Z
  ```
- [ ] Cut `release/vX.Y.Z` from `main` on **desktop** (same commands, in the desktop repo).
- [ ] Record org plugin pins — resolve the current HEAD of each plugin in `build-common.sh` and commit `plugin-lock.json` to `release/vX.Y.Z` on desktop:
  ```bash
  # From the slopsmith-desktop repo, on release/vX.Y.Z
  node scripts/generate-plugin-lock.js > plugin-lock.json
  git add plugin-lock.json
  git commit -m "chore: record plugin pins for vX.Y.Z"
  git push
  ```
- [ ] Announce the branch cut. All vX.Y.Z work now targets `release/vX.Y.Z`. `main` is frozen at the previous release.

---

## Phase 2 — Alpha / beta builds

Repeat as needed throughout the development cycle.

- [ ] Verify all planned PRs for this tag are merged to `release/vX.Y.Z`
- [ ] Confirm CI is green on `release/vX.Y.Z` in both repos
- [ ] Tag core:
  ```bash
  # In got-feedback/feedBack, on release/vX.Y.Z
  git tag vX.Y.Z-alpha.1    # or -beta.1, etc.
  git push origin vX.Y.Z-alpha.1
  ```
- [ ] Monitor `release.yml` on core — Docker image should appear on GHCR within ~5 minutes
- [ ] Tag desktop with the same tag:
  ```bash
  # In got-feedback/feedBack-desktop, on release/vX.Y.Z
  git tag vX.Y.Z-alpha.1
  git push origin vX.Y.Z-alpha.1
  ```
- [ ] Monitor `release.yml` on desktop — installers should be attached to the GitHub Release
- [ ] Share the GitHub Release link with testers. Note the Velopack channel (`alpha` or `beta`) in the release notes.

---

## Phase 3 — Final release

- [ ] Verify all planned issues for vX.Y.Z are closed or deferred to a future milestone
- [ ] Confirm CI is green on `release/vX.Y.Z` in both repos
- [ ] Update `CHANGELOG.md` in core: rename `[Unreleased]` to `[vX.Y.Z] - YYYY-MM-DD`, open a new empty `[Unreleased]` section above it. PR to `release/vX.Y.Z`.
- [ ] Update bug report form version dropdown — add `X.Y.Z` to the options list in `.github/ISSUE_TEMPLATE/bug_report.yml` in both core and desktop repos. PR to `release/vX.Y.Z`.
- [ ] Tag core:
  ```bash
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```
- [ ] Monitor `release.yml` on core:
  - Docker image pushed to GHCR as `:vX.Y.Z` and `:latest`
  - `notify-slopsmith` job dispatches the VERSION sync to core `main`
- [ ] Tag desktop:
  ```bash
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```
- [ ] Monitor `release.yml` on desktop — signed installers attached to the GitHub Release
- [ ] Verify the GitHub Release on desktop has all platform artifacts:
  - [ ] Windows: `.msi` + Velopack `releases.win-x64-stable.json`
  - [ ] macOS: `*-osx.zip` + Velopack `releases.osx-arm64-stable.json`
  - [ ] Linux: `.AppImage` + `.deb`

---

## Phase 4 — Merge to main

- [ ] Open PR: `release/vX.Y.Z` → `main` on **core**. Wait for `ship-ci.yml` to pass, then merge.
- [ ] Open PR: `release/vX.Y.Z` → `main` on **desktop**. Wait for `ship-ci.yml` to pass, then merge.
- [ ] Delete `release/vX.Y.Z` branches on both repos after merge.
- [ ] Close the milestone tracking issue.

---

## Promoting a nightly to alpha / beta

If you want to ship a nightly as an alpha without a rebuild:

1. Identify the nightly date to promote (e.g. `20260615`)
2. Trigger `promote.yml` on `slopsmith-desktop` via `workflow_dispatch`:
   - `nightly_date`: `20260615`
   - `version`: `0.3.0-alpha.1`
   - `channel`: `alpha`

This re-tags the GHCR nightly image (core) and attaches the nightly artifacts to a new GitHub Release (desktop). No code changes, no rebuild.
