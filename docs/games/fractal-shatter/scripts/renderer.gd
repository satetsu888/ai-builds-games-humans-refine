extends Node2D

var game_ref: Node = null

var _poly_cache := {}
var _bg_points: Array = []
var _bg_time := 0.0

const SW := 540.0
const SH := 960.0
const GAME_H := 720.0
const GROUND := 680.0
const CTRL_TOP := 740.0

func _ready() -> void:
	_generate_bg_points()

func _generate_bg_points() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 42
	for i in range(40):
		_bg_points.append({
			"x": r.randf_range(0.0, SW),
			"y": r.randf_range(0.0, GAME_H),
			"size": r.randf_range(15.0, 60.0),
			"phase": r.randf() * TAU,
		})

func _process(delta: float) -> void:
	_bg_time += delta
	queue_redraw()

func _draw() -> void:
	if game_ref == null:
		return
	var state: String = game_ref.game_state
	_draw_background()
	match state:
		"title":
			_draw_title()
		"playing":
			_draw_game()
		"game_over":
			_draw_game()
			_draw_game_over_overlay()

# --- Background ---
func _draw_background() -> void:
	draw_rect(Rect2(0, 0, SW, SH), Color("#0A0A1A"))
	draw_rect(Rect2(0, GAME_H, SW, SH - GAME_H), Color("#080810"))
	var w = game_ref.world
	var diff := 1
	if w != null:
		diff = w.difficulty()
	var alpha := lerpf(0.04, 0.08, clampf(float(diff) - 1.0, 0.0, 4.0) / 4.0)
	var col := Color(0.3, 0.35, 0.5, alpha)
	for p in _bg_points:
		var ox := sin(_bg_time * 0.3 + float(p["phase"])) * 3.0
		var oy := cos(_bg_time * 0.25 + float(p["phase"])) * 3.0
		var cx := float(p["x"]) + ox
		var cy := float(p["y"]) + oy
		var sz: float = p["size"]
		var pts := PackedVector2Array([
			Vector2(cx, cy - sz * 0.5),
			Vector2(cx - sz * 0.43, cy + sz * 0.25),
			Vector2(cx + sz * 0.43, cy + sz * 0.25),
			Vector2(cx, cy - sz * 0.5),
		])
		draw_polyline(pts, col, 1.0)

func _draw_title() -> void:
	var font := ThemeDB.fallback_font
	var cx := SW / 2.0
	draw_string(font, Vector2(20, 250), "FRACTAL SHATTER", HORIZONTAL_ALIGNMENT_CENTER, SW - 40, 28, Color("#88CCEE"))
	var ctrl_col := Color("#A0A8B8")
	draw_string(font, Vector2(cx - 90, 350), "< / A  :  Move Left", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ctrl_col)
	draw_string(font, Vector2(cx - 90, 375), "> / D  :  Move Right", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ctrl_col)
	draw_string(font, Vector2(cx - 90, 400), "SPACE / Z  :  Slash", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ctrl_col)
	# Start button
	var btn_rect := Rect2(cx - 90, 470, 180, 50)
	var blink := fmod(_bg_time, 1.2) < 0.8
	var btn_col := Color("#FFDD44", 0.9) if blink else Color("#FFDD44", 0.6)
	draw_rect(btn_rect, Color(0.15, 0.12, 0.05, 0.6))
	draw_rect(btn_rect, btn_col, false, 2.0)
	draw_string(font, Vector2(cx - 90, 502), "START", HORIZONTAL_ALIGNMENT_CENTER, 180, 24, btn_col)

# --- Game ---
func _draw_game() -> void:
	var w = game_ref.world
	if w == null:
		return
	_draw_ground()
	_draw_ground_debris(w)
	_draw_crystals(w)
	_draw_slash_effects(w)
	_draw_sparkles(w)
	_draw_player(w)
	_draw_hud(w)
	_draw_virtual_buttons()

func _draw_ground() -> void:
	draw_line(Vector2(0, GROUND), Vector2(SW, GROUND), Color(0.2, 0.22, 0.3, 0.6), 1.0)
	for i in range(3):
		var y := GROUND + float(i) * 8.0
		var a := 0.04 * (1.0 - float(i) / 3.0)
		draw_line(Vector2(0, y), Vector2(SW, y), Color(0.15, 0.17, 0.25, a), 8.0)

# --- Crystals ---
func _draw_crystals(w: RefCounted) -> void:
	var kill_pos := Vector2.ZERO
	if w.game_over:
		kill_pos = w.death_hit_pos as Vector2
	for c in w.crystals:
		var gen := int(c["generation"])
		var cx := float(c["x"])
		var cy := float(c["y"])
		var r := float(c["radius"])
		var rot := float(c["rotation"])
		var seed_v := int(c.get("poly_seed", 0))
		var is_killer := kill_pos != Vector2.ZERO and Vector2(cx, cy).distance_to(kill_pos) < r + 2.0
		var poly := _get_polygon(seed_v, r, gen)
		var color := Color("#882222") if is_killer else _crystal_color(gen)
		var outline_color := Color("#FF4422") if is_killer else _crystal_outline_color(gen)
		var xform := Transform2D(rot, Vector2(cx, cy))
		draw_set_transform_matrix(xform)
		draw_colored_polygon(poly, color)
		var outline := poly.duplicate()
		outline.append(poly[0])
		draw_polyline(outline, outline_color, 2.0 if is_killer else 1.5)
		if is_killer:
			draw_circle(Vector2.ZERO, r * 1.5, Color("#FF4422", 0.25))
		elif gen >= 2:
			draw_circle(Vector2.ZERO, r * 1.4, Color(outline_color, 0.15 if gen == 2 else 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _crystal_color(gen: int) -> Color:
	match gen:
		1: return Color("#506880")
		2: return Color("#6A9AB8")
		3: return Color("#B8A860")
	return Color.WHITE

func _crystal_outline_color(gen: int) -> Color:
	match gen:
		1: return Color("#88CCEE")
		2: return Color("#AAEEFF")
		3: return Color("#FFEEAA")
	return Color.WHITE

func _get_polygon(seed_v: int, radius: float, gen: int) -> PackedVector2Array:
	var key := seed_v * 100 + gen
	if _poly_cache.has(key):
		return _poly_cache[key]
	var poly := _generate_fractal_polygon(radius, 7 + gen, 0.25, seed_v)
	_poly_cache[key] = poly
	return poly

func _generate_fractal_polygon(radius: float, num_points: int, jitter: float, s: int) -> PackedVector2Array:
	var r := RandomNumberGenerator.new()
	r.seed = s
	var pts := PackedVector2Array()
	for i in range(num_points):
		var angle := float(i) / float(num_points) * TAU
		var rad := radius * (1.0 + r.randf_range(-jitter, jitter))
		pts.append(Vector2(cos(angle) * rad, sin(angle) * rad))
	return pts

# --- Player ---
func _draw_player(w: RefCounted) -> void:
	var px: float = w.player_x
	var py: float = GROUND - 16.0
	var r: float = 16.0
	draw_circle(Vector2(px, py), r + 3.0, Color("#E0D8C8", 0.15))
	draw_circle(Vector2(px, py), r, Color("#F0E8D8"))
	draw_arc(Vector2(px, py), r, 0, TAU, 32, Color("#E0D8C8"), 1.5)
	if not w.game_over:
		var breath := sin(_bg_time * 3.0) * 1.5
		draw_arc(Vector2(px, py), r + breath, 0, TAU, 32, Color("#E0D8C8", 0.08), 1.0)

func _combo_color(combo_count: int) -> Color:
	if combo_count <= 1:
		return Color("#E0D8C8")
	elif combo_count <= 3:
		return Color("#FFDD44")
	elif combo_count <= 6:
		return Color("#FF8833")
	else:
		return Color("#FF4422")

func _sparkle_color(offset: float) -> Color:
	var t := fmod(_bg_time * 3.0 + offset, 1.0)
	if t < 0.33:
		return Color("#FFFAE0").lerp(Color("#FFD866"), t / 0.33)
	elif t < 0.66:
		return Color("#FFD866").lerp(Color("#FFEECC"), (t - 0.33) / 0.33)
	else:
		return Color("#FFEECC").lerp(Color("#FFFAE0"), (t - 0.66) / 0.34)

# --- Slash effects ---
func _draw_slash_effects(w: RefCounted) -> void:
	for e in w.slash_effects:
		var age := float(e["age"])
		var dur := float(e["duration"])
		var progress := age / dur
		var cx := float(e["x"])
		var cy := float(e["y"])
		var reach := float(e["reach"])
		var combo := int(e["combo"])
		var has_sparkle := combo >= 2
		var trail_col := _combo_color(combo)
		var tilt := sin(cx * 3.7) * 8.0 + 5.0
		var arc_start := Vector2(cx - reach, cy + tilt)
		var arc_end := Vector2(cx + reach, cy - tilt)
		var tip_t := minf(progress * 2.5, 1.0)
		var tip_hold := progress >= 0.4 and progress < 0.6
		var segments := 14
		var full_arc := PackedVector2Array()
		for i in range(segments + 1):
			var t := float(i) / float(segments)
			var base := arc_start.lerp(arc_end, t)
			var curve := sin(t * PI) * 14.0
			full_arc.append(Vector2(base.x, base.y - curve))
		# Trail
		var trail_end_idx := int(tip_t * float(segments))
		if trail_end_idx >= 1:
			for i in range(trail_end_idx):
				var t := float(i) / float(trail_end_idx)
				var trail_alpha := t * t * (1.0 - progress * 0.8)
				var p0 := full_arc[i]
				var p1 := full_arc[i + 1]
				var width := lerpf(1.0, 3.5, t)
				var seg_col: Color = trail_col
				seg_col.a = trail_alpha
				draw_line(p0, p1, seg_col, width)
				if t > 0.4:
					draw_line(p0, p1, Color(seg_col, trail_alpha * 0.25), width + 7.0)
		# Blade tip
		var show_tip := (tip_t < 1.0 and trail_end_idx <= segments) or tip_hold
		if show_tip:
			var tip_idx := segments if tip_hold else mini(trail_end_idx, segments)
			var tip_pos := full_arc[tip_idx]
			var tip_alpha := 1.0
			if tip_hold:
				tip_alpha = 1.0 - (progress - 0.4) / 0.2 * 0.3
			else:
				tip_alpha = 1.0 - progress * 0.5
			var prev_idx := maxi(tip_idx - 1, 0)
			var tip_dir := (full_arc[tip_idx] - full_arc[prev_idx]).normalized()
			var tip_perp := Vector2(-tip_dir.y, tip_dir.x)
			var tip_pts := PackedVector2Array([
				tip_pos + tip_dir * 10.0,
				tip_pos + tip_perp * 3.5,
				tip_pos - tip_dir * 4.0,
				tip_pos - tip_perp * 3.5,
			])
			draw_colored_polygon(tip_pts, Color(1, 1, 1, tip_alpha))
			draw_colored_polygon(PackedVector2Array([
				tip_pos + tip_dir * 16.0, tip_pos + tip_perp * 7.0,
				tip_pos - tip_dir * 8.0, tip_pos - tip_perp * 7.0,
			]), Color(trail_col, tip_alpha * 0.3))
			if has_sparkle:
				var num_sparkles := mini(combo, 8)
				for si in range(num_sparkles):
					var sp_angle := _bg_time * 12.0 + float(si) * TAU / float(num_sparkles)
					var sp_dist := 12.0 + sin(_bg_time * 8.0 + float(si) * 2.0) * 6.0
					var sp_pos := tip_pos + Vector2(cos(sp_angle), sin(sp_angle)) * sp_dist
					var sp_col := _sparkle_color(float(si) * 0.12)
					sp_col.a = tip_alpha * 0.8
					draw_circle(sp_pos, 2.0, sp_col)
		# Fade
		if progress >= 0.6:
			var fade := 1.0 - (progress - 0.6) / 0.4
			if fade > 0.0:
				var fade_col := trail_col
				fade_col.a = fade * 0.5
				draw_polyline(full_arc, fade_col, 2.0)
				draw_polyline(full_arc, Color(fade_col, fade * 0.15), 8.0)
		# Trail sparkles
		if has_sparkle and trail_end_idx >= 2:
			var num_trail_sparkles := mini(combo * 2, 12)
			for si in range(num_trail_sparkles):
				var st := fmod(_bg_time * 5.0 + float(si) * 0.37, 1.0)
				var arc_idx := int(st * float(trail_end_idx - 1))
				if arc_idx >= full_arc.size() - 1:
					continue
				var base_pos := full_arc[arc_idx].lerp(full_arc[arc_idx + 1], fmod(st * float(trail_end_idx), 1.0))
				var offset := Vector2(sin(_bg_time * 10.0 + float(si) * 3.0) * 10.0, cos(_bg_time * 8.0 + float(si) * 4.0) * 8.0)
				var sp_col := _sparkle_color(float(si) * 0.08)
				sp_col.a = (1.0 - progress) * 0.6
				draw_circle(base_pos + offset, 1.5, sp_col)

# --- Ground debris ---
func _draw_ground_debris(w: RefCounted) -> void:
	var kill_pos := Vector2.ZERO
	if w.game_over:
		kill_pos = w.death_hit_pos as Vector2
	for d in w.ground_debris:
		var age := float(d["age"])
		var lt := float(d["lifetime"])
		var fade_start := 0.6
		var alpha := 1.0
		if age / lt > fade_start:
			alpha = 1.0 - (age / lt - fade_start) / (1.0 - fade_start)
		var x := float(d["x"])
		var y := float(d["y"])
		var r := float(d["radius"])
		var gen := int(d["generation"])
		var is_killer := kill_pos != Vector2.ZERO and Vector2(x, y).distance_to(kill_pos) < r + 2.0
		var col := _crystal_outline_color(gen)
		var danger_col: Color
		if is_killer:
			danger_col = Color("#FF2200")
			danger_col.a = 1.0
		else:
			danger_col = col.lerp(Color("#FF6644"), 0.35)
			danger_col.a = alpha
		var angle := age * 6.0
		draw_set_transform(Vector2(x, y), angle, Vector2.ONE)
		var pts := PackedVector2Array([
			Vector2(-r, -r * 0.6), Vector2(r * 0.8, -r * 0.4),
			Vector2(r * 0.4, r * 0.8), Vector2(-r * 0.6, r * 0.5),
		])
		draw_colored_polygon(pts, danger_col)
		pts.append(pts[0])
		draw_polyline(pts, Color(danger_col, alpha * 0.9), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# --- Sparkles ---
func _draw_sparkles(w: RefCounted) -> void:
	for sp in w.sparkles:
		var age := float(sp["age"])
		var lt := float(sp["lifetime"])
		var alpha := 1.0 - age / lt
		draw_circle(Vector2(float(sp["x"]), float(sp["y"])), 3.0 * alpha, Color("#FFEEAA", alpha))

# --- HUD ---
func _draw_hud(w: RefCounted) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(12, 26), "SCORE: %d" % w.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#E0D8C8"))
	if w.combo > 1:
		var combo_size := mini(16 + w.combo * 3, 36)
		var col := _combo_color(w.combo)
		var text := "x%d" % w.combo
		draw_string(font, Vector2(12, 50), text, HORIZONTAL_ALIGNMENT_LEFT, -1, combo_size, col)
		var shimmer_col := _sparkle_color(0.0)
		shimmer_col.a = 0.3 + sin(_bg_time * 10.0) * 0.25
		draw_string(font, Vector2(13, 51), text, HORIZONTAL_ALIGNMENT_LEFT, -1, combo_size, shimmer_col)

# --- Game Over ---
func _draw_game_over_overlay() -> void:
	draw_rect(Rect2(0, 0, SW, GAME_H), Color(0, 0, 0, 0.3))
	var font := ThemeDB.fallback_font
	var w = game_ref.world
	var cx := SW / 2.0
	draw_rect(Rect2(cx - 120, 280, 240, 150), Color(0, 0, 0, 0.5))
	draw_string(font, Vector2(cx - 120, 315), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, 240, 28, Color("#FF6644"))
	if w != null:
		draw_string(font, Vector2(cx - 120, 355), "Score: %d" % w.score, HORIZONTAL_ALIGNMENT_CENTER, 240, 20, Color("#E0D8C8"))
	# Retry button
	var btn_rect := Rect2(cx - 70, 385, 140, 40)
	var blink := fmod(_bg_time, 1.0) < 0.6
	var btn_col := Color("#FFDD44", 0.9) if blink else Color("#FFDD44", 0.6)
	draw_rect(btn_rect, Color(0.15, 0.12, 0.05, 0.7))
	draw_rect(btn_rect, btn_col, false, 2.0)
	draw_string(font, Vector2(cx - 70, 412), "RETRY (R)", HORIZONTAL_ALIGNMENT_CENTER, 140, 18, btn_col)

# --- Virtual buttons (below game area) ---
func _draw_virtual_buttons() -> void:
	var font := ThemeDB.fallback_font
	if not game_ref.has_touch:
		return
	draw_line(Vector2(0, GAME_H + 5), Vector2(SW, GAME_H + 5), Color(0.2, 0.22, 0.3, 0.3), 1.0)
	var btn_a := 0.18
	var txt_a := 0.4
	var press_a := 0.38
	# Left
	var la := press_a if game_ref.touch_left else btn_a
	draw_rect(Rect2(15, CTRL_TOP, 120, 100), Color(1, 1, 1, la), true)
	draw_rect(Rect2(15, CTRL_TOP, 120, 100), Color(1, 1, 1, txt_a), false, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(45, CTRL_TOP + 50), Vector2(75, CTRL_TOP + 30), Vector2(75, CTRL_TOP + 70)]), Color(1, 1, 1, txt_a))
	# Right
	var ra := press_a if game_ref.touch_right else btn_a
	draw_rect(Rect2(155, CTRL_TOP, 120, 100), Color(1, 1, 1, ra), true)
	draw_rect(Rect2(155, CTRL_TOP, 120, 100), Color(1, 1, 1, txt_a), false, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(235, CTRL_TOP + 50), Vector2(205, CTRL_TOP + 30), Vector2(205, CTRL_TOP + 70)]), Color(1, 1, 1, txt_a))
	# Slash
	var sa := press_a if game_ref.touch_slash else btn_a
	var sc := _combo_color(game_ref.world.combo) if game_ref.world else Color("#FFDD44")
	draw_rect(Rect2(310, CTRL_TOP, 215, 100), Color(sc, sa), true)
	draw_rect(Rect2(310, CTRL_TOP, 215, 100), Color(sc, txt_a), false, 2.0)
	draw_string(font, Vector2(370, CTRL_TOP + 58), "SLASH", HORIZONTAL_ALIGNMENT_CENTER, 100, 24, Color(1, 1, 1, txt_a))
