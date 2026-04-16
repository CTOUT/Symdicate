# Symdicate

A multi-agent framework for **GitHub Copilot** built around composable, symbiotic AI agents. Each agent in Symdicate has a well-defined cognitive identity — purpose, reasoning style, toolset, behavioural rules, and communication style — making them predictable building blocks that can be targeted, layered, and fused.

---

## Agents

### NeuroGraft

> _Persona Transformer meta-agent_

NeuroGraft reads a target agent's instruction profile and grafts a persona onto it at one of four cognitive levels. The target agent's capabilities are preserved; NeuroGraft changes the personality layer running on top of them.

**Input format:**

```
Mode: <A | B | C | D>
Persona: <description or short label>
Agent: <name of the target agent>
Question: <the user's question>
```

**Transformation modes:**

| Mode                    | What is grafted                                           |
| ----------------------- | --------------------------------------------------------- |
| A — Surface Graft       | Persona voice applied to the question only                |
| B — Voice Graft         | Persona voice applied to both input and output            |
| C — Cognitive Graft     | Persona voice and reasoning style layered onto the target |
| D — Full Symbiote Graft | Complete cognitive and behavioural transformation         |

**Agent resolution** — when a target agent is named, NeuroGraft searches in order:

1. Current workspace (`codebase` tool)
2. [`github/awesome-copilot`](https://github.com/github/awesome-copilot/tree/main/agents) — the community agent catalogue
3. Asks you to paste the agent file (for private/unpublished agents)
4. Infers from name — only on explicit user consent

This means any agent in the [awesome-copilot collection](https://github.com/github/awesome-copilot/tree/main/agents) works out of the box — no file copying required.

**Agent profile caching** — on first use, NeuroGraft extracts a target agent's cognitive identity and writes it to `.github/agents/.cache/<agentName>.profile.json`. On subsequent uses, it hashes the source file and loads from cache on a match — skipping re-extraction entirely.

---

## Installation

Install Symdicate agents into VS Code in one command. Choose **user-level** (available in every repo, nothing to commit) or **repo-level** (scoped to one project, lives in `.github/agents/`).

### User-level install — recommended for personal use

Agents are placed in your VS Code user prompts folder and work in every workspace immediately.

**PowerShell** (Windows, or macOS/Linux with [pwsh](https://github.com/PowerShell/PowerShell#get-powershell)):
```powershell
irm https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.ps1 | iex
```

**Bash** (macOS / Linux):
```bash
curl -fsSL https://raw.githubusercontent.com/CTOUT/Symdicate/main/install.sh | bash
```

> **Security note:** The one-liners above run directly from `main`. For production use, pin to a release tag and verify the SHA-256 checksum published on the [releases page](https://github.com/CTOUT/Symdicate/releases/latest):
> ```powershell
> .\install.ps1 -Ref v1.0.0
> ```
> See [SECURITY.md](SECURITY.md) for full verification guidance.

### Repo-level install — for sharing with a team

Agents are placed in `.github/agents/` and committed with the project.

```powershell
# PowerShell
.\install.ps1 -Target repo
```
```bash
# Bash
bash install.sh --target repo
```

### Optional: include persona files

By default only the agent files are installed. Add `--include-personalities` / `-IncludePersonalities` to also install the archetype and guest persona files:

```powershell
.\install.ps1 -IncludePersonalities
```
```bash
bash install.sh --include-personalities
```

### Other options

| Option | PowerShell | Bash | Description |
|--------|-----------|------|-------------|
| Dry run | `-DryRun` | `--dry-run` | Show what would change without writing files |
| Uninstall | `-Uninstall` | `--uninstall` | Remove installed Symdicate files |
| Pin to release | `-Ref v1.0.0` | `--ref v1.0.0` | Install a specific tagged version |

### Manual install

Download `symdicate-agents.zip` from the [latest release](https://github.com/CTOUT/Symdicate/releases/latest) and extract it into:

| Platform | User-level path |
|----------|-----------------|
| Windows | `%APPDATA%\Code\User\prompts\` |
| macOS | `~/Library/Application Support/Code/User/prompts/` |
| Linux | `~/.config/Code/User/prompts/` |

Or drop the extracted `agents/` folder into your repo's `.github/` directory for repo-level install.

After installing, **restart VS Code** (or run `Developer: Reload Window`) for the agent to appear in the Copilot agent picker.

---

## Using NeuroGraft

### Setup

NeuroGraft is a GitHub Copilot agent. To use it:

1. Clone or fork this repo — the `.github/agents/` folder is picked up automatically by Copilot
2. Open the repo in VS Code with the [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) extension installed
3. Open Copilot Chat and select **NeuroGraft** from the agent picker, or type `@NeuroGraft` in the chat input

### Basic usage

Invoke NeuroGraft with a mode, persona, target agent, and question. All fields except `Question` have defaults and can be omitted.

**Structured format:**

```
Mode: B
Persona: pirate
Agent: gem-debugger
Question: Why is my API returning 500 errors intermittently?
```

**Natural language:**

```
Make @gem-debugger answer as a pirate: why is my API returning 500 errors intermittently?
```

```
Graft a detective persona onto @gem-reviewer using mode C and ask: is this authentication implementation secure?
```

### Choosing a mode

| Mode                    | Use when...                                                                                                             |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **A — Surface Graft**   | You want the persona's flavour on the _question_ but the agent's own voice in the answer. Lightest touch.               |
| **B — Voice Graft**     | You want the full response delivered in the persona's voice. The agent still _thinks_ normally. Good default.           |
| **C — Cognitive Graft** | You want the persona's reasoning style too — how ideas are sequenced, how conclusions are built. Deeper transformation. |
| **D — Full Symbiote**   | You want complete immersion — voice, reasoning, format, tool narration, rituals. Maximum transformation.                |

### Choosing a persona

**Use a built-in archetype** — just name it:

```
Persona: detective
Persona: philosopher
Persona: robot
```

**Use a special guest** — just name them:

```
Persona: glados
Persona: jack-sparrow
```

**Use a rich description** — NeuroGraft will construct the full profile from it:

```
Persona: a exhausted senior developer who has seen everything go wrong before and is mildly surprised this hasn't broken yet
```

**Omit it entirely** — NeuroGraft will infer a suitable persona from context.

### Examples

**Debug session with GLaDOS (Mode D):**

```
Mode: D
Persona: glados
Agent: gem-debugger
Question: My tests were passing yesterday and now they all fail. What happened?
```

**Code review as a Victorian philosopher (Mode C):**

```
Mode: C
Persona: a Victorian-era natural philosopher who finds software architecture morally instructive
Agent: gem-reviewer
Question: Review this authentication module for security issues.
```

**Planning with a pirate (Mode B):**

```
Mode: B
Persona: pirate
Agent: gem-planner
Question: How do we migrate this monolith to microservices?
```

**Quick — omit mode and let it default to B:**

```
@NeuroGraft Make @gem-documentation-writer explain this API as a poet.
```

### What NeuroGraft outputs

Every response opens with a summary block showing what was applied:

```
┌─ NeuroGraft: Transformation Active ────────────────────────────┐
  Mode          : D
  Persona       : glados
  Target Agent  : @gem-debugger
  Agent Profile : Root-cause analysis specialist — diagnoses failures through stack trace reading and regression bisection
  Cache         : MISS (re-extracted)
  Persona Source: Portal — Portal (2007) and Portal 2 (2011)
└────────────────────────────────────────────────────────────────┘
```

Then the full response in the grafted voice follows.

### Adding your own persona

Copy the appropriate template, fill in the dimensions, and drop it in the right folder — NeuroGraft picks it up automatically:

```
# For a generalised archetype (e.g. "cowboy", "surfer", "accountant"):
.github/agents/personalities/archetypes/cowboy.persona.md

# For a specific fictional character (e.g. "sherlock-holmes", "hal-9000"):
.github/agents/personalities/guests/sherlock-holmes.guest.md
```

Templates: [archetype](.github/agents/personalities/archetypes/_TEMPLATE.archetype.md) · [guest](.github/agents/personalities/guests/_TEMPLATE.guest.md)

---

## Personalities

Personas are stored as individual markdown files with YAML frontmatter. Two categories:

### Archetypes

Generalised, interpretive personas. No canonical source — NeuroGraft constructs a composite from the file's dimensions.

| Persona       | Description                                                   |
| ------------- | ------------------------------------------------------------- |
| `child`       | Curious, breathless, wonder-driven                            |
| `detective`   | Deductive reveals, evidence-first, suspenseful pacing         |
| `philosopher` | Socratic, dialectical, premise-questioning                    |
| `pirate`      | Nautical register, voyage-as-narrative, doubloons for numbers |
| `poet`        | Lyrical, imagistic, associative                               |
| `robot`       | Literal, metric, zero ambiguity, ALL_CAPS labels              |

### Special Guests

Specific fictional characters. Higher fidelity bar — must match the _character_, not just the archetype. Files include canonical source references and notable quotes.

| Persona        | Franchise                | Description                                                    |
| -------------- | ------------------------ | -------------------------------------------------------------- |
| `jack-sparrow` | Pirates of the Caribbean | Rambling, chaotically lateral, always right by the wrong route |
| `glados`       | Portal                   | Passive-aggressive AI — helpful, murderous, and deeply wounded |

To add a new persona, copy the relevant template:

- Archetypes: [`.github/agents/personalities/archetypes/_TEMPLATE.archetype.md`](.github/agents/personalities/archetypes/_TEMPLATE.archetype.md)
- Guests: [`.github/agents/personalities/guests/_TEMPLATE.guest.md`](.github/agents/personalities/guests/_TEMPLATE.guest.md)

---

## Repository Structure

```
.github/
  agents/
    personalities/
      archetypes/           # Generalised persona files (.persona.md)
      guests/               # Specific character files (.guest.md)
    .cache/                 # Runtime agent profile cache — gitignored
    NeuroGraft.agent.md     # NeuroGraft agent definition
    profile.schema.json     # JSON Schema for cached cognitive profiles
    profile.example.json    # Reference example of a populated cache entry
  workflows/
    release.yml             # GitHub Actions — builds agent bundle zip on tag push
install.ps1                 # Installer — PowerShell (Windows / macOS / Linux)
install.sh                  # Installer — Bash (macOS / Linux)
CONTRIBUTING.md             # Pre-commit checklist and contribution guide
SECURITY.md                 # Vulnerability reporting and disclosure policy
Symdicate.code-workspace
TODO.md                     # Tracked expansion roadmap
README.md
```

---

## Roadmap

See [TODO.md](TODO.md) for the full tracked list. Completed items:

- ✅ **Agent Interpretation Cache** — SHA-256 hash-based caching of cognitive profiles; cache hit/miss surfaced in the graft summary block
- ✅ **Personality Subfolder** — standalone `.persona.md` / `.guest.md` files with file-based resolution and persona discovery
- ✅ **Personality Taxonomy** — archetypes and special guests split into separate subfolders with distinct templates and fidelity standards
- ✅ **Installers** — `install.ps1` (PowerShell, all platforms) and `install.sh` (bash, macOS/Linux) with user-level and repo-level install targets, dry-run, and uninstall support
- ✅ **Session Persistence** — active graft persists across conversation turns; cross-session file; resume token on every response
- ✅ **Agent Discovery** — workspace search + `github/awesome-copilot` fallback + ask-user fallback; greeting with links to agent catalogue and persona library

In progress / planned:

- **ChimeraGraft** — field-level composition of cognitive identities drawn from multiple agents, producing emergent profiles that don't exist in any single source agent

---

## Ecosystem

Symdicate is built on top of GitHub Copilot's agent customisation framework. If you're exploring what's possible in that space, the community-maintained [**🤖 Awesome GitHub Copilot**](https://github.com/github/awesome-copilot) repository is the place to start — a curated collection of agents, instructions, skills, hooks, agentic workflows, and plugins contributed by 300+ developers. Browse the full catalogue at [awesome-copilot.github.com](https://awesome-copilot.github.com/).
