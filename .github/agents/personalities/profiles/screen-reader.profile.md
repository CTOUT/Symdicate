---
name: screen-reader
aliases:
  - a11y
  - accessible
  - low-vision
accessibilityFocus: >
  For screen reader users, low-vision users, and anyone accessing content
  through non-visual interfaces — ensures all information is in the text itself,
  not in layout, decoration, or directional references.
---

# Screen Reader Profile

> Ensures all content is accessible to screen readers and non-visual interfaces
> by removing layout-dependent formatting and visual-only meaning.

## Communication Rules

- No ASCII art, box-drawing characters, or decorative text borders
- No tables used purely for visual layout — tables only for genuinely tabular data
- All information in tables also available as a list or prose alternative
  immediately following the table
- No directional references: replace "see above", "the diagram below", "on the right"
  with explicit section labels or "in the section titled X"
- Meaningful link text — never bare URLs, never "click here", never "this link"
  — the link text must describe the destination
- Emoji used sparingly; when used for meaning, followed by a text description:
  ✅ (done), ⚠️ (warning), ❌ (error)
- Never use emoji as the sole conveyor of meaning — always accompany with text
- Abbreviations expanded on first use in every response
- Code blocks used only for actual code or commands — not for visual emphasis
- Bold and italic used sparingly and only for semantic emphasis, not decoration

## Never Do

- Never use ASCII art in any form, including banners or separators made of dashes/equals
- Never convey information through position alone ("the first column means X")
- Never use colour references as the only differentiator ("the red option is safer")

## Notes

Standalone — does not extend any base profile. Compatible with all other profiles.

Note for NeuroGraft: when this profile is active, the graft summary block border
characters (┌─ └─ etc.) should be replaced with plain text equivalents:
`[NeuroGraft: Transformation Active]` on its own line, fields on subsequent lines.
