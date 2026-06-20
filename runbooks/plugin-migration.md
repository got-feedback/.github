# Runbook: Plugin Migration

Step-by-step checklist for migrating a plugin from a personal account into the slopsmith org.

This applies to bundled plugins currently living on personal accounts (see [docs/plugins.md](../docs/plugins.md#community-plugins-personal-accounts) for the current list).

---

## Prerequisites

- The plugin has been bundled in at least one desktop release
- The plugin author has agreed to transfer the repo to the org
- The plugin has an AGPL-compatible license (MIT, BSD, or Apache-2.0)

---

## Steps

### 1 — Create a -bak fork (if not already done)

Before touching anything, create a safety fork in the org. If the transfer fails or the author changes their mind, the fork is the fallback the desktop build can point to.

In the slopsmith org, fork `<author>/<repo>` as `slopsmith/<repo>-bak`. This is a one-time step — skip if the fork already exists.

### 2 — Verify license

Confirm the repo has a LICENSE file and the license is AGPL-compatible (MIT, BSD, Apache-2.0). If no license file exists, ask the author to add one before transferring — a repo without a license is not legally safe to bundle.

### 3 — Check open PRs and issues

Review any open PRs and issues on the personal repo. Notify contributors that the repo is moving — their issue/PR URLs will redirect after the transfer, but they should know in advance.

### 4 — Coordinate the transfer with the author

The author transfers the repo from their GitHub account settings:

**Author's steps:**
- Go to `github.com/<author>/<repo> → Settings → Danger Zone → Transfer repository`
- Transfer to organisation: `slopsmith`
- The repo lands as `slopsmith/<repo>` (keeping its original name, without `-bak`)

GitHub automatically sets up redirects from the old URL for all git operations and web links.

### 5 — Add branch protection

After transfer, the repo is in the org but has no rulesets applied yet. Verify that the org-level **Ruleset 2** (`slopsmith-plugin-*`, `main` branch) picked it up automatically — it should, since it targets repos by naming pattern.

Confirm in the repo's Settings → Rules that `ci / plugin-lint` is a required check.

### 6 — Add the plugin-lint CI workflow

If the transferred repo doesn't already have a `.github/workflows/ci.yml`, add one via PR:

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  plugin-lint:
    uses: slopsmith/.github/.github/workflows/plugin-lint.yml@main
```

### 7 — Update build-common.sh in slopsmith-desktop

Change the entry in `scripts/build-common.sh` from the personal account to the org:

```bash
# Before
<author>/slopsmith-plugin-<name>

# After
got-feedback/feedBack-plugin-<name>
```

Open a PR on the active `release/*` branch of `slopsmith-desktop`. Also update `plugin-lock.json` to point to the new repo's HEAD commit.

### 8 — Update the community plugins table in docs/plugins.md

Remove the plugin from the "current personal-account plugins" table in this repo, or mark it as transferred.

### 9 — Retire the -bak fork

Once `build-common.sh` is updated and merged and the transfer is confirmed stable (one full nightly build succeeds pulling from the org repo), archive or delete the `-bak` fork:

**github.com/slopsmith/`<repo>-bak` → Settings → Danger Zone → Archive this repository**

Archiving is preferred over deletion — it preserves history and keeps the redirect in place for anyone who bookmarked the bak URL.

---

## If the author declines to transfer

If an author doesn't want to transfer but is comfortable staying bundled:

1. Ensure the `-bak` fork exists in the org
2. Confirm the author is responsive to security/breaking-change requests
3. Document the risk in the community plugins table in `docs/plugins.md`

If the author becomes unresponsive or the repo is deleted, update `build-common.sh` to point to the `-bak` fork and open a PR to the active release branch.
