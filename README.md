# Slopsmith DevOps

This repository is the single source of truth for Slopsmith's development process, CI/CD pipeline, and contributor guidelines. All other repos link here rather than duplicating this content. Templates for other repositories are propagated out from here.

## Model summary

Slopsmith uses a **release-centric branching model**. Each version gets its own `release/vX.Y.Z` branch cut at the start of the development cycle. All work for that version targets the release branch. `main` only receives one merge per version — when the final release ships — and always reflects the last stable release.

`slopsmith` (core) and `slopsmith-desktop` follow the same version number and are tagged together on release day.

---

## Quick reference

| I want to… | Go to |
|---|---|
| Understand the branching model | [docs/branching.md](docs/branching.md) |
| Understand the CI/CD pipeline | [docs/pipeline.md](docs/pipeline.md) |
| Understand daily workflow and commit rules | [docs/guidelines.md](docs/guidelines.md) |
| Understand plugin tiers and governance | [docs/plugins.md](docs/plugins.md) |
| Set up GitHub rulesets and issue templates | [docs/github-setup.md](docs/github-setup.md) |
| Cut a new release | [runbooks/release.md](runbooks/release.md) |
| Apply a hotfix to a shipped version | [runbooks/hotfix.md](runbooks/hotfix.md) |
| Migrate a plugin into the org | [runbooks/plugin-migration.md](runbooks/plugin-migration.md) |

---

## Repos this applies to

| Repo | Role |
|---|---|
| `got-feedback/feedBack` | Core — FastAPI server, plugin loader, Docker image |
| `got-feedback/feedBack-desktop` | Desktop — Electron wrapper, native audio engine |
| `got-feedback/feedBack-plugin-*` | Org plugins — bundled in desktop, lighter governance |
