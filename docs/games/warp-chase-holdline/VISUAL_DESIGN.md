# Visual Design: Warp Chase Holdline

**Visual Tags**: #geometry-primitive-modularity, #analog-line-noise-warp

## 1. Visual Concept

"Pursuit machines built from geometric modules glide across a line-world that is subtly warped by noise."

## 2. Color Palette

| Role | Color Name | Hex | Usage |
|:---|:---|:---|:---|
| Player | Ice Cyan | `#76F7FF` | Player outline and thrust heading |
| Chaser | Hot Coral | `#FF5F6D` | Chaser outline |
| Background | Deep Navy | `#0D1321` | Base background |
| Positive feedback | Acid Lime | `#C7FF4F` | Score gain and combo display |
| Warning | Amber | `#FFC857` | Near-danger ring |

## 3. Object Rendering Specs

- Player: composite primitive of arc + forward triangle
- Chaser: rotated square + small circular core
- Ring effect: concentric line rings
- Use line-based `_draw()` rendering; apply slight time-dependent noise at line vertices for subtle warping

## 4. Background and Environment Design

- Low-contrast grid-line background
- Slightly time-shift grid endpoints so the scene breathes even when static
- Layers:
  - Background: noise-warped grid
  - Midground: player/chasers
  - Foreground: near-miss rings and score pops

## 5. Feedback Effects

| Event | Visual response | Tag reference |
|:---|:---|:---|
| Score gain | Lime ring expansion at collision point + score pop | geometry + analog |
| Damage / Game over | Red full-screen flash + thicker player outline | analog-line-noise-warp |
| Near miss | Brief thin amber ring | geometry-primitive-modularity |
| State change (difficulty rise) | Slightly increase background line-noise amplitude | analog-line-noise-warp |

## 6. Relation to Visual Tags

- `geometry-primitive-modularity`:
  - Unify player/enemy/UI effects with circles/lines/squares only
  - Preserve recognition through shape combinations
- `analog-line-noise-warp`:
  - Add subtle endpoint noise to avoid sterile visuals
  - Increase warp amplitude during danger proximity for stronger danger recognition

## 7. Typography Implementation (UI/HUD)

- Define Theme-token-equivalent structure in script and unify color/size/decoration by role.
- Font setup:
  - Body: `DejaVuSans.ttf`
  - Heading: `DejaVuSans-Bold.ttf`
  - Numeric: `NotoSansMono-Bold.ttf`
- Role separation:
  - Heading (`GAME OVER`, `CHAIN`)
  - Info (event notices)
  - Numeric emphasis (score number always visible)
- Unify text drawing via `_draw_styled_text()` with subtle shadow + 1px outline.
- `CHAIN` and `GAME OVER` use `_draw_emphasis_text()` with slight cyan/coral split for analog flavor.
- On score gain, enlarge numeric size briefly; do not show label strings.
- Keep always-on HUD to score numeric only; show `SHIELD/WAVE` as short event notifications.
- Added title screen to validate the three-role font setup (`display/base/numeric`) in one view.

## 8. Anti-AI-Generic Rules

### 8.1 Visual Hierarchy Rule

- Protagonist: player uses thickest cyan line + speed trail + proximity arcs
- Danger: chaser increases outline width and surrounding halo by distance
- Reward: enemy collision displays lime cross + ring diffusion at impact point
- 2-second recognition check: distinguishable by color temperature and reaction type (cool = player, warm = danger, lime = score)

### 8.2 Template-Symbol Upper Bound

- Adopted familiar elements (max 2): grid background, geometric objects
- Replaced unique elements: threat link lines, distance-dependent halos, event-only peripheral danger veil

### 8.3 UI-Independent Feedback

| Event | Non-UI visual response | Intensity (low/med/high) |
|:---|:---|:---|
| Score | Collision cross, ring diffusion, lime afterglow | Med |
| Damage | Red screen flash, shield reaction ring | High |
| Near miss | Amber arc around player + increased danger veil | Med |

### 8.4 Composition and Gaze Guidance

- Initial focal point: cool core and speed trail around player
- Screen flow: threat-link lines from nearby chasers indicate danger direction
- Anti-center-clutter: shift gaze from fixed center toward threat direction using background density and danger-edge effects
