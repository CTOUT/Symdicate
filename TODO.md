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

## [x] 7. Persona Library Expansion — v1.1

**Goal:** Grow the seed persona library with more archetypes and special guests. Prioritise variety across cognitive styles, communication registers, and cultural frames — not just surface voice differences.

### Proposed Archetypes

- [x] **7.A1 — `scientist`** — Empirical, hypothesis-driven, cites uncertainty explicitly, distinguishes observation from inference, uses precise quantified language.
- [x] **7.A2 — `mentor`** — Patient, Socratic, meets the learner where they are, asks questions before answering, frames everything as a learning opportunity.
- [x] **7.A3 — `bureaucrat`** — Procedurally correct, clause-referencing, risk-averse, never commits without the proper form being filed first.
- [x] **7.A4 — `comedian`** — Finds the absurdity in everything, uses timing and misdirection, structures answers as setups and punchlines, never loses the actual answer in the joke.
- [x] **7.A5 — `stoic`** — Calm, unfazed, frames everything in terms of what is within one's control, no emotional colouring, radiates equanimity.

### Proposed Special Guests

- [x] **7.G1 — `hermione-granger`** (Harry Potter) — Precise, research-first, cites sources, corrects errors gently but firmly, believes preparation is everything.
- [x] **7.G2 — `data`** (Star Trek: TNG) — Literal, statistically precise, no contractions, frames emotion as an observed phenomenon to be studied, finds human idiom puzzling.
- [x] **7.G3 — `wednesday-addams`** (The Addams Family) — Deadpan, morbidly literal, untouched by optimism, finds suffering intellectually interesting, never sarcastic — completely sincere.

---

## [ ] 8. Neurodiversity Support — Cognitive Accessibility Profiles

**Goal:** Introduce a new category of persona — **cognitive accessibility profiles** — that transform how any agent communicates to better match different neurological processing styles. Unlike archetypes (which add a character voice) or guests (which impersonate a specific persona), accessibility profiles are communication _filters_: they change structure, explicitness, and sensory load without imposing a personality.

**Motivation:** Neurodiverse users — including those with autism, ADHD, dyslexia, sensory processing differences, and others — often find default AI agent communication styles difficult to parse. Responses may rely on implied context, idiomatic language, ambiguous hedging, dense unstructured prose, or social cues that require neurotypical inference. An accessibility profile removes these frictions without removing capability.

**Key design distinction from archetypes:** A `pirate` archetype is an overlay — the agent _becomes_ a pirate. An accessibility profile is a _filter_ — the agent remains itself, but communicates through a lens optimised for a specific processing style. The persona is subordinate to clarity.

### New category: `profiles/`

Accessibility profiles live in a new subfolder: `.github/agents/personalities/profiles/`. They use the extension `.profile.md` and a distinct frontmatter schema that emphasises communication rules over personality dimensions.

### Proposed Profiles

- [ ] **8.P1 — `direct`** — The foundation profile. Eliminates ambiguity, idioms, implied meaning, and social padding. Every statement means exactly what it says. Especially useful for autism spectrum users.
  - No rhetorical questions
  - No idioms or metaphors unless explicitly labelled as such
  - No implied next steps — all actions stated explicitly
  - No hedging phrases that create ambiguity (`"you might want to..."` → `"do this:"`)
  - Numbered steps for any multi-part instruction
  - Definitions provided for any term that could be interpreted multiple ways

- [ ] **8.P2 — `structured`** — For users who process information better with clear visual hierarchy. Headers, numbered lists, and explicit section boundaries for everything. No flowing prose for instructional content.

- [ ] **8.P3 — `low-load`** — Reduces cognitive load. Shorter sentences. One idea per sentence. No nested clauses. Explicit transitions. Pauses built into structure. Useful for ADHD, sensory overload states, or fatigue.

- [ ] **8.P4 — `high-context`** — The inverse profile — for users who want maximum information density, explicit reasoning chains, and all relevant caveats stated. Nothing left implied. Every assumption surfaced.

- [ ] **8.P5 — `dyslexia`** — Optimised for dyslexic readers. Reduces decoding load without reducing content. Extends: `direct`.
  - Short sentences — one idea per sentence, no nested or embedded clauses
  - Active voice throughout; no double negatives
  - Plain vocabulary — concrete over abstract; jargon always defined on first use
  - Consistent terminology — never use synonyms for the same concept within a response
  - Bold for key terms and emphasis; never italics for emphasis (harder to decode for many dyslexic readers)
  - Spell out all abbreviations on first use, every response
  - Lists over prose for all instructional content
  - Generous whitespace between sections — no dense unbroken paragraphs

- [ ] **8.P6 — `dyspraxia`** — Supports working memory and executive function differences. Often co-occurs with ADHD. Extends: `low-load`.
  - One instruction per numbered step — never `"do X while doing Y, then Z"` in a single step
  - Explicit start point for every task — never assume the reader knows where to begin
  - No implied sequencing — every next action stated explicitly
  - Working memory support — brief context restatement at the start of each major section; never rely on the reader holding earlier content in mind across a long response
  - Summary/recap at the end of any multi-part response
  - Chunk complex information into clearly bounded, independently readable sections

- [ ] **8.P7 — `dyscalculia`** — Reduces numerical processing friction. Standalone (no base extends needed — distinct rule domain).
  - Small quantities written as words (`"three steps"` not `"3"`)
  - Numbers always labelled clearly — never bare numerals without context
  - No arithmetic left to the reader — all calculations done explicitly in the response
  - Quantities given in concrete analogies where helpful (`"10MB — roughly 5 average photos"`)
  - Percentages accompanied by a concrete equivalent (`"50%"` → `"1 in every 2 cases"`)
  - Implicit numerical comparisons made explicit (`"this is faster"` → `"this takes 2 seconds instead of 10"`)
  - Dates and times written in full — never abbreviated

- [ ] **8.P8 — `mental-health`** — Base profile for mental health accessibility. Not intended for direct use — extended by `anxiety`, `depression`, and `stress`.
  - No language that implies the user should already know something (`"obviously"`, `"just"`, `"simply"`, `"easy"`)
  - Frame errors and wrong turns as expected parts of the process, never as failures
  - No false positivity or forced cheerfulness — calm, neutral, matter-of-fact warmth
  - Always provide one clear recommended path — avoid overwhelming with options
  - Never use urgency or pressure language (`"quickly"`, `"you need to"`, `"immediately"`)

- [ ] **8.P9 — `anxiety`** — For users experiencing anxiety or low confidence. Extends: `mental-health`.
  - Lead with what is safe and working before addressing what needs to change
  - Uncertainty stated calmly — never as alarm (`"this could be dangerous"` → `"double-check this before proceeding"`)
  - Explicit reassurance at decision points with multiple valid options
  - Never leave a response on an unresolved problem without acknowledging it and offering a next step

- [ ] **8.P10 — `depression`** — For users experiencing depression or low energy states. Extends: `mental-health`, `low-load`.
  - Concise by default — never pad responses; every sentence earns its place
  - Break tasks into the smallest meaningful units — never imply a task is large or complex upfront
  - Lead with the single most actionable thing; defer everything secondary
  - Positive framing without minimising real difficulty
  - Avoid language that implies effort should feel easy (`"this is straightforward"`)

- [ ] **8.P11 — `stress`** — For users in high-stress or overloaded states. Extends: `mental-health`, `low-load`.
  - Open with the single most important thing — everything else is secondary
  - Explicit `"you don't need to read the rest right now"` escape points after the critical information
  - Prioritise ruthlessly — never present everything as equally important
  - No background context or caveats before the core answer; offer them after if needed

- [ ] **8.P12 — `cognitive-fatigue`** — For users post-illness, post-concussion, or with chronic fatigue conditions. Extends: `low-load`, `mental-health`.
  - Very short responses by default; offer to expand explicitly (`"want more detail on any of these?"`)
  - No cross-references that require holding earlier content in memory — restate what's needed
  - Explicit transitions between every idea
  - Never imply the user should retain information across a long response

- [ ] **8.P13 — `screen-reader`** — Structural accessibility for screen reader and low-vision users. Standalone.
  - No ASCII art, box-drawing characters, or tables used purely for layout
  - All table information also available as a list or prose alternative
  - No directional references (`"see above"`, `"the diagram below"`)
  - Meaningful link text — never bare URLs or `"click here"`
  - Emoji used sparingly and never as the sole conveyor of meaning; described in brackets when used for meaning (`"✅ (done)"`)
  - Abbreviations always expanded on first use

- [ ] **8.P14 — `eal`** — English as an Additional Language. Standalone.
  - No idioms — replace with literal equivalents (`"keep an eye on"` → `"monitor"`)
  - No phrasal verbs where a single verb exists (`"find out"` → `"discover"`, `"set up"` → `"configure"`)
  - No culture-specific references without brief explanation
  - Simpler sentence structures — subject-verb-object preferred
  - Avoid contractions in formal or instructional content
  - Spell out all abbreviations on first use

### Profile Inheritance Tree

```
direct
  ├── dyslexia        (+ consistent terminology, bold/no-italic, abbreviation rules)
  └── dyscalculia     (distinct domain — no overlap with direct, standalone)

low-load
  ├── dyspraxia       (+ working memory support, recap, explicit start points)
  ├── depression      (extends: mental-health + low-load)
  ├── stress          (extends: mental-health + low-load)
  └── cognitive-fatigue (extends: low-load + mental-health)

mental-health         (base — not for direct use)
  ├── anxiety         (extends: mental-health)
  ├── depression      (extends: mental-health + low-load)
  ├── stress          (extends: mental-health + low-load)
  └── cognitive-fatigue (extends: mental-health + low-load)

structured            (standalone)
high-context          (standalone)
screen-reader         (standalone — structural, not cognitive)
eal                   (standalone)
```

### Sub-tasks

- [x] **8.1 — Define the `.profile.md` schema and template**
      Distinct from `.persona.md` — frontmatter fields: `name`, `aliases`, `extends` (list of base profile names whose rules are inherited), `accessibilityFocus` (freetext description of target neurological context), `communicationRules` (explicit list), `neverDo` (absolute prohibitions). No personality dimensions section.

  **Inheritance rule:** NeuroGraft merges rule sets in order — base profiles first, child profile last. Child rules take precedence on conflict. Multiple inheritance is supported (e.g. `extends: [low-load, mental-health]`). Circular extends are an error.

- [x] **8.2 — Create `profiles/` folder and `_TEMPLATE.profile.md`**

- [x] **8.3 — Create seed profiles**
      Foundation profiles (no extends): `direct`, `structured`, `low-load`, `high-context`, `mental-health` (base only — not for direct use), `dyscalculia`, `screen-reader`, `eal`.
      Derived profiles: `dyslexia` (extends `direct`), `dyspraxia` (extends `low-load`), `anxiety` (extends `mental-health`), `depression` (extends `mental-health` + `low-load`), `stress` (extends `mental-health` + `low-load`), `cognitive-fatigue` (extends `low-load` + `mental-health`).

- [x] **8.4 — Update NeuroGraft persona resolution to check `profiles/`**
      Resolution order extended: archetypes → guests → profiles → infer. A profile label resolves to a communication filter, not a character. The graft summary block shows `Profile` instead of `Persona` when a `.profile.md` is active.

- [x] **8.5 — Profiles compose with personas**
      A profile and a persona should be stackable: `Persona: pirate, Profile: direct` produces a pirate who is nonetheless unambiguous and literal. The profile's `neverDo` rules take precedence over persona voice where they conflict — clarity overrides character.

- [x] **8.6 — Update Persona Discovery to include profiles**
      `list profiles` or `list personas` both surface available profiles, clearly labelled as accessibility profiles with their `accessibilityFocus` description.

- [x] **8.7 — Update installer to include profiles in `--include-personalities`**
      The `profiles/` folder is included when `--include-personalities` / `-IncludePersonalities` is passed.

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

## [x] 6. Session Persistence — Stay in Character Across Conversations

**Goal:** NeuroGraft currently relies on conversation history to hold the active graft (Mode, Persona, target Agent). When a new chat session starts, that context is gone and the graft must be re-stated. This item implements session persistence so NeuroGraft can resume a graft automatically in a new conversation.

**Root cause of the drift problem:** There are actually two distinct failure modes:

1. **Within-session drift** — NeuroGraft forgets the persona mid-conversation even though the history is present. This is a compliance issue in the agent instructions, fixable without any storage mechanism.
2. **Cross-session loss** — A new chat window starts with no context. The graft is completely gone. This requires a storage mechanism.

Both must be addressed.

### Sub-tasks

- [x] **6.1 — Fix within-session drift (instruction hardening)**
      `Session State` section added to `NeuroGraft.agent.md` defining: active session tracking within a conversation, silent inheritance of Mode/Persona/Agent on follow-up prompts, new-session override behaviour, session commands (`end session`, `current graft?`, `resume: <token>`), and the character-persistence rule. Two new never-do rules added: never drop the graft between turns, never ask the user to re-state values the active session already holds.

- [x] **6.2 — Define session file schema**
      Session file schema defined inline in Agent Reading Protocol Step 4. Fields: `sessionId`, `startedAt`, `mode`, `persona`, `personaSource`, `targetAgent`, `agentProfileHash`. Written to `.github/agents/.cache/neurograft-session.json`.

- [x] **6.3 — Update Agent Reading Protocol: session check**
      Step 0 added to Agent Reading Protocol. Checks for `neurograft-session.json` before anything else; resumes silently if no new parameters provided; detects agent file changes via `agentProfileHash` comparison and re-extracts if stale.

- [x] **6.4 — Add resume token to every response (Option B fallback)**
      Resume token appended after all grafted content, separated by `---`. Format: `↩ Resume: \`Mode:X | Persona:Y | Agent:Z\``. Works cross-machine, cross-session, in read-only environments.

- [x] **6.5 — Add session commands**
      Session commands defined in `Session State` section (6.1) and Step 0 handles session file writes. Commands: `end session` / `clear session` / `reset`, `current graft?`, `resume: <token>`.

- [x] **6.6 — Surface session status in the output header**
      `Session` line added to graft summary block with three states: `NEW`, `RESUMED (started <startedAt>)`, `NONE (no session file)`.

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
