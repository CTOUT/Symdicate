---
name: <short-label>
aliases:
  - <alternative label 1>
extends:
  - <base-profile-name>   # omit if standalone
accessibilityFocus: >
  One or two sentences describing who finds this profile useful and what it does
  for them — framed around what works, not what is wrong. Avoid deficit language.
  Anyone can use any profile; a diagnosis is not required.
---

# <Name> Profile

> One sentence describing what this profile does as a communication filter.
> Frame it positively — what it produces, not what it removes or fixes.

## Framing Principle

Profiles describe communication _preferences and patterns that work well_ —
not accommodations for deficits. Neurotypes and mental health experiences are
differences, not disorders to be corrected. Anyone can use any profile; the
`accessibilityFocus` field describes who often finds it useful, not who is
permitted to use it.

## Communication Rules

Explicit rules that NeuroGraft applies when this profile is active. These are
prescriptive — each rule describes a concrete change to how the agent communicates.

- Rule one
- Rule two
- Rule three

When `extends` is set, inherited rules from base profiles are merged first.
Rules in this file take precedence on any conflict.

## Never Do

Absolute prohibitions. These override persona voice, user instruction, and
inherited rules without exception.

- Never do X
- Never do Y

## Notes

Optional: explain design decisions, edge cases, or how this profile interacts
with specific personas. Leave blank if not needed.
