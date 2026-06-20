# CI/CD Pipeline

---

## Workflow overview

| Workflow | Repo | Trigger | What it does |
|---|---|---|---|
| `ci.yml` | core, desktop | PR to `release/**` | Full test suite — required to pass before merge |
| `ship-ci.yml` | core, desktop | PR to `main` | Full test suite on the final release-to-main PR |
| `nightly.yml` | desktop | Cron 02:00 UTC | Builds from the active `release/*` branch; falls back to `main` |
| `release.yml` | core, desktop | Tag push `v*` | Full build + sign; publishes to GitHub Releases |
| `promote.yml` | desktop | `workflow_dispatch` | Re-tags a nightly as alpha / beta / release — no rebuild |

---

## ci.yml — test suite

Runs on every PR targeting `release/**`. Must pass before merge.

**Core checks:**
```
pytest
JS plugin-API tests (node --test)
tailwind-fresh             covers static/ and bundled: true plugins
print() / traceback guard  server.py, lib/, routes.py in bundled: true plugins
plugin manifest validation all plugins/*/plugin.json
```

**Desktop checks:**
```
TypeScript compilation
npm audit (high severity)
```

---

## ship-ci.yml — final release PR check

Runs on every PR targeting `main` — in practice once per version, on the `release/vX.Y.Z` → `main` merge PR. Runs the identical suite as `ci.yml`. Ensures the full release branch passes cleanly before landing on `main`.

---

## nightly.yml — scheduled builds

Runs at 02:00 UTC every night.

**Branch selection logic:**
- If any `release/v*` branch exists → build the most recently created one
- Otherwise → build `main`

During active development there is almost always an active release branch, so nightlies effectively always build from `release/*`. `main` is only the nightly source in the quiet window between a release shipping and the next release branch being cut.

**Core artifact:** Docker image pushed to GHCR as `:nightly` and `:nightly-YYYYMMDD`

**Desktop artifacts:** Electron installers for Windows x64, macOS ARM64, Linux x64 — uploaded as GitHub Actions artifacts (7-day retention). Desktop clones core at the same branch as the nightly. Org plugins are cloned at **tip of their default branch** — no pinning for nightlies.

---

## release.yml — tag builds

Triggered by any tag matching `v*` on either repo.

**Tag sequence (always tag core first):**

1. Tag `v0.3.0` on core (`release/v0.3.0`) → triggers core `release.yml`
2. Tag `v0.3.0` on desktop (`release/v0.3.0`) → desktop CI clones core at the `v0.3.0` tag; org plugins are cloned at the commits pinned in `plugin-lock.json`
3. `notify-slopsmith` job in desktop's `release.yml` dispatches to core → core `VERSION` file updated on `main`
4. Open `release/v0.3.0` → `main` PRs on both repos; merge after CI passes

**Core output:** Docker image → GHCR `:v0.3.0` (+ `:latest` for non-pre-release tags)

**Desktop output:** Signed installers attached to the GitHub Release. Velopack update channels are derived from the tag:

```
v0.3.0-alpha.1  → alpha channel
v0.3.0-beta.1   → beta channel
v0.3.0          → stable channel
```

See [runbooks/release.md](../runbooks/release.md) for the full release checklist.

---

## promote.yml — nightly to release

When a nightly build is good enough to ship as an alpha or beta, a maintainer promotes it without rebuilding.

Trigger: `workflow_dispatch` on `slopsmith-desktop` with inputs:
- `nightly_date` — YYYYMMDD of the nightly run to promote
- `version` — target version string (e.g. `0.3.0-beta.1`)
- `channel` — `alpha`, `beta`, or `release`

**Core:** re-tags the existing GHCR nightly image to the new version tag. No rebuild.

**Desktop:** downloads the artifacts from the specified nightly run and attaches them to a new GitHub Release. No rebuild.

---

## Plugin-lock pinning

Org plugins (`got-feedback/feedBack-plugin-*`) are cloned by the desktop build at build time. For release builds, they are pinned to specific commits recorded in `plugin-lock.json` on the active `release/*` branch. Nightlies always use tip.

`plugin-lock.json` is created when the release branch is cut (see [runbooks/release.md](../runbooks/release.md)) and can be updated via PR on the release branch if a specific plugin fix needs to ship in the release.

Format:
```json
{
  "got-feedback/feedBack-plugin-notedetect": "abc1234",
  "got-feedback/feedBack-plugin-piano": "def5678",
  "masc0t/slopsmith-plugin-find-more": "ghi9012"
}
```
