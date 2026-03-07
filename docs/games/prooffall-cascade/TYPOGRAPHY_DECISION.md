# Typography Decision: Prooffall Cascade

Phase 8 typography implementation is completed.

## 1. Candidate Comparison

Visual target: misregistered letterpress mood + stable HUD readability.

- Candidate A: `Special Elite` only
  - Pros: strongest typewriter/letterpress personality.
  - Cons: low legibility for compact HUD text and dense numbers.
- Candidate B: `IBM Plex Sans` + `IBM Plex Mono`
  - Pros: high readability and stable numeric width.
  - Cons: weaker identity for headline moments.
- Candidate C (adopted): `Special Elite` + `IBM Plex Sans` + `IBM Plex Mono`
  - Pros: keeps letterpress identity in headline states while preserving gameplay readability.
  - Cons: three-family setup (kept within guide limit).

## 2. Adopted Role Mapping

- Heading role (`DisplayLabel`): `SpecialElite-Regular.ttf`, size `38`
  - Used for `GAME OVER` style messaging.
- Information role (`InfoLabel`): `IBMPlexSans-Variable.ttf`, size `14`
  - Used for bottom-row controls guidance text.
- Numeric role (`ScoreLabel`): `IBMPlexMono-SemiBold.ttf`, size `22`
  - Used for top HUD numeric labels (`Score`, `Pressure`).
- Emphasis role: world-space transient score popups remain draw-based and keep numeric readability.

## 3. Theme Implementation Notes

- Typography is now centralized in `hud_layer.gd` through a single `Theme` object.
- Outline tokens are applied only where contrast is required (`DisplayLabel`, `ScoreLabel`).
- Constant animation text effects are avoided; emphasis remains event-driven.

## 4. License Record

- Font files are bundled under `assets/fonts/`.
- License originals are stored under `licenses/`.
- License summary is recorded in `THIRD_PARTY_LICENSES.md`.
