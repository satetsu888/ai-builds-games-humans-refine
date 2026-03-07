extends RefCounted
class_name HudRenderer

const FONT_NUMERIC_PATH := "res://assets/fonts/NotoSansMono-Bold.ttf"
const FONT_EMPHASIS_PATH := "res://assets/fonts/DejaVuSans-Bold.ttf"

var _numeric_font_cache: Font
var _emphasis_font_cache: Font

func draw_hud(canvas: CanvasItem, state: Variant, popups: Array, viewport: Vector2, score_pulse: float, suppress_game_over_message: bool = false) -> void:
	var numeric_font: Font = _resolve_font(FONT_NUMERIC_PATH, true)
	var emphasis_font: Font = _resolve_font(FONT_EMPHASIS_PATH, false)
	if numeric_font == null or emphasis_font == null:
		return
	var pulse := 1.0 + score_pulse * 0.24
	var score_size := int(round(36.0 * pulse))
	var score_color := Color(0.94, 0.98, 1.0, 0.96)
	canvas.draw_string(numeric_font, Vector2(0.0, 38.0), str(state.score), HORIZONTAL_ALIGNMENT_CENTER, viewport.x, score_size, Color(0.10, 0.14, 0.20, 0.55))
	canvas.draw_string(numeric_font, Vector2(0.0, 36.0), str(state.score), HORIZONTAL_ALIGNMENT_CENTER, viewport.x, score_size, score_color)

	for popup in popups:
		var t := float(popup.get("t", 0.0))
		var duration := float(popup.get("duration", 0.5))
		var p := clampf(t / maxf(duration, 0.001), 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - p, 3.0)
		var rise := 30.0 * ease_out
		var pos := Vector2(popup.get("pos", viewport * 0.5))
		var text := str(popup.get("text", ""))
		var size := int(popup.get("size", 28))
		var color: Color = Color(popup.get("color", Color(0.95, 0.95, 1.0, 1.0)))
		canvas.draw_string(emphasis_font, Vector2(pos.x, pos.y - rise + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0.10, 0.14, 0.20, color.a * 0.55))
		canvas.draw_string(emphasis_font, Vector2(pos.x, pos.y - rise), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)

	if state.game_over and not suppress_game_over_message:
		var msg := "CHAIN BROKEN"
		canvas.draw_string(emphasis_font, Vector2(0.0, viewport.y * 0.50), msg, HORIZONTAL_ALIGNMENT_CENTER, viewport.x, 40, Color(1.0, 0.88, 0.76, 0.96))

func _resolve_font(path: String, numeric_slot: bool) -> Font:
	var cache := _numeric_font_cache if numeric_slot else _emphasis_font_cache
	if cache != null:
		return cache
	var loaded := ResourceLoader.load(path)
	var font := loaded as Font
	if font == null:
		font = ThemeDB.fallback_font
	if numeric_slot:
		_numeric_font_cache = font
	else:
		_emphasis_font_cache = font
	return font
