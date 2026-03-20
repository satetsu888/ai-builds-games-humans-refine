# Mini-Game Design Guide

## 1. Design Challenges

- Creating diverse gameplay experiences with minimal input.
- Designing appropriate difficulty curves and risk/reward systems.
- Providing intuitive feedback for player actions.
- Preventing monotonous operations (button mashing, idle play).

## 2. Seven Core Design Principles and Evaluation Criteria

Integrate "principles (what to do)" and "evaluation (confirmation items)" to clarify design guidelines.

### (1) Simplicity and Intuitiveness

- Principle: Use basic shapes (circles, triangles, squares), keep backgrounds simple. Eliminate UI, explanations, and multiple resource management. Create a "self-explanatory" structure where rules are conveyed through play.
- Evaluation: Can rules and object roles be understood immediately without text?

### (2) Visual Feedback and Game Over

- Principle: Convey success, failure, and danger states through animation, color, and size changes. Game over conditions should be single and obvious at a glance, such as "collision," "falling," "time running out," "structure collapsing," or "gauge depleting."
- Evaluation: Are action results visually clear? Are failure reasons fair and obvious?

### (3) Skill-Based Scoring and Risk/Reward

- Principle: Reward intentional actions and high-risk behavior (e.g., close calls) rather than simple tasks. Design so mastery directly reflects in score.
- Evaluation: Does score reflect player skill? Are there always meaningful choices (safe vs. challenging)?

### (4) Novel Mechanics

- Principle: Without being bound by existing concepts, invent surprising behaviors from physical laws (gravity, magnetism, inertia), geometric principles, or their negation.
- Evaluation:
  - Are there moments where players feel "I've never seen this before"?
  - Are there elements that cannot be explained by existing tag combinations alone?
  - Do diverse developments emerge from a single mechanic?

### (5) Causal Intuition

- Principle: Every cause-and-effect rule in the game should map to a physical or spatial intuition that humans already possess. If a mechanic requires an abstract intermediary concept (zones, invisible states, delayed triggers) to explain the connection between action and result, redesign the causal chain so the connection is self-evident.
- Good causal chain: action → immediate visible consequence that shares physical logic with the action. "Push an object → it slides and hits others" (momentum transfer). "Hold a button → character charges and glows" (accumulation is visible). "Ignite a fuse → flame travels along the rope → barrel explodes" (fire propagation).
- Bad causal chain: action → invisible state change → delayed/unrelated consequence. "Touch a pillar → a zone is created → later, mutated entities spawn from that zone" (requires learning an arbitrary rule).
- Test: Can each rule be stated as a single-sentence physical analogy without using game-specific jargon (zone, gauge, state, phase)?
- Evaluation:
  - Can a first-time player predict what will happen before it happens, based on visual cues alone?
  - Does every consequence share a spatial or physical relationship with its cause (proximity, contact, motion direction)?
  - Are there any rules where the player must die once to learn an arbitrary connection?

### (6) Context-Dependent Actions

- Principle: Every action button (beyond basic movement) must have situations where pressing it is beneficial AND situations where pressing it is harmful or wasteful. The player must constantly judge "should I act NOW?" rather than acting whenever possible. If an action is always beneficial regardless of timing or context, it becomes a reflex rather than a decision — leading to button-mashing as the optimal strategy.
- Design approach:
  - **Beneficial context**: Define when the action produces the best outcome (e.g., "attack when enemies are clustered," "jump at the edge of a platform," "fire when the target is aligned").
  - **Costly context**: Define when the action produces a negative outcome or opportunity cost (e.g., "attack on miss creates a vulnerability window," "jumping at the wrong time lands you in danger," "firing depletes limited ammo needed later").
  - The cost does not need to be symmetric with the benefit — a small cost that occasionally matters is enough to create meaningful timing decisions.
- Test: For each action button, can you concretely describe both "the best moment to press it" and "the worst moment to press it"?
- Evaluation:
  - Does each action button have at least one situation where NOT pressing it is the better choice?
  - Would a policy of "press this button as often as possible" perform worse than a policy of "press this button at the right moments"?
  - Can the player learn to read the game state to judge when to act?

### (7) Superlinear Scoring

- Principle: The scoring system must reward deliberate multi-step setups with non-linear score growth. A player who creates specific conditions through a sequence of correct actions should score dramatically more than a player who simply performs individual correct actions. This separates "skilled play" from "strategic play" — the latter should be rewarded with accelerating returns.
- Patterns (use at least one):
  - **Chain multiplier**: The n-th success in a chain scores n× (or n²×) base points. Chains break on failure, creating tension between extending the chain and cashing out safely.
  - **Setup → trigger**: Creating a specific spatial or temporal arrangement, then executing an action on it, yields more than the sum of individual actions. Example: letting enemies cluster, then hitting the cluster for area damage that scores per-enemy × chain-length.
  - **Condition combo**: Meeting multiple conditions simultaneously multiplies the reward. Example: destroying an enemy while airborne, near a wall, at low HP each add a multiplier.
  - **Threshold bonus**: Accumulating a resource to a threshold triggers a bonus event. Example: filling a combo meter triggers a score burst, but the meter decays so you must sustain performance.
- Test: Can a player who understands the scoring system score 5× or more than a player who plays skillfully but without strategic setup?
- Evaluation:
  - Is there at least one scoring mechanism where reward grows faster than linearly with consecutive successes?
  - Does the game create moments where a patient setup yields a dramatically larger score than immediate action?
  - Can test policies that simulate "strategic patience" (e.g., waiting for conditions, then acting) outscore policies that simply act frequently?

## 3. Interaction Patterns (Reference)

Examples of mechanics based on input. These are starting points for ideas, not constraints. The number of available buttons is determined by `button_types` (1–5) chosen in Phase 1.

### 3.1 Single-Button State Patterns

| Input | Mechanic | Application Examples |
| :--- | :--- | :--- |
| **Press** | Instant change | Direction change (90/180°), jump, emit pulse, teleport, split, place marker, attribute toggle |
| **Hold** | Accumulation/Extension | Power/angle adjustment, stretch, shield deployment, energy charging, toggle state |
| **Release** | Release/Recoil | Projectile firing, charged burst execution, state release effects |

### 3.2 Multi-Button Patterns (button_types ≥ 2)

| Pattern | Mechanic | Application Examples |
| :--- | :--- | :--- |
| **Role separation** | Each button controls a distinct axis | Move / Act, Left / Right, Jump / Place |
| **Exclusive toggle** | Only one button's effect is active | Stance switching (offense ↔ defense, gather ↔ build), element cycling |
| **Simultaneous combo** | Pressing multiple buttons at once triggers a special action | Charged dash (move + attack), emergency brake |
| **Sequential chain** | Button order matters | Input combos for special moves, rhythm sequences |

## 4. Movement and Environment Mechanics (Reference)

Examples of movement pattern and terrain combinations. Ideas beyond these are welcome.

### 4.1 Player Movement/Actions

- **Auto-movement**: Auto-run, constant bouncing, fixed oscillation, acceleration
- **Special movement**: Gravity reversal, wall reflection, fixed-point rotation, teleport
- **Actions**: Area effect (burst/wave), deflection, physics-based projectiles, chain reactions, state toggle

### 4.2 Environment/Terrain Interaction

- **Terrain**: Irregular ground, floating/moving platforms, chasms, temporary footholds
- **Gimmicks**: Environment zones with changing behavior, hazards (spikes, crushers, rising water, wind gusts, crumbling floors), physics puzzles

## 5. Role of Tags

Tags are not design specifications but inspiration starting points (seeds).

- **Stimulus, not constraint**: Expand associations from tags, feel free to depart from them
- **Contradiction is opportunity**: Use contradicting tags as creative tension (see §8)
- **Deviation allowed**: No problem if final design cannot be explained by tags
- **Purpose**: Functions as randomness to "shift" LLM ideas from existing patterns

## 6. Starting Points for Ideas

Idea starting points independent of tags. Use when stuck or when pursuing novelty from the start.

### 6.1 Abstract Questions

| Perspective | Example Questions |
| :--- | :--- |
| **Negation** | What if there's no screen? No score? No failure? |
| **Sensation** | What moment raises heart rate? What is relief? What is "close call"? |
| **Beyond physics** | What if you could manipulate probability? What if causality is reversed? What if time branches? |
| **Cross-discipline** | Musical tension and resolution, ecosystem predation, chemical chain reactions |
| **Reverse from emotion** | How to create feeling of "betrayal"? What is the joy of "discovery"? |

### 6.2 Ideas from Constraints

Set constraints of "without ~" and work backwards:

- No movement (game that works with only on-screen changes)
- No enemies (battle against environment or self)
- No scoring (goal is state maintenance or change)
- No visuals (works with only sound or rhythm)

## 7. Procedure for Designing Games from Tags

Design in the following order from given tag groups.

1. **Free Association**: Look at tags, verbalize the first images or sensations that come to mind (refer to §6)
2. **Deviation Exploration**: Consider the "opposite," "negation," or "extreme" of tags, explore unexpected directions
3. **Core Experience Decision**: Define the "momentary sensation" you want to give the player in one phrase
4. **Mechanics Construction**: Design input scheme that realizes the core experience
5. **Causal Chain Audit**: For each rule, write a one-sentence physical analogy. If you cannot, redesign the causal chain (see §2.5)
6. **Context-Dependent Action Audit**: For each action button, describe the best and worst moments to press it. If an action has no bad timing, redesign it to include a cost or opportunity cost (see §2.6)
7. **Superlinear Scoring Design**: Identify at least one scoring mechanism where reward accelerates with multi-step setups. Document the setup → payoff structure (see §2.7)
8. **Consistency Verification**: Verify design with the checklist in §10

※ Use tags as stimulus for steps 1-2, don't be bound by tags from step 3 onwards.

## 8. Tag Contradiction and Creative Tension

When contradicting tags are given, it's an opportunity for invention, not a constraint.

| Contradiction Example | Conventional Approach | Creative Interpretation |
| :--- | :--- | :--- |
| `field:1D` and `field:3D` | Adopt one | Space that looks 1D but has depth, or move 1D-like in 3D space |
| `on_pressed:jump` and `on_pressed:shoot` | Select by priority | Jump and shoot as same action (jumping trajectory becomes attack, etc.) |
| `player:auto_move` and `on_holding:stop` | Organize dependencies | Design where stopping itself is a risk |

**Principle**: Don't resolve contradiction, invent a new concept that makes contradiction possible.

## 9. Output Format

Output in the following format to `tmp/games/<slug>/README.md`.

```markdown
# <GAME_NAME> (<slug>)

## 0. Tag Record

- Mechanism (3): #m_tag1, #m_tag2, #m_tag3
- Visual (2): #v_tag1, #v_tag2
- Structure (1): #s_tag1
- button_types: <1-5>
- Unexpected pair check: `<pair_a> + <pair_b>` is not in `data/tags/obvious_pairs.json`

## 0.5 State Model (minimal)

| State Variable | Increase/Decrease Triggers | UI/Feedback Reflection |
| :--- | :--- | :--- |
| var_a | <what changes it> | <where/how it is shown> |
| var_b | <what changes it> | <where/how it is shown> |

Notes:
- Add state variables only when they create a new decision that cannot be expressed by existing rules.
- Each state must have at least one in-world representation (terrain/behavior/color/shape/speed/sound), not only HUD numbers.

## 1. Core Mechanics

<Input → Behavior → End condition, scoring system, difficulty increase mechanism>
<difficulty variable convention: initial value 1, +1 per elapsed minute — see balance-pattern-guide.md §1>

## 1.5 Tradeoff Definition

- Concrete behavior pair: `<action_safe>` vs `<action_risky>`
- Tradeoff explanation: how improving one state worsens another

## 1.6 Causal Chain Audit

For each game rule, a one-sentence physical analogy:

| Rule | Causal Sentence | Physical Basis |
| :--- | :--- | :--- |
| <rule_1> | When [action], [consequence] because [reason] | <fragmentation / momentum / accumulation / etc.> |
| <rule_2> | When [action], [consequence] because [reason] | ... |

## 1.7 Context-Dependent Action Audit

For each action button (beyond movement), the best and worst moments to press it:

| Action | Best Moment | Worst Moment | Cost of Mistiming |
| :--- | :--- | :--- | :--- |
| <action_1> | <when pressing yields maximum benefit> | <when pressing is harmful or wasteful> | <what the player loses> |
| <action_2> | ... | ... | ... |

## 1.8 Superlinear Scoring Design

- Mechanism: <which superlinear pattern is used — chain multiplier / setup-trigger / condition combo / threshold bonus>
- Setup: <what the player must do or arrange before the payoff>
- Trigger: <the action that converts the setup into a large score>
- Growth curve: <how score scales — e.g., "n-th chain hit scores n × base" or "cluster size² points">
- Linear baseline: <what a player scores without strategic setup, just reacting>
- Strategic ceiling: <what a player scores with deliberate setup, and why it is ≥5× the baseline>

## 2. Object Specifications

<Each object's shape, behavior, collision handling>

## 3. Design Guide Analysis

<Evaluation against seven core design principles, including causal intuition audit>

## 4. Relationship with Tags

<Idea development from tags>

## 5. Basis for Novelty

<Elements beyond existing patterns, and how this game differs from the most similar existing game(s)>

## 6. Engagement Design

### 6.1 Prediction & Surprise
<Situations where the same input produces different outcomes depending on context>

### 6.2 Mastery Curve
- Beginner: <concrete behavior>
- Intermediate: <concrete behavior>
- Expert: <concrete behavior>

### 6.3 Meaningful Choices
- Decision point 1: <situation, options, and tradeoffs>
- Decision point 2: <situation, options, and tradeoffs>

### 6.4 Tension Rhythm
<Expected tension curve over a 30-second window: what creates peaks and valleys>

### 6.5 Replay Motivation
- "If only I had...": <the realization players have after game over>
- Run-to-run variation: <what makes each attempt feel different>
```

## 10. Design Quality Checklist

Confirm the following before completing design.

- [ ] Is the input scheme within the `button_types` limit chosen in Phase 1?
- [ ] Is the game over condition single and visually obvious?
- [ ] Is button mashing/idle play not the optimal solution?
- [ ] Can you provide reasoned answers to all 7 principles in §2?
- [ ] Did ideas start from tags and have elements beyond existing patterns?
- [ ] Are there moments of feeling "I've never seen this before"?
- [ ] If state variables are used, is each one justified by a distinct decision purpose?
- [ ] If state variables are used, does each one have a non-text in-world feedback channel?
- [ ] Is there at least 1 explicit tradeoff between states/actions (including action vs terrain)?
- [ ] Does at least one world-side persistent history remain from player actions?
- [ ] Can every rule be stated as a one-sentence physical analogy without game-specific jargon?
- [ ] Does every consequence share a spatial or physical relationship with its cause?
- [ ] Does each action button have a documented "best moment" and "worst moment" to press it?
- [ ] Would "press as often as possible" perform worse than "press at the right moments" for each action?
- [ ] Is there at least one scoring mechanism where reward grows faster than linearly with consecutive successes?
- [ ] Can a strategic player score ≥5× more than a player who acts skillfully but without deliberate setup?

## Appendix: SCAMPER Method (Auxiliary Technique)

Idea assistance through transformation of existing elements. However, this is an auxiliary for when stuck, not the primary ideation method.

- **Substitute**: Replace jump with teleport or gravity reversal.
- **Combine**: Combine bounce mechanics with direction change.
- **Adapt**: Adapt existing arcade games or physical phenomena (pendulum, waves) to the chosen `button_types` constraint.
- **Modify**: Character grows giant with hold duration. Danger increases with speed.
- **Put to other uses**: Use obstacles or challenge objects as platforms or tools.
- **Eliminate**: Remove "obvious" elements like gravity or direct movement control.
- **Rearrange**: Stage composition constantly changes.

**Note**: SCAMPER method is transformation of existing elements and has limits for generating fundamentally new ideas. Use together with abstract questions in §6, aiming for "new concepts" beyond transformation.
