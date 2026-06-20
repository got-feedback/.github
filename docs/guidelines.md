# DevOps Guidelines

Guidelines for contributors to `got-feedback/feedBack` and `got-feedback/feedBack-desktop`. For plugin-specific rules see [plugins.md](plugins.md).

---

## Daily workflow

- All work goes through PRs — no direct pushes to `main` or `release/**`
- Always branch from the **active `release/vX.Y.Z` branch**, not `main`
- Keep branches focused; avoid bundling unrelated changes in one PR
- Commit style: [Conventional Commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`

---

## Branch naming

Format: `<type>/<issue-number>-short-description`

Examples:
- `fix/412-audio-dropout-on-seek`
- `feature/388-lyrics-sync`
- `chore/bump-tailwind` (no issue number for mechanical changes)

**Tip:** Use GitHub's "Create a branch" button on an issue (Development panel in the sidebar). It auto-names the branch and links the resulting PR back to the issue.

---

## Issue policy

| Branch type | Issue required | Rationale |
|---|---|---|
| `fix/*` | Yes — always | Bugs must be reported and triaged before code is written. Creates a permanent link between report, fix, and release. |
| `feature/*` | Yes for external contributors; maintainer's discretion for small additions | Surfaces design questions early; avoids PRs being closed for wrong direction. |
| `hotfix/*` | Yes — always | Creates the paper trail for a patch release: issue documents what broke, PR documents the fix, tag documents when it shipped. |
| `chore/`, `docs/`, `refactor/` | No | Low-risk and mechanical; an issue for a dependency bump or typo fix is pure friction. |

---

## Bug reports

Bug reports should include:
- **Version** — the exact version tag or nightly date (`v0.3.0`, `nightly-20260608`)
- **Platform** — Docker / Desktop Windows / Desktop macOS / Desktop Linux
- **Steps to reproduce** — minimum steps to trigger the issue
- **Expected vs. actual behaviour**

The core and desktop repos enforce this via issue forms. See [github-setup.md](github-setup.md).

---

## Starting a new version

1. Open a tracking issue: "v0.3.0 milestone" — list planned features and link to relevant issues
2. Cut `release/v0.3.0` from `main` on both core and desktop
3. Record org plugin pins in `plugin-lock.json` on `release/v0.3.0` (see [pipeline.md](pipeline.md#plugin-lock-pinning))
4. Announce the branch cut in the relevant channels — from this point all v0.3.0 work targets `release/v0.3.0`
5. `main` remains frozen at the previous release until v0.3.0 ships

---

## During development (alpha / beta)

- All features and fixes are PRed against `release/v0.3.0`
- No cherry-picks needed — everything for this version is already on the release branch
- Tags are cut by a maintainer when a build is ready for wider testing (see [runbooks/release.md](../runbooks/release.md))
- Nightly builds run automatically from the active release branch at 02:00 UTC

---

## Commit message style

Follow [Conventional Commits](https://www.conventionalcommits.org/). Subject line ≤ 72 characters. Body only when the *why* isn't obvious from the diff.

```
feat(player): add stem balance controls to mixer popover

fix(highway): correct fret position for 7-string arrangements

chore: bump tailwind to 3.4.19

docs: update plugin manifest reference for diagnostics.callable
```

Type reference:

| Type | Use for |
|---|---|
| `feat` | New user-facing functionality |
| `fix` | Bug fix |
| `chore` | Dependency bumps, build changes, tooling — no production code change |
| `docs` | Documentation only |
| `refactor` | Code restructuring with no behaviour change |
| `perf` | Performance improvement |
| `test` | Test additions or corrections |

---

## PR checklist

Before marking a PR ready for review:

- [ ] Branches from and targets the active `release/vX.Y.Z` branch
- [ ] CI passes (all required checks green)
- [ ] Linked to an issue (for `fix/*` and `feature/*`)
- [ ] `CHANGELOG.md` `[Unreleased]` section updated if the change is user-visible
- [ ] For core plugin changes: `tailwind.min.css` rebuilt if new Tailwind classes were added (`bash scripts/build-tailwind.sh`)
