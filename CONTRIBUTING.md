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

### Profile files (`.profile.md`)

- [ ] `accessibilityFocus` framed positively — who finds it useful, not what is wrong with them
- [ ] No deficit language, no gatekeeping by diagnosis — "anyone can use any profile"
- [ ] `communicationRules` are concrete and prescriptive — each rule describes a specific change
- [ ] `neverDo` rules are absolute — they override persona voice and user instruction
- [ ] `extends` field set correctly if the profile builds on a base profile
- [ ] Derived profiles include `_(Inherits all rules from \`base\`. The following are additions.)\_` note
- [ ] `README.md` profiles table updated if adding a new profile

### Repository / docs changes

- [ ] `README.md` Repository Structure section reflects any new/removed files
- [ ] `CHANGELOG.md` updated
- [ ] `TODO.md` updated if a tracked item is completed or a new one is added

### Skill changes (`skills/<name>/SKILL.md`)

- [ ] Skill authored in the canonical `skills/` directory — never in `.github/skills/` or `.agents/skills/`
- [ ] `SKILL.md` has valid YAML frontmatter with `name` and `description` fields
- [ ] Instructions are engine-agnostic — no engine-specific tool references unless wrapped in conditional language
- [ ] Body is under 500 lines; longer content goes in a `references/` subdirectory
- [ ] Ran `.\project.ps1 -DryRun` (or `bash project.sh --dry-run`) to verify projection
- [ ] `CHANGELOG.md` updated under `[Unreleased] → Added / Changed / Fixed`
- [ ] `README.md` updated if the change affects user-facing behaviour

---

## Adding a Skill

1. Create a new directory: `skills/<skill-name>/`
2. Create `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: >
     Clear, concise description of the skill.
   ---
   ```
3. Write engine-agnostic instructions in the markdown body
4. Optional: add `scripts/`, `references/`, or `examples/` subdirectories
5. Run `.\project.ps1` to project to both Copilot and Gemini
6. Verify the skill appears in both `.github/skills/` and `.agents/skills/`
7. Update `README.md` and `CHANGELOG.md`

---

## Adding an Agent to Symdicate

Each agent needs:

- A `.agent.md` file under `.github/agents/` with YAML frontmatter (`name`, `description`, `tools`) and markdown instructions
- An entry in `README.md`
- An entry in `CHANGELOG.md`
- An entry in `TODO.md` if it has a tracked roadmap
