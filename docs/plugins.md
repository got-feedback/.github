# Plugin Tiers and Governance

Slopsmith distinguishes three plugin tiers with different integration levels and governance requirements.

---

## Tier overview

| Tier | Location | Ships via | Versioned with core |
|---|---|---|---|
| **Core plugins** (`bundled: true`) | `got-feedback/feedBack/plugins/` | Docker image + desktop | Yes — tied to core release |
| **Org plugins** | `got-feedback/feedBack-plugin-*` repos | Desktop only | No — independent cadence |
| **Community plugins** | Personal accounts | Desktop only | No — migration target |

---

## Core plugins

Core plugins have `"bundled": true` in their `plugin.json`. They live directly in the `got-feedback/feedBack` repository under `plugins/` and are the source of truth for what ships in the Docker image.

**Governance:** full core contribution workflow applies.
- PR required, CI must pass, 1 approval required
- Issue-first for bugs and features (see [guidelines.md](guidelines.md))
- Changes follow the core release cycle — a fix to a core plugin ships in the next tagged release

**CI checks that cover core plugins:**
- `tailwind-fresh` — Tailwind build covers `plugins/*/` in addition to `static/`
- `print() / traceback guard` — extended to `plugins/*/routes.py`
- `plugin manifest validation` — all `plugins/*/plugin.json` files validated for required fields

**When to make a plugin a core plugin:** when it provides functionality that every Slopsmith user should have (visualization, note detection, core editor tooling) and the plugin's development is tightly coupled to the core API. Moving a plugin into core is a deliberate decision — it increases the surface covered by core CI and ships the plugin to Docker users who may not want it.

---

## Org plugins

Org plugins live in their own repos under the `slopsmith` GitHub org (`got-feedback/feedBack-plugin-*`). The desktop build clones them at build time via `build-common.sh`.

**Governance:** lighter model. Plugin authors own their workflow.

**Required:**
- Branch protection on `main`: no force pushes, no direct pushes from outside the maintainer set
- Minimal CI (`ci / plugin-lint`) must pass on every push to `main`:
  - `plugin.json` validation — required fields present, valid JSON, `id` matches directory name
  - `print()` guard on `routes.py` if the plugin has a backend
  - JS syntax check: `node --check screen.js`
- AGPL-compatible license (MIT, BSD, Apache-2.0)

**Not required:**
- A specific branching model
- PR-based workflow (single-maintainer repos may push directly to `main`)
- Conventional Commits or any particular commit style
- Issue-first policy

The full core contribution guidelines apply only when a plugin is integrated into the core repo.

**Reusable CI workflow:** the `plugin-lint` job is defined as a reusable workflow in this repo. Org plugin repos call it rather than maintaining their own lint logic:

```yaml
# .github/workflows/ci.yml in any got-feedback/feedBack-plugin-* repo
jobs:
  plugin-lint:
    uses: slopsmith/.github/.github/workflows/plugin-lint.yml@main
```

---

## Community plugins (personal accounts)

Plugins on personal accounts are a transitional state. They are bundled in the desktop build while awaiting migration to the org.

**Reliability backstop:** for any bundled plugin on a personal account, a maintainer forks it into the org as `slopsmith-plugin-<name>-bak`. This fork exists solely as a fallback if the original repo disappears or breaks. It is not actively maintained and is retired when the plugin transfers to the org.

**Current personal-account plugins bundled in desktop:**

| Plugin | Author | Status |
|---|---|---|
| `find-more` | masc0t | Transfer pending |
| `invert-highway` | masc0t | Transfer pending |
| `themes` | masc0t | Transfer pending |
| `update-manager` | masc0t | Transfer pending |
| `song-preview` | DeathlySin | Transfer pending |
| `nam-rig-builder` | Jafz2001 | Transfer pending |
| `guitar-theory` | topkoa | Transfer pending |
| `slopscale` | ChrisBeWithYou | Transfer pending |
| `transpose-chords` | alleexx | Transfer pending |
| `stem-mixer` | narvasus | Transfer pending |

`masc0t` maintains four plugins from a single account — this is the highest single-point-of-failure risk in the desktop plugin set and is the near-term migration priority.

For the migration process see [runbooks/plugin-migration.md](../runbooks/plugin-migration.md).

---

## Plugin pinning in desktop releases

Nightly builds clone org and community plugins at **tip of their default branch**.

Release builds use commits pinned in `plugin-lock.json` on the active `release/*` branch. Pins are recorded when the release branch is cut and can be updated via PR on that branch if a specific plugin fix needs to ship in the release.

See [pipeline.md](pipeline.md#plugin-lock-pinning) for the file format.
