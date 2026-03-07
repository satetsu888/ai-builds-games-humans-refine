# Visual Design: Polarity Lasso Chain

## 1. Concept

"Quiet void with analog-warped tactical traces."

- Large negative space keeps attention on loop closure moments.
- Organic line warping avoids sterile geometry and supports chain tension.

## 2. Palette (5 colors)

- Background void: `#141A24`
- Player / hero: `#C8E8FA`
- Threat / spark: `#F96E58`
- Reward / loop: `#57D7C5`
- Neutral trail / UI: `#8B97AA`

## 3. Drawing Spec

- Background: sparse horizontal warped lines with low alpha.
- Player: bright cyan disk + thin ring for motion emphasis.
- Beacon: small warm markers; loop is translucent fill + bright outline.
- Spark: dense warm-red circles with minimal bloom substitute (alpha stack).

## 4. Feedback Design

- Score: loop fill pulse and chain disappearance wave.
- Damage/game over: warm desaturation + fatal tone.
- Near miss: subtle right-top indicator + danger tone pulse.
- State change (reverse): immediate direction swap and beacon velocity inversion.

## 5. Mechanics Integration

- Loop closure readability is prioritized over decorative clutter.
- Negative space allows instant trajectory prediction.
- Heat causes stronger line warping to externalize escalating risk.

## 6. Checklist

- [x] Roles recognizable in under 2 seconds.
- [x] Score/damage/near-miss have non-text visual response.
- [x] Style coherence across background/object/HUD.
- [x] Subtle motion exists even when input is idle.

## 7. AI-Generated Look Suppression Rules

### 7.1 Visual Hierarchy Rules

- Protagonist: cyan orbiting disk with highest luminance.
- Threat: warm-red spark dots with denser motion.
- Reward: teal loop polygon flash.
- 2-second recognition check: player/threat/reward are separable by color + motion + shape.

### 7.2 Limits on Familiar Template Symbols

- Adopted familiar elements (max 2): circle player, line trajectory hints.
- Replaced unique element: standard bullet shooter trails replaced by reversible beacon-lasso geometry.

### 7.3 UI-Independent Feedback

| Event | Non-UI visual response | Intensity (Low/Med/High) |
| :---- | :--------------------- | :----------------------- |
| Score | Loop polygon pulse + spark chain wipe | High |
| Damage | Immediate player overlap with spark + scene tension drop | High |
| Near miss | Local spark-player proximity burst + mild warp increase | Med |

### 7.4 Composition and Gaze Guidance

- Initial focal point: orbit ring around center-left zone.
- Visual flow: edge spawns -> orbit path -> enclosed loop center.
- Anti-center-clutter implementation: loop setup is distributed across orbit arc with sparse background and limited simultaneous beacons.

## 8. Phase 8 Visual Refinement (Human Feedback)

- Active spark danger readability:
  - Active sparks use a dual-layer silhouette (halo + core) plus velocity tail.
  - Inactive sparks stay smaller and desaturated with no tail.
  - Threat recognition no longer depends on color only.
- Beacon vs spark separation:
  - Beacon shape changed to hollow diamond marker language instead of circle language.
  - Beacon center and short neutral trail imply "tool/anchor" identity, distinct from hazard motion.
- Fun and reward response:
  - Loop closure now emits a local radial burst around the closure centroid.
  - Loop edge thickness/alpha subtly evolve with life to keep feedback alive without clutter.
