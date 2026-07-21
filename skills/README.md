# Skills

Canonical source of truth for all Symdicate-authored skills. Each subdirectory
contains a `SKILL.md` file and optional supporting resources.

> **Note:** This directory is for Symdicate's own skills only. External skills
> installed via vscode-copilot-sync (`.github/skills/`) are subscriptions and
> are not tracked in this repo.

## Structure

```text
skills/
  <skill-name>/
    SKILL.md              # Required — YAML frontmatter + markdown instructions
    scripts/              # Optional — helper scripts
    references/           # Optional — supplementary documentation
    examples/             # Optional — reference implementations
```

## Format

Every `SKILL.md` must begin with YAML frontmatter:

```yaml
---
name: <skill-name>
description: >
  Clear description of what this skill does and when to trigger it.
---
```

The `name` and `description` fields are required. Additional engine-specific
fields (e.g. Copilot's `allowed-tools`) are permitted — engines that don't
recognise them will ignore them gracefully.

The markdown body contains the full instructions for the skill. Keep it under
500 lines; use a `references/` subdirectory for anything longer.

## Engine Compatibility

This directory is **engine-neutral**. The projection script (`project.ps1` /
`project.sh`) creates engine-specific copies in the locations each AI engine
expects:

| Engine  | Projection Target        |
| ------- | ------------------------ |
| Copilot | `.github/skills/<name>/` |
| Gemini  | `.agents/skills/<name>/` |

Run `.\project.ps1` (or `bash project.sh`) to project skills to both engines.

## Authoring Guidelines

- Author all skills in this directory — never directly in `.github/skills/` or
  `.agents/skills/`
- Run the projection script after creating or modifying a skill
- Keep instructions engine-agnostic — avoid referencing engine-specific tools or
  paths unless wrapped in conditional language
