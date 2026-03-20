# Visual Design: Fractal Shatter

**Visual Tags**: #background-fractal-motif

## 1. Visual Concept

**"Crystalline geometry shattering against deep recursive darkness"**

The screen is a dark void filled with subtle, slowly shifting fractal patterns. Bright, sharp-edged crystalline shapes fall through this space, cracking apart into self-similar children on impact with the player's slash. The contrast between the dark, intricate background and the bright, clean foreground objects creates readability and atmosphere simultaneously.

## 2. Color Palette

| Role | Color | Hex | Usage |
| :--- | :--- | :--- | :--- |
| Background | Deep indigo-black | #0A0A1A | Base background, creates depth |
| Player | Soft white with warm glow | #F0E8D8 | Player circle — warmest element on screen, always visible |
| Crystal (Gen 1) | Ice blue | #88CCEE | Original crystals — cool, solid, clearly "thing to interact with" |
| Crystal (Gen 2) | Cyan-white | #AAEEFF | Split fragments — brighter than parent, signals "derived from crystal" |
| Crystal (Gen 3) | Bright gold-white | #FFEEAA | Smallest fragments — hottest color, signals "valuable / final" |
| Danger / Shockwave | Warm red-orange | #FF6644 | Ground impact debris — immediately reads as "danger" |
| Combo accent | Yellow → Orange → Red | #FFDD44 → #FF8833 → #FF4422 | Player outline shifts with combo, visible but not distracting |

## 3. Object Rendering Specifications

### Player Circle
- Solid filled circle with soft outer glow (2-3px halo)
- Warm white (#F0E8D8) base color — distinctly warmer than any crystal
- Subtle breathing animation: scale oscillates ±3% at ~1.5Hz
- Combo state: outline color shifts through combo accent palette
- On death: circle shatters outward into 8-12 warm-colored particles

### Crystal (Gen 1)
- Fractal polygon shape: 6-8 sided polygon with recursive edge detail (one level of Koch-curve-like perturbation on each edge)
- Solid ice-blue fill with thin bright outline (1px, slightly lighter than fill)
- Subtle rotation as it falls (~15°/s) — feels like it has mass
- Size: ~50px diameter

### Fragment (Gen 2)
- Same fractal polygon shape but smaller (~30px), visibly a "piece" of the parent
- Brighter cyan-white fill — color shift signals "this came from a crystal"
- Faster rotation (~30°/s) — lighter, more energetic
- Faint afterimage trail (2-3 ghost frames) during parabolic arc

### Fragment (Gen 3)
- Smallest fractal polygon (~18px), brightest color (gold-white)
- Strong glow halo — "valuable" signal
- Fastest rotation (~60°/s)
- Visible trail during arc (4-5 ghost frames, brighter than gen-2 trails)

### Slash Effect
- Bright white vertical line from player upward
- Flash appears for ~0.15s, then fades
- Width: ~6px at base, tapers to 2px at top
- At combo tiers, line color matches combo accent (yellow/orange/red)
- Brief bloom/glow around the line

### Ground Shockwave
- Semicircular burst of sharp triangular debris particles along the ground
- Color: warm red-orange (#FF6644) — sharply contrasts with cool crystal colors
- Particles skid outward, shrinking and fading over 0.3s
- Size proportional to crystal generation (gen 1 = wide, gen 3 = narrow)

### Background
- Base: deep indigo-black (#0A0A1A)
- Fractal overlay: subtle Sierpinski-triangle-like recursive pattern, drawn with very low opacity (~5-8%) lines
- Pattern slowly shifts/breathes (vertices drift slightly at ~0.5Hz)
- As difficulty increases: fractal density increases (more recursive depth), opacity rises slightly (8→12%)
- No sudden color changes — the background is atmospheric, never distracting

## 4. Background & Environment

**Layer structure** (back to front):
1. **Background**: Solid dark fill + animated fractal pattern overlay (very low contrast)
2. **Ground plane**: Thin horizontal line near bottom (~10% from bottom edge). Subtle gradient below it (slightly lighter than background) to ground the scene.
3. **Crystal layer**: All falling crystals and fragments. Primary gameplay focus.
4. **Player layer**: Player circle. Always rendered on top of ground, below effects.
5. **Effects layer**: Slash flash, shockwave debris, sparkle bursts, combo glow. Highest visual priority.

The fractal background pattern creates ambient visual richness without competing with gameplay elements. Its low opacity and cool color ensure crystals and the player remain clearly readable.

## 5. Feedback Effects

| Event | Visual Response | Intensity |
| :--- | :--- | :--- |
| Slash hit (score) | Crystal cracks with bright flash at contact point. Fragments launch with motion blur/trail. Brief screen-wide brightness pulse (subtle, ~5% for 0.1s). Sparkle particles at crack point. | Med — scales with generation (gen 3 burst = High) |
| Gen 3 burst (big score) | Fragment explodes into 8-12 gold sparkle particles that arc outward and fade. Brief additive glow at burst point. Screen flash slightly stronger than normal slash. | High |
| Combo step | Player outline color advances (white→yellow→orange→red). Brief radial pulse from player (expanding ring, fades in 0.2s). Slash line color matches new combo tier. | Low-Med — grows with combo count |
| Ground shockwave | Red-orange debris triangles burst outward along ground. Brief warm-tinted flash at impact point. Micro screen shake (1-2px, 0.1s). | Med — scales with crystal size |
| Near miss (crystal passes close) | Brief white rim flash on player circle (0.1s). Subtle camera nudge (0.5px). | Low |
| Game over | Player circle shatters into warm particles. Screen shake (6-8px, 0.3s). Brief chromatic aberration (RGB split). All game objects freeze briefly (0.15s hitstop) then fade. Background dims. | High |
| Difficulty increase | Background fractal pattern gains one level of recursive detail. Subtle, no abrupt change. | Low (ambient) |

## 6. Causal Visibility Map

| Mechanic | Cause | Consequence | Visual Bridge |
| :--- | :--- | :--- | :--- |
| Slash splits crystal | Player fires vertical slash through crystal | Crystal cracks into 2 smaller fragments | Flash at contact point → crack line appears on crystal → fragments separate from the crack, launching outward with trails. Material continuity: fragments look like pieces of the parent (same shape, similar color, smaller). |
| Fragments fly in arcs | Crystal splits | Fragments arc upward and outward, then fall | Afterimage trail shows the parabolic path in real time. Motion is smooth and follows visible gravity. Player can read the arc shape to predict landing point. |
| Smaller = faster | Crystal generation increases | Fragments are smaller, fall faster, glow brighter | Size visibly decreases. Brightness/glow increases with generation (cold→warm shift). Speed difference is visible through trail length (faster = longer trail). |
| Ground shockwave | Crystal/fragment hits ground | Debris skids along ground | Impact flash at contact point → debris particles emerge FROM the crystal → skid outward along ground surface. Color shifts to red-orange to signal danger. Spatial continuity: debris radiates from impact point. |
| Gen 3 burst | Slash hits gen-3 fragment | Sparkle explosion (no debris) | Fragment flashes bright → explodes into gold sparkle particles that arc outward and fade. Clearly different from splitting (sparkles vs. solid fragments). Signals "this is the end of the chain." |
| Combo glow | Rapid consecutive slashes | Player glows brighter, slash changes color | Player outline color shifts with each combo step. Gradual, connected to the slash events. Player visually "heats up" with activity. |
| Contact = death | Crystal material touches player | Player pops | Immediate flash at contact point → player shatters into particles → screen shake + chromatic split. The shattering mirrors how crystals shatter — same visual language, applied to the player. |

## 7. AI-Generated Look Suppression Rules

### 7.1 Visual Hierarchy Rules

- Player-controlled: Warm white circle — only warm-toned filled circle on screen
- Challenge element: Cool blue/cyan fractal polygons — cold palette, jagged edges
- Goal element: Gold-white gen-3 fragments — brightest objects, signal "value"
- 2-second recognition check: Warm circle at bottom = me. Cold jagged shapes falling = threat/target. Bright gold small things = valuable. Red on ground = danger.

### 7.2 Limits on Familiar Template Symbols

- Adopted familiar elements (max 2): Circle for player (universal), Red for danger (universal)
- Replaced unique element: Crystals are fractal polygons (not generic circles, squares, or sprites). Shockwave is angular debris (not generic expanding ring).

### 7.3 UI-Independent Feedback

| Event | Non-UI visual response | Intensity (Low/Med/High) |
| :--- | :--- | :--- |
| Score | Crystal crack flash + fragment launch trails + sparkles | Med |
| Failure | Red-orange ground debris burst + screen micro-shake | Med |
| Near miss | White rim flash on player + subtle camera nudge | Low |

### 7.4 Composition and Gaze Guidance

- Initial focal point: Player circle at bottom-center (warmest, brightest solid shape on the dark background)
- Visual flow: Eyes track from player upward to falling crystals (top-down threat direction matches visual attention flow)
- Anti-center-clutter implementation: Player is at bottom-center, not screen center. Crystals spawn across full width at top. The vertical midscreen is open space where arcs play out — action is distributed, not concentrated.

## 8. Relationship with Visual Tags

**#background-fractal-motif** (the sole visual tag) influenced the design in multiple ways:

1. **Crystal shapes**: Fractal polygons with recursive edge detail — directly derived from "fractal motif." Each generation is a self-similar smaller copy, which IS fractal repetition.
2. **Background pattern**: Animated Sierpinski-like recursive geometry — literal fractal motif as atmosphere.
3. **Splitting mechanic synergy**: The game's core mechanic (crystals splitting into self-similar children) is itself a fractal process. The visual tag and the gameplay mechanic reinforce each other naturally.
4. **Difficulty scaling**: More fractal detail in background as difficulty rises — the visual complexity mirrors the gameplay complexity.

**Deviation from literal interpretation**: Rather than making everything fractal (which would hurt readability), the fractal motif is concentrated in crystal shapes and background atmosphere, while the player and effects use simple, clean geometry for contrast. The fractal quality serves both aesthetics and gameplay communication (self-similar splitting = core mechanic).
