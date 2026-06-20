# GitHub Setup

Configuration steps for GitHub rulesets and issue templates.

---

## Repository rulesets

Org-wide rulesets require a paid GitHub plan. On a free org, rulesets are applied per-repo using the gh CLI scripts in [`scripts/`](../scripts/README.md).

### Pre-requisite: create the admins team

The core/desktop ruleset uses this team as a bypass actor for emergency hotfixes and the version-sync bot. Create it before running the scripts:

**github.com/slopsmith → Settings → Teams → New team**

- Team name: `admins`
- Visibility: Visible
- Add the relevant maintainer accounts as members

### Apply rulesets

```bash
# Requires gh authenticated as an org admin
bash scripts/apply-ruleset-core.sh          # slopsmith + slopsmith-desktop
bash scripts/apply-ruleset-core-checks.sh   # slopsmith only (extra CI checks)
bash scripts/apply-ruleset-plugins.sh       # all slopsmith-plugin-* repos
```

Run again whenever a new plugin repo is added to the org:

```bash
bash scripts/apply-ruleset-plugins.sh slopsmith-plugin-<name>
```

All scripts are idempotent. See [`scripts/README.md`](../scripts/README.md) for the full rule breakdown.

### What each ruleset enforces

| Ruleset | Repos | Branches | Rules |
|---|---|---|---|
| `branch-protection` | `slopsmith`, `slopsmith-desktop` | `main`, `release/**` | No force push/delete, PR + 1 approval, `ci / test` |
| `core-ci-checks` | `slopsmith` only | `main`, `release/**` | `ci / tailwind-fresh`, `ci / manifest-validation` |
| `plugin-branch-protection` | `slopsmith-plugin-*` | `main` | No force push/delete, `ci / plugin-lint` |

> **Status check names:** A required check is only enforced after it has run at least once in the repo. If CI hasn't run yet the rule exists but has no effect — trigger a workflow run to register the check name with GitHub.

---

## Issue forms

Issue forms gate new issue submissions to a structured format. Disable blank issues so every submission goes through a template.

### config.yml — disable blank issues

```yaml
# .github/ISSUE_TEMPLATE/config.yml  (in got-feedback/feedBack and got-feedback/feedBack-desktop)
blank_issues_enabled: false
contact_links:
  - name: Plugin issues
    url: https://github.com/slopsmith
    about: For plugin-specific bugs, open an issue in the relevant slopsmith-plugin-* repo.
```

### Bug report form

```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug report
description: Something isn't working correctly
labels: ["bug"]
body:
  - type: dropdown
    id: version
    attributes:
      label: Version
      description: The exact version where the bug occurs.
      options:
        - nightly
        - 0.3.0
        - 0.2.9
        - Other (specify in description)
    validations:
      required: true

  - type: dropdown
    id: platform
    attributes:
      label: Platform
      options:
        - Docker
        - Desktop — Windows
        - Desktop — macOS (Apple Silicon)
        - Desktop — macOS (Intel)
        - Desktop — Linux
    validations:
      required: true

  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      placeholder: "1. Open song X\n2. Click Y\n3. …"
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected behaviour
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual behaviour
    validations:
      required: true

  - type: textarea
    id: context
    attributes:
      label: Additional context
      description: Logs, screenshots, song format (Sloppak), anything else relevant.
    validations:
      required: false
```

### Feature request form

```yaml
# .github/ISSUE_TEMPLATE/feature_request.yml
name: Feature request
description: Suggest a new feature or improvement
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem or motivation
      description: What are you trying to do that you can't do today?
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed solution
      description: What would you like to happen? Rough sketches or examples welcome.
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
      description: Any other approaches you've thought about?
    validations:
      required: false
```

---

## Version label upkeep

The bug report form requires a version selection, but the dropdown options need to be kept current as new versions ship. Update the `options` list in `bug_report.yml` as part of the release checklist (see [runbooks/release.md](../runbooks/release.md)).

GitHub has no native "if label A then label B required" enforcement. The structured form is the practical alternative — it gates submissions at creation time, which is where the vast majority of improperly tagged issues originate.
