# Contributing to Symdicate

Thanks for your interest in contributing. This document covers the development workflow and pre-commit checklist.

---

## Pre-commit Checklist

Before every commit, run through this list:

### Agent changes (`NeuroGraft.agent.md`, persona files, schema files)
- [ ] Instructions are clear, unambiguous, and internally consistent
- [ ] New tools added to the frontmatter only if actually used in the instructions
- [ ] No hardcoded paths — use `**/*` glob patterns for workspace searches
- [ ] `CHANGELOG.md` updated under `[Unreleased] → Added / Changed / Fixed`
- [ ] `README.md` updated if the change affects user-facing behaviour or the repo structure

### Installer changes (`install.ps1`, `install.sh`)
- [ ] Both installers kept functionally equivalent where possible
- [ ] `install.sh` uses SHA-256 comparison (not `diff -q`)
- [ ] Any new `Invoke-RestMethod` calls include `-TimeoutSec 30`
- [ ] Tested with `-DryRun` / `--dry-run` before testing a real install
- [ ] `CHANGELOG.md` updated

### Persona files (`.persona.md`, `.guest.md`)
- [ ] All five dimensions populated (voice, reasoning style, reference frame, format preferences, behavioural tells)
- [ ] Guest files include `franchise`, `canonicalSource`, and `contentNote` fields
- [ ] Real-person guests: `contentNote` explicitly prohibits fabricating opinions or private facts
- [ ] File placed in the correct subfolder (`archetypes/` or `guests/`)
- [ ] `README.md` persona table updated if adding a new seed persona

### Repository / docs changes
- [ ] `README.md` Repository Structure section reflects any new/removed files
- [ ] `CHANGELOG.md` updated
- [ ] `TODO.md` updated if a tracked item is completed or a new one is added

---

## Changelog Format

Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Add entries under `## [Unreleased]` — never edit a released version section.

```markdown
## [Unreleased]

### Added
- Short description of new feature

### Changed
- Short description of change to existing behaviour

### Fixed
- Short description of bug fix
```

---

## Cutting a Release

1. Ensure `CHANGELOG.md` `[Unreleased]` section is complete
2. Rename `[Unreleased]` to `[vX.Y.Z] — YYYY-MM-DD`
3. Add a new empty `[Unreleased]` section above it
4. Update the diff link at the bottom of `CHANGELOG.md`
5. Commit: `chore: prepare release vX.Y.Z`
6. Tag: `git tag vX.Y.Z -m "<release notes>"` — the tag message becomes the GitHub release body
7. Push: `git push && git push --tags`
8. GitHub Actions builds the zip and creates the release automatically

---

## Adding a Persona

**Archetype** (generalised, no canonical source):
1. Copy `.github/agents/personalities/archetypes/_TEMPLATE.archetype.md`
2. Name it `<label>.persona.md` and fill in all five dimensions
3. Add to the README archetypes table

**Special Guest** (specific fictional character):
1. Copy `.github/agents/personalities/guests/_TEMPLATE.guest.md`
2. Name it `<character-name>.guest.md` and fill in all fields including `franchise`, `canonicalSource`, and `contentNote`
3. Add to the README special guests table

---

## Adding an Agent to Symdicate

Each agent needs:
- A `.agent.md` file under `.github/agents/` with YAML frontmatter (`name`, `description`, `tools`) and markdown instructions
- An entry in `README.md`
- An entry in `CHANGELOG.md`
- An entry in `TODO.md` if it has a tracked roadmap
