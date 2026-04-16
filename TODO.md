# Symdicate — NeuroGraft Roadmap

Tracked expansion items for the NeuroGraft persona transformer.

---

## [x] 1. Agent Interpretation Cache

**Goal:** Avoid re-analysing an `agent.md` file on every invocation. If the file content has not changed since the last read, load the cached cognitive identity instead of re-extracting it with tokens.

### Sub-tasks

- [x] **1.1 — Define cache key strategy**
      The cache key is the **SHA-256 hex digest** of the full raw content of the source `.agent.md` file, stored in the `sourceHash` field of the cache entry. Content hashing is preferred over modification timestamps, which are unreliable across git checkouts and different execution environments. Schema formalised in `.github/agents/profile.schema.json`.

- [x] **1.2 — Design cache storage location**
      Runtime cache files are written to `.github/agents/.cache/<agentName>.profile.json` (directory is gitignored). A committed reference example at `.github/agents/profile.example.json` shows what a fully populated entry looks like, using NeuroGraft itself as the subject.

- [x] **1.3 — Define cache schema**
      `.github/agents/profile.schema.json` created (JSON Schema draft-07). Defines and validates all required fields: `agentName`, `sourceHash` (pattern-enforced 64-char hex), `cachedAt` (date-time), and the five `cognitiveIdentity` sub-fields. Delivered as part of 1.1.

- [x] **1.4 — Update Agent Reading Protocol in NeuroGraft**
      `NeuroGraft.agent.md` Agent Reading Protocol rewritten as a four-step sequence: (1) check cache and hash-compare, (2) read source file, (3) extract cognitive identity, (4) write cache. Cache hit/miss/stale logic explicit. Schema reference included.

- [x] **1.5 — Add cache fallback behaviour**
      Folded into Step 4 of the updated Agent Reading Protocol: if the cache cannot be written, NeuroGraft continues silently. Cache absence is never treated as a failure.

- [x] **1.6 — Surface cache status in the output header**
      `Cache` line added to the graft summary block with three states: `HIT (profile unchanged)`, `MISS (re-extracted)`, `NONE (no cache written)`. Matching fallback warning added to the Output Format section: `⚠ Cache could not be written — continuing without cache.`

---

## [x] 2. Personality Subfolder

**Goal:** Move the inline persona examples out of `NeuroGraft.agent.md` and into a dedicated `personalities/` subfolder. Each personality becomes a standalone, reusable `.persona.md` file that any agent in the Symdicate framework can reference.

### Sub-tasks

- [x] **2.1 — Create the personalities folder**
      `.github/agents/personalities/` created and populated.

- [x] **2.2 — Define the persona file schema**
      `_TEMPLATE.persona.md` created with YAML frontmatter (`name`, `aliases`) and markdown sections for all five dimensions plus example phrasing.

- [x] **2.3 — Extract and create seed personas**
      All six created: `child.persona.md`, `pirate.persona.md`, `detective.persona.md`, `philosopher.persona.md`, `robot.persona.md`, `poet.persona.md`. Each fully specifies all five dimensions with example phrasing.

- [x] **2.4 — Update NeuroGraft persona resolution**
      _Persona Inference Rules_ rewritten as a two-step protocol: (1) check `personalities/<label>.persona.md` via `codebase` tool, load if found; (2) fall back to inference with `⚠ No persona file found` warning if not.

- [x] **2.5 — Support persona discovery**
      Persona Discovery section added to _Persona Inference Rules_: NeuroGraft lists all `*.persona.md` files (excluding `_TEMPLATE`) when asked, returning each persona's `name` and one-line summary.

- [x] **2.6 — Remove inline persona examples from NeuroGraft.agent.md**
      Inline examples table removed. Replaced with a pointer to `.github/agents/personalities/` and the file-based resolution protocol.

---

## Backlog / Future Ideas

- **Community personas** — a convention for third-party persona packs dropped into `personalities/` that NeuroGraft auto-discovers.
- **Persona blending** — allow two persona labels to be combined (e.g. `pirate + philosopher`) producing a merged cognitive profile.
- **Per-agent default persona** — allow an `agent.md` file to declare a preferred default persona for when NeuroGraft targets it.
- **Cache TTL option** — optional `maxAge` field in the cache entry to force re-extraction after a set period even if the file hash is unchanged.
- **awesome-copilot submission** — submit NeuroGraft as a plugin to [github/awesome-copilot](https://github.com/github/awesome-copilot) for wider distribution once the agent is stable.

---

## [x] 5. Distribution — Installers and Releases

**Goal:** Allow users to install Symdicate agents without cloning the entire repo. Provide platform-appropriate one-liners for Windows, macOS, and Linux, plus a downloadable zip artifact for manual installs.

### Sub-tasks

- [x] **5.1 — Create `install.ps1` (PowerShell — Windows / macOS / Linux)**
  Cross-platform installer supporting:
  - `-Target user` (default) — installs to VS Code user prompts folder (per-platform path detection including Insiders)
  - `-Target repo` — installs to `.github/agents/` in the specified or current repo
  - `-IncludePersonalities` — also installs archetype and guest persona files
  - `-Ref` — pin to a specific branch, tag, or commit
  - `-DryRun` — preview without writing files
  - `-Uninstall` — remove installed files
  Fetches files directly from GitHub raw URLs; hash-compares before overwriting.

- [x] **5.2 — Create `install.sh` (Bash — macOS / Linux)**
  Equivalent bash installer with the same options (`--target`, `--ref`, `--include-personalities`, `--dry-run`, `--uninstall`). Detects VS Code, VS Code Insiders, and Cursor prompts paths. Falls back to a hardcoded persona file list if `jq` is not available.

- [x] **5.3 — Create GitHub Actions release workflow**
  `.github/workflows/release.yml` — triggers on `v*.*.*` tag push. Builds `symdicate-agents.zip` (agents folder, excluding `.cache/`) and attaches it to a GitHub release. Release body auto-includes install one-liners pinned to the release tag.

- [x] **5.4 — Update README with installation section**
  Full installation section added covering: user-level vs repo-level, PowerShell one-liner, bash one-liner, optional personality install, all flags table, and manual zip install paths for all platforms.

---

## [ ] 3. ChimeraGraft — Multi-Agent Cognitive Fusion

**Goal:** Allow NeuroGraft to compose a new cognitive identity from _fields drawn across multiple agents_, rather than using one agent's identity wholesale. The result is an emergent cognitive profile that doesn't exist in any single source agent. A persona can then optionally be applied on top via the existing Mode A–D system.

**Key distinction from running agents in sequence:** Sequential execution produces separate outputs that the user reconciles. ChimeraGraft fuses the cognitive identity _before_ any response is generated — the agent reasons and responds as a single, unified entity whose personality is an engineered composite.

### Design Questions to Resolve Before Implementation

- [ ] **3.Q1 — Field-level selection syntax**
      How does the user specify which field comes from which agent? Options:
  - Explicit map: `reasoningStyle: @ThinkingBeastMode, toolset: @gem-devops, communicationStyle: @gem-documentation-writer`
  - Shorthand: `@ThinkingBeastMode[reasoning] + @gem-devops[tools] + @gem-documentation-writer[style]`
  - Natural language: "think like Beast Mode, use devops tools, write like a tech writer" (NeuroGraft infers the mapping)

- [ ] **3.Q2 — Conflict resolution strategy**
      Cognitive identity fields from different agents can contradict each other (e.g. one agent's `behaviouralRules` demands thorough verification; another's `communicationStyle` demands maximum brevity). Resolution strategies to evaluate:
  - **Priority order** — declare a dominant agent whose fields win on conflict
  - **Explicit override** — user explicitly re-states the conflicting field in the chimera definition
  - **NeuroGraft arbitration** — NeuroGraft detects conflicts, surfaces them to the user, and asks for a ruling before proceeding

- [ ] **3.Q3 — Partial field composition**
      Should it be possible to take _part_ of a field from one agent and _part_ from another? For example: Agent A's `communicationStyle` (brevity) but Agent B's `communicationStyle` (markdown formatting conventions). This is "persona blending" applied to agent fields, not just personas.

- [ ] **3.Q4 — Placement in the mode system**
      ChimeraGraft changes the _source_ of the cognitive identity, not the _depth_ of persona grafting. It is orthogonal to Modes A–D. Options:
  - Treat it as a pre-processing step: resolve the chimera first, then apply a Mode A–D persona graft on top
  - Introduce a formal `Mode E` label to signal that source composition is active alongside voice/cognitive transformation
  - Keep it as a separate input keyword (`Chimera:`) that co-exists with the existing `Mode:` parameter

- [ ] **3.Q5 — Cache interaction**
      Each source agent in a chimera will have its own cache entry (from Item 1). The chimera's composed identity should also be cacheable. The cache key would need to encode the full composition — agent names, fields selected, and hashes of all source files — so any change to any source invalidates the chimera cache.

### Sub-tasks (once design questions are resolved)

- [ ] **3.1 — Define chimera input format** (resolves 3.Q1)
- [ ] **3.2 — Implement conflict detection and resolution logic** (resolves 3.Q2)
- [ ] **3.3 — Extend Agent Reading Protocol** to support reading and merging multiple agents in a single pass
- [ ] **3.4 — Extend cache schema** to support composite cache keys for chimera profiles (resolves 3.Q5)
- [ ] **3.5 — Update graft summary block** to list all source agents and the field-to-agent mapping:
  ```
  ║  Mode         : C                                              ║
  ║  Chimera      : YES                                           ║
  ║  reasoning    : @ThinkingBeastMode                            ║
  ║  toolset      : @gem-devops                                   ║
  ║  style        : @gem-documentation-writer                     ║
  ║  Persona      : detective                                     ║
  ```
- [ ] **3.6 — Add chimera discovery** — NeuroGraft can list the available agents and their cognitive identity fields so the user can make informed composition choices

---

## [x] 4. Personality Taxonomy — Archetypes and Special Guests

**Goal:** Split the flat `personalities/` folder into two subfolders with distinct authoring standards, fidelity expectations, and resolution behaviour.

- `personalities/archetypes/` — generalised, interpretive personas (pirate, robot, detective). No single canonical source. NeuroGraft constructs a composite from the dimensions in the file. "Correct" means internally consistent and recognisable as the _type_.
- `personalities/guests/` — specific fictional or public characters (Jack Sparrow, GLaDOS, Sherlock Holmes). Canonical source material exists. NeuroGraft must match the _character_, not just the archetype. Fidelity bar is higher.

### Sub-tasks

- [x] **4.1 — Move existing persona files into `archetypes/`**
      All six seed files moved to `personalities/archetypes/`. `_TEMPLATE.persona.md` renamed to `_TEMPLATE.archetype.md`.

- [x] **4.2 — Create `guests/` folder and guest template**
      `personalities/guests/_TEMPLATE.guest.md` created with YAML frontmatter fields: `franchise`, `universe`, `canonicalSource`, `contentNote`, plus a Notable Quotes section.

- [x] **4.3 — Create seed guest personas**
      `jack-sparrow.guest.md` (Pirates of the Caribbean) and `glados.guest.md` (Portal) created and fully specified.

- [x] **4.4 — Update NeuroGraft persona resolution**
      Resolution now checks `archetypes/<label>.persona.md` then `guests/<label>.guest.md` before falling back to inference. Guest personas surface `Persona Source` line in the graft summary block.

- [x] **4.5 — Update persona discovery**
      Discovery response now groups results as Archetypes (`.persona.md`) and Special Guests (`.guest.md`), with `franchise` included for guests.

- [x] **4.6 — Add real-person safeguard to NeuroGraft**
      Rule added to _What You Must Never Do_: fabricating opinions, statements, or private facts about real individuals is prohibited even in-character. `contentNote` field on guest files is an absolute constraint that overrides user instruction.
