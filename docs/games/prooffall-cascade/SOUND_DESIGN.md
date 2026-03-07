# Sound Design: Prooffall Cascade

**Visual Tags (Sound Source)**: `#typography-objectification`, `#analog-chromatic-offset`

## 1. Audio Concept

Detuned print-shop clicks wrapped in unstable glassy rings.

## 2. Waveform Palette

| Role | Waveform | Parameters | Usage |
| :--- | :--- | :--------- | :---- |
| Primary tone | detuned sine pair | 320-880 Hz, 1.5-3% detune | score and state motifs |
| Texture / noise | short filtered noise burst | fast decay, low mix | typewriter attack and damage transient |

## 3. Semantic Timbre Mapping

- `score`: bright detuned double-ping with short upward bend
- `danger`: thin high bandpassed hiss pulse
- `damage`: low thud plus noisy crack
- `state change`: dry type-click followed by a brief split-tone glide

## 4. Event Specification

| Event | Sound |
| :--- | :--- |
| Score gain | 90-140ms detuned ping, overtone layers scale by score tier (chain depth proxy) |
| Chain extension | harmonic layers (1.5x/2.0x/2.6x) are added progressively |
| Jam warning | 60ms hiss tick when danger is detected |
| Jam critical band | 65ms hiss/ring loop while `max_jam_ratio >= 0.02` (near-immediate after top reach), interval shortens with risk |
| Jam release | 70ms low release tone when critical jam state is cleared |
| Pulse press | glyph-dependent mechanical click + short suction tail during collapse wind-up |
| Pressure step-up | 140ms two-note detuned warning chime on each `field_pressure` increment |
| Damage / death | 280ms downward noisy falloff |
| Game over | 450ms descending detuned ring with muted tail |

## 5. Dynamic Parameters

- Score tier (derived from event points) adds overtone layers.
- `field_pressure` sharpens score partials and shifts pressure-step root pitch.
- Jam critical loop interval compresses from ~340ms to ~120ms as `max_jam_ratio` approaches 1.0.
- Pulse base frequency is mapped to focused glyph class (`A/E/O`) to reinforce typography objectification.

## 6. Continuous-Sound Policy

- No always-on ambient bed is used.
- Continuous perception is achieved only through context-gated jam critical ticks, preserving collapse readability.

## 7. Cross-Game Variation Plan

- This game fixes on detuned sine pairs plus click noise.
- Future games should vary waveform family, envelope sharpness, and rhythmic spacing rather than reusing this print-click motif.
