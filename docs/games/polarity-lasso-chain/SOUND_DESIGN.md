# Sound Design: Polarity Lasso Chain

**Visual Tags (Sound Source)**: `analog-line-noise-warp`, `composition-negative-space`

## 1. Audio Concept

"Sparse analog hum with sharp tactical punctuations."

## 2. Waveform Palette

| Role | Waveform | Parameters | Usage |
| :--- | :--- | :--- | :--- |
| Primary tone | Triangle + sine | 140-520Hz, short envelope | Score, state-change, danger motifs |
| Texture / grit | White-noise mix | 20-35% mix on failure | Damage and danger harshness |

## 3. Sound Event Specifications

| Event | Waveform | Frequency | Duration | Envelope | Dynamic Parameter |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Score gain | Sine + pulse bright | 300Hz + combo/points offset | 80-180ms | Fast attack, mid release | pitch += combo, gain += points |
| Danger pulse | Triangle | 140-190Hz | 70ms | Fast decay | pitch follows heat |
| Damage | Sine + noise | 220Hz down-sweep | 280ms | Tiny attack, long release | noise mix fixed high |
| State change | Triangle-dark | 190Hz | 120ms | Mid attack/release | fixed motif |
| Ambient tension | Triangle + low sine | ~84Hz carrier | continuous | smoothed gain | gain follows heat + near-miss |

## 4. Relationship with Visual Tags

- `analog-line-noise-warp`: introduces unstable low-level hum and slight gritty components.
- `composition-negative-space`: keeps event count sparse so each cue has semantic weight.

## 5. Semantic Lock & Cross-Game Variation

### 5.1 In-Game Semantic Lock

| Event Family | Timbre Family | Why it is recognizable |
| :--- | :--- | :--- |
| Score | bright sine+pulse | only upward, clean motif |
| Danger | short low triangle ping | repeated tension marker |
| Damage | noisy descending thud | only broad/noisy event |
| State change | short dark chirp | unique fixed pitch stamp |

### 5.2 Cross-Game Variation Plan

- Vary from previous games by using triangle-dominant low hum, narrower pitch band, and sparse rhythm spacing.
- Keep motif-first variation with micro detune only; avoid pure random timbre swaps.

## 6. Checklist

- [x] Core events are distinguishable.
- [x] Sound style follows visual tags.
- [x] Dynamic response exists (combo/heat/near-miss).
- [x] Semantic mapping is fixed within game.
- [x] Cross-game variation plan is explicit.
