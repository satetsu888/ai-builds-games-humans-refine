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
- Game-over conditions must be tied to in-world hazards/state collapse. Do not directly punish non-action itself.
- Test-agent-specific branching (hidden behavior that is only advantageous/disadvantageous during tests) is prohibited.

## Instruction: When You Are Told “Make a Game”

Execute Phases 1–8 in order.
Phase 7 is evaluation-report only (no implementation changes). Implementation changes are allowed only in Phase 8 from human feedback.
Each phase below lists required files and commands.

If you modify the game based on human instructions, you must run through Web export.

---

## Phase 1: Tag Selection

Randomly select 3 mechanic tags, 2 visual tags, and 1 structure tag.
Mechanic tags must satisfy at least one non-obvious pair based on `data/tags/obvious_pairs.json`.
Also choose a random integer `button_types` from `1-5`.

```bash
node scripts/random_tag_selector.js --file data/tags/mechanism_tags.csv -n 3 --require-unexpected-pair --obvious-pairs data/tags/obvious_pairs.json
node scripts/random_tag_selector.js --file data/tags/visual_tags.csv -n 2
node scripts/random_tag_selector.js --file data/tags/structure_tags.csv -n 1
node -e "console.log(Math.floor(Math.random() * 5) + 1)"  # button_types (1-5)
```

To reproduce with the same seed, add `-s <number>`.
If `button_types` must also be reproducible, use the same `-s <number>` and a seeded random call in `node` to generate the same value.

**How to treat tags**: Tags are creative seeds, not strict specs. Use contradictory tags as creative tension. Do not fear divergence.

**Minimum validation**:

- [ ] Selected 1 structure tag from `data/tags/structure_tags.csv`
- [ ] Recorded `mechanism 3 + visual 2 + structure 1` in `README.md`
- [ ] Recorded `button_types: <1-5>` in `README.md`
- [ ] Satisfied `non-obvious pair >= 1` under `data/tags/obvious_pairs.json`

---

## Phase 2: Game Design

**Reference**: `guides/mini-game-design-guide.md`

Design game rules using mechanic tags as seeds.

1. Free-association and deliberate deviation from tags
2. Define the core experience in one sentence
3. Design controls (within `button_types` chosen in Phase 1)
4. Causal chain audit (see Causal Intuition Guard below)
5. Design player engagement (see Engagement Design below)
6. Validate via checklist (`guides/mini-game-design-guide.md` §10 and Engagement checklist below)

**Output**: `tmp/games/<slug>/README.md` (core mechanics, controls, object specs, novelty rationale, tag log, state-variable table, tradeoff explanation, engagement design)

**Visible-Causality Guard (required)**:

- State variables must not exist "just to have a number." Before adding one, explicitly state one new decision that existing rules cannot express.
- Each state variable must have at least one in-world, non-HUD causal manifestation (terrain/behavior/color/shape/speed/sound).
- If expressible with existing state, prefer integration (state reduction) over adding new state.

### Causal Intuition Guard (required)

Every cause-and-effect rule must be explainable as a one-sentence physical analogy that a player can intuit without reading instructions.

For each mechanic, write a **causal sentence** in the format: "When [action], [consequence] because [physical reason]."

- **Pass**: "When you break a crystal, shards fly outward because that's how fragmentation works."
- **Pass**: "When you hold the button, the character charges and glows because energy visibly accumulates."
- **Fail**: "When you break a crystal, a zone appears that later spawns mutated enemies." (Requires learning an arbitrary rule — no physical intuition connects action to delayed consequence.)

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
- Example: "Beginner holds inhale until hit. Intermediate releases before shards arrive. Expert times inhale windows around shard spawn patterns."

#### (3) Meaningful Choices

Are there moments where the player must choose between meaningfully different options?

- List at least two decision points per play session where the player weighs alternatives.
- Each choice must have both upside and downside — not a dominant option.

#### (4) Tension Rhythm

Does the game alternate between tension and relief?

- Describe the expected tension curve over a 30-second window.
- Identify what creates the "peaks" (danger approach, resource depletion) and "valleys" (safe window, reward collection).
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

- Visual hierarchy rule (1 protagonist / 1 danger / 1 reward)
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
8. Lock event-to-timbre mapping for `score / danger / damage / state change` within a game
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
- Exploratory input tests (random or heuristic, multiple trials)
- Output of `exploratory.best.score` and `monotonous.max_score`
- Output `logs/test.json` on every run with required minimum fields:
  - `monotonous.max_score`
  - `exploratory.best.score`
  - `exploratory_ratio`
  - `telemetry.death_analysis / spawn_analysis / scoring_analysis / input_analysis`
- Treat missing required fields as test failure
- Auto-update `logs/improvement_report.md` for improvement-history comparison

### 6b: Mechanics Evaluation (Exploratory Ratio)

```text
exploratory_ratio = exploratory.best.score / monotonous.max_score
```

| Exploratory Ratio | Evaluation  | Meaning                                   |
| :---------------- | :---------- | :---------------------------------------- |
| <= 1.0            | Fail        | Monotonous input is optimal (no skill)    |
| 1.0 - 1.5         | Needs work  | Skill reflection is insufficient           |
| > 1.5             | Pass        | Better play is rewarded                    |

Exploratory ratio is necessary but not sufficient. KPI gains with degraded experience are rejected.

Check:

- [ ] Game-over conditions function correctly
- [ ] Score is added as intended
- [ ] Difficulty increases over time
- [ ] Button-mashing/idle is not optimal
- [ ] Skillful play is rewarded
- [ ] For each added state variable, non-HUD in-world causality is implemented in code

Subjective visual/sound evaluation and UI-hidden comprehension checks are done in Phase 8.

### 6c: Experience Curve Analysis

Beyond the final score, analyze the **temporal shape** of each test run to detect engagement problems that aggregate metrics miss.

Tests should record per-interval snapshots (recommended: every 5 seconds) with at least:
- Score delta (points gained in this interval)
- Danger events (shard contacts, near misses, damage taken)
- Active entity count

From these snapshots, evaluate:

| Pattern | Symptom | Likely Cause |
| :--- | :--- | :--- |
| Dead start | Score delta = 0 for the first 10+ seconds | Objects take too long to reach the player; no early engagement |
| Flat tension | Danger events are uniformly distributed | No difficulty escalation or phase transitions; monotone pacing |
| Spike death | Death occurs within 2 seconds of first damage | No recovery window; difficulty cliff instead of curve |
| No peaks | Score delta is constant throughout | No combo/bonus/risk-reward moments; steady drip of points |
| Front-loaded | All scoring happens in first half, near-zero later | Difficulty increase shuts down scoring rather than shifting it |

Record the experience curve evaluation in `logs/test.json` under `telemetry.experience_curve` and flag detected patterns.

If the design includes a tension rhythm description (Phase 2, §1.7), compare the actual curve shape against the design intent.

### 6d: Engagement Design Verification

Verify each element from the Phase 2 Engagement Design against the implementation:

- [ ] Context-dependent outcomes exist in code (same input, different result based on game state)
- [ ] Score distributions across test seeds show variance (not all runs score identically)
- [ ] At least one ability/action is sometimes beneficial and sometimes costly depending on timing
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

### Engagement Evaluation

In addition to mechanics analysis, evaluate the game against the Phase 2 Engagement Design:

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
- Could you distinguish player / threat / reward at a glance?
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

- tag1, tag2, tag3

### Visual Tags

- vtag1, vtag2

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
| `data/tags/mechanism_tags.csv`              | Mechanics tags (107 tags)                     | Phase 1          |
| `data/tags/visual_tags.csv`                 | Visual tags (54 tags)                         | Phase 1          |
| `data/tags/structure_tags.csv`              | Structure tags (game skeleton)                | Phase 1          |
| `data/tags/obvious_pairs.json`              | Obvious-pair definitions (non-obvious check)  | Phase 1          |
| `scripts/random_tag_selector.js`            | Tag selection script                          | Phase 1          |
| `guides/mini-game-design-guide.md`          | Mechanics design guide                        | Phase 2          |
| `guides/visual-design-guide.md`             | Visual design guide                           | Phase 3          |
| `guides/typography-implementation-guide.md` | Typography exploration/implementation/license | Phase 5/8        |
| `guides/sound-design-guide.md`              | Sound design guide (procedural audio)         | Phase 4          |
| `templates/godot-base/`                     | New game initialization template              | Phase 5          |
| `templates/godot-base/TEMPLATE_SCOPE.md`    | Template immutable-layer rules                | Phase 5          |
| `guides/game-improvement-guide.md`          | Improvement guide (analysis methods)          | Phase 7          |
| `guides/balance-pattern-guide.md`           | Balance adjustment pattern set                | Phase 7          |
| `.agents/skills/headless-godot/`            | Godot headless operation skill                | Phase 5-6        |
