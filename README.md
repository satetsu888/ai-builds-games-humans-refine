# AI Builds Games, Humans Refine

## A Tiny Story

> **AI:** "I made a game! Wanna try it?"
>
> **Human:** "Of course. Let me play... This is fun. Maybe this part could feel clearer, and this moment could pop more."
>
> **AI:** "Okay! I'll fix it and show you the next version."

This project is a human-in-the-loop mini-game workshop:

- AI quickly builds a playable Godot mini-game.
- A human plays it and gives warm, practical feedback.
- AI improves the game and brings back a better version.
- Repeat until it feels genuinely fun.

## What This Repo Is For

- Fast game prototyping with AI
- Human feedback-driven refinement
- Iterative quality improvement (design, mechanics, visuals, sound)

## Workflow Overview

`AGENTS.md` defines an 8-phase workflow for generating and refining a mini-game:

1. **Phase 1 — Tag Selection**: Randomly choose mechanic tags (player / action / ability / context), a visual tag, a structure tag, and a `button_types` count (1–5).
2. **Phase 2 — Game Design**: Turn tags into a concrete game design. Includes a Causal Intuition Guard (every rule must have a one-sentence physical analogy), Context-Dependent Action Guard (every action button must have best/worst timing), Superlinear Scoring Guard (strategic play must yield dramatically higher scores), and Engagement Design (prediction & surprise, mastery curve, meaningful choices, tension rhythm, replay motivation).
3. **Phase 3 — Visual Design**: Define visual direction, palette, composition, non-text feedback rules, and causal visibility mapping.
4. **Phase 4 — Sound Design**: Design procedural sound effects (Godot `AudioStreamGenerator` only, no external audio files) and event-to-sound mappings.
5. **Phase 5 — Godot Implementation**: Implement the game in Godot 4.2+ from the base template, following headless rules, responsibility-split scripts, and typography guidelines. Run script validation (`--check-only`) before testing.
6. **Phase 6 — Testing & Evaluation**: Run headless tests and evaluate three metrics — exploratory ratio (skill vs. monotonous input), periodic resistance (adaptive vs. fixed-rhythm play), and exploratory score variance (context-dependence). Also includes experience curve analysis and action/scoring structure verification.
7. **Phase 7 — Improvement Evaluation Report**: Analyze issues and propose at least 3 improvement options using improvement operators (state reduction, world integration, input semantics inversion, spatial historization, risk-reward shift). No implementation changes — evaluation only.
8. **Phase 8 — Human-in-the-Loop Improvement**: Humans play the Web export and give feedback via a structured play-test protocol (5-second / 30-second / 3-minute checkpoints). AI implements changes, re-tests, and re-exports iteratively.

### Core Principles

- **Experience-First**: KPIs are detectors for gameplay quality, not optimization goals. Changes that degrade player experience are rejected even if KPI values improve.
- **Visible Causality**: Every cause-and-effect must be intuitable without reading instructions.
- **No Test Gaming**: Test-agent-specific branching, direct scoring for raw input facts, and meta-penalties for non-action are all prohibited.
