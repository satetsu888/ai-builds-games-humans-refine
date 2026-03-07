# Warp Chase Holdline (warp-chase-holdline)

**Mechanics Tags**: #rule-physics, #obstacle-chase, #on_holding-move  
**Visual Tags**: #geometry-primitive-modularity, #analog-line-noise-warp

## 1. Core Mechanics

The player controls an inertia-driven drone. It accelerates forward only while `thrust` is held, then glides on inertia after release. Chaser drones always pursue the player but turn slowly, so they drift outward due to inertia.

- Game over: player collides with an enemy
- Score:
  - Enemy-enemy collision: high score
  - Near miss (avoid collision within a close distance): bonus score
- Multiplier system:
  - `MULTI +1` for each enemy-enemy collision (up to x12)
  - Enemy collision resets decay timer
  - Higher multiplier decays faster (lower multiplier has longer grace)
  - Near miss extends decay timer
  - Decay pauses while enemies remain in danger distance (only while moving)
- Difficulty ramp:
  - Enemy speed and concurrent spawn count rise over time
  - Enemy composition changes by wave transitions
- Spatial rule:
  - Player and enemies wrap at screen edges (torus space)
- Defense system:
  - Player has a one-hit shield
  - On enemy contact, shield cancels game over and is consumed
  - Shield recovers after ~15 seconds

## 2. Control Design

Inputs are three:

- `move_left` (A / Left): rotate heading counterclockwise
- `move_right` (D / Right): rotate heading clockwise
- `thrust` (Space / Z): generate thrust only while pressed

Intent:
- Controlling hold duration matters more than button mashing
- Designing evasive lines with inertial glide is a skill axis

## 3. Object Specifications

- Player (circle + triangle)
  - Rigidbody-like velocity accumulation (lightweight physics)
  - Angular velocity and linear damping
- Chaser (square)
  - Accelerates toward player direction
  - Slow turning, drifts outward by inertia
- Enemy variants
  - `hunter`: standard chaser (baseline threat)
  - `drifter`: pierces toward escape lines blocked by orbiter
  - `orbiter`: cuts off lanes by pre-positioning ahead of player motion
  - `lancer`: periodic high-speed charge breaker
- Wave generator (threat budget)
  - Auto-generates per-wave enemy composition from danger budget instead of fixed table
  - Generation constraints:
    - Single-type bias capped at 56%
    - Total danger budget has a hard cap (fixed unfairness ceiling)
    - Enemy types unlock by progression (`hunter->drifter->orbiter->lancer`)
- Arena border (line)
  - Visual guide only (no physical collision)
- Pulse ring (effect)
  - Ring effect for near miss and collisions

## 4. Design Guide Analysis

- Simplicity: single purpose (survival) + explicit collision failure
- Visual feedback: near-miss ring, collision flash, acceleration trail
- Skill scoring: routing, near misses, and inertia control produce high scores
- Novel mechanics: "move only while held" + "push your own inertial trap onto chasers"

## 5. Relation to Tags

- `rule-physics`: inertia, damping, and turn-lag of pursuit bodies
- `obstacle-chase`: always-on pursuing enemy AI
- `on_holding-move`: accelerate only while thrust is held; glide after release

## 6. Novelty Basis

The player does not directly attack enemies. Instead, they chain enemy-enemy collisions by managing their own thrust, then sustain multiplier before decay for higher score. Inputs are few, but mastery of inertial prediction creates a clear skill gap.

## 7. Similarity Check

It is adjacent to Asteroids-like inertia and chase-enemy elements, but differentiated by torus-space mixed-enemy wave management and guidance-specialized design with no attack button.

## 8. Web Footprint Notes

- Use `exclude_filter` in `export_presets.cfg` to exclude development files (`logs/`, `tools/tests/`, design docs, etc.) from Web output
- After export, run `scripts/precompress_web.sh` to produce `*.gz` for `index.wasm/js/pck`
- Enable `Content-Encoding: gzip` on the delivery server and serve `*.gz`
