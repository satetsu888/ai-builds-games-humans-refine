# AGENTS.md — Godot Mini-Game Auto-Generation

Entry point for AI agents to automatically design, implement, and improve mini-games in Godot 4.2+.

## Operational Principle (Single Source of Truth)

- The only source of truth for execution steps, constraints, and evaluation criteria is this `AGENTS.md`.
- Other documents (`*-guide.md`) are reference guides for principles/patterns only; do not duplicate procedural definitions there.
- When procedures change, update this document and keep referenced guides focused on principles and implementation patterns.

## Experience-First Principle (KPI Guardrails)

- KPIs (such as exploratory ratio) are **detectors for gameplay quality**, not optimization goals.
- Changes that degrade player experience must be rejected even if KPI values improve.
- Scoring must be tied only to in-game event causality. Direct scoring for raw input facts is prohibited.
- Game-over conditions must be tied to in-world consequences/state collapse. Do not directly punish non-action itself.
- Test-agent-specific branching (hidden behavior that is only advantageous/disadvantageous during tests) is prohibited.

## Instruction: When You Are Told “Make a Game”

Execute Phases 1–8 in order.
Phase 7 is evaluation-report only (no implementation changes). Implementation changes are allowed only in Phase 8 from human feedback.
Each phase below lists required files and commands.

If you modify the game based on human instructions, you must run through Web export.

---

## Phase 1: Tag Selection

Select mechanic tags from 4 groups (6 total), 1 visual tag, and 1 structure tag.
Also choose a random integer `button_types` from `1-5`.

Mechanic tag groups:

| Group | File | Pick |
| :--- | :--- | :--- |
| player | `data/tags/mechanism_player_tags.csv` | 1 |
| action | `data/tags/mechanism_action_tags.csv` | 2 |
| ability | `data/tags/mechanism_ability_tags.csv` | 1 |
| context | `data/tags/mechanism_context_tags.csv` (obstacle / field / rule / on_got_item) | 1 |

```bash
node scripts/random_mechanism_selector.js
node scripts/random_tag_selector.js --file data/tags/visual_tags.csv -n 1
node scripts/random_tag_selector.js --file data/tags/structure_tags.csv -n 1
node -e "console.log(Math.floor(Math.random() * 5) + 1)"  # button_types (1-5)
```

To reproduce with the same seed, add `-s <number>` to each command.
If `button_types` must also be reproducible, use the same `-s <number>` and a seeded random call in `node` to generate the same value.

**How to treat tags**: Tags are creative seeds, not strict specs. Use contradictory tags as creative tension. Do not fear divergence.

**Minimum validation**:

- [ ] Selected 1 structure tag from `data/tags/structure_tags.csv`
- [ ] Recorded `mechanism 5 (player 1 + action 2 + ability 1 + context 1) + visual 1 + structure 1` in `README.md`
- [ ] Recorded `button_types: <1-5>` in `README.md`

---

## Phase 2: Game Design

**Reference**: `guides/mini-game-design-guide.md`

Design game rules using mechanic tags as seeds.

### Design Principle: Experience First, Then Verify

Phase 2 has two stages: **Design** (imagine the fun, build the minimum) and **Verify** (test quality with guards).

- Guards and checklists exist to TEST whether the core experience has depth, not to ADD mechanics.
- If a guard check fails, return to Stage 1 and redesign the core mechanic. Do NOT add a new mechanic to pass the check.
- A mini-game should have ONE core mechanic that is deep, not many mechanics that are shallow.
- **Complexity budget**: A design may have at most 3 mechanics beyond basic movement. If you exceed this, simplify before proceeding. Satisfying guards through the depth of one mechanic is better than satisfying them through the breadth of many.

### Design Principle: Conceptual Coherence

All mechanics in the game must be explainable through concepts that are **conceptually proximate** to the player's perceived identity of the core entity.

1. **Identify the core metaphor**: Determine what the player will perceive the main entity as based on its visual form and behavior.
2. **Enumerate associated concepts**: List 5-8 concepts that people naturally associate with that metaphor.
3. **Constrain mechanics to associated concepts**: Every mechanic (attack, defense, scoring, failure, growth) must map to one of these associated concepts. If a mechanic requires a concept outside this set, either replace it with one that fits or reconsider the core metaphor.

**Why**: When mechanics are conceptually distant from the player's mental model, they feel arbitrary and require explanation. When mechanics are conceptually proximate, the player intuits the rules from the metaphor alone without a tutorial.

**Test**: For each mechanic, ask "Would someone who only knows the core metaphor (not the game rules) guess that this mechanic exists?" If no, the mechanic is conceptually distant and should be redesigned.

### Stage 1 — Design (experience-first)

1. Free-association and deliberate deviation from tags
2. Describe the core experience as a concrete moment: "The player feels [emotion] when [specific moment happens]" — if you cannot make someone want to play with this one sentence, the concept is not ready
3. Identify the **core metaphor** and list 5-8 associated concepts (see Conceptual Coherence principle above)
4. Design ONE core mechanic that creates that moment, using only concepts from step 3
5. Design controls (within `button_types` chosen in Phase 1)
5. Design mobile touch layout: map each control action to a touch zone. The virtual gamepad must accommodate all actions within thumb-reachable screen regions. Separate directional movement and action buttons (e.g., movement on one side, actions on the other). Choose screen orientation (portrait `540x960` recommended for single-hand play; landscape if the game requires wide field of view) and document the choice with rationale.
6. Design game flow states: every game must have three states — **title**, **playing**, and **game_over**. Title screen starts the game via keyboard (SPACE/Z/Enter) or screen tap. Game-over screen shows final score and a retry prompt, activated via R key or retry button tap. Document the transition triggers in the controls section.
7. Design scoring that naturally rewards the core experience

### Stage 2 — Verify (guards as quality tests)

Test the design against each guard. For any failing guard, return to Stage 1 and redesign the core — do not add new mechanics.

8. Conceptual coherence audit (see Conceptual Coherence principle above)
9. Causal chain audit (see Causal Intuition Guard below)
10. Context-dependent action audit (see Context-Dependent Action Guard below)
11. Superlinear scoring design (see Superlinear Scoring Guard below)
12. Engagement design (see Engagement Design below)
13. Validate via checklist (`guides/mini-game-design-guide.md` §10 and all Guard/Engagement checklists below)

**Output**: `tmp/games/<slug>/README.md` (core mechanics, controls, touch zone layout, screen orientation, game flow states, object specs, novelty rationale, tag log, state-variable table, tradeoff explanation, engagement design)

**Visible-Causality Guard (required)**:

- State variables must not exist "just to have a number." Before adding one, explicitly state one new decision that existing rules cannot express.
- Each state variable must have at least one in-world, non-HUD causal manifestation (terrain/behavior/color/shape/speed/sound).
- If expressible with existing state, prefer integration (state reduction) over adding new state.

### Causal Intuition Guard (required)

Every cause-and-effect rule must be explainable as a one-sentence physical analogy that a player can intuit without reading instructions.

For each mechanic, write a **causal sentence** in the format: "When [action], [consequence] because [physical reason]."

- **Pass**: "When you push an object off a ledge, it falls and smashes what's below because gravity pulls things down."
- **Pass**: "When you hold the button, the character charges and glows because energy visibly accumulates."
- **Fail**: "When you touch a pillar, a zone appears that later spawns mutated entities." (Requires learning an arbitrary rule — no physical intuition connects action to delayed consequence.)

If a causal sentence requires abstract intermediary concepts (zones, invisible states, delayed triggers, parameters), redesign the mechanic:

1. **Shorten the chain**: Remove intermediary steps. Can the consequence follow directly from the action?
2. **Make it physical**: Replace abstract state changes with visible material transformations (breaking → fragments, charging → growing, burning → spreading).
3. **Add a visual bridge**: If delay is mechanically necessary, add a visible process that connects action to consequence (a growing crack, a spreading glow, a traveling wave).

Record causal sentences in `README.md` section `1.6 Causal Chain Audit`.

### Causal Intuition Checklist

- [ ] Every rule has a one-sentence physical analogy in `README.md` §1.6
- [ ] No rule requires abstract jargon (zone, gauge, state, phase) to explain the cause-effect link
- [ ] Every consequence shares a spatial or physical relationship with its cause
- [ ] Delayed consequences have a visible bridge connecting action to result

### Context-Dependent Action Guard (required)

Every action button (beyond basic movement) must have situations where pressing it is the right choice AND situations where pressing it is the wrong choice. If an action is always beneficial, it becomes a reflex (button mashing) rather than a decision.

For each action button, document in `README.md` section `1.7 Context-Dependent Action Audit`:

| Action | Best Moment | Worst Moment | Cost of Mistiming |
| :--- | :--- | :--- | :--- |

- **Pass**: "Launch is best when enemies are clustered (chain reaction). Launch is worst when no targets are nearby (wasted cooldown leaves you unable to fire when a cluster forms)."
- **Pass**: "Jump is best at platform edges (maximum distance). Jump is worst over spikes (you land on them instead of walking around)."
- **Fail**: "Attack is always good — it destroys anything it touches with no cooldown or cost." (No reason to ever NOT press it → mashing is optimal.)

If an action has no bad timing, add a cost:
1. **Cooldown/resource cost**: Action has a recovery period or limited uses, so mistimed use wastes the opportunity.
2. **Vulnerability window**: Performing the action creates a brief opening where the player is exposed.
3. **State commitment**: The action changes the game state in a way that forecloses other options temporarily.

### Context-Dependent Action Checklist

- [ ] Every action button has a documented best and worst moment in `README.md` §1.7
- [ ] For each action, "press as often as possible" would perform worse than "press at the right moments"
- [ ] The cost of mistiming is observable in-game (not hidden or negligible)

### Superlinear Scoring Guard (required)

The scoring system must include at least one mechanism where reward grows faster than linearly with player skill and setup. This ensures that strategic, multi-step play is dramatically more rewarding than simple correct actions, creating depth beyond basic competence.

Document the superlinear scoring design in `README.md` section `1.8 Superlinear Scoring Design`:

- **Mechanism**: Which pattern — chain multiplier, setup→trigger, condition combo, or threshold bonus
- **Setup**: What the player must arrange or accumulate
- **Trigger**: The action that converts setup into a large score
- **Growth curve**: How score scales (e.g., n², 2^n, n×base)

- **Pass**: "Chain hits score n × base_points for the n-th hit in a chain. A 5-chain scores 1+2+3+4+5 = 15× base, vs 5× base for 5 individual hits." (Triangular growth rewards chaining.)
- **Pass**: "Letting 4 enemies cluster then hitting them all scores 4² = 16 points, vs 4 × 1 = 4 for individual kills." (Quadratic growth rewards patience.)
- **Fail**: "Each enemy killed gives 1 point regardless of context." (Linear — no reason to set up anything.)

### Superlinear Scoring Checklist

- [ ] At least one scoring mechanism has documented superlinear growth in `README.md` §1.8
- [ ] A strategic player can score ≥5× more than a skillful-but-non-strategic player
- [ ] The setup required for superlinear scoring involves observable risk or opportunity cost

### Engagement Design (required)

Mechanics alone do not make a game worth playing. Before finalizing design, explicitly define **why the player will want to keep playing**.

The following five elements must each be addressed in `README.md` section `1.7 Engagement Design`. Not every element needs to be strong — but each must be consciously considered and the design decision documented.

#### (1) Prediction & Surprise

Does the game create moments where the player forms an expectation and then has it confirmed or subverted?

- Identify at least one situation where the same input produces different outcomes depending on context.
- If context-dependence does not exist, document why the mechanics still create surprise (e.g., emergent spatial interactions).

#### (2) Mastery Curve

Can the player feel "I'm getting better at this"?

- Define what separates a beginner, intermediate, and expert player in concrete behavioral terms (not score numbers).
- Example: "Beginner dodges reactively. Intermediate anticipates patterns and positions early. Expert baits hazards into favorable formations before countering."

#### (3) Meaningful Choices

Are there moments where the player must choose between meaningfully different options?

- List at least two decision points per play session where the player weighs alternatives.
- Each choice must have both upside and downside — not a dominant option.

#### (4) Tension Rhythm

Does the game alternate between tension and relief?

- Describe the expected tension curve over a 30-second window.
- Identify what creates the "peaks" (challenge intensification, approaching deadline, accumulating instability, resource depletion) and "valleys" (safe window, reward collection).
- If the game is constant intensity, document why that works for the core experience.

#### (5) Replay Motivation

Why does the player press "retry" after game over?

- Define the "if only I had..." moment: what does the player realize they could have done differently?
- Describe at least one source of run-to-run variation that makes each attempt feel different (procedural layout, spawn timing, emergent combinations).

### Engagement Design Checklist

- [ ] Section `1.7 Engagement Design` exists in `README.md` with all five elements addressed
- [ ] At least one context-dependent outcome is documented (Prediction & Surprise)
- [ ] Beginner/intermediate/expert behaviors are defined in concrete terms (Mastery Curve)
- [ ] At least two non-trivial decision points are identified (Meaningful Choices)
- [ ] Tension peaks and relief valleys are described for a 30-second window (Tension Rhythm)
- [ ] A specific "if only I had..." moment is articulated (Replay Motivation)

---

## Phase 3: Visual Design

**Reference**: `guides/visual-design-guide.md`

Design the screen using visual tags as seeds.

1. Verbalize visual direction from tags
2. Identify integration points with mechanics
3. Decide a 3-5 color palette
4. Design feedback effects aligned to tag style
5. **Causal visibility audit**: For each causal chain from Phase 2 §1.6, design the visual expression that makes the cause-effect link self-evident without text (see `guides/visual-design-guide.md` §2.5). Verify spatial continuity, material continuity, temporal immediacy, and motion logic.
6. Document anti-AI-generic rules in `VISUAL_DESIGN.md`

- Visual hierarchy rule (1 player-controlled / 1 challenge element / 1 goal element)
- Upper bound on template-like symbols
- Feedback design that does not rely on UI text
- Composition rules (gaze guidance and center-clutter avoidance)
- Causal visibility mapping (how each mechanic's cause-effect chain is shown visually)

7. Validate via checklist (`guides/visual-design-guide.md` §10)

**Output**: `tmp/games/<slug>/VISUAL_DESIGN.md` (concept, palette, rendering specs, effect design)
Use `guides/visual-design-guide.md` §7.1 (`VISUAL_DESIGN.md Required Addendum Template`) for required addendum text.

## Phase 4: Sound Design

**Reference**: `guides/sound-design-guide.md`

Use visual tags as input to define SFX direction. Do not choose separate sound tags.
All SFX must be generated procedurally with Godot `AudioStreamGenerator`; no external audio files.

1. Derive sound style from visual tags (`guides/sound-design-guide.md` §3 mapping table)
2. Define one-sentence sound concept
3. Select waveform palette (1-2 base waveforms + modulation method)
4. Design SFX per game event (`guides/sound-design-guide.md` §4)
5. Define dynamic parameters (combo/speed/difficulty linkage)
6. For continuous sounds, specify start condition, stop condition, and release on stop (allowed reverb tail)
7. Validate via checklist (`guides/sound-design-guide.md` §8)
8. Lock event-to-timbre mapping for `score / tension / failure / state change` within a game
9. Vary timbre design per game (waveform, pitch range, envelope, modulation, rhythm)

**Output**: `tmp/games/<slug>/SOUND_DESIGN.md` (concept, waveform palette, per-event specs, dynamic parameters)

---

## Phase 5: Godot Implementation

**Skill**: `headless-godot` (load before implementation)

Create the Godot project based on Phase 2/3/4 design docs.
Initialization must start from template.

```bash
cp -r templates/godot-base/ tmp/games/<slug>/
```

Template default resolution is `960x540`. If changing resolution, update `project.godot`, `web/custom_shell.html`, and `export_presets.cfg` together.

Template scope is documented in `templates/godot-base/TEMPLATE_SCOPE.md`.

### Implementation Constraints

- GDScript (Godot 4.2+)
- Godot built-in nodes only (no external addons)
- Must run with `--headless`
- Before font adoption, implement using `ThemeDB` fallback only (no pre-bundled fonts)

### Game State Machine & Input Requirements

Every game must implement the following baseline interaction patterns. These are not part of the template (they involve game-specific logic) but are mandatory for every game built from the template.

#### Game State Machine

Implement a three-state machine in the main orchestrator:

- **title**: Display game name and controls summary. Transition to `playing` on keyboard input (SPACE, Z, or Enter) or screen tap. Do not auto-start.
- **playing**: Run the game loop. Transition to `game_over` when the game-over condition triggers.
- **game_over**: Display final score and retry prompt ("Press R to Retry" + visible retry button for touch). Transition to `playing` (via `_reset_game()`) on R key press or retry button tap. Do not auto-restart.

Test hooks (`enable_test_mode`, `force_reset_for_test`) must set state to `playing` directly, bypassing the title screen.

#### Touch Input Handling

All games must accept touch input alongside keyboard input:

- Handle `InputEventScreenTouch`, `InputEventScreenDrag`, and `InputEventMouseButton` (left click as touch proxy for desktop testing) in `_input(event)`.
- Map screen coordinates to named zones via a `_touch_zone(pos: Vector2) -> String` function. Zone definitions are game-specific (based on the control layout designed in Phase 2).
- Track active touches in a Dictionary (`touch_index -> zone_name`) and derive boolean input flags per zone via `_update_touch_state()`.
- Set a `has_touch: bool` flag on first `InputEventScreenTouch`. This flag is permanent (never resets to false) and controls virtual gamepad visibility.
- Scale touch coordinates from viewport space to game resolution before zone mapping (e.g., `game_resolution / viewport_size`).
- In `playing` state, unify keyboard and touch inputs (e.g., `var move_left := Input.is_key_pressed(KEY_A) or touch_left`).
- In `title` state, accept a start-zone tap or generic screen tap as game start.
- In `game_over` state, accept a retry-zone tap to restart.

#### Virtual Gamepad

When `has_touch` is true, draw a virtual gamepad in the rendering layer:

- Reserve a control area separated from the gameplay area (e.g., below or beside the game field). The gameplay area and the control area must not overlap.
- Draw one button per game action, sized for thumb operation (minimum ~100×80 pixels at game resolution).
- Provide visual press feedback (opacity change or color shift when a zone is active).
- Label each button with its action icon or short text.
- In `game_over` state, draw a visible retry button within the game area.
- In `title` state, draw a visible start button.
- Do not show the virtual gamepad when `has_touch` is false (keyboard/gamepad-only users should not see touch buttons).

#### Screen Orientation

- Portrait orientation (`540x960`) is recommended for mobile ergonomics (thumb-reachable controls at the bottom).
- Landscape is allowed if the game design requires a wide field of view.
- When choosing orientation, update `project.godot`, `web/custom_shell.html`, and `export_presets.cfg` together (existing resolution change rule).
- The control area layout must account for the chosen orientation: portrait games place controls at the bottom; landscape games place controls on the sides or bottom.

### Implementation Policy (for iterative improvement)

- Split into multiple scripts by responsibility, not one giant script.
- Keep `main.gd` as orchestrator only (update order and dependency wiring).
- Example responsibility axes:
  1. **Game state** (score/progression/multiplier/win-loss)
  2. **Player controls** (input/movement/actions)
  3. **World entities/environment** (non-player dynamics/environmental change)
  4. **UI/HUD** (display/notifications/transitions)
  5. **Effects/Audio** (visual FX/procedural sound)
- During improvements, edit only scripts for the target responsibility whenever possible; minimize cross-cutting changes.

### Deliverable Structure

```text
tmp/games/<slug>/
├── project.godot
├── main.tscn
├── main.gd
├── README.md
├── VISUAL_DESIGN.md
├── TYPOGRAPHY_DECISION.md
├── SOUND_DESIGN.md
├── THIRD_PARTY_LICENSES.md
├── assets/
│   └── fonts/        # bundle only adopted fonts (minimal)
├── licenses/         # original font license texts
├── tools/
│   └── tests/
│       └── run_tests.gd
├── logs/
│   ├── test.log
│   ├── test.json
│   └── improvement_report.md
└── scripts/          # as needed
```

### Deliverable Traceability Rule

Do not merge all documents into one file; use `README.md` as the index page.
`README.md` must include at least relative links to:

- `VISUAL_DESIGN.md`
- `TYPOGRAPHY_DECISION.md`
- `SOUND_DESIGN.md`
- `THIRD_PARTY_LICENSES.md`
- `logs/test.json`
- `logs/improvement_report.md`

### Godot Headless Rules

- Always use `--headless --path <PROJECT_DIR>`
- Capture logs with `mkdir -p logs && ... 2>&1 | tee logs/<name>.log`
- Do not edit `.tscn` directly as text (use `--headless --script`)
- In sandbox/CI/WSL, set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` to absolute paths under `<PROJECT_DIR>`

### Web Export Resolution and Canvas Layout

- Separate in-game render resolution (fixed) from page layout (centered placement).
- Choose render resolution per game (example: `960x540`; can be changed by project requirements).
- Match `project.godot` `window/size/viewport_width` and `window/size/viewport_height` to chosen render resolution.
- In `export_presets.cfg`, default to `html/canvas_resize_policy=0` and explicitly manage canvas buffer size.
- If using `export_filter="all_resources"` in `export_presets.cfg`, include at least these in `exclude_filter`: `build/web/*`, `.godot/*`, `.tmp-godot-data/*`, `.tmp-godot-config/*`, `.tmp-godot-cache/*`, `logs/*`, `tools/tests/*`.
- Require `html/custom_html_shell` and treat `res://web/custom_shell.html` as source of truth.
- `web/custom_shell.html` must:
  - Explicitly set `<canvas id="canvas" width="..." height="...">`
  - Re-assign same values to `canvas.width` / `canvas.height` before startup
  - Center canvas via centered `body` layout
- Do not directly edit `build/web/index.html` (it is overwritten on re-export).

### Older Browser Compatibility (required)

Web exports must work on older smartphone browsers (e.g., devices 3-5 years old). Apply the following settings to every game:

#### Nothreads Export Template

Use Godot's `nothreads` variant of the WebAssembly export template. This avoids reliance on `SharedArrayBuffer` and `WebWorker`, which older mobile browsers do not support reliably.

- The project stores the nothreads template at `templates/export/godot.web.template_release.wasm32.nothreads.zip`.
- After copying the template with `cp -r templates/godot-base/ tmp/games/<slug>/`, set `custom_template/release` in `export_presets.cfg` to the **absolute path** of the nothreads template zip (Godot requires absolute paths for custom templates). Use the project root to resolve: `<PROJECT_ROOT>/templates/export/godot.web.template_release.wasm32.nothreads.zip`.
- When upgrading Godot version, rebuild the nothreads template from source with SIMD disabled (`scons platform=web target=template_release arch=wasm32 threads=no use_volk=no`), then update the template file in `templates/export/`.

#### Cross-Origin Isolation Headers

Godot's default web export sets `ensureCrossOriginIsolationHeaders: true` in `GODOT_CONFIG`, which requires COOP/COEP headers. Older browsers fail to load with these headers.

- After web export, verify that the generated `index.html` contains `"ensureCrossOriginIsolationHeaders":false` in `GODOT_CONFIG`. The nothreads template should produce this automatically; if not, patch the generated `index.html` as a post-export step.

#### SIMD Disabled

The nothreads template must be built without WebAssembly SIMD instructions. Older mobile devices lack SIMD support in their WASM engines. The custom template build command above (`arch=wasm32`) produces a non-SIMD build.

### Typography Implementation

Apply rules from `guides/typography-implementation-guide.md`:

- Centralize font/color/size with `Theme` (minimize per-node overrides)
- Split display roles into `Heading / Info / Numeric / Emphasis`
- Restrict HUD to info display; emphasis only for events (no constant blinking/glow)
- Use stable-width font for numeric HUD
- Ensure readability over noisy backgrounds with outline/shadow
- Full font adoption (compare/adopt/bundle/license integration) is done in Phase 8
- Do not bundle non-adopted candidate fonts
- Reflect license info in `THIRD_PARTY_LICENSES.md` and `licenses/`

### Script Validation (required before Phase 6)

Run GDScript static analysis to catch type annotation errors and compilation issues before testing.

```bash
PROJECT_DIR="$(pwd)/tmp/games/<slug>" && \
mkdir -p "$PROJECT_DIR"/.tmp-godot-data "$PROJECT_DIR"/.tmp-godot-config "$PROJECT_DIR"/.tmp-godot-cache && \
XDG_DATA_HOME="$PROJECT_DIR/.tmp-godot-data" \
XDG_CONFIG_HOME="$PROJECT_DIR/.tmp-godot-config" \
XDG_CACHE_HOME="$PROJECT_DIR/.tmp-godot-cache" \
godot --headless --check-only --path "$PROJECT_DIR" 2>&1 | tee "$PROJECT_DIR/logs/check.log"
```

- Fix all reported errors before proceeding to Phase 6
- If `--check-only` reports warnings about missing type annotations, add explicit types
- Re-run until exit code is 0

---

## Phase 6: Testing & Evaluation

Evaluate implemented game via manual play and/or headless execution.

### 6a: Runtime Verification

```bash
PROJECT_DIR="$(pwd)/tmp/games/<slug>" && \
mkdir -p "$PROJECT_DIR"/.tmp-godot-data "$PROJECT_DIR"/.tmp-godot-config "$PROJECT_DIR"/.tmp-godot-cache "$PROJECT_DIR"/logs && \
XDG_DATA_HOME="$PROJECT_DIR/.tmp-godot-data" \
XDG_CONFIG_HOME="$PROJECT_DIR/.tmp-godot-config" \
XDG_CACHE_HOME="$PROJECT_DIR/.tmp-godot-cache" \
godot --headless --path "$PROJECT_DIR" --script res://tools/tests/run_tests.gd 2>&1 | tee "$PROJECT_DIR/logs/test.log"
```

If you create `run_tests.gd`, include at least:

- Monotonous input tests (`no_input` / `spam_action` / `hold_action`)
- Periodic input tests: fixed hold/release cycles at multiple intervals (e.g., 30, 60, 90, 120, 180 frame periods). These detect whether a simple repeating rhythm can achieve high scores.
- Exploratory input tests (random or heuristic, multiple trials across multiple seeds)
- Output of `exploratory.best.score` and `monotonous.max_score`
- Output `logs/test.json` on every run with required minimum fields:
  - `monotonous.max_score`
  - `periodic.max_score` (highest score across all periodic cycle tests)
  - `exploratory.best.score`
  - `exploratory.score_stddev` (standard deviation of exploratory scores across all seeds/variants)
  - `exploratory_ratio`
  - `periodic_resistance` (`exploratory.best.score / periodic.max_score` — how much better context-aware play is vs best fixed rhythm)
  - `telemetry.death_analysis / spawn_analysis / scoring_analysis / input_analysis`
- Treat missing required fields as test failure
- Auto-update `logs/improvement_report.md` for improvement-history comparison

### 6b: Mechanics Evaluation

Three metrics are used together. All three must pass for a game to be considered mechanically sound.

#### (1) Exploratory Ratio

```text
exploratory_ratio = exploratory.best.score / monotonous.max_score
```

| Exploratory Ratio | Evaluation  | Meaning                                   |
| :---------------- | :---------- | :---------------------------------------- |
| <= 1.0            | Fail        | Monotonous input is optimal (no skill)    |
| 1.0 - 1.5         | Needs work  | Skill reflection is insufficient           |
| > 1.5             | Pass        | Better play is rewarded                    |

#### (2) Periodic Resistance

```text
periodic_resistance = exploratory.best.score / periodic.max_score
```

Tests whether a fixed hold/release rhythm (at any interval) can match context-aware play. Fixed-rhythm strategies are a specific failure mode: the player discovers a single timing pattern and repeats it indefinitely, producing good scores without reading the game state.

| Periodic Resistance | Evaluation  | Meaning                                        |
| :------------------ | :---------- | :--------------------------------------------- |
| <= 1.5              | Fail        | A fixed rhythm scores nearly as well as adaptive play |
| 1.5 - 3.0           | Needs work  | Some advantage to reading the game, but rhythm is competitive |
| > 3.0               | Pass        | Fixed rhythms cannot compete with context-aware input |

#### (3) Exploratory Score Variance

```text
exploratory.score_stddev = stddev of all exploratory trial scores
```

Measures whether the game produces varied outcomes from varied input. High variance means context matters — the same strategy yields different results depending on game state (spawn positions, entity configurations). Low variance suggests the game is deterministic or insensitive to timing.

| Score Stddev (relative to mean) | Evaluation  | Meaning                                        |
| :------------------------------ | :---------- | :--------------------------------------------- |
| CV < 0.1                        | Fail        | Outcomes are nearly identical regardless of context |
| CV 0.1 - 0.3                    | Needs work  | Some variation but game state has limited impact |
| CV > 0.3                        | Pass        | Game state significantly affects outcomes        |

(CV = coefficient of variation = stddev / mean)

All three metrics are necessary but not sufficient. KPI gains with degraded experience are rejected.

Check:

- [ ] Game-over conditions function correctly
- [ ] Score is added as intended
- [ ] Difficulty increases over time
- [ ] Button-mashing/idle is not optimal
- [ ] Skillful play is rewarded
- [ ] No fixed hold/release cycle achieves a top score (periodic resistance)
- [ ] Exploratory scores show meaningful variance across seeds (context-dependence)
- [ ] For each action button, spam policy scores less than timing-aware policy (context-dependent actions)
- [ ] At least one superlinear scoring mechanism produces observable score acceleration in test results
- [ ] For each added state variable, non-HUD in-world causality is implemented in code
- [ ] Game state machine transitions correctly: title → playing → game_over → playing (retry)
- [ ] R key restarts the game from game_over state
- [ ] Touch zones are defined for all control actions plus start and retry
- [ ] Virtual gamepad renders only when `has_touch` is true
- [ ] Title screen does not auto-start; requires explicit input
- [ ] Game-over screen displays final score and retry prompt

Subjective visual/sound evaluation and UI-hidden comprehension checks are done in Phase 8.

### 6c: Experience Curve Analysis

Beyond the final score, analyze the **temporal shape** of each test run to detect engagement problems that aggregate metrics miss.

Tests should record per-interval snapshots (recommended: every 5 seconds) with at least:
- Score delta (points gained in this interval)
- Challenge events (hazard contacts, near misses, failures)
- Active entity count

From these snapshots, evaluate:

| Pattern | Symptom | Likely Cause |
| :--- | :--- | :--- |
| Dead start | Score delta = 0 for the first 10+ seconds | Objects take too long to reach the player; no early engagement |
| Flat tension | Challenge events are uniformly distributed | No difficulty escalation or phase transitions; monotone pacing |
| Spike death | Death occurs within 2 seconds of first failure | No recovery window; difficulty cliff instead of curve |
| No peaks | Score delta is constant throughout | No combo/bonus/risk-reward moments; steady drip of points |
| Front-loaded | All scoring happens in first half, near-zero later | Difficulty increase shuts down scoring rather than shifting it |

Record the experience curve evaluation in `logs/test.json` under `telemetry.experience_curve` and flag detected patterns.

If the design includes a tension rhythm description (Phase 2, §1.7), compare the actual curve shape against the design intent.

### 6d: Action & Scoring Structure Verification

Verify the Context-Dependent Action and Superlinear Scoring guards against the implementation:

- [ ] For each action button, "spam" monotonous policy scores less than a timing-aware exploratory policy
- [ ] At least one action is sometimes beneficial and sometimes costly depending on game state
- [ ] Superlinear scoring is functional: compare best exploratory score against a theoretical "linear ceiling" (actions × base_points)
- [ ] Score variance across exploratory policies is high (strategic policies outscore random-but-active policies)

### 6e: Engagement Design Verification

Verify each element from the Phase 2 Engagement Design against the implementation:

- [ ] Context-dependent outcomes exist in code (same input, different result based on game state)
- [ ] Score distributions across test seeds show variance (not all runs score identically)
- [ ] Tension rhythm is observable in the experience curve (not flat)

---

## Phase 7: Improvement Evaluation Report

Analyze issues found in Phase 6 and propose improvement candidates.

- Propose at least 3 options (not just one)
- Breakdown:
  - Option A: uses improvement operators (below)
  - Option B: uses a different operator combination from A
  - Option C: free-form option without those operator types (for comparison)
- For each option, write expected impact, risk, and complexity cost (state count / exception-rule count)
- Record proposals in `README.md` and `logs/improvement_report.md`
- After Phase 7 completion, execute Web export and proceed to Phase 8

### Improvement Operators (Search Algorithm)

- `State reduction`: Remove state variables that require explanation and merge into existing state
- `Integrate into world representation`: Move HUD-only info into terrain/behavior/color/sound causality
- `Input semantics inversion`: Switch same input role by context/phase to create judgment context
- `Spatial historization`: Persist player action results in environment to affect next decisions
- `Risk reward shift`: Reduce safe-zone steady scoring and shift rewards toward risky success

Per evaluation, choose 2-3 operators and vary combinations across proposals.

### Violation Fix Templates

- If monotonous input is optimal:
  - Reduce safe steady scoring
  - Move scoring opportunities to ones achievable only under risk
  - Document expected exploratory-ratio change as a forecast
- If state variables are excessive:
  - Remove weakly-justified added states
  - Merge into existing state while preserving decision structure
  - Explicitly state decisions that must remain after reduction

### Mechanics Improvement

**Reference**: `guides/game-improvement-guide.md`, `guides/balance-pattern-guide.md`

- Identify root causes (logic changes, not mere numeric tuning)
- Apply/compare patterns from `guides/balance-pattern-guide.md` in candidate options
- Treat "state variables requiring explanation" as reduction targets and integrate into world-side behavior
- Improvement report must record: "3 presented options", "adoption-candidate rationale", and "rejection rationale"
- Implement only after humans choose an option in Phase 8

Subjective visual/sound improvements are out of Phase 7 scope.

### Action & Scoring Structure Evaluation

Evaluate the Context-Dependent Action and Superlinear Scoring guards:

- **Context-Dependent Actions**: For each action button, does the "spam" monotonous policy score worse than a timing-aware exploratory policy? If spam is competitive, the action lacks sufficient cost for mistiming.
- **Superlinear Scoring**: Calculate the "strategic multiplier" = best exploratory score / (number of scoring actions × base points). If this is close to 1.0, scoring is linear and there is no reward for multi-step setups.
- **Score Ceiling Gap**: Compare the best exploratory score against the theoretical maximum under linear scoring. A large gap indicates superlinear scoring is working. A small gap indicates strategic depth is lacking.

When proposing improvement options, at least one option must address a detected action or scoring structure weakness.

### Engagement Evaluation

In addition to mechanics and structure analysis, evaluate the game against the Phase 2 Engagement Design:

- **Prediction & Surprise**: Do the test results show context-dependent scoring patterns, or is every frame equivalent?
- **Mastery Curve**: Is there a measurable gap between the worst and best exploratory policies? Does a "smarter" policy consistently outperform?
- **Meaningful Choices**: Are multiple input channels used in the best-performing policy, or is one channel dominant?
- **Tension Rhythm**: Does the experience curve (6c) show peaks and valleys, or is it flat?
- **Replay Motivation**: Do different test seeds produce meaningfully different outcomes (score variance)?

When proposing improvement options, at least one option must target a detected engagement weakness — not only mechanics KPIs.

### Prohibited

- Numeric tuning only (e.g., `speed *= 0.8`)
- Condition-branch addition only (e.g., `if too_hard: make_easier()`)
- Increasing randomness
- Claiming depth improvement by merely adding state variables
- Treating color-only changes as sufficient anti-AI-generic measures
- Treating HUD text addition as sufficient feedback fix
- Direct score for input facts (e.g., activity bonus)
- Meta penalties that directly fail on non-action (e.g., instant death for idle/stall)
- Hidden rules added only to pass test metrics (autoplay-specialized branches)

---

## Phase 8: Human-in-the-Loop Improvement

Optional phase where humans view/play Web export and iterate improvements through dialogue with the AI agent.

### Goal

- Complement headless metrics with lived experience quality (feel/readability/sound impression/tempo)
- Reduce mismatch between design intent and real play experience by incorporating human feedback
- Validate engagement design hypotheses from Phase 2 through actual play

### Structured Play-Test Protocol

When the human plays the game, the AI should ask for feedback structured around these time-based checkpoints:

#### 5-Second Test (First Impression)
- Did you understand what to do without reading instructions?
- Could you distinguish player / challenge / objective at a glance?
- Was there an immediate urge to interact?

#### 30-Second Test (Core Loop)
- Did you experience at least one "that was close" or "nice!" moment?
- Did you want to try a different approach after your first failure?
- Was there a moment where you made a deliberate choice (not just reacting)?

#### 3-Minute Test (Sustained Engagement)
- At what point, if any, did you feel bored or like "I've seen everything"?
- Did the game feel different at the end compared to the beginning?
- After game over, did you want to retry? If yes, what were you hoping to do differently?

Record responses in `logs/improvement_report.md` under "Human Feedback — Play-Test". AI should use these responses to identify gaps between the Phase 2 engagement design and the actual experience, then propose targeted improvements.

### Minimum Operation Rules

- Record short notes from human play observations and pass requests to AI
- AI implements requests and re-runs Phase 6 tests every time
- After tests, always update Phase 7 evaluation report
- After modifications, execute Web export
- Iterative dialogue can continue for as many rounds as needed
- Full typography execution (font comparison/adoption/bundling/license reflection) should generally happen here
- For typography implementation, follow `guides/typography-implementation-guide.md` and update `TYPOGRAPHY_DECISION.md`, `THIRD_PARTY_LICENSES.md`, and `licenses/`

### Recording (recommended)

- Add a "Human Feedback" section to `logs/improvement_report.md` with reasons and changes

---

## Final Report

At Phase 7 completion, you must output the following report.
Because Phase 7 is evaluation-only, "Not implemented / N/A" is allowed in the after-improvement column.
If implementation occurs in Phase 8, update this report using re-run Phase 6 results.

```markdown
# Game Generation Report: <GAME_NAME>

## Selected Tags

### Mechanics Tags

- player: tag1
- action: tag2, tag3
- ability: tag4
- context: tag5, tag6

### Visual Tags

- vtag1

### Structure Tags

- stag1

## Test Results

| Metric            | Initial | After Improvement |
| :---------------- | :------ | :---------------- |
| Exploratory Ratio | X.Xx    | Y.Yx              |

Note: Visual/sound/AI-genericness evaluations are added only if Phase 8 is executed.

## Improvements

### Mechanics Improvement

1. <What changed and why>

### Visual Improvement

1. <What changed and why>

### Sound Improvement

1. <What changed and why>
```

---

## File List

| File                                        | Purpose                                       | Referenced Phase |
| :------------------------------------------ | :-------------------------------------------- | :--------------- |
| `data/tags/mechanism_player_tags.csv`       | Player group tags (15 tags)                   | Phase 1          |
| `data/tags/mechanism_action_tags.csv`       | Action group tags (27 tags)                   | Phase 1          |
| `data/tags/mechanism_ability_tags.csv`      | Ability group tags (15 tags)                  | Phase 1          |
| `data/tags/mechanism_context_tags.csv`      | Context group tags (49 tags: obstacle/field/rule/on_got_item) | Phase 1 |
| `data/tags/visual_tags.csv`                 | Visual tags (54 tags)                         | Phase 1          |
| `data/tags/structure_tags.csv`              | Structure tags (game skeleton)                | Phase 1          |
| `scripts/random_tag_selector.js`            | Single-file tag selection script              | Phase 1          |
| `scripts/random_mechanism_selector.js`      | Grouped mechanism tag selection script        | Phase 1          |
| `guides/mini-game-design-guide.md`          | Mechanics design guide                        | Phase 2          |
| `guides/visual-design-guide.md`             | Visual design guide                           | Phase 3          |
| `guides/typography-implementation-guide.md` | Typography exploration/implementation/license | Phase 5/8        |
| `guides/sound-design-guide.md`              | Sound design guide (procedural audio)         | Phase 4          |
| `templates/godot-base/`                     | New game initialization template              | Phase 5          |
| `templates/godot-base/TEMPLATE_SCOPE.md`    | Template immutable-layer rules                | Phase 5          |
| `templates/export/godot.web.template_release.wasm32.nothreads.zip` | Nothreads WASM export template (older browser compat) | Phase 5 |
| `guides/game-improvement-guide.md`          | Improvement guide (analysis methods)          | Phase 7          |
| `guides/balance-pattern-guide.md`           | Balance adjustment pattern set                | Phase 7          |
| `.agents/skills/headless-godot/`            | Godot headless operation skill                | Phase 5-6        |
