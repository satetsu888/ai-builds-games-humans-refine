# Sound Design: Fractal Shatter

**Visual Tags (Sound Source)**: #background-fractal-motif

## 1. Audio Concept

**"Crystalline chimes shattering into bright resonant fragments"**

Derived from the fractal-motif visual tag: fractal patterns suggest recursive, layered, self-similar structures. Sonically, this translates to resonant harmonic tones (sine harmonics: fundamental + 3rd + 5th) that break apart into shorter, higher-pitched versions of themselves — mirroring how crystals visually split into smaller self-similar pieces. The sound world is clean and crystalline, not noisy or gritty.

## 2. Waveform Palette

| Role | Waveform | Parameters | Usage |
| :--- | :--- | :--- | :--- |
| Primary tone | Sine + 3rd harmonic (×3 freq, 0.3 amp) | Base freq: 400-1200Hz depending on event | Crystal interactions, score, combo — bright, bell-like |
| Impact texture | Short noise burst (white noise, 10-30ms) | Bandpass filtered 2-6kHz | Slash contact, ground impact — percussive crack |
| Failure tone | Sine with slow downward pitch sweep | Start: 300Hz → End: 80Hz over 500ms | Game over, negative events — descending, final |

## 3. Sound Event Specifications

| Event | Waveform | Frequency | Duration | Envelope | Dynamic Parameter |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Slash (gen 1 hit) | Noise burst + sine harmonic | Noise: 3kHz BP, Sine: 500Hz + 1500Hz | 80ms | Sharp attack (2ms), fast decay (78ms) | — |
| Slash (gen 2 hit) | Noise burst + sine harmonic | Noise: 4kHz BP, Sine: 700Hz + 2100Hz | 70ms | Sharp attack (2ms), fast decay (68ms) | Pitch higher than gen 1 (smaller = higher) |
| Slash (gen 3 burst) | Sine harmonic chord + shimmer | Sine: 900Hz + 1350Hz + 2700Hz | 150ms | Sharp attack (2ms), sustain (50ms), release (100ms) | Brightest, most resonant. Combo: pitch += combo × 30Hz |
| Combo step | Short sine ping | 800Hz + combo × 100Hz | 50ms | Instant attack, fast decay | Pitch rises with each combo step |
| Ground shockwave | Noise burst + low sine | Noise: 1-3kHz BP (wide), Sine: 120Hz | 120ms | Attack 5ms, decay 115ms | Amplitude scales with crystal size (gen 1 = loud, gen 3 = soft) |
| Near miss | Filtered noise whisper | Noise: 2-5kHz, very low volume | 40ms | Soft attack (5ms), fast fade | — |
| Game over | Descending sine + noise | Sine: 300Hz → 80Hz sweep, Noise: broadband | 500ms | Attack 5ms, sustain 200ms, fade 295ms | — |
| Difficulty shift | Very subtle sine tone shift | Low sine: 60Hz, barely audible | 300ms | Slow attack (100ms), slow fade (200ms) | — |

## 4. Relationship with Visual Tags

**#background-fractal-motif → Sound Direction:**

- **Recursive/self-similar** → Harmonic sine tones (fundamental + overtones create natural "self-similar" frequency relationships). Crystal hits at different generations use the SAME harmonic structure but at different base frequencies — the sound is a "smaller copy" of itself, mirroring the visual fractal splitting.
- **Geometric precision** → Clean sine waves rather than noisy or organic sounds. Crystalline, bell-like quality. Sharp transients.
- **Pattern richness from simple rules** → Only 2 waveform types (sine harmonics + noise bursts) combine to create all game sounds. Simple palette, rich output — like fractal generation itself.

## 5. Semantic Lock & Cross-Game Variation

### 5.1 In-Game Semantic Lock

| Event Family | Timbre Family | Why it is recognizable |
| :--- | :--- | :--- |
| Score (slash hits) | Bright sine harmonics + noise transient | Upward pitch, clean bell-like ring. Always paired with visual crack. Higher generations = higher pitch = "more valuable" is intuitive. |
| Tension (combo) | Rising sine pings | Each combo step adds pitch. Ascending tone = escalation. Player hears their combo state without looking at visuals. |
| Failure (shockwave, game over) | Low sine + broadband noise | Descending pitch, heavier noise component. Contrasts sharply with bright score sounds. "Something went wrong" is immediate. |
| State change (difficulty shift) | Deep, barely audible sine pulse | Subtle, doesn't interrupt gameplay. Background atmospheric shift mirrors background visual shift. |

### 5.2 Cross-Game Variation Plan

- **Waveform**: Sine harmonics (3rd + 5th overtones) — chosen for crystalline quality. Other games might use square/triangle for different visual tags.
- **Pitch range**: 400-2700Hz for scoring events (mid-bright). Crystalline visuals demand bright mid-highs, not bass-heavy or tinny extremes.
- **Envelope**: Very short attacks (2-5ms) with fast decays. Matches the sharp, cracking visual of crystal fracture. A glow-themed game would use softer attacks.
- **Modulation**: Harmonic layering (additive synthesis) rather than FM/AM. Creates the "bell-like" quality that fits geometric crystal visuals.
- **Rhythm**: Sound events mirror the "slash → arc → slash" rhythm of gameplay. Bursts of sound during slash chains, silence during movement/planning. Other games might have continuous drone or rhythmic backing.
