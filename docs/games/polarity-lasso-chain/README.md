# Polarity Lasso Chain (polarity-lasso-chain)

## Links

- [VISUAL_DESIGN.md](./VISUAL_DESIGN.md)
- [TYPOGRAPHY_DECISION.md](./TYPOGRAPHY_DECISION.md)
- [SOUND_DESIGN.md](./SOUND_DESIGN.md)
- [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md)
- [logs/test.json](./logs/test.json)
- [logs/improvement_report.md](./logs/improvement_report.md)

## 0. Tag Record

- Mechanism (3): `on_pressed-reverse_state`, `rule-surround`, `on_pressed-shoot`
- Visual (2): `analog-line-noise-warp`, `composition-negative-space`
- Structure (1): `structure-chain_reaction`
- `button_types: 2`
- Seed: `20260305`
- Unexpected pair check: selected by `--require-unexpected-pair` (non-obvious pair >= 1 satisfied)

## 0.5 State Model (minimal)

| State Variable | Increase/Decrease Triggers | UI/Feedback Reflection |
| :--- | :--- | :--- |
| `heat` | Shot/reverse increases, capture success and time decrease | Background line warp grows, ambient danger hum grows, spark speed rises |
| `combo` | Loop capture success increases, miss/timeout decreases | Capture flash pitch/point burst rises, HUD combo value rises |
| `polarity` | Reverse input toggles | Orbit direction flips, beacon drift vector inverts instantly |

Notes:
- `heat` was added to create a new decision: build larger loops with more shots vs. avoid world acceleration risk.
- Each state has in-world feedback, not HUD-only.

## 1. Core Mechanics

- Player auto-orbits the center.
- One-button rule (`Space` / left click / screen tap): shoot a beacon and reverse orbit polarity in the same beat (beacon drift also inverts).
- If beacon chain returns near the first beacon, it closes a loop (`rule-surround`).
- Sparks entering loop area are captured; nearby sparks chain-detonate (`structure-chain_reaction`).
- Score comes only from captured sparks with risk/combo multipliers.
- Game over is only when a spark collides with player body.
- Difficulty variable follows guide convention: starts at `1`, rises with elapsed minute base.

## 1.5 Tradeoff Definition

- Concrete behavior pair: `rapid safe micro loops` vs `delayed high-density risky loop closure`
- Tradeoff explanation: waiting and shaping a larger loop near incoming sparks yields high chain score but raises collision risk due to accumulated sparks and heat-driven speed.

## 2. Object Specifications

- Player: cyan orbiting disk, fixed orbit radius, collision radius 13.
- Beacon: warm marker shot from player; drifts and becomes loop vertex.
- Spark hazard: red moving orb spawned from screen edge toward center with tangential drift.
- Loop zone: translucent polygon made from beacon chain; temporary capture region.
- Chain reaction: captured sparks remove nearby sparks in radius.

## 3. Design Guide Analysis

- Simplicity: one-button input, one loss condition, shape-based entities.
- Visual feedback: polarity flips, loop polygon flash, spark removal chains, near-miss pulse counts.
- Skill/risk scoring: no input/spam underperform; precise timing and positioning of loop closure drives score.
- Novel mechanic: reverse-state not only affects player direction but retroactively rewires beacon field for surround timing.

## 4. Relationship with Tags

- `on_pressed-shoot` -> beacon placement.
- `on_pressed-reverse_state` -> orbit and beacon vector inversion.
- `rule-surround` -> loop closure detection and enclosed capture.
- `structure-chain_reaction` -> enclosed spark triggers nearby cascade.
- `analog-line-noise-warp` -> noisy, breathing background lines.
- `composition-negative-space` -> sparse center and wide empty margins emphasizing event islands.

## 5. Basis for Novelty

Loop construction is not static drawing; orbit reversal changes future and past beacon geometry at once, enabling "retroactive lasso" chain timing that differs from fixed trap or pure shooter patterns.

## 6. Design Checklist

- [x] Input scheme is within selected `button_types` (2).
- [x] Single obvious game over condition (spark collision).
- [x] Idle/spam is not intended optimal strategy.
- [x] Four design principles addressed.
- [x] State variables justified with distinct decisions.
- [x] Each state has non-text in-world feedback.
- [x] Safe vs risky tradeoff is explicit.
- [x] Player action leaves persistent world history (beacon chain / loop zones).

## 7. Phase 7 Improvement Candidates

### A (operator-applied)

- Operator set: `Risk-reward shift + Spatial historization`
- Idea: remove low-value captures and award only for captures when player is within near-miss band; keep temporary ionized-trail zones that modify future spark path.
- Expected effect: exploratory timing becomes more valuable.
- Risk: may over-penalize beginners.
- Complexity cost: state `ionized trail` adds 1 state, 2 exceptional rules.

### B (different operator combination from A)

- Operator set: `Input semantics inversion + World-representation integration`
- Idea: when heat exceeds threshold, `action_b` becomes short brake instead of reverse; heat is represented by visible orbit ring jitter only (no numeric dependency).
- Expected effect: same input gains context-dependent meaning.
- Risk: learnability cost on threshold transition.
- Complexity cost: no new state; 1 phase-switch rule.

### C (free proposal)

- Idea: introduce moving "void window" where loops cannot close, forcing spatial route planning.
- Expected effect: improves composition usage and anti-center clustering.
- Risk: can feel unfair without telegraph.
- Complexity cost: 1 moving field object, 1 exclusion rule.

Adoption candidate: Option A (largest exploratory-ratio upside without breaking the current core).
Reason not adopted (current): B increases comprehension cost; C increases unfair-death risk.

## Game Generation Report: Polarity Lasso Chain

## Selected Tags

### Mechanics Tags

- on_pressed-reverse_state, rule-surround, on_pressed-shoot

### Visual Tags

- analog-line-noise-warp, composition-negative-space

### Structure Tags

- structure-chain_reaction

## Test Results

| Metric | Initial | After Improvement |
| :--- | :--- | :--- |
| Exploratory Ratio | 9.90x | N/A |

## Improvements

### Mechanics Improvement

1. Phase 7 included evaluation report only (no implementation changes).

### Visual Improvement

1. Phase 7 included evaluation report only (no implementation changes).

### Sound Improvement

1. Phase 7 included evaluation report only (no implementation changes).
