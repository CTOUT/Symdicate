# Changelog

All notable changes to Symdicate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

#### NeuroGraft — Persona Transformer agent
- Four transformation modes (A — Surface Graft, B — Voice Graft, C — Cognitive Graft, D — Full Symbiote Graft)
- Structured and natural language input formats with sensible defaults
- Agent profile caching — SHA-256 content-hash-based cache at `.github/agents/.cache/<agentName>.profile.json`; cache schema defined in `profile.schema.json`; reference example in `profile.example.json`
- Graft summary block on every response (mode, persona, target agent, agent profile, cache status, persona source)

#### Personality system
- Personality taxonomy split into archetypes (`personalities/archetypes/`) and special guests (`personalities/guests/`)
- Archetype template (`_TEMPLATE.archetype.md`) and guest template (`_TEMPLATE.guest.md`)
- Six seed archetypes: `child`, `detective`, `philosopher`, `pirate`, `poet`, `robot`
- Two seed special guests: `glados` (Portal), `jack-sparrow` (Pirates of the Caribbean)
- File-based persona resolution — NeuroGraft checks persona files before inferring from label
- Persona discovery — NeuroGraft lists available personas grouped by category on request
- Real-person safeguard — `contentNote` field on guest files is an absolute constraint overriding user instruction

#### Session persistence
- `Session State` section in agent instructions — active graft persists across all turns in a conversation
- Silent session inheritance — follow-up prompts with no Mode/Persona/Agent reuse the active session
- Session commands: `end session`, `current graft?`, `resume: <token>`
- Cross-session file persistence at `.github/agents/.cache/neurograft-session.json`
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

---

[Unreleased]: https://github.com/CTOUT/Symdicate/compare/v1.0.0...HEAD
