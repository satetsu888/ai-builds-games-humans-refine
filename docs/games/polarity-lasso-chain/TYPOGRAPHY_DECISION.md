# Typography Decision

## Phase 5 Status

- Font selection: Applied for gameplay UI.
- Runtime fonts:
  - numeric HUD: `assets/fonts/NotoSansMono-Bold.ttf`
  - emphasis/event popup: `assets/fonts/DejaVuSans-Bold.ttf`
- Role split applied:
  - `numeric`: top-center score number (always visible)
  - `emphasis`: capture and combo popup texts (event-only)
  - `info`: non-essential debug metrics removed from HUD
- HUD policy:
  - no `SCORE` label text
  - no constant `HEAT/DIFF/NEAR` debug readout
  - emphasis appears only on scoring moments and fades quickly

## License Reflection

- Bundled font files under `assets/fonts/` only for selected pair.
- Added license texts under `licenses/fonts/`.
- Reflected entries in `THIRD_PARTY_LICENSES.md`.
