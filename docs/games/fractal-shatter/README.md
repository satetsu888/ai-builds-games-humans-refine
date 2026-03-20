# Fractal Shatter (fractal-shatter)

## 0. Tag Record

- Mechanism (6):
  - player: #player-circle
  - action: #on_released-throw, #on_pressed-jump
  - ability: #ability-instant_line
  - context: #obstacle-split, #field-multiple
- Visual (1): #background-fractal-motif
- Structure (1): #structure-phase_shift
- button_types: 3

## 0.5 State Model (minimal)

| State Variable | Increase/Decrease Triggers | UI/Feedback Reflection |
| :--- | :--- | :--- |
| combo_count | +1 on slash hit within 1.5s of previous hit; resets to 0 on timeout or whiff | Player circle outline color shifts (white → yellow → orange → red) with combo steps |
| difficulty | +1 per elapsed minute | Crystal spawn rate and fall speed visibly increase; background fractal pattern becomes denser |

Notes:
- 2 state variables only. Absolute minimum.
- `combo_count` drives the "extend chain or play safe" decision. Visible purely through player glow color — no HUD number.
- `difficulty` is time-based pressure. Expressed through spawn density and speed — the screen itself shows danger.

## 1. Core Mechanics

**View**: Side view. Player circle on the ground. Crystals fall from above.

**Controls** (3 buttons):
- **A — Move Left**: Walk left. Hold to keep moving.
- **B — Move Right**: Walk right. Hold to keep moving.
- **C — Slash**: Instant vertical cut upward from the player's position. Hits everything directly above in a narrow column. Short cooldown (~0.3s).

**Core loop**:
1. Fractal crystals fall from the top of the screen at various horizontal positions
2. Move under a crystal and press Slash to cut it
3. Crystal splits into 2 smaller fragments that fly apart in **parabolic arcs** (upward and outward, then falling back down)
4. While fragments are airborne, run to where one will land and slash again for combo points
5. Chain through generations (gen 1 → 2 → 3 → sparkle burst) for escalating score

**Two threats**:
- **Airborne**: Any falling crystal or fragment that lands on you = game over
- **Ground impact**: Any crystal or fragment that hits the ground creates a brief shockwave — sharp debris skids outward along the ground (~0.3s). Contact with debris = game over

**Why you MUST slash**: Unslashed crystals hit the ground and create large, dangerous shockwaves. Slashing converts big crystals into smaller fragments with smaller shockwaves. Fully chain-slashing to gen-3 and bursting them in mid-air = zero ground impact. So slashing is both scoring AND ground safety management.

**Splitting and arcs by generation**:
- **Gen 1** (original, ~50px): Splits into 2 gen-2 fragments. Fragments fly in **high, wide arcs** with long airtime (~2s). Easy to read and chase.
- **Gen 2** (~30px, 1.4× fall speed): Splits into 2 gen-3 fragments. **Medium arcs**, moderate airtime (~1.2s). Requires quicker movement.
- **Gen 3** (~18px, 1.8× fall speed): **Low, short arcs**, brief airtime (~0.6s). Must react fast. On slash: bursts into sparkles (no further split, no ground impact).

**Ground shockwave by generation**:
- Gen 1 landing: Large shockwave (debris spreads ~80px from impact). Very dangerous.
- Gen 2 landing: Medium shockwave (~50px spread).
- Gen 3 landing: Small shockwave (~25px spread). Manageable.
- Gen 3 burst (slashed in air): No shockwave. Clean.

**Difficulty**: difficulty starts at 1, +1 per elapsed minute.
- Crystal spawn rate: base_rate × difficulty (more falling at once)
- Crystal fall speed: base_speed × (1 + 0.15 × difficulty)

**Game Over**: Contact with any crystal, fragment, or ground shockwave debris. Single condition: "touching crystal material kills you" — whether it's falling from above or skidding along the ground from an impact.

## 1.5 Tradeoff Definition

- Concrete behavior pair: `Slash and retreat (safe, moderate score)` vs `Slash and chase fragments for combo chain (dangerous, high score)`
- Tradeoff explanation: After slashing, fragments fly in parabolic arcs. You know where they'll land. Running to the landing point to chain-slash = higher combo and generation bonus, but you're positioning yourself under falling objects. Each chain extension is a calculated gamble.

- Secondary tradeoff: `Slash everything to keep ground safe (active)` vs `Dodge falling crystals and accept ground shockwaves (passive)`
- Tradeoff explanation: Unslashed crystals create big ground shockwaves. Slashing clears them but creates airborne fragments. The player must balance air threats (fragments) vs ground threats (shockwaves). Full chain-slashing to gen-3 burst is the only way to eliminate both.

## 1.6 Causal Chain Audit

| Rule | Causal Sentence | Physical Basis |
| :--- | :--- | :--- |
| Slash splits crystal | When you cut upward through a crystal, it cracks into two pieces because a blade fractures brittle material. | Fragmentation |
| Fragments fly in parabolic arcs | When a crystal breaks, pieces fly upward and outward then fall back down because force launches them and gravity pulls them back. | Projectile motion |
| Smaller fragments have shorter arcs | When a small piece is launched, it doesn't fly as far because it has less momentum. | Mass-momentum relationship |
| Smaller fragments fall faster | When pieces get smaller, they fall faster because lighter objects have less air resistance relative to their weight. | Terminal velocity |
| Gen 3 bursts into sparkles | When the smallest fragment is slashed, it shatters into dust because it's too small to hold together. | Material limit |
| Ground impact shockwave | When a heavy crystal smashes into the ground, sharp debris skids outward because impact scatters material along the surface. | Impact fragmentation |
| Bigger crystal = bigger shockwave | When a larger crystal hits the ground, more debris flies further because more mass means more energy on impact. | Energy proportional to mass |
| Contact = death | When sharp crystal material hits the soft bubble, it pops because sharp edges puncture soft surfaces. | Puncture |

## 1.7 Context-Dependent Action Audit

| Action | Best Moment | Worst Moment | Cost of Mistiming |
| :--- | :--- | :--- | :--- |
| Slash | Under a crystal with a clear path to chase its fragments. Best when combo is active (chain extending). Best when a large gen-1 crystal is about to hit the ground (preventing big shockwave). | Under a crystal when other fragments are already falling nearby — you can't dodge while slashing. Also bad when combo has lapsed (restarting at 1×). | 0.3s cooldown locks you in place briefly. If fragments are falling near you, that 0.3s can mean death. Wasted slash = missed combo window. |
| Move Left / Right | After slashing, run to where a fragment will land to extend the combo chain. Or: run away from a ground shockwave zone. | Running toward a fragment's landing point when another fragment is falling along your path — you walk into it. | Walking into a falling fragment = instant death. Running away from a combo opportunity = combo timer expires. |

Key: "Slash as fast as possible while standing still" creates fragments that arc away and fall back — eventually one lands on you or the ground shockwaves overlap your position. Timed movement between slashes is essential.

## 1.8 Superlinear Scoring Design

- **Mechanism**: Generation depth × combo chain multiplier
- **Setup**: Slash a gen-1 crystal. Its gen-2 fragments arc away. Run to where one will land, slash it (gen-2 → gen-3). Run to the gen-3 fragment's landing point, slash it (burst). Each slash within 1.5s builds the combo.
- **Trigger**: The chain of slash → run → slash → run that converts a single crystal lineage into a cascade of combo-multiplied burst points.
- **Growth curve**: Gen G scores G_pts (gen 1 = 1pt, gen 2 = 3pt, gen 3 = 7pt). Combo C multiplies by C. A full chain from one crystal: gen1(1×1) + gen2a(3×2) + gen2b(3×3) + gen3a(7×4) + gen3b(7×5) + gen3c(7×6) + gen3d(7×7) = 1 + 6 + 9 + 28 + 35 + 42 + 49 = **170 pts** from one crystal lineage.
- **Linear baseline**: Player who only slashes gen-1 crystals, no combos, no chaining: 1 pt per crystal. ~1 crystal/2s over 60s = ~30 pts.
- **Strategic ceiling**: Expert who chains full lineages with maintained combo: ~170 pts per lineage × ~5 lineages per minute = ~850 pts. That is **≥28× the linear baseline**.
- **Risk**: Chasing fragments means running toward falling objects. Each chase is a bet that you'll arrive before the fragment lands and that nothing else falls on you en route.

## 2. Object Specifications

### Player Circle
- Shape: Circle with soft glow outline
- Size: Radius ~16px (constant)
- Position: On the ground, moves left/right freely
- Collision: Contact with any crystal material (falling or ground debris) = game over
- Visual: Outline color shifts with combo count (white → yellow → orange → red)

### Crystal (Generation 1)
- Shape: Fractal polygon (Koch-snowflake-like, jagged self-similar edges)
- Size: ~50px diameter
- Fall speed: base_speed × difficulty
- On slash: Splits into 2 gen-2 fragments. Fragments launch in symmetric parabolic arcs — high, wide, ~2s airtime.
- On ground impact: Large shockwave (debris skids ~80px outward along ground, lasts 0.3s)
- Visual: Cool crystalline blue-white, solid opacity

### Fragment (Generation 2)
- Shape: Smaller fractal polygon, visibly a "child" of gen-1
- Size: ~30px diameter
- Fall speed: 1.4× gen-1 speed
- On slash: Splits into 2 gen-3 fragments. Medium parabolic arcs, ~1.2s airtime.
- On ground impact: Medium shockwave (~50px spread)
- Visual: Brighter, slightly cyan-shifted

### Fragment (Generation 3)
- Shape: Smallest fractal polygon, bright and sharp
- Size: ~18px diameter
- Fall speed: 1.8× gen-1 speed
- On slash: Bursts into sparkle particles (destroyed, points awarded, NO ground impact)
- On ground impact: Small shockwave (~25px spread)
- Visual: Bright white-gold glow, faint trail

### Slash Effect
- Shape: Thin vertical line extending upward from player (~120px tall, ~8px wide)
- Duration: Instantaneous hit detection, visual flash persists ~0.15s
- Cooldown: 0.3s between slashes
- Visual: White line with bloom. Color matches combo tier.

### Ground Shockwave
- Shape: Expanding semicircle of sharp debris along the ground surface
- Size: Proportional to crystal/fragment generation (gen 1 = 80px, gen 2 = 50px, gen 3 = 25px)
- Duration: 0.3s, then fades
- Visual: Sharp crystalline fragments skidding outward, matching the parent crystal's color

### Background
- Base: Dark with subtle fractal recursive pattern (Sierpinski-like)
- Behavior: Pattern density increases with difficulty (more intricate as game progresses)
- No phase-based color shifts. Consistent cool-dark palette.

## 3. Design Guide Analysis

### (1) Simplicity and Intuitiveness
Three buttons: left, right, slash. Crystals fall, slash them, dodge the arcing fragments. Ground impacts create visible debris. Everything is physically intuitive — no abstract systems.

### (2) Visual Feedback and Game Over
Slash = flash line + crack. Split = fragments arc away with trail. Combo = player glow color. Ground impact = visible debris burst. Game over = pop. All feedback is visual, no text needed.

### (3) Skill-Based Scoring and Risk/Reward
Safe play scores ~30 pts/min. Aggressive combo chaining scores ~850 pts/min. 28× gap ensures skill is massively rewarded. Risk is visceral — you run toward falling objects.

### (4) Novel Mechanics
"Slashing creates parabolic fragment arcs you must chase" is not standard. Most slash-games treat cutting as terminal (Fruit Ninja) or create random debris (Asteroids). Here, fragments follow **predictable physics** that the player can read and plan around, creating a spatial puzzle layered on top of an action game. The ground shockwave mechanic means both slashing AND not slashing have consequences.

### (5) Causal Intuition
All 8 rules have one-sentence physical analogies (§1.6). Cut = fracture. Arcs = projectile motion. Impact = debris. No abstract jargon.

### (6) Context-Dependent Actions
Slashing when fragments are already falling nearby = death. Moving toward a landing point when your path crosses another fragment's trajectory = death. Both actions require timing and spatial awareness (§1.7).

### (7) Superlinear Scoring
Gen depth × combo creates superlinear growth. 28× gap between baseline and strategic ceiling (§1.8).

## 4. Relationship with Tags

| Tag | Influence |
| :--- | :--- |
| player-circle | Player is a circle |
| on_released-throw | Slash is a release of cutting energy upward (derived from "release" concept) |
| on_pressed-jump | Not used as explicit jump. Vertical element expressed through parabolic fragment arcs instead. Tags are seeds. |
| ability-instant_line | Slash is an instantaneous vertical line — no travel time |
| obstacle-split | Core mechanic: crystals split into smaller fragments with parabolic arcs |
| field-multiple | Multiple crystals and fragments in the air simultaneously = multiple spatial events to track. Left and right halves of screen as implicit "fields" to manage. |
| structure-phase_shift | Not used as explicit phase system. Natural difficulty progression creates emergent "phase" feel (calm early game → chaotic late game). Tags are seeds. |
| background-fractal-motif | Crystals are fractal shapes; background uses recursive patterns |

**Creative deviation**: Dropped jump and phase shift as explicit mechanics. The parabolic arc physics and ground shockwaves create enough depth without additional systems. Two tags unused — acceptable per design guide §5 ("deviation allowed, final design need not be explained by tags").

## 5. Basis for Novelty

**Most similar games**: Fruit Ninja (slash falling objects), Asteroids (shoot-to-split)

**Key differences**:
- Fruit Ninja: slashing is purely positive and terminal. Here, slashing **creates predictable parabolic threats** you must then chase or dodge.
- Asteroids: fragments drift randomly. Here, fragments follow **readable physics** (parabolic arcs) that enable route planning.
- Neither game has the ground shockwave mechanic where unslashed objects create ground-level danger, forcing the player to actively engage rather than passively dodge.

**"Never seen this before" moment**: The realization that you can *read* where fragments will land and plan a route through multiple landing points to chain-slash a full lineage. The game transitions from "reaction game" to "spatial prediction game" as mastery develops.

## 6. Engagement Design

### 6.1 Prediction & Surprise
- **Predictable physics**: Parabolic arcs follow consistent physics. Players learn to read trajectories and predict landing points. This creates the core "prediction" satisfaction.
- **Emergent surprise**: Multiple crystals' fragment arcs can intersect unexpectedly. A planned route to chain-slash one lineage gets disrupted by fragments from another crystal crossing the path.

### 6.2 Mastery Curve
- **Beginner**: Slashes crystals as they approach. Doesn't chase fragments. Gets hit by ground shockwaves from unslashed landings. Survives ~20s. Score: ~10 pts.
- **Intermediate**: Understands arc physics. Chases gen-2 fragments for combos. Manages ground safety by slashing most crystals before they land. Survives 60-90s. Score: ~300 pts.
- **Expert**: Reads multiple arcs simultaneously. Plans routes through predicted landing points to chain-slash full lineages (gen 1→2→3→burst). Maintains high combos across multiple crystal lineages. Survives 120s+. Score: 2,000+ pts.

### 6.3 Meaningful Choices
- **Decision point 1: "Chase or retreat?"** — After slashing a crystal, two gen-2 fragments arc away. Chase one for combo points (risky — running toward a landing zone) or retreat to safety (combo drops)?
- **Decision point 2: "Which crystal to slash first?"** — Two crystals are falling at different positions. One is about to hit the ground (big shockwave imminent). The other is higher up (more time). Slash the urgent one to prevent the shockwave, or slash the high one for a longer combo chain window?

### 6.4 Tension Rhythm
**30-second window**:
- 0-5s (Valley): 1-2 crystals falling slowly. Player plans approach. Low tension.
- 5-12s (Rising): Player slashes a crystal and chases fragments. Multiple arcs in the air. Attention splits between fragment trajectories and new crystals spawning. Tension builds.
- 12-20s (Peak): Combo chain is active. Player is running between landing points, slashing rapidly. Fragments and new crystals overlap. Ground shockwaves from missed fragments add ground-level danger. Maximum tension.
- 20-25s (Resolution): Combo chain ends (completed or broken). Brief lull as current fragments clear. Player catches breath.
- 25-30s (Reset): New wave of crystals begins. Player surveys positions and plans next chain route. Tension resets.

### 6.5 Replay Motivation
- **"If only I had..."**: "If only I had gone left instead of right — that gen-3 fragment landed exactly where I could have reached it." / "If only I had slashed that crystal before it hit the ground — the shockwave got me." / "If only I hadn't been greedy chasing a gen-3 when another crystal was falling on my path."
- **Run-to-run variation**: Crystal spawn positions and timing are random. Each run creates different spatial puzzles for route planning. Sometimes crystals cluster (easy chains), sometimes they spread (must choose which to pursue). Fragment arcs interact differently each time. No two runs produce the same spatial puzzle.

## Document Links

- [VISUAL_DESIGN.md](./VISUAL_DESIGN.md)
- [TYPOGRAPHY_DECISION.md](./TYPOGRAPHY_DECISION.md)
- [SOUND_DESIGN.md](./SOUND_DESIGN.md)
- [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md)
- [logs/test.json](./logs/test.json)
- [logs/improvement_report.md](./logs/improvement_report.md)

---

# Game Generation Report: Fractal Shatter

## Selected Tags

### Mechanics Tags

- player: player-circle
- action: on_released-throw, on_pressed-jump
- ability: ability-instant_line
- context: obstacle-split, field-multiple

### Visual Tags

- background-fractal-motif

### Structure Tags

- structure-phase_shift

## Test Results

| Metric | Initial | After Improvement |
| :--- | :--- | :--- |
| Exploratory Ratio | 9.90 | Not implemented / N/A |
| Periodic Resistance | 9.90 | Not implemented / N/A |
| Score CV | 1.664 | Not implemented / N/A |
| Monotonous Max | 0 | Not implemented / N/A |
| Exploratory Best | 30 | Not implemented / N/A |

Note: Visual/sound/AI-genericness evaluations are added only if Phase 8 is executed.

## Improvements

### Mechanics Improvement

1. Phase 7 proposed 3 options (see logs/improvement_report.md). Recommended: Option C (wider slash arc) for immediate playability. Implementation deferred to Phase 8.

### Visual Improvement

1. Not yet evaluated (Phase 8 scope).

### Sound Improvement

1. Not yet evaluated (Phase 8 scope).
