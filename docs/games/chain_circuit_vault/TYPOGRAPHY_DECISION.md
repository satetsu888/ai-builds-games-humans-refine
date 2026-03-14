# Typography Decision

## Phase

Phase 8 font adoption completed.

## Selected Fonts

- `Noto Sans Mono Bold`
  - Use: numeric HUD score, score popups
  - Why: stable-width numerals, compact counters, square-ish terminals that fit the circuit / glyph aesthetic
- `Noto Sans Mono Regular`
  - Use: base UI role fallback for future info labels
  - Why: same family as numeric role, keeps single-family consistency in a minimal UI

## Candidate Comparison

- `Noto Sans Mono`
  - Strengths: OFL-1.1, explicit mono numerals, clear at small Web sizes, visually compatible with runic/circuit abstraction
  - Weaknesses: less distinctive than a custom display face
- `Ubuntu Sans Mono`
  - Strengths: warmer personality, readable
  - Weaknesses: more humanist and softer than the rest of the game's hard-edged symbols; license handling is less straightforward than OFL in this environment

## Roles

- Heading: `Noto Sans Mono Bold`, reserved for future event headings if needed
- Info: `Noto Sans Mono Regular`
- Numeric: `Noto Sans Mono Bold`, size 30, top-center score and floating score popups
- Emphasis: same family, conveyed mainly by color/position/outline, not by a separate decorative face

## Theme Tokens

- `font_ui_base`: `Noto Sans Mono Regular`
- `font_ui_numeric`: `Noto Sans Mono Bold`
- `size_lg`: 30
- `text_primary`: `#d9f3ff`
- `outline_size`: 2
- `outline_color`: `#102032`

## Readability Rules

- Score stays as digits only, centered at the top edge to minimize vertical waste in the 540x540 frame.
- Outline size 2 with dark outline color preserves legibility against the animated board.
- Numeric popups use the same bold mono font so score causality stays visually linked.
- HUD text remains informational only; gameplay causality stays in-world.

## License

- Font family: Noto Sans Mono
- Source: system package `fonts-noto-mono`
- License: SIL Open Font License 1.1
- Bundled files:
  - `assets/fonts/NotoSansMono-Regular.ttf`
  - `assets/fonts/NotoSansMono-Bold.ttf`
  - `licenses/fonts/OFL-NotoSansMono.txt`
