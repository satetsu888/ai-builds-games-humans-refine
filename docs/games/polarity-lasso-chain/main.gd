extends Node2D

const MetricsTracker = preload("res://metrics_tracker.gd")
const GameState = preload("res://game/game_state.gd")
const PlayerController = preload("res://game/player_controller.gd")
const WorldSim = preload("res://game/world_sim.gd")
const HudRenderer = preload("res://game/hud_renderer.gd")
const AudioManager = preload("res://game/audio_manager.gd")
const TITLE_FADE_SECONDS := 0.32
const GAME_OVER_INPUT_LOCK_SECONDS := 0.5
const GAME_OVER_AUTO_RETURN_SECONDS := 3.0
const BGM_STREAM_PATH := "res://assets/audio/bgm.mp3"
const BGM_PLAYER_GAIN := 0.18

var test_mode := false
var test_action_a := false
var test_action_c := false

var score := 0
var elapsed := 0.0
var game_over := false
var active_entities: Array = []

var entity_type_counts: Dictionary = {}
var behavior_event_counts: Dictionary = {}
var max_single_type_ratio := 0.0
var avg_active_entities_30s := 0.0
var untelegraphed_fail_count := 0
var _active_entity_sample_sum := 0.0
var _active_entity_sample_frames := 0

var _state = GameState.new()
var _player = PlayerController.new()
var _world = WorldSim.new()
var _hud = HudRenderer.new()
var _audio = AudioManager.new()

var _prev_action_a := false
var _near_miss_events := 0
var _close_hint := {"visible": false, "ready": false, "center": Vector2.ZERO, "radius": 72.0, "target_index": -1}
var _ui_popups: Array[Dictionary] = []
var _score_pulse := 0.0
var _loop_burst_t := 0.0
var _loop_burst_center := Vector2(480.0, 270.0)
var _loop_burst_radius := 92.0
var _spark_fades: Array[Dictionary] = []
var _bg_ripples: Array[Dictionary] = []
var _active_threat_points: Array[Vector2] = []
var _danger_vignette := 0.0
var _threat_density := 0.0
var _bg_flow_dir := Vector2(1.0, 0.0)
var _bg_spawn_dir := Vector2(1.0, 0.0)
var _bg_spawn_urgency := 0.0
var _bg_combo_energy := 0.0
var _touch_pressed := false
var _title_active := true
var _title_transition := false
var _title_transition_t := 0.0
var _game_over_input_lock_t := 0.0
var _game_over_auto_return_t := 0.0
var _bgm_player: AudioStreamPlayer
var _bgm_enabled := false
var _app_audio_focus := true
var _bgm_resume_position := 0.0
var _bgm_paused_by_focus := false

func _ready() -> void:
	_audio.setup(self)
	_create_bgm_player()
	_reset_game()
	_title_active = true
	_title_transition = false
	_title_transition_t = 0.0
	_game_over_input_lock_t = 0.0
	_game_over_auto_return_t = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_app_audio_focus = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_app_audio_focus = false
		if is_instance_valid(_bgm_player) and _bgm_player.playing:
			_bgm_resume_position = maxf(0.0, _bgm_player.get_playback_position())
			_bgm_paused_by_focus = true
			_bgm_player.stop()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_pressed = bool(event.pressed)

func _physics_process(delta: float) -> void:
	_update_bgm_loop()
	if test_mode:
		return
	var action_a := Input.is_action_pressed("ui_accept") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or _touch_pressed
	var action_edge := action_a and not _prev_action_a
	if _state.game_over:
		_game_over_input_lock_t = maxf(0.0, _game_over_input_lock_t - delta)
		_game_over_auto_return_t = maxf(0.0, _game_over_auto_return_t - delta)
		var should_return := _game_over_auto_return_t <= 0.0
		if _game_over_input_lock_t <= 0.0 and action_edge:
			should_return = true
		if should_return:
			_state.game_over = false
			game_over = false
			_title_active = true
			_title_transition = false
			_title_transition_t = 0.0
			_game_over_auto_return_t = 0.0
			_prev_action_a = action_a
		queue_redraw()
		return
	if _title_transition:
		_title_transition_t = maxf(0.0, _title_transition_t - delta)
		if _title_transition_t <= 0.0:
			_title_transition = false
			_title_active = false
		_prev_action_a = action_a
		queue_redraw()
		return
	if _title_active:
		if action_edge:
			_reset_game()
			_title_transition = true
			_title_transition_t = TITLE_FADE_SECONDS
		_prev_action_a = action_a
		queue_redraw()
		return
	_simulate_frame(delta, action_a)

func _simulate_frame(delta: float, action_a: bool) -> void:
	if _state.game_over:
		return
	_state.tick(delta)
	var press_edge := action_a and not _prev_action_a
	var shot_edge := press_edge
	var reverse_edge := press_edge
	if shot_edge:
		_state.register_shot()
	if reverse_edge:
		_state.register_reverse()
		MetricsTracker.inc_behavior_event(behavior_event_counts, "reverse")
		_audio.state_change()

	_player.update(delta, _state.polarity, _state.difficulty)
	_close_hint = _world.get_auto_close_hint(_player.position)
	var world_out := _world.update(delta, _player.position, shot_edge, reverse_edge, _state.difficulty, _state.heat)
	for t in world_out["spawned_types"]:
		MetricsTracker.record_spawned_entity(entity_type_counts, str(t))

	var captured := int(world_out["captured"])
	if captured > 0:
		var initial_active_captured := int(world_out.get("initial_active_captured", 0))
		var points := _state.register_capture(captured, initial_active_captured)
		MetricsTracker.inc_behavior_event(behavior_event_counts, "capture")
		MetricsTracker.inc_behavior_event(behavior_event_counts, "chain")
		score = _state.score
		_audio.score(points, _state.combo)
		var center := Vector2(480.0, 270.0)
		if is_inside_tree():
			center = get_viewport_rect().size * 0.5
			_spawn_popup("+%d" % captured, center + Vector2(0.0, -12.0), 46, Color(0.46, 0.95, 0.84, 1.0), 0.62)
		if _state.combo > 1:
			_spawn_popup("x%d" % _state.combo, center + Vector2(0.0, -58.0), 30, Color(1.0, 0.86, 0.42, 0.96), 0.5)
		_score_pulse = 1.0

	var post_awards: Array = world_out.get("post_awards", [])
	var post_positions: Array = world_out.get("post_award_positions", [])
	for i in range(post_awards.size()):
		var base := int(post_awards[i])
		var popup_pos: Vector2 = _player.position
		if i < post_positions.size():
			popup_pos = Vector2(post_positions[i])
		var post_points := _state.register_followup_capture(base)
		if post_points > 0:
			MetricsTracker.inc_behavior_event(behavior_event_counts, "capture")
			score = _state.score
			_audio.score(post_points, _state.combo)
			_spawn_popup("+%d x%d" % [base, _state.combo], popup_pos + Vector2(0.0, -28.0), 24, Color(0.88, 0.95, 1.0, 0.95), 0.45)
			_score_pulse = 1.0
	for p in world_out.get("capture_bursts", []):
		_spawn_spark_fade(Vector2(p))

	if bool(world_out.get("loop_vanished", false)):
		_state.reset_combo()

	if bool(world_out["loop_closed"]):
		MetricsTracker.inc_behavior_event(behavior_event_counts, "loop_closed")
		_loop_burst_t = 0.34
		_loop_burst_center = Vector2(world_out.get("loop_close_center", _player.position))
		_loop_burst_radius = float(world_out.get("loop_close_radius", 84.0))
	if int(world_out["near_miss"]) > 0:
		_near_miss_events += int(world_out["near_miss"])
		MetricsTracker.inc_behavior_event(behavior_event_counts, "near_miss")
		_audio.danger(clampf(_state.heat, 0.0, 1.0))

	if bool(world_out["player_hit"]):
		_state.set_game_over()
		_game_over_input_lock_t = GAME_OVER_INPUT_LOCK_SECONDS
		_game_over_auto_return_t = GAME_OVER_AUTO_RETURN_SECONDS
		if not bool(world_out["telegraphed_fail"]):
			untelegraphed_fail_count += 1
		_audio.damage()
	_update_reactive_background(delta, world_out)

	active_entities = _world.collect_active_entities()
	var update := MetricsTracker.update_test_metrics(elapsed, active_entities, _active_entity_sample_sum, _active_entity_sample_frames, max_single_type_ratio)
	max_single_type_ratio = float(update["max_single_type_ratio"])
	_active_entity_sample_sum = float(update["active_entity_sample_sum"])
	_active_entity_sample_frames = int(update["active_entity_sample_frames"])
	avg_active_entities_30s = float(update["avg_active_entities_30s"])

	elapsed = _state.elapsed
	score = _state.score
	game_over = _state.game_over
	_audio.update(delta, _state.heat, clampf(float(_near_miss_events) * 0.01, 0.0, 1.0))
	_update_ui_effects(delta)
	_prev_action_a = action_a
	queue_redraw()

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.10, 0.14, 1.0), true)
	_draw_background_lines(view)
	_draw_combo_field(view)
	_draw_spawn_warning_wash(view)
	_draw_background_heatmap()
	_draw_background_ripples()
	_draw_danger_vignette(view)
	for l in _world.loops:
		_draw_loop_zone(l)
	_draw_close_preview()
	for b in _world.beacons:
		_draw_beacon(Vector2(b["pos"]))
	for s in _world.sparks:
		_draw_spark(s)
	_draw_spark_fades()
	var wobble := sin(_state.elapsed * 2.4) * 0.08
	draw_circle(_player.position, 12.0 + wobble * 3.0, Color(0.78, 0.91, 0.98, 0.95))
	draw_arc(_player.position, 18.0, 0.0, TAU, 28, Color(0.78, 0.91, 0.98, 0.35), 1.2)
	_draw_auto_close_ring()
	_draw_loop_burst()
	_hud.call("draw_hud", self, _state, _ui_popups, view, _score_pulse, _title_active or _title_transition)
	if _title_active or _title_transition:
		_draw_title_overlay(view)

func _draw_title_overlay(view: Vector2) -> void:
	var fade_alpha := 1.0
	if _title_transition:
		fade_alpha = clampf(_title_transition_t / TITLE_FADE_SECONDS, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.05, 0.07, 0.11, 0.70 * fade_alpha), true)
	var title_font := ThemeDB.fallback_font
	if title_font == null:
		return
	var cx := view.x * 0.5
	var cy := view.y * 0.5
	var center := Vector2(cx, cy - 8.0)
	var beat := 0.90 + 0.10 * sin(float(Time.get_ticks_msec()) * 0.0032)
	var ring_r := minf(view.x, view.y) * 0.40 + beat * 8.0
	var now := float(Time.get_ticks_msec()) * 0.001
	draw_arc(center, ring_r, 0.0, TAU, 128, Color(0.66, 0.92, 1.0, 0.34 * fade_alpha), 2.2)
	draw_arc(center, ring_r - 16.0, 0.0, TAU, 128, Color(0.42, 0.82, 0.92, 0.24 * fade_alpha), 1.2)
	var beacon_angle := now * 1.45
	var beacon_pos := center + Vector2(cos(beacon_angle), sin(beacon_angle)) * ring_r
	var beacon_shape := PackedVector2Array([
		beacon_pos + Vector2(0.0, -10.0),
		beacon_pos + Vector2(10.0, 0.0),
		beacon_pos + Vector2(0.0, 10.0),
		beacon_pos + Vector2(-10.0, 0.0),
	])
	draw_colored_polygon(beacon_shape, Color(0.58, 0.98, 0.90, 0.20 * fade_alpha))
	draw_polyline(beacon_shape + PackedVector2Array([beacon_shape[0]]), Color(0.88, 1.0, 0.96, 0.88 * fade_alpha), 1.8)
	var title_angle := -now * 0.72
	_draw_arc_centered_text(
		center,
		ring_r - 28.0,
		"POLARITY LASSO CHAIN",
		title_font,
		36,
		title_angle,
		Color(0.92, 0.97, 1.0, 0.92 * fade_alpha)
	)
	var cta_pulse := 0.76 + 0.24 * sin(float(Time.get_ticks_msec()) * 0.008)
	_draw_arc_centered_text(
		center,
		ring_r - 28.0,
		"PRESS SPACE / CLICK / TAP TO START",
		title_font,
		18,
		title_angle + PI,
		Color(0.86, 1.0, 0.94, (0.56 + cta_pulse * 0.32) * fade_alpha)
	)

func _draw_arc_centered_text(center: Vector2, radius: float, text: String, font: Font, size: int, center_angle: float, color: Color) -> void:
	if text.is_empty():
		return
	var advs: Array[float] = []
	var widths: Array[float] = []
	var total_advance := 0.0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var glyph_w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var adv := glyph_w + 1.6
		advs.append(adv)
		widths.append(glyph_w)
		total_advance += adv
	var cursor := -total_advance * 0.5
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var adv := float(advs[i])
		var glyph_w := float(widths[i])
		var mid := cursor + adv * 0.5
		var angle := center_angle + (mid / maxf(radius, 1.0))
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		var tangent := angle + PI * 0.5
		draw_set_transform(pos, tangent, Vector2.ONE)
		draw_string(font, Vector2(-glyph_w * 0.5, 0.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		cursor += adv
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_background_lines(view: Vector2) -> void:
	var flow := _bg_flow_dir.normalized()
	if flow.length() <= 0.001:
		flow = Vector2(1.0, 0.0)
	var line_count := 30 + int(round(_bg_combo_energy * 12.0))
	for i in range(line_count):
		var ratio := float(i) / maxf(float(line_count - 1), 1.0)
		var y: float = ratio * view.y
		var wav: float = sin(_state.elapsed * (0.7 + _bg_combo_energy * 0.5) + float(i) * 0.62) * (3.0 + _state.heat * 7.0 + _bg_spawn_urgency * 4.0)
		var drift: Vector2 = flow * (sin(_state.elapsed * 0.45 + float(i) * 0.21) * (10.0 + 16.0 * _bg_spawn_urgency))
		var shear: Vector2 = Vector2(flow.y, -flow.x) * (12.0 + _bg_combo_energy * 18.0)
		var alpha: float = 0.10 + _bg_combo_energy * 0.05 + _bg_spawn_urgency * 0.08
		var line_color := Color(0.40 + _bg_combo_energy * 0.10, 0.45 + _bg_combo_energy * 0.08, 0.52 + _bg_spawn_urgency * 0.10, alpha)
		draw_line(
			Vector2(view.x * 0.08, y + wav) + drift - shear,
			Vector2(view.x * 0.92, y - wav) + drift + shear,
			line_color,
			1.0 + _bg_combo_energy * 0.5
		)

func _draw_combo_field(view: Vector2) -> void:
	if _bg_combo_energy <= 0.01:
		return
	var spacing := 120.0 - _bg_combo_energy * 58.0
	var diag := _bg_flow_dir.normalized()
	var perp := Vector2(-diag.y, diag.x)
	var center := view * 0.5
	for i in range(-6, 7):
		var offset := perp * (float(i) * spacing)
		var a := center + offset - diag * view.x
		var b := center + offset + diag * view.x
		draw_line(a, b, Color(0.46, 0.80, 0.86, 0.05 + _bg_combo_energy * 0.07), 0.9)

func _draw_spawn_warning_wash(view: Vector2) -> void:
	if _bg_spawn_urgency <= 0.01:
		return
	var a := _bg_spawn_urgency
	if absf(_bg_spawn_dir.x) > absf(_bg_spawn_dir.y):
		var w := 20.0 + 34.0 * a
		if _bg_spawn_dir.x > 0.0:
			draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(w, view.y)), Color(0.90, 0.34, 0.30, 0.05 + a * 0.08), true)
		else:
			draw_rect(Rect2(Vector2(view.x - w, 0.0), Vector2(w, view.y)), Color(0.90, 0.34, 0.30, 0.05 + a * 0.08), true)
	else:
		var h := 16.0 + 28.0 * a
		if _bg_spawn_dir.y > 0.0:
			draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(view.x, h)), Color(0.90, 0.34, 0.30, 0.05 + a * 0.08), true)
		else:
			draw_rect(Rect2(Vector2(0.0, view.y - h), Vector2(view.x, h)), Color(0.90, 0.34, 0.30, 0.05 + a * 0.08), true)

func _draw_loop_zone(loop: Dictionary) -> void:
	var poly: Array[Vector2] = loop["poly"]
	if poly.size() < 3:
		return
	var life_ratio: float = clampf(float(loop.get("life", 0.0)) / 2.2, 0.0, 1.0)
	var close_progress: float = 1.0 - life_ratio
	var phase: float = _state.elapsed * 8.0 + close_progress * 4.5
	var packed_poly := PackedVector2Array(poly)
	# Loops can become self-intersecting as beacons drift; skip fill when triangulation is invalid.
	if Geometry2D.triangulate_polygon(packed_poly).size() >= 3:
		draw_colored_polygon(packed_poly, Color(0.18, 0.62, 0.57, 0.15 + close_progress * 0.08))
	var closed_points := poly + [poly[0]]
	draw_polyline(closed_points, Color(0.44, 0.92, 0.80, 0.78 + close_progress * 0.18), 2.2 + close_progress * 1.2)
	draw_polyline(closed_points, Color(0.76, 1.0, 0.94, 0.30 + close_progress * 0.25), 1.0 + close_progress * 0.7)

	# Secondary outline with slight phase-shifted spatial lag for richer closure feedback.
	var lag_offset: Vector2 = Vector2(cos(phase * 0.63), sin(phase * 0.47)) * (1.4 + close_progress * 1.1)
	var lagged: Array[Vector2] = []
	for p in poly:
		lagged.append(p + lag_offset)
	lagged.append(lagged[0])
	draw_polyline(lagged, Color(0.60, 1.0, 0.90, 0.18 + close_progress * 0.22), 1.2)

	# Running highlight that scans along loop perimeter.
	var perimeter: float = 0.0
	for i in range(poly.size()):
		perimeter += poly[i].distance_to(poly[(i + 1) % poly.size()])
	if perimeter > 0.001:
		var travel: float = fmod((_state.elapsed * 140.0) + close_progress * perimeter * 1.4, perimeter)
		var accum: float = 0.0
		var scan_pos: Vector2 = poly[0]
		var scan_dir: Vector2 = Vector2.RIGHT
		for i in range(poly.size()):
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var seg_len := a.distance_to(b)
			if accum + seg_len >= travel:
				var t := (travel - accum) / maxf(seg_len, 0.001)
				scan_pos = a.lerp(b, t)
				scan_dir = (b - a).normalized()
				break
			accum += seg_len
		draw_circle(scan_pos, 3.2, Color(0.96, 1.0, 0.90, 0.94))
		draw_line(scan_pos - scan_dir * 11.0, scan_pos + scan_dir * 6.0, Color(0.82, 1.0, 0.92, 0.58), 1.4)

	# Vertex pulse accents to make polygon structure legible.
	for i in range(poly.size()):
		var pulse := 0.5 + 0.5 * sin(_state.elapsed * 9.4 + float(i) * 0.92 + close_progress * 5.6)
		var r := 2.3 + pulse * 2.2
		draw_circle(poly[i], r, Color(0.78, 1.0, 0.92, 0.28 + pulse * 0.40))

func _draw_background_heatmap() -> void:
	var strength := clampf(_threat_density, 0.0, 1.0)
	if strength <= 0.01:
		return
	for p in _active_threat_points:
		var base_alpha := (0.04 + strength * 0.06)
		draw_circle(p, 42.0, Color(0.96, 0.36, 0.30, base_alpha))
		draw_circle(p, 20.0, Color(1.0, 0.44, 0.34, base_alpha * 1.2))

func _draw_background_ripples() -> void:
	for ripple in _bg_ripples:
		var life := maxf(float(ripple.get("life", 0.9)), 0.01)
		var age := float(ripple.get("age", 0.0))
		var p := clampf(age / life, 0.0, 1.0)
		var inv := 1.0 - p
		var center := Vector2(ripple.get("center", Vector2.ZERO))
		var radius := float(ripple.get("radius", 80.0)) * (0.74 + p * 1.18)
		var intensity := float(ripple.get("intensity", 1.0))
		draw_arc(center, radius, 0.0, TAU, 72, Color(0.56, 0.98, 0.88, (0.30 + intensity * 0.22) * inv), 2.0 + intensity * 0.8)
		draw_arc(center, radius + 18.0, 0.0, TAU, 72, Color(0.74, 1.0, 0.94, (0.17 + intensity * 0.12) * inv), 1.2)

func _draw_danger_vignette(view: Vector2) -> void:
	var d := clampf(_danger_vignette, 0.0, 1.0)
	if d <= 0.01:
		return
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.40, 0.16, 0.14, 0.07 * d), true)
	draw_rect(Rect2(Vector2(3.0, 3.0), view - Vector2(6.0, 6.0)), Color(1.0, 0.48, 0.38, 0.24 * d), false, 3.0)
	draw_rect(Rect2(Vector2(13.0, 13.0), view - Vector2(26.0, 26.0)), Color(1.0, 0.58, 0.46, 0.16 * d), false, 1.6)

func _draw_auto_close_ring() -> void:
	if not bool(_close_hint.get("visible", false)):
		return
	var ring_center := Vector2(_close_hint.get("center", Vector2.ZERO))
	var ring_radius := float(_close_hint.get("radius", 72.0))
	var ready := bool(_close_hint.get("ready", false))
	var pulse := 0.86 + 0.14 * sin(_state.elapsed * 6.0)
	var fill_color := Color(0.24, 0.90, 0.74, 0.18 * pulse) if ready else Color(0.90, 0.95, 1.0, 0.12 * pulse)
	var edge_color := Color(0.32, 1.0, 0.86, 0.98) if ready else Color(0.96, 0.98, 1.0, 0.92)
	draw_circle(ring_center, ring_radius, fill_color)
	draw_arc(ring_center, ring_radius, 0.0, TAU, 96, edge_color, 3.2)
	draw_arc(ring_center, ring_radius - 6.0, 0.0, TAU, 96, Color(edge_color, 0.45), 1.2)

func _draw_close_preview() -> void:
	if _world.beacons.size() < 2:
		return
	var preview_points: Array[Vector2] = []
	for b in _world.beacons:
		preview_points.append(Vector2(b["pos"]))
	preview_points.append(_player.position)
	var ready := bool(_close_hint.get("ready", false))
	var preview_color := Color(0.34, 0.96, 0.82, 0.62) if ready else Color(0.90, 0.95, 1.0, 0.34)
	draw_polyline(preview_points, preview_color, 1.6)
	if ready:
		var idx := int(_close_hint.get("target_index", -1))
		if idx >= 0 and idx < _world.beacons.size():
			var target := Vector2(_world.beacons[idx]["pos"])
			draw_line(_player.position, target, Color(0.34, 0.96, 0.82, 0.76), 1.6)

func _draw_beacon(pos: Vector2) -> void:
	var t: float = float(_state.elapsed)
	var pulse := 0.84 + 0.16 * sin(t * 5.2 + pos.x * 0.02 + pos.y * 0.03)
	var shape := PackedVector2Array([
		pos + Vector2(0.0, -7.2),
		pos + Vector2(7.2, 0.0),
		pos + Vector2(0.0, 7.2),
		pos + Vector2(-7.2, 0.0),
	])
	draw_colored_polygon(shape, Color(0.48, 0.94, 0.86, 0.22 + pulse * 0.10))
	draw_polyline(shape + PackedVector2Array([shape[0]]), Color(0.80, 1.0, 0.95, 0.84 + pulse * 0.14), 1.6)
	draw_circle(pos, 1.8, Color(0.92, 0.99, 0.97, 0.9))
	draw_line(pos + Vector2(-10.0, 0.0), pos + Vector2(-18.0, 0.0), Color(0.62, 0.72, 0.84, 0.26), 1.0)

func _draw_spark(spark: Dictionary) -> void:
	var spark_pos := Vector2(spark["pos"])
	var is_active := bool(spark.get("active", false))
	var vel := Vector2(spark.get("vel", Vector2.ZERO))
	var dir := vel.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(0.0, -1.0)
	if is_active:
		var pulse := 0.78 + 0.22 * sin(_state.elapsed * 8.6 + spark_pos.x * 0.02)
		draw_circle(spark_pos, 8.4, Color(0.98, 0.42, 0.34, 0.16 + pulse * 0.12))
		draw_circle(spark_pos, 5.4, Color(0.98, 0.44, 0.35, 0.90))
		draw_circle(spark_pos + dir * 1.1, 2.1, Color(1.0, 0.87, 0.72, 0.86))
		draw_line(spark_pos - dir * 4.0, spark_pos - dir * 14.0, Color(0.98, 0.52, 0.38, 0.62), 1.8)
	else:
		draw_circle(spark_pos, 4.2, Color(0.58, 0.66, 0.82, 0.58))
		draw_circle(spark_pos, 2.0, Color(0.78, 0.84, 0.93, 0.55))

func _draw_loop_burst() -> void:
	if _loop_burst_t <= 0.0:
		return
	var p := clampf(_loop_burst_t / 0.34, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - p, 3.0)
	var radius := _loop_burst_radius * (0.72 + ease * 0.58)
	var alpha := 0.34 * (1.0 - p)
	draw_arc(_loop_burst_center, radius, 0.0, TAU, 80, Color(0.50, 1.0, 0.88, alpha), 2.8)
	draw_arc(_loop_burst_center, radius + 14.0, 0.0, TAU, 80, Color(0.72, 1.0, 0.94, alpha * 0.65), 1.4)

func _update_reactive_background(delta: float, world_out: Dictionary) -> void:
	_active_threat_points.clear()
	var nearest := INF
	for s in _world.sparks:
		if not bool(s.get("active", false)):
			continue
		var p := Vector2(s["pos"])
		if _active_threat_points.size() < 20:
			_active_threat_points.append(p)
		nearest = minf(nearest, p.distance_to(_player.position))
	var count_factor := clampf(float(_active_threat_points.size()) / 8.0, 0.0, 1.0)
	_threat_density = lerpf(_threat_density, count_factor, clampf(delta * 4.2, 0.0, 1.0))
	var combo_target := clampf(float(maxi(_state.combo - 1, 0)) / 6.0, 0.0, 1.0)
	_bg_combo_energy = lerpf(_bg_combo_energy, combo_target, clampf(delta * 5.5, 0.0, 1.0))
	_bg_spawn_urgency = maxf(0.0, _bg_spawn_urgency - delta * 2.8)
	var spawn_active_edges: Array = world_out.get("spawn_active_edges", [])
	if not spawn_active_edges.is_empty():
		var edge := str(spawn_active_edges[spawn_active_edges.size() - 1])
		_bg_spawn_dir = _edge_to_dir(edge)
		_bg_spawn_urgency = 1.0
	var polarity_dir := Vector2(float(_state.polarity), 0.0)
	var flow_vec := polarity_dir * 0.35 + _bg_spawn_dir * (_bg_spawn_urgency * 1.25)
	if flow_vec.length() <= 0.001:
		flow_vec = polarity_dir
	_bg_flow_dir = _bg_flow_dir.lerp(flow_vec.normalized(), clampf(delta * 5.0, 0.0, 1.0))
	var target_vignette := 0.0
	if nearest < INF:
		target_vignette = clampf((220.0 - nearest) / 220.0, 0.0, 1.0)
	target_vignette = maxf(target_vignette, clampf(float(world_out.get("near_miss", 0)) * 0.15, 0.0, 0.9))
	_danger_vignette = lerpf(_danger_vignette, target_vignette, clampf(delta * 7.0, 0.0, 1.0))
	if bool(world_out.get("loop_closed", false)):
		var capture_scale := clampf(float(world_out.get("captured", 1)) / 6.0, 0.0, 1.0)
		_bg_ripples.append({
			"center": Vector2(world_out.get("loop_close_center", _player.position)),
			"radius": float(world_out.get("loop_close_radius", 84.0)),
			"age": 0.0,
			"life": 0.9 + capture_scale * 0.35,
			"intensity": 0.8 + capture_scale * 0.7,
		})
		if _bg_ripples.size() > 12:
			_bg_ripples.remove_at(0)

func _edge_to_dir(edge: String) -> Vector2:
	match edge:
		"top":
			return Vector2(0.0, 1.0)
		"right":
			return Vector2(-1.0, 0.0)
		"bottom":
			return Vector2(0.0, -1.0)
		_:
			return Vector2(1.0, 0.0)

func _draw_spark_fades() -> void:
	for f in _spark_fades:
		var life := maxf(float(f.get("life", 0.40)), 0.01)
		var age := float(f.get("age", 0.0))
		var pos := Vector2(f.get("pos", Vector2.ZERO))
		var t := clampf(age / life, 0.0, 1.0)
		var inv := 1.0 - t
		var radius := 6.0 + t * 18.0
		draw_circle(pos, 4.6 + t * 2.4, Color(1.0, 0.76, 0.61, 0.34 * inv))
		draw_arc(pos, radius, 0.0, TAU, 28, Color(1.0, 0.58, 0.42, 0.78 * inv), 2.2)
		draw_arc(pos, radius + 8.0, 0.0, TAU, 28, Color(1.0, 0.72, 0.56, 0.46 * inv), 1.4)
		var dir := Vector2(f.get("dir", Vector2(0.0, -1.0))).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2(0.0, -1.0)
		var spark_offset := Vector2(f.get("spark_offset", Vector2.ZERO))
		var spark_pos := pos + spark_offset * (0.25 + t * 0.95)
		draw_circle(spark_pos, 1.6 + inv * 0.6, Color(1.0, 0.86, 0.72, 0.72 * inv))
		draw_line(pos - dir * (1.0 + t * 2.0), pos - dir * (7.0 + t * 11.0), Color(1.0, 0.67, 0.52, 0.62 * inv), 1.8)

func _reset_game() -> void:
	_state.reset()
	_player.reset()
	_world.reset()
	_prev_action_a = false
	_near_miss_events = 0
	_close_hint = {"visible": false, "ready": false, "center": Vector2.ZERO, "radius": 72.0, "target_index": -1}
	_ui_popups.clear()
	_score_pulse = 0.0
	_loop_burst_t = 0.0
	_loop_burst_center = Vector2(480.0, 270.0)
	_loop_burst_radius = 92.0
	_spark_fades.clear()
	_bg_ripples.clear()
	_active_threat_points.clear()
	_danger_vignette = 0.0
	_threat_density = 0.0
	_bg_flow_dir = Vector2(float(_state.polarity), 0.0)
	_bg_spawn_dir = Vector2(1.0, 0.0)
	_bg_spawn_urgency = 0.0
	_bg_combo_energy = 0.0
	_touch_pressed = false
	_game_over_input_lock_t = 0.0
	_game_over_auto_return_t = 0.0
	var m := MetricsTracker.reset_metric_trackers({"spark": 0, "beacon": 0, "loop": 0}, ["capture", "chain", "loop_closed", "near_miss", "reverse"])
	entity_type_counts = m["entity_type_counts"]
	behavior_event_counts = m["behavior_event_counts"]
	max_single_type_ratio = float(m["max_single_type_ratio"])
	avg_active_entities_30s = float(m["avg_active_entities_30s"])
	untelegraphed_fail_count = int(m["untelegraphed_fail_count"])
	_active_entity_sample_sum = 0.0
	_active_entity_sample_frames = 0
	active_entities.clear()
	score = 0
	elapsed = 0.0
	game_over = false
	queue_redraw()

func enable_test_mode(enabled: bool) -> void:
	test_mode = enabled
	if enabled:
		_title_active = false
		_title_transition = false
		_title_transition_t = 0.0

func force_reset_for_test(test_seed: int) -> void:
	seed(test_seed)
	_reset_game()

func step_for_test(delta: float, action_a: bool, action_b: bool, action_c: bool) -> void:
	test_action_a = action_a
	test_action_c = action_c
	_simulate_frame(delta, action_a)

func step_for_test_dict(delta: float, inputs: Dictionary) -> void:
	var a := bool(inputs.get("action_a", false))
	step_for_test(delta, a, false, false)

func get_test_input_channels() -> Array:
	return [
		{"name": "action_a", "type": "bool"},
	]

func get_monotonous_policies() -> Array:
	return [
		{
			"name": "no_input",
			"policy": func(_f): return {"action_a": false},
		},
		{
			"name": "spam_action",
			"policy": func(f): return {"action_a": (f % 2) == 0},
		},
		{
			"name": "hold_action",
			"policy": func(_f): return {"action_a": true},
		},
	]

func get_exploration_policies() -> Array:
	return [
		{
			"name": "orbit_flip_builder",
			"policy": func(f):
				var fire: bool = (f % 12) == 0
				var flip: bool = (f % 53) == 0
				return {"action_a": fire or flip},
		},
		{
			"name": "dense_then_flip",
			"policy": func(f):
				var phase: int = f % 90
				return {
					"action_a": (phase < 42 and (phase % 6) == 0) or phase == 44 or phase == 75,
				},
		},
		{
			"name": "risk_harvest",
			"policy": func(f):
				var fire: bool = (f % 10) == 0 or (f % 37) == 0
				var flip: bool = (f % 41) == 0
				return {"action_a": fire or flip},
		},
	]

func get_metrics() -> Dictionary:
	return {
		"score": score,
		"game_over": game_over,
		"elapsed": elapsed,
		"active_entities": active_entities.size(),
		"entity_type_counts": entity_type_counts.duplicate(true),
		"max_single_type_ratio": max_single_type_ratio,
		"behavior_event_counts": behavior_event_counts.duplicate(true),
		"avg_active_entities_30s": avg_active_entities_30s,
		"untelegraphed_fail_count": untelegraphed_fail_count,
	}

func set_wave_for_test(target_phase: int) -> void:
	_state.elapsed = float(target_phase) * 20.0
	_state.difficulty = 1.0 + (_state.elapsed / 60.0)

func _spawn_popup(text: String, pos: Vector2, size: int, color: Color, duration: float) -> void:
	_ui_popups.append({
		"text": text,
		"pos": pos,
		"size": size,
		"color": color,
		"duration": duration,
		"t": 0.0,
	})

func _update_ui_effects(delta: float) -> void:
	for i in range(_ui_popups.size() - 1, -1, -1):
		var p := _ui_popups[i]
		p["t"] = float(p.get("t", 0.0)) + delta
		if float(p["t"]) >= float(p.get("duration", 0.5)):
			_ui_popups.remove_at(i)
	for i in range(_spark_fades.size() - 1, -1, -1):
		var f := _spark_fades[i]
		f["age"] = float(f.get("age", 0.0)) + delta
		if float(f["age"]) >= float(f.get("life", 0.26)):
			_spark_fades.remove_at(i)
	for i in range(_bg_ripples.size() - 1, -1, -1):
		var r := _bg_ripples[i]
		r["age"] = float(r.get("age", 0.0)) + delta
		if float(r["age"]) >= float(r.get("life", 0.9)):
			_bg_ripples.remove_at(i)
	_score_pulse = maxf(0.0, _score_pulse - delta * 3.2)
	_loop_burst_t = maxf(0.0, _loop_burst_t - delta)

func _spawn_spark_fade(pos: Vector2) -> void:
	for _i in range(2):
		_spark_fades.append({
			"pos": pos + Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5)),
			"age": 0.0,
			"life": randf_range(0.32, 0.50),
			"dir": Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)),
			"spark_offset": Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)),
		})
	if _spark_fades.size() > 120:
		_spark_fades = _spark_fades.slice(_spark_fades.size() - 120, _spark_fades.size())

func _create_bgm_player() -> void:
	if not ResourceLoader.exists(BGM_STREAM_PATH):
		_bgm_enabled = false
		return
	var stream := load(BGM_STREAM_PATH)
	if not (stream is AudioStream):
		_bgm_enabled = false
		return
	if stream is AudioStreamMP3:
		var mp3_stream := stream as AudioStreamMP3
		mp3_stream.loop = true
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = stream
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = linear_to_db(BGM_PLAYER_GAIN)
	add_child(_bgm_player)
	_bgm_enabled = true

func _update_bgm_loop() -> void:
	if not _bgm_enabled or not is_instance_valid(_bgm_player):
		return
	if not _app_audio_focus:
		if _bgm_player.playing:
			_bgm_resume_position = maxf(0.0, _bgm_player.get_playback_position())
			_bgm_paused_by_focus = true
			_bgm_player.stop()
		return
	var should_play: bool = not test_mode and not _title_active and not _title_transition and not _state.game_over
	if should_play:
		if not _bgm_player.playing:
			if _bgm_paused_by_focus:
				_bgm_player.play(_bgm_resume_position)
				_bgm_paused_by_focus = false
			else:
				_bgm_player.play()
		return
	if _bgm_player.playing:
		_bgm_resume_position = 0.0
		_bgm_paused_by_focus = false
		_bgm_player.stop()
