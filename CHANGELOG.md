# Changelog

All notable changes to Symdicate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

#### Persona library expansion (Item 7)
- Five new archetypes: `scientist`, `mentor`, `bureaucrat`, `comedian`, `stoic`
- Three new special guests: `hermione-granger` (Harry Potter), `data` (Star Trek: TNG), `wednesday-addams` (The Addams Family)
- Installer static fallback list updated with all new files

#### Accessibility and wellbeing profiles (Item 8)
- New `personalities/profiles/` category that change how any agent communicates, not who it is. Anyone can use any profile; no diagnosis or label required.
- 15 profile files: `_TEMPLATE.profile.md` plus 14 seed profiles
- Foundation profiles (no extends): `direct`, `low-load`, `structured`, `high-context`, `dyscalculia`, `screen-reader`, `eal`, and `mental-health` (base only)
- Derived profiles with `extends` inheritance: `dyslexia` (extends `direct`), `dyspraxia` (extends `low-load`), `anxiety`, `depression`, `stress` (all extend `mental-health`), `cognitive-fatigue` (extends `low-load` + `mental-health`)
- Profile files include `accessibilityFocus`, `communicationRules`, and `neverDo` fields; `extends` field for rule inheritance
- Framing principle in template and all profiles: differences, not deficits; tools to help, not labels
- NeuroGraft updated: `Profile:` parameter added to structured input format and greeting; profile resolution added to Step 1 (archetypes → guests → profiles → infer); `Persona and Profile Discovery` section updated with affirming profile listing; `Profile` line added to graft summary block
- Installers updated: `personalities/profiles/` included when `--include-personalities` / `-IncludePersonalities` is passed; dynamic API fetch + static fallback list both updated

---

## [v1.0.0] — 2026-04-16

### Added

#### NeuroGraft — Persona Transformer agent
- Four transformation modes (A — Surface Graft, B — Voice Graft, C — Cognitive Graft, D — Full Symbiote Graft)
- Structured and natural language input formats with sensible defaults
- Agent profile caching — SHA-256 content-hash-based cache at `.github/agents/.cache/<agentName>.profile.json`; cache schema defined in `profile.schema.json`; reference example in `profile.example.json`
- Graft summary block on every response (mode, persona, target agent, agent profile, cache status, session status, persona source)
- Greeting — when invoked with no parameters, NeuroGraft responds with a quick-start guide linking to the agent catalogue and persona library

#### Agent resolution
- Four-step fallback chain: workspace → `github/awesome-copilot` → ask user to paste → infer from name (explicit consent only)
- Any agent in the [awesome-copilot collection](https://github.com/github/awesome-copilot/tree/main/agents) resolves automatically without file copying
- Agent profile source noted in graft summary block (`workspace`, `github/awesome-copilot`, `pasted by user`, or `inferred`)

#### Personality system
- Personality taxonomy split into archetypes (`personalities/archetypes/`) and special guests (`personalities/guests/`)
- Archetype template (`_TEMPLATE.archetype.md`) and guest template (`_TEMPLATE.guest.md`)
- Six seed archetypes: `child`, `detective`, `philosopher`, `pirate`, `poet`, `robot`
- Two seed special guests: `glados` (Portal), `jack-sparrow` (Pirates of the Caribbean)
- File-based persona resolution — workspace search then infer from label
- Persona discovery — NeuroGraft lists available personas grouped by category on request, with scope note
- Real-person safeguard — `contentNote` field on guest files is an absolute constraint overriding user instruction

#### Session persistence
- `Session State` section in agent instructions — active graft persists across all turns in a conversation
- Silent session inheritance — follow-up prompts with no Mode/Persona/Agent reuse the active session
- Session commands: `end session`, `current graft?`, `resume: <token>`
- Cross-session file persistence at `.github/agents/.cache/neurograft-session.json`
- Stale session detection — if the target agent file changes between sessions, cognitive identity is re-extracted automatically
- Resume token appended to every response for portable cross-session restart
- `Session` line in graft summary block

#### Distribution
- `install.ps1` — PowerShell installer for Windows, macOS, Linux; user-level and repo-level targets; dry-run and uninstall support
- `install.sh` — Bash installer for macOS and Linux; same feature parity; Cursor detection
- `.github/workflows/release.yml` — GitHub Actions workflow that builds `symdicate-agents.zip` and creates a GitHub release on version tag push

#### Repository
- `README.md` with full usage guide, persona tables, installation instructions, and ecosystem references
- `TODO.md` tracking all expansion items
- `LICENSE` (MIT)
- `.gitignore` and `.gitattributes`

### Fixed

- Agent and persona search used hardcoded `.github/agents/` paths — replaced with workspace-wide `**/*` glob patterns so both repo-level and any workspace-visible files are found
- Discovery response said "none detected" when user-level installs exist but aren't workspace-visible — now correctly explains the workspace scope and directs users to name agents directly
- Step 0 / Step 1 merge artifact in Agent Reading Protocol — cache hit/miss bullets were incorrectly placed inside Step 0; moved to Step 1 where they belong
- `create_file` and `replace_string_in_file` tools added to NeuroGraft frontmatter — cache and session files can now actually be written (previously only declared, never possible)
- NeuroGraft tool list trimmed: removed `vscode/memory`, `vscode/resolveMemoryFileUri` (wrong persistence scope — would bleed sessions across workspaces), and `agent` (would enable actual sub-agent invocation, conflicting with the simulate-from-instructions design); updated to non-legacy tool name format
- `install.ps1` `Invoke-RestMethod` call had no timeout — added `-TimeoutSec 30`
- `install.sh` used `diff -q` for change detection instead of SHA-256 — aligned with `install.ps1` behaviour; `sha256sum`/`shasum -a 256` used with cross-platform fallback
- `install.sh` `|| true` on arithmetic counter increments now includes explanatory comment clarifying this suppresses the expected exit code 1 from `((n++))` when `n` is 0, not genuine errors
- **HIGH** — Script injection in `release.yml`: `${{ github.ref_name }}` was interpolated directly into a `run:` shell command; moved to `env:` block so it is passed as an environment variable and never raw-interpolated
- **HIGH** — Mutable action version pins in `release.yml`: `actions/checkout@v4` and `softprops/action-gh-release@v2` pinned to immutable commit SHAs
- **MEDIUM** — `SECURITY.md` documented SHA-256 checksum verification but release workflow published no checksum file; `checksums.sha256` is now generated and attached to every release
- **LOW** — `install.ps1` uninitialised counter keys: `not-found` and `would-remove` added to `$counts` initialisation
- **LOW** — README one-liner install commands had no proximate security note; callout added directing users to pin to a release tag and verify checksums

---

[Unreleased]: https://github.com/CTOUT/Symdicate/compare/v1.0.0...HEAD
[v1.0.0]: https://github.com/CTOUT/Symdicate/releases/tag/v1.0.0
