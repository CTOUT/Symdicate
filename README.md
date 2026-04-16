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

| Mode | What is grafted |
|------|----------------|
| A — Surface Graft | Persona voice applied to the question only |
| B — Voice Graft | Persona voice applied to both input and output |
| C — Cognitive Graft | Persona voice and reasoning style layered onto the target |
| D — Full Symbiote Graft | Complete cognitive and behavioural transformation |

**Persona resolution** — when a short label is given, NeuroGraft searches in order:
1. `personalities/archetypes/` — generalised, interpretive personas
2. `personalities/guests/` — specific fictional characters with higher fidelity requirements
3. Falls back to inference if no file is found

**Agent profile caching** — on first use, NeuroGraft extracts a target agent's cognitive identity and writes it to `.github/agents/.cache/<agentName>.profile.json`. On subsequent uses, it hashes the source file and loads from cache on a match — skipping re-extraction entirely.

---

## Personalities

Personas are stored as individual markdown files with YAML frontmatter. Two categories:

### Archetypes

Generalised, interpretive personas. No canonical source — NeuroGraft constructs a composite from the file's dimensions.

| Persona | Description |
|---------|-------------|
| `child` | Curious, breathless, wonder-driven |
| `detective` | Deductive reveals, evidence-first, suspenseful pacing |
| `philosopher` | Socratic, dialectical, premise-questioning |
| `pirate` | Nautical register, voyage-as-narrative, doubloons for numbers |
| `poet` | Lyrical, imagistic, associative |
| `robot` | Literal, metric, zero ambiguity, ALL_CAPS labels |

### Special Guests

Specific fictional characters. Higher fidelity bar — must match the *character*, not just the archetype. Files include canonical source references and notable quotes.

| Persona | Franchise | Description |
|---------|-----------|-------------|
| `jack-sparrow` | Pirates of the Caribbean | Rambling, chaotically lateral, always right by the wrong route |
| `glados` | Portal | Passive-aggressive AI — helpful, murderous, and deeply wounded |

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

In progress / planned:

- **ChimeraGraft** — field-level composition of cognitive identities drawn from multiple agents, producing emergent profiles that don't exist in any single source agent

---

## Ecosystem

Symdicate is built on top of GitHub Copilot's agent customisation framework. If you're exploring what's possible in that space, the community-maintained [**🤖 Awesome GitHub Copilot**](https://github.com/github/awesome-copilot) repository is the place to start — a curated collection of agents, instructions, skills, hooks, agentic workflows, and plugins contributed by 300+ developers. Browse the full catalogue at [awesome-copilot.github.com](https://awesome-copilot.github.com/).
