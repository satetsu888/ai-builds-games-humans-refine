# Sound Design: Warp Chase Holdline

**Visual Tags (Sound Source)**: #geometry-primitive-modularity, #analog-line-noise-warp

## 1. Audio Concept

"Pursuit-alert sound built from crisp geometric tones layered with subtle analog warp noise."

## 2. Waveform Palette

| Role | Waveform | Parameters | Usage |
|:---|:---|:---|:---|
| Primary tone | Triangle + Sine | 420-1200 Hz, short AR envelope | Core for near miss, wave shifts, and score rise sounds |
| Mechanical edge | Square (duty 0.3-0.32) | 180-900 Hz, low duty | Hard impact character and piercing damage texture |
| Analog warp texture | White Noise (low mix) | -1.0..1.0, 8-35% mix | Adds line-noise-warp texture and emphasizes danger events |

## 3. Sound Event Specifications

| Event | Waveform | Frequency | Duration | Envelope | Dynamic Parameter |
|:---|:---|:---|:---|:---|:---|
| Score gain (enemy-enemy collision) | Sine + short-duty square | base 760Hz + combo, upward sweep | 120ms | Attack 7%, Release 52% | `pitch += multiplier`, `brightness += impact_speed`, `accent += chain_streak` |
| Danger ping (high threat proximity) | Narrow-duty square + noise | 520-760Hz | 100ms | Attack 3%, Release 72% | `pitch += danger_level`, `noise += danger_level`, cooldown 320ms |
| Near miss | Narrow-duty square + triangle + noise | 560Hz start, short downward bend | 90ms | Attack 5%, Release 65% | `gain += player_speed`, `pitch += multiplier` |
| Thrust loop (while pressing thrust) | Low sine + soft triangle + filtered noise | base 88-130Hz (speed/difficulty linked) | Continuous | Smooth fade in/out, no hard retrigger | `gain += thrust hold`, `freq += speed`, `texture += speed` |
| Damage (shield hit) | Square + noise | 220Hz start, descending | 280ms | Attack 2%, Release 82% | `noise_mix += impact_speed`, `pitch_offset += difficulty` |
| Shield recharge ready | Sine pair | 780Hz start, short rise | 160ms | Attack 8%, Release 55% | `pitch += difficulty` |
| Wave shift / difficulty step | Triangle + low sine | 420Hz base + wave index, upward | 180ms | Attack 3%, Release 62% | `pitch += wave`, `tension += difficulty` |
| Game over | Sine + triangle + slight noise | ~440Hz exponential descent | 420ms | Attack 1%, Release 90% | `weight += difficulty`, `start_pitch += multiplier` |
| Ambient bed (continuous) | Low sine + triangle drone, thin pulse, shield overtone, light noise | 54-410Hz core + slow modulation | Continuous | Smooth fade only, no hard retrigger | `danger += hiss+density`, `multiplier += harmonic_open`, `wave += base_pitch`, `shield += high_overtone`, `turn/thrust += pulse_motion` |

## 4. Relationship with Visual Tags

- `geometry-primitive-modularity`:
  - Separate events using short, sharply contoured values centered on triangle/square waves.
  - Unify near miss, score, and wave shift with stepwise modular pitch motion.
- `analog-line-noise-warp`:
  - Mix slight noise into all events to avoid overly pure tones and sonify line warping.
  - Raise noise ratio for damage/game-over to synchronize red flash with danger perception.
  - In ambient layer, increase noise amount and phase wobble as danger approaches to sync with stronger background grid warping.

## 4.1 Ambient BGM-like Layer

- Purpose:
  - Create BGM-like continuity as spatial pressure tracking play state, not a fixed music loop.
- Components:
  - Low drone: base pitch rises slightly with speed and wave progress.
  - Orbital pulse: thin periodicity emerges from turning amount and `thrust`.
  - Shield aura: high overtones remain while shield is active and gradually return during recharge.
  - Warp noise: increase noise and stereo wobble by danger density.
- Prohibited:
  - Explicit bar-based looping
  - Occupying foreground timbre bands of score/danger/damage with the continuous layer

## 5. Semantic Lock and Cross-Game Variation

### 5.1 In-Game Semantic Lock

| Event Family | Timbre Family | Why it is recognizable |
|:---|:---|:---|
| Score | Bright ascending family (triangle + harmonic tail) | Upward sweep and bright harmonics signal reward instantly |
| Danger | Thin warning family (narrow square + hiss) | Thin pulse + short noise quickly indicates approaching danger |
| Damage | Low-noise family (descending square + grit) | Descending dissonance separates failure events clearly |
| State change | Transparent transition family (sine/triangle rise) | Indicates progression update without confusion with attack cues |

### 5.2 Cross-Game Variation Plan

- Changes from previous similar work:
  - Added dedicated danger event (event-driven threshold crossing, not constant loop)
  - Reassigned near miss from score-family to danger-family timbre
  - Introduced constrained detune (`+-1.5-3%`) for all events to reduce repetitive machine feel
- Rationale:
  - Keep 1:1 correspondence with visual danger links and proximity warnings, reducing UI-text dependency
  - Lock meaning <-> timbre mapping within one game while avoiding cross-game template reuse
