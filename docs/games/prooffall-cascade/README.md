# Prooffall Cascade (prooffall-cascade)

Index:
- [VISUAL_DESIGN.md](./VISUAL_DESIGN.md)
- [TYPOGRAPHY_DECISION.md](./TYPOGRAPHY_DECISION.md)
- [SOUND_DESIGN.md](./SOUND_DESIGN.md)
- [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md)
- [logs/test.json](./logs/test.json)
- [logs/improvement_report.md](./logs/improvement_report.md)

## 0. Tag Record

- Mechanism (3): `#rule-match`, `#ability-reshape` (was `#weapon-change_field`), `#on_pressed-change_field`
- Visual (2): `#typography-objectification`, `#analog-chromatic-offset`
- Structure (1): `#structure-chain_reaction`
- Seed: `20260306`
- button_types: `3`
- Unexpected pair check: `rule-match + ability-reshape` is not in `data/tags/obvious_pairs.json`

## 0.5 State Model (minimal)

| State Variable | Increase/Decrease Triggers | UI/Feedback Reflection |
| :--- | :--- | :--- |
| `focus_glyph` | Changes to the glyph of the tile the player is currently standing on | Matching tiles brighten, non-matching tiles dull, the player outline borrows the glyph color |
| `field_pressure` | Increases over time | New rows rise faster, jam tolerance shortens, the bottom glow thickens, chromatic offset intensifies |

Notes:
- `focus_glyph` exists because "clear now or relocate first" cannot be expressed by position alone.
- `field_pressure` exists because time progression must be represented as world-side pressure (row rise and jam tolerance), not as hidden timers only.
- No hidden resource is added beyond these; score follows only world events.

## 1. Core Mechanics

The player is a proofreader riding a rising landscape of letter-slabs above a void.

- `Left` / `Right`: move across the top surface, with short coyote time for hopping one-tile gaps.
- `Pulse`: stamp the current `focus_glyph` into the field and start a delayed collapse of the connected same-glyph cluster underfoot.
- When a cluster collapses, unsupported slabs fall. New groups of 3+ matching glyphs auto-collapse, producing chain reactions.
- Score is awarded only when slabs are destroyed by collapse events (`(removed_count - 2)^2`).
- Long hesitation is punished by jam failure: if a column remains filled to the top for too long, game over triggers.
- Difficulty variable convention: `field_pressure` starts at `1` and rises every 10 seconds; row rise interval tightens each pressure step.
- Game over: jam failure when top-clog persists beyond pressure-dependent tolerance.

## 1.5 Tradeoff Definition

- Concrete behavior pair: `surface trim` vs `deep detonation`
- Tradeoff explanation: trimming small surface clusters keeps the skyline manageable but yields small gains; waiting to trigger larger chains scores more, but increases jam risk while consuming setup time.

## 2. Object Specifications

- `Proofreader`: small bright glyph-framed runner; reads the glyph beneath them and inherits that color. Can move only by terrain contact and short air drift.
- `Letter Slab`: rectangular terrain tile carrying one glyph class (`A`, `E`, `O`-like abstract forms). Same-glyph adjacency defines collapse groups.
- `Void`: bottom hazard zone and pressure expression layer (visual threat, not direct fail trigger in current implementation).
- `Pressure Bar`: not a HUD meter; the bottom of the stage glows thicker and rises in sync with pressure.
- `Collapse Echo`: expanding RGB-split rings marking detonations and chain depth.

## 3. Design Guide Analysis

- Simplicity and intuitiveness: one hazard, three buttons, and a single readable rule: "stand on a letter, pulse to erase that letter-family."
- Visual feedback and game over: pulsed clusters flash before removal, falling debris is visible, and jam escalation is shown by tile jitter and top-edge warning glow.
- Skill-based scoring and risk/reward: points come from intentional collapse timing and chain setup under rising pressure while preventing top-clog.
- Novel mechanics: the attack is also terrain surgery; the safest floor is the same structure you must destroy for score.

## 4. Relationship with Tags

- `rule-match`: only matching glyph groups collapse, and falling debris keeps re-evaluating that rule.
- `ability-reshape`: the pulse rewrites traversable terrain, altering the environment structure.
- `on_pressed-change_field`: field change is immediate on button press, not on passive timers.
- `typography-objectification`: letters are literal platforms and hazards, not UI decoration.
- `analog-chromatic-offset`: pulses and pressure use restrained RGB splitting to imply print misregistration.
- `structure-chain_reaction`: the best outcomes come from setting up secondary and tertiary collapses.

## 5. Basis for Novelty

This differs from match puzzle descendants because matching is performed by locomotion and demolition timing, not by swapping tiles from a safe overview. It also differs from platform clearers because the player's current floor determines the active "ammo," so reading terrain and sacrificing it are the same action.

## 6. Phase 7 Improvement Candidates

### A. `Risk-reward shift` + `Spatial historization`

- Expected effect: move scoring emphasis from safe micro-clears to deliberate chain setup and let previous collapse scars shape later routes.
- Risk: overemphasis on setup can increase dead time and reduce responsiveness.
- Complexity cost: low, uses existing gap history plus scoring weighting logic.

### B. `Input semantics inversion` + `World-representation integration`

- Expected effect: let pulse preserve a cluster when airborne but detonate it while grounded, reducing HUD dependence.
- Risk: meaning split may become opaque without stronger telegraphing.
- Complexity cost: medium, adds context-sensitive pulse semantics.

### C. Free proposal

- Expected effect: add drifting "proof dust" slabs that temporarily bridge gaps after a collapse, making escape routes more expressive.
- Risk: can soften the core tension if bridges persist too long.
- Complexity cost: medium, introduces a temporary terrain type.

## 7. Final Report

# Game Generation Report: Prooffall Cascade

## Selected Tags

### Mechanics Tags

- rule-match, ability-reshape, on_pressed-change_field

### Visual Tags

- typography-objectification, analog-chromatic-offset

### Structure Tags

- structure-chain_reaction

## Test Results

| Metric | Initial | After Improvement |
| :--- | :--- | :----- |
| Exploratory Ratio | 1.72x | N/A |

## Improvements

### Mechanics Improvement

1. To be filled after Phase 7 evaluation.
2. Recommended adoption is `Risk-reward shift + Spatial historization`: reduce value of safe surface mashing and increase value of chain-planning decisions.

### Visual Improvement

1. Implemented in Phase 8: added a title screen aligned with visual concept and changed flow to start with `Press Space to Begin Proof`.
2. Added three glyph-color badges (`A/E/O`) on the title card to prime glyph-family reading before play.

### Sound Improvement

1. Implemented in Phase 8: changed `pulse` center frequency per glyph (`A/E/O`) so terrain-context differences are audible under same input.
2. Added overtone layers by score band (chain-depth approximation) to strengthen sonic reward for successful chains.
3. Added dedicated two-tone `pressure_step` chime, critical intermittent tone starting at `jam_ratio >= 0.02`, and recovery release sound for audible danger foreshadow/release.
4. From human feedback ("sound starts too late"), moved warning threshold earlier and expanded warning band to upper-mid frequencies for better audibility.

## 8. Human Feedback Iteration (2026-03-07)

- Request: implement further concept-aligned SFX additions end-to-end.
- Implementation:
  - `field_controller.gd`: added `glyph` and `cluster_size` to `pulse_event`.
  - `main.gd`: added `pressure_step` wiring, per-frame max-jam tracking, and event-specific audio parameter branches.
  - `fx_audio.gd`: added glyph-specific pulse, chain-depth score, pressure step, jam critical/release.
  - `SOUND_DESIGN.md`: synchronized to the above spec.
- Additional request: add a title screen aligned with visual concept.
- Additional implementation:
  - `hud_layer.gd`: added `PROOFFALL CASCADE` title overlay, subcopy, glyph badges, and start prompt.
  - `main.gd`: added start-wait state on first boot; pressing `pulse` closes title and starts play; auto-skip in test mode.
- Verification:
  - Ran headless tests (`logs/test.log`, `logs/test.json` updated).
  - Ran Web export (`logs/web_export.log`, `build/web/index.html` updated).
