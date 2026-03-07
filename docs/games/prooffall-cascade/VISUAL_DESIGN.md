# Visual Design: Prooffall Cascade

## 1. Concept

Misregistered letterpress platforms hanging over a proofing void.

## 2. Palette

| Role | Color | Use |
| :--- | :--- | :--- |
| Background haze | `#101018` | deep field |
| Player / neutral ink | `#F5EEDC` | runner body and highlights |
| Glyph A family | `#FF7A59` | hot slab color |
| Glyph E family | `#5ED4C8` | cool slab color |
| Glyph O family / warning split | `#FFD166` | third glyph and collapse accent |

## 3. Drawing Specification

- Slabs are thick rectangles with a central glyph line motif, not text labels.
- Each glyph family has a distinct silhouette imprint so recognition works without reading.
- Bright edges receive a light chromatic-offset duplicate during pulse and pressure spikes only.
- The player outline is clean and bright so it remains the primary read over the field.

## 4. Feedback Design

- Score: collapsing slabs eject offset fragments and a short outward ring.
- Damage/death: the runner desaturates and splits into RGB ghosts while dropping into the void.
- Jam warning: when a column approaches jam timeout, slab edges tremble and top-edge warning glow intensifies.
- State change: stepping onto a new glyph family recolors the player outline and brightens all matching slabs.

## 5. Layering

- Background: soft vertical gradient with faint scanline noise.
- Play field: slab stacks and the player.
- Foreground: collapse rings, offset ghosts, and compact score numerals near the event source.

## 6. Anti-Template Rules

- Avoid generic neon HUD panels; feedback must live on terrain and motion.
- Keep familiar typography usage to one element: numerals only appear as short-lived world particles.
- Do not center-stack all activity; the tallest columns should drift left/right over time.

## 7. AI-Generated Look Suppression Rules

### 7.1 Visual Hierarchy Rules

- Protagonist: bright ivory runner with the strongest luminance contrast.
- Threat: the void band and collapsing flashing slabs.
- Reward: local collapse rings and floating numeric shards at the blast site.
- 2-second recognition check: player, safe slab, and void hazard are separable by brightness and motion before any text is read.

### 7.2 Limits on Familiar Template Symbols

- Adopted familiar elements (max 2): score numerals, rectangular terrain tiles
- Replaced unique element: tiles carry abstract letterpress imprints instead of generic gem or brick icons

### 7.3 UI-Independent Feedback

| Event | Non-UI visual response | Intensity (Low/Med/High) |
| :---- | :--------------------- | :----------------------- |
| Score | slab fragments + local RGB ring | Med |
| Damage | player body loses fill and trails downward ghosts | High |
| Jam warning | slab edges jitter and top edge flashes warm | Low |

### 7.4 Composition and Gaze Guidance

- Initial focal point: the bright runner slightly above center.
- Visual flow: eye moves from runner to highlighted matching slabs, then down to the glowing void.
- Anti-center-clutter implementation: tallest columns are biased away from center and score particles stay local to their collapse origin.
