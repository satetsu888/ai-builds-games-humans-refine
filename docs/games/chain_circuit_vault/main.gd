extends Node2D

const GameState = preload("res://scripts/game_state.gd")
const PlayerController = preload("res://scripts/player_controller.gd")
const WorldController = preload("res://scripts/world_controller.gd")
const HudController = preload("res://scripts/hud_controller.gd")
const EffectsAudio = preload("res://scripts/effects_audio.gd")

const GRID_SIZE := Vector2i(11, 11)
const CELL_SIZE := 40
const BOARD_OFFSET := Vector2(50, 56)
const VIEWPORT_SIZE := Vector2(540, 540)
const SCORE_POPUP_TTL := 0.75
const EMERGENCY_MIN_CABLE_LENGTH := 10
const INITIAL_CABLE_LENGTH := 5.0
const BGM_STREAM_PATH := "res://assets/audio/bgm.mp3"
const BGM_PLAYER_GAIN := 0.3
const BOARD_BG := Color("0f1726")
const BOARD_STROKE := Color("2f4d68")
const GRID_CELL_DARK := Color("132235")
const CORRUPTION_FILL := Color("872634")
const CORRUPTION_EDGE := Color("d85b67")
const CORRUPTION_CORE := Color("4a0e18")
const RUNE_BASE := Color("f3c969")
const RUNE_GLOW := Color("fff2ba")
const GENERATOR_CORE := Color("ff8e42")
const GENERATOR_RING := Color("ffd7a4")
const PULSE_BASE := Color("d7f1ff", 0.95)
const PULSE_ENHANCED := Color("7fffd1", 0.95)
const PULSE_ENHANCED_GLOW := Color("caffef", 0.5)
const CABLE_BASE := Color("6ed5e4")
const CABLE_CHARGED := Color("a6ffe0")
const CABLE_GHOST := Color("7ad4df", 0.35)
const CORE_BASE := Color("e7fcff")
const CORE_READY := Color("9cffb5")
const RUNE_ECHO_TTL := 0.7
const MODE_TITLE := "title"
const MODE_PLAYING := "playing"
const MODE_GAME_OVER := "game_over"

var test_mode := false
var _test_inputs := {
	"move_up": false,
	"move_down": false,
	"move_left": false,
	"move_right": false,
}

var state := GameState.new()
var player := PlayerController.new()
var world := WorldController.new()
var hud: HudController = null
var sfx: EffectsAudio = null
var _throw_enhanced := false
var _purify_combo := 0
var _score_popups: Array[Dictionary] = []
var _rune_echoes: Array[Dictionary] = []
var _ui_numeric_font: FontFile = null
var _last_warning_cell := Vector2i(-1, -1)
var _conduction_audio_step := 0
var _screen_mode := MODE_TITLE
var _menu_elapsed := 0.0
var _bgm_player: AudioStreamPlayer = null
var _bgm_enabled := false
var _app_audio_focus := true
var _bgm_resume_position := 0.0
var _bgm_paused_by_focus := false

func _ready() -> void:
	_ensure_retry_action()
	_ensure_confirm_action()
	_ui_numeric_font = load("res://assets/fonts/NotoSansMono-Bold.ttf") as FontFile
	hud = HudController.new()
	sfx = EffectsAudio.new()
	add_child(hud)
	add_child(sfx)
	_create_bgm_player()
	_reset_game(randi())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_app_audio_focus = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_app_audio_focus = false
		if is_instance_valid(_bgm_player) and _bgm_player.playing:
			_bgm_resume_position = maxf(0.0, _bgm_player.get_playback_position())
			_bgm_paused_by_focus = true
			_bgm_player.stop()

func _physics_process(delta: float) -> void:
	_update_bgm_loop()
	if test_mode:
		return
	if _screen_mode == MODE_TITLE:
		_menu_elapsed += delta
		if Input.is_action_just_pressed("confirm"):
			_start_run()
		queue_redraw()
		return
	if _screen_mode == MODE_GAME_OVER:
		_menu_elapsed += delta
		if Input.is_action_just_pressed("confirm"):
			_screen_mode = MODE_TITLE
			_update_hud()
			queue_redraw()
		return
	_simulate_frame(delta, _read_runtime_inputs())

func _draw() -> void:
	var board_rect := Rect2(BOARD_OFFSET, Vector2(GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE))
	draw_rect(board_rect, BOARD_BG, true)
	draw_rect(board_rect, BOARD_STROKE, false, 4.0)
	_draw_board_cells()
	_draw_spread_warning()
	_draw_runes()
	_draw_rune_echoes()
	_draw_detached_cable()
	_draw_player_cable()
	_draw_pulses()

	var popup_font: FontFile = _ui_numeric_font
	if popup_font != null:
		for popup in _score_popups:
			var p := popup["pos"] as Vector2
			var label := str(popup["value"])
			var label_size := popup_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 30)
			draw_string(
				popup_font,
				p + Vector2(-label_size.x * 0.5, 10),
				label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				30,
				Color(1.0, 0.95, 0.55, 1.0)
			)

	var head := _cell_to_world(player.head_cell)
	var ready := player.trail_length >= EMERGENCY_MIN_CABLE_LENGTH
	var head_fill := CORE_BASE
	var head_ring := Color("96efff", 0.8)
	if ready:
		head_fill = CORE_READY
		head_ring = Color("47ff86", 0.95)
	draw_circle(head, 17.0, Color(head_fill, 0.14))
	draw_circle(head, 13.0, head_fill)
	draw_arc(head, 19.0, 0.0, TAU, 20, Color("10202c", 0.95), 2.0)
	draw_arc(head, 22.0 + sin(state.elapsed * 3.0) * 2.0, 0.0, TAU, 24, head_ring, 3.0)
	draw_line(head + Vector2(-5, 0), head + Vector2(5, 0), Color("0b1621", 0.85), 2.0)
	draw_line(head + Vector2(0, -5), head + Vector2(0, 5), Color("0b1621", 0.85), 2.0)
	if _screen_mode == MODE_TITLE:
		_draw_title_overlay()
	elif _screen_mode == MODE_GAME_OVER:
		_draw_game_over_overlay()

func _simulate_frame(delta: float, inputs: Dictionary) -> void:
	state.tick(delta)
	world.tick(delta)
	_tick_score_popups(delta)
	_tick_rune_echoes(delta)
	var skip_corruption_fail_this_frame := false
	var conduction := world.step_conduction(delta)
	if bool(conduction["triggered"]):
		if sfx != null:
			sfx.play_conduction_step(_conduction_audio_step, bool(conduction["scorable"]))
		_conduction_audio_step += 1
		if bool(conduction["scorable"]):
			_award_purify_combo(conduction["purified_cells"])
		if int(conduction["purified_count"]) > 0 and bool(conduction["scorable"]):
			state.register_event("purify")
			if sfx != null:
				sfx.play_score(4)
	if bool(conduction["finished"]):
		_conduction_audio_step = 0

	var events := player.step(delta, inputs)
	if world.is_corrupted(player.head_cell):
		if player.trail_length >= EMERGENCY_MIN_CABLE_LENGTH:
			world.conduct_emergency_on_cable(player.trail_cells, player.head_cell)
			_conduction_audio_step = 0
			player.sever_and_reset_to_initial()
			_throw_enhanced = false
			_purify_combo = 0
			skip_corruption_fail_this_frame = true
			state.register_event("emergency_pulse")
			if sfx != null:
				sfx.play_spread_confirm()
		else:
			state.end_game("entered corruption")
			if sfx != null:
				sfx.play_damage()

	world.ensure_runes(player.get_cable_set())

	if events["throw_step"] != null:
		if int(events["throw_step"]["step"]) == 1:
			world.clear_pulse_visuals()
			_throw_enhanced = false
			_purify_combo = 0
		state.register_event("throw")
		if sfx != null:
			sfx.play_throw()
		var throw_result := world.resolve_throw_step(
			events["throw_step"]["origin"],
			events["throw_step"]["dir"],
			int(events["throw_step"]["step"]),
			player.get_cable_set(),
			_throw_enhanced
		)
		if not bool(throw_result["valid"]):
			player.cancel_idle_throw()
			_throw_enhanced = false
		if bool(throw_result["hit_rune"]):
			player.grow(int(throw_result["destroyed_runes"]))
			_throw_enhanced = true
			_add_rune_echo(events["throw_step"]["origin"] + events["throw_step"]["dir"] * int(events["throw_step"]["step"]))
			state.register_event("enhanced_throw")
			if sfx != null:
				sfx.play_enhance_charge()
		_award_purify_combo(throw_result["purified_cells"])
		if int(throw_result["purified_cells"].size()) > 0:
			state.register_event("purify")
			if sfx != null:
				sfx.play_score(3)
		if bool(throw_result["destroyed_generator"]):
			state.register_event("generator_break")
			if sfx != null:
				sfx.play_generator_break()
		if bool(throw_result["cable_conducted"]):
			world.conduct_enhanced_on_cable(player.trail_cells, throw_result["cable_hit_cell"])
			_conduction_audio_step = 0
			player.sever_and_reset_to_initial()
			player.cancel_idle_throw()
			_throw_enhanced = false
		if bool(throw_result["stop_throw"]):
			player.cancel_idle_throw()
			_throw_enhanced = false
		for _cell in throw_result["new_corruption"]:
			state.register_event("friendly_fire")
			if sfx != null:
				sfx.play_state_change()

	var cable_length_ratio := float(player.trail_length) / INITIAL_CABLE_LENGTH
	var spread := world.spread_corruption(delta, player.get_cable_set(), state.difficulty_level, cable_length_ratio)
	var warning_cell := world.get_spread_warning_cell()
	if warning_cell != Vector2i(-1, -1) and warning_cell != _last_warning_cell:
		if sfx != null:
			sfx.play_spread_warning()
	_last_warning_cell = warning_cell
	if bool(spread["spread"]):
		state.register_event("spread")
		if sfx != null:
			sfx.play_spread_confirm()
	if not skip_corruption_fail_this_frame and world.is_corrupted(player.head_cell):
		if player.trail_length >= EMERGENCY_MIN_CABLE_LENGTH:
			world.conduct_emergency_on_cable(player.trail_cells, player.head_cell)
			_conduction_audio_step = 0
			player.sever_and_reset_to_initial()
			_throw_enhanced = false
			_purify_combo = 0
			skip_corruption_fail_this_frame = true
			state.register_event("emergency_pulse")
			if sfx != null:
				sfx.play_spread_confirm()
		else:
			state.end_game("corruption reached core")
			if sfx != null:
				sfx.play_damage()
	if bool(spread["collapse"]):
		state.end_game("board collapsed")
		if sfx != null:
			sfx.play_damage()
	if state.game_over:
		_screen_mode = MODE_GAME_OVER

	state.update_entity_telemetry(_collect_entity_snapshots())
	_update_hud()
	queue_redraw()

func _award_purify_combo(purified_cells: Array) -> void:
	for cell in purified_cells:
		var grid_cell: Vector2i = cell
		player.grow(1)
		_purify_combo += 1
		state.add_score(_purify_combo, false)
		_score_popups.append({
			"pos": _cell_to_world(grid_cell),
			"value": _purify_combo,
			"ttl": SCORE_POPUP_TTL,
		})

func _tick_score_popups(delta: float) -> void:
	for i in range(_score_popups.size() - 1, -1, -1):
		var popup := _score_popups[i]
		popup["ttl"] = float(popup["ttl"]) - delta
		_score_popups[i] = popup
		if float(popup["ttl"]) <= 0.0:
			_score_popups.remove_at(i)

func _tick_rune_echoes(delta: float) -> void:
	for i in range(_rune_echoes.size() - 1, -1, -1):
		var echo := _rune_echoes[i]
		echo["ttl"] = float(echo["ttl"]) - delta
		_rune_echoes[i] = echo
		if float(echo["ttl"]) <= 0.0:
			_rune_echoes.remove_at(i)

func _collect_entity_snapshots() -> Array:
	var entities: Array = []
	for _rune in world.runes:
		entities.append({"type": "rune"})
	for _c in world.corruption.keys():
		entities.append({"type": "corruption"})
	for _p in world.pulse_cells:
		entities.append({"type": "pulse"})
	return entities

func _update_hud() -> void:
	if hud != null:
		hud.visible = _screen_mode == MODE_PLAYING
		hud.set_values(state.score, state.game_over, state.game_over_reason)

func _read_runtime_inputs() -> Dictionary:
	return {
		"move_up": Input.is_action_pressed("ui_up"),
		"move_down": Input.is_action_pressed("ui_down"),
		"move_left": Input.is_action_pressed("ui_left"),
		"move_right": Input.is_action_pressed("ui_right"),
	}

func _ensure_retry_action() -> void:
	if not InputMap.has_action("retry"):
		InputMap.add_action("retry")
	var has_r := false
	for ev in InputMap.action_get_events("retry"):
		if ev is InputEventKey and ev.keycode == KEY_R:
			has_r = true
			break
	if not has_r:
		var retry_key := InputEventKey.new()
		retry_key.keycode = KEY_R
		InputMap.action_add_event("retry", retry_key)

func _ensure_confirm_action() -> void:
	if not InputMap.has_action("confirm"):
		InputMap.add_action("confirm")
	var has_space := false
	for ev in InputMap.action_get_events("confirm"):
		if ev is InputEventKey and ev.keycode == KEY_SPACE:
			has_space = true
			break
	if not has_space:
		var space_key := InputEventKey.new()
		space_key.keycode = KEY_SPACE
		InputMap.action_add_event("confirm", space_key)

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
	_bgm_player.volume_db = linear_to_db(BGM_PLAYER_GAIN)
	if not _app_audio_focus:
		if _bgm_player.playing:
			_bgm_resume_position = maxf(0.0, _bgm_player.get_playback_position())
			_bgm_paused_by_focus = true
			_bgm_player.stop()
		return
	var should_play := _screen_mode == MODE_PLAYING
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

func _cell_to_world(cell: Vector2i) -> Vector2:
	return BOARD_OFFSET + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)

func _draw_board_cells() -> void:
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			if world.is_corrupted(cell):
				_draw_corruption_cell(center)
			elif (x + y) % 2 == 0:
				draw_rect(Rect2(center - Vector2(20, 20), Vector2(40, 40)), GRID_CELL_DARK, true)
			if _is_adjacent_to_corruption(cell):
				draw_rect(Rect2(center - Vector2(19, 19), Vector2(38, 38)), Color(CORRUPTION_EDGE, 0.12), false, 2.0)
			if world.is_generator(cell):
				_draw_generator(center)

func _draw_corruption_cell(center: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(state.elapsed * 2.6 + center.x * 0.03 + center.y * 0.04)
	draw_rect(Rect2(center - Vector2(20, 20), Vector2(40, 40)), CORRUPTION_FILL, true)
	draw_rect(Rect2(center - Vector2(18, 18), Vector2(36, 36)), Color(CORRUPTION_EDGE, 0.45 + pulse * 0.2), false, 2.0)
	draw_rect(Rect2(center - Vector2(12, 12), Vector2(24, 24)), Color(CORRUPTION_CORE, 0.45 + pulse * 0.15), true)
	for corner in [Vector2(-12, -12), Vector2(12, -12), Vector2(-12, 12), Vector2(12, 12)]:
		draw_line(center + corner * 0.55, center + corner, Color(CORRUPTION_EDGE, 0.4 + pulse * 0.25), 2.0)

func _draw_generator(center: Vector2) -> void:
	var phase := state.elapsed * 1.8 + center.x * 0.01
	var spin := sin(phase) * 0.22
	var body := _regular_polygon(center, 6, 13.0, PI / 6.0)
	var shell := _regular_polygon(center, 6, 18.0, PI / 6.0 + spin)
	var halo := _regular_polygon(center, 6, 21.0 + sin(phase * 2.0) * 1.5, PI / 6.0 - spin * 0.6)
	draw_polyline(halo + PackedVector2Array([halo[0]]), Color(GENERATOR_RING, 0.18), 2.0)
	draw_colored_polygon(shell, Color("25151a", 0.9))
	draw_polyline(shell + PackedVector2Array([shell[0]]), Color(GENERATOR_RING, 0.75), 2.0)
	draw_colored_polygon(body, GENERATOR_CORE)
	draw_polyline(body + PackedVector2Array([body[0]]), Color("fff1cf", 0.85), 2.0)
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var drift := Vector2(-dir.y, dir.x) * sin(phase + dir.x * 1.3 + dir.y * 1.7) * 1.5
		draw_line(center + dir * 8.0 + drift * 0.4, center + dir * 16.0 + drift, Color("5d2b22", 0.9), 3.0)
		draw_line(center + dir * 16.0 + drift, center + dir * 21.0 + drift * 1.2, Color(GENERATOR_RING, 0.7), 2.0)
	draw_circle(center, 4.0 + sin(phase * 3.0) * 0.7, Color("fff2dc", 0.65))

func _draw_spread_warning() -> void:
	var warning_cell := world.get_spread_warning_cell()
	if warning_cell == Vector2i(-1, -1):
		return
	var wc := _cell_to_world(warning_cell)
	var pulse := 0.45 + 0.55 * sin(state.elapsed * 7.0)
	draw_rect(Rect2(wc - Vector2(18, 18), Vector2(36, 36)), Color("ff7a7a", 0.1 + pulse * 0.12), true)
	draw_rect(Rect2(wc - Vector2(18, 18), Vector2(36, 36)), Color("ffd3d3", 0.55 + pulse * 0.3), false, 2.0)
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var source: Vector2i = warning_cell + dir
		if not world.is_corrupted(source):
			continue
		var source_pos := _cell_to_world(source)
		var offset := Vector2(dir.x, dir.y) * 13.0
		draw_line(source_pos + offset, wc - offset, Color(CORRUPTION_EDGE, 0.3 + pulse * 0.3), 4.0)
		draw_line(source_pos + offset * 0.6, wc - offset * 0.3, Color("ffd0d0", 0.2 + pulse * 0.18), 2.0)
		_draw_spread_seam(wc, dir, pulse)

func _draw_runes() -> void:
	for cell in world.runes:
		var c := _cell_to_world(cell)
		var pulse := 0.5 + 0.5 * sin(state.elapsed * 4.0 + c.x * 0.05)
		draw_circle(c, 18.0, Color(RUNE_BASE, 0.08 + pulse * 0.08))
		draw_arc(c, 17.0, 0.0, TAU, 24, Color(RUNE_GLOW, 0.95), 2.0)
		draw_arc(c, 11.0, 0.0, TAU, 18, Color(RUNE_BASE, 0.9), 2.0)
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_line(c + dir * 6.0, c + dir * 13.0, Color(RUNE_GLOW, 0.9), 2.0)
		draw_line(c + Vector2(-5, -7), c + Vector2(0, 7), Color(RUNE_BASE, 0.95), 2.0)
		draw_line(c + Vector2(0, 7), c + Vector2(5, -7), Color(RUNE_BASE, 0.95), 2.0)
		draw_line(c + Vector2(-3, -1), c + Vector2(3, -1), Color(RUNE_GLOW, 0.9), 2.0)

func _draw_rune_echoes() -> void:
	for echo in _rune_echoes:
		var ttl := float(echo["ttl"])
		var ratio := clampf(ttl / RUNE_ECHO_TTL, 0.0, 1.0)
		var c: Vector2 = echo["pos"]
		var radius := lerpf(11.0, 24.0, 1.0 - ratio)
		draw_arc(c, radius, 0.0, TAU, 28, Color(RUNE_GLOW, ratio * 0.65), 2.0)
		draw_arc(c, radius * 0.72, 0.0, TAU, 20, Color(PULSE_ENHANCED, ratio * 0.55), 2.0)
		draw_line(c + Vector2(-radius * 0.28, 0), c + Vector2(radius * 0.28, 0), Color("fff8d8", ratio * 0.8), 2.0)
		draw_line(c + Vector2(0, -radius * 0.28), c + Vector2(0, radius * 0.28), Color("fff8d8", ratio * 0.8), 2.0)

func _draw_detached_cable() -> void:
	var front_cell := Vector2i(-1, -1)
	for i in range(world.pulse_cells.size() - 1, -1, -1):
		var candidate: Vector2i = world.pulse_cells[i]
		if world.pulse_enhanced.has(candidate):
			front_cell = candidate
			break
	for i in range(world.detached_cable_cells.size()):
		var detached := world.detached_cable_cells[i]
		var dc := _cell_to_world(detached)
		var charged := world.pulse_enhanced.has(detached)
		var node_color := CABLE_GHOST
		var line_color := Color(CABLE_GHOST, 0.28)
		if charged:
			node_color = Color(CABLE_CHARGED, 0.78)
			line_color = Color(CABLE_CHARGED, 0.58)
			draw_circle(dc, 16.0, Color(PULSE_ENHANCED_GLOW, 0.2))
		if detached == front_cell:
			node_color = Color("f1fff6", 0.98)
			line_color = Color("d2fff0", 0.9)
			draw_circle(dc, 20.0, Color(PULSE_ENHANCED_GLOW, 0.3))
			draw_arc(dc, 15.0, 0.0, TAU, 22, Color(PULSE_ENHANCED, 0.85), 3.0)
		draw_circle(dc, 9.0, node_color)
		if i > 0:
			var dprev := _cell_to_world(world.detached_cable_cells[i - 1])
			draw_line(dc, dprev, line_color, 4.0)

func _draw_player_cable() -> void:
	for i in range(player.trail_cells.size()):
		var cell := player.trail_cells[i]
		var c := _cell_to_world(cell)
		var fade := 1.0 - float(i) / maxf(1.0, float(player.trail_cells.size()))
		var tint := Color(CABLE_BASE, 0.72 + fade * 0.22)
		if i == 0 and player.trail_length >= EMERGENCY_MIN_CABLE_LENGTH:
			tint = Color(CABLE_CHARGED, 0.92)
		draw_circle(c, 11.0 - float(i) * 1.05, tint)
		draw_circle(c, 4.0, Color("10202c", 0.6))
		if i > 0:
			var prev := _cell_to_world(player.trail_cells[i - 1])
			draw_line(c, prev, Color(CABLE_BASE, 0.85), 6.0)
			draw_line(c, prev, Color("e3ffff", 0.08 + fade * 0.08), 2.0)

func _draw_pulses() -> void:
	for cell in world.pulse_cells:
		var c := _cell_to_world(cell)
		var enhanced := world.pulse_enhanced.has(cell)
		if enhanced:
			draw_circle(c, 19.0, Color(PULSE_ENHANCED_GLOW, 0.25))
			draw_rect(Rect2(c - Vector2(15, 15), Vector2(30, 30)), Color(PULSE_ENHANCED_GLOW, 0.15), true)
			draw_rect(Rect2(c - Vector2(14, 14), Vector2(28, 28)), PULSE_ENHANCED, false, 3.0)
			draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), PULSE_ENHANCED, 3.0)
			draw_line(c + Vector2(0, -10), c + Vector2(0, 10), PULSE_ENHANCED, 3.0)
			draw_circle(c, 4.0, Color("effff9", 0.9))
		else:
			draw_rect(Rect2(c - Vector2(14, 14), Vector2(28, 28)), PULSE_BASE, false, 2.0)
			draw_line(c + Vector2(-7, 0), c + Vector2(7, 0), PULSE_BASE, 2.0)
			draw_circle(c, 3.0, Color(PULSE_BASE, 0.8))

func _regular_polygon(center: Vector2, sides: int, radius: float, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(sides):
		var angle := rotation + TAU * float(i) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _draw_spread_seam(center: Vector2, dir: Vector2i, pulse: float) -> void:
	var normal := Vector2(dir.x, dir.y)
	var tangent := Vector2(-normal.y, normal.x)
	var seam_center := center + normal * 18.0
	var half_len := 12.0
	var wobble := sin(state.elapsed * 10.0 + center.x * 0.03 + center.y * 0.05) * 1.5
	draw_line(
		seam_center - tangent * half_len,
		seam_center + tangent * half_len,
		Color(CORRUPTION_EDGE, 0.42 + pulse * 0.28),
		4.0
	)
	draw_line(
		seam_center - tangent * (half_len - 3.0) + normal * wobble,
		seam_center + tangent * (half_len - 3.0) - normal * wobble,
		Color("ffd3d3", 0.2 + pulse * 0.2),
		2.0
	)
	var notch_base := seam_center - tangent * 7.0
	for i in range(3):
		var start := notch_base + tangent * float(i * 7)
		draw_line(
			start,
			start - normal * (4.0 + pulse * 2.0),
			Color(CORRUPTION_EDGE, 0.26 + pulse * 0.18),
			2.0
		)

func _add_rune_echo(cell: Vector2i) -> void:
	_rune_echoes.append({
		"pos": _cell_to_world(cell),
		"ttl": RUNE_ECHO_TTL,
	})

func _draw_title_overlay() -> void:
	var pulse := 0.5 + 0.5 * sin(_menu_elapsed * 2.0)
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.03, 0.05, 0.08, 0.68), true)
	_draw_center_text("CHAIN CIRCUIT VAULT", 138.0, 36, Color("effff9"), _ui_numeric_font)
	_draw_title_input_demo(236.0, pulse)
	_draw_title_charge_demo(336.0, pulse)
	_draw_title_start_prompt(432.0, pulse)

func _draw_game_over_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.08, 0.02, 0.04, 0.78), true)
	_draw_center_text("SYSTEM COLLAPSE", 176.0, 34, Color("ffd7d7"), _ui_numeric_font)
	_draw_center_text(str(state.score), 242.0, 42, Color("fff6c7"), _ui_numeric_font)
	_draw_center_text(state.game_over_reason.to_upper(), 286.0, 16, Color("ff9f9f"), ThemeDB.fallback_font)
	_draw_center_text("SPACE TO RETURN TO TITLE", 352.0, 18, Color("d8e6f0"), _ui_numeric_font)

func _draw_center_text(text: String, baseline_y: float, font_size: int, color: Color, font: Font) -> void:
	if font == null:
		return
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(
		font,
		Vector2((VIEWPORT_SIZE.x - size.x) * 0.5, baseline_y),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)

func _draw_text_centered_at(text: String, center: Vector2, font_size: int, color: Color, font: Font) -> void:
	if font == null:
		return
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(
		font,
		Vector2(center.x - size.x * 0.5, center.y + size.y * 0.2),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)

func _draw_title_input_demo(baseline_y: float, pulse: float) -> void:
	var center_x := VIEWPORT_SIZE.x * 0.5
	var key_center := Vector2(center_x - 110.0, baseline_y)
	var key_size := Vector2(28, 28)
	var up := Rect2(key_center + Vector2(-14, -34), key_size)
	var left := Rect2(key_center + Vector2(-48, 0), key_size)
	var down := Rect2(key_center + Vector2(-14, 0), key_size)
	var right := Rect2(key_center + Vector2(20, 0), key_size)
	for rect in [up, left, down, right]:
		draw_rect(rect, Color("132235", 0.82), true)
		draw_rect(rect, Color("d8e6f0", 0.55), false, 2.0)
	_draw_text_centered_at("^", up.get_center(), 18, Color("effff9"), _ui_numeric_font)
	_draw_text_centered_at("<", left.get_center(), 18, Color("effff9"), _ui_numeric_font)
	_draw_text_centered_at("v", down.get_center(), 18, Color("effff9"), _ui_numeric_font)
	_draw_text_centered_at(">", right.get_center(), 18, Color("effff9"), _ui_numeric_font)
	_draw_text_centered_at("MOVE", key_center + Vector2(0, 54), 14, Color("b7cad6"), ThemeDB.fallback_font)

	var release_center := Vector2(center_x, baseline_y + 6.0)
	draw_line(release_center + Vector2(-38, 0), release_center + Vector2(38, 0), Color(CABLE_BASE, 0.42), 3.0)
	draw_line(release_center + Vector2(28, -8), release_center + Vector2(38, 0), Color(CABLE_BASE, 0.42), 2.0)
	draw_line(release_center + Vector2(28, 8), release_center + Vector2(38, 0), Color(CABLE_BASE, 0.42), 2.0)
	draw_circle(release_center, 18.0, Color(CORE_BASE, 0.08))
	draw_circle(release_center, 12.0, Color(CORE_BASE, 0.18))
	draw_line(release_center + Vector2(-5, 0), release_center + Vector2(5, 0), Color("132235", 0.82), 2.0)
	draw_line(release_center + Vector2(0, -5), release_center + Vector2(0, 5), Color("132235", 0.82), 2.0)
	_draw_text_centered_at("RELEASE", release_center + Vector2(0, 34), 14, Color("d8e6f0"), _ui_numeric_font)

	var pulse_center := Vector2(center_x + 122.0, baseline_y + 6.0)
	var grid_origin := pulse_center + Vector2(-46, -12)
	var cell := 24.0
	var step_phase := fposmod(_menu_elapsed * 1.6, 1.0)
	var active_steps := clampi(int(floor(step_phase * 5.0)), 0, 4)
	for i in range(4):
		var rect := Rect2(grid_origin + Vector2(float(i) * cell, 0), Vector2(cell, cell))
		draw_rect(rect, Color("132235", 0.62), true)
		draw_rect(rect, Color(CABLE_BASE, 0.22), false, 2.0)
		if i < active_steps:
			draw_rect(rect.grow(-3.0), Color(PULSE_ENHANCED_GLOW, 0.12), true)
			draw_rect(rect.grow(-2.0), PULSE_BASE, false, 2.0)
			draw_line(rect.get_center() + Vector2(-5, 0), rect.get_center() + Vector2(5, 0), Color(PULSE_BASE, 0.9), 2.0)
	_draw_text_centered_at("PULSE", pulse_center + Vector2(0, 34), 14, Color("9cffb5"), _ui_numeric_font)

func _draw_title_charge_demo(baseline_y: float, pulse: float) -> void:
	var grid_origin := Vector2(162, baseline_y - 11)
	var cell := 24.0
	var timeline := fposmod(_menu_elapsed * 0.7, 1.0)
	var step := clampi(int(floor(timeline * 10.0)), 0, 9)
	var pulse_cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
		Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0)
	]
	var rune_cell := Vector2i(2, 0)
	var corruption_cell := Vector2i(6, 0)
	for x in range(9):
		var rect := Rect2(grid_origin + Vector2(float(x) * cell, 0), Vector2(cell, cell))
		draw_rect(rect, Color("132235", 0.55), true)
		draw_rect(rect, Color(CABLE_BASE, 0.16), false, 2.0)
		var key := Vector2i(x, 0)
		if key == corruption_cell:
			if step < 7:
				draw_rect(rect.grow(-2.0), Color(CORRUPTION_FILL, 0.82), true)
				draw_rect(rect.grow(-1.0), Color(CORRUPTION_EDGE, 0.58), false, 2.0)
				draw_line(rect.get_center() + Vector2(-5, -5), rect.get_center() + Vector2(5, 5), Color(CORRUPTION_EDGE, 0.38), 2.0)
				draw_line(rect.get_center() + Vector2(5, -5), rect.get_center() + Vector2(-5, 5), Color(CORRUPTION_EDGE, 0.38), 2.0)
		if key == rune_cell:
			var center := rect.get_center()
			draw_circle(center, 11.0, Color(RUNE_BASE, 0.08 + pulse * 0.04))
			draw_arc(center, 10.0, 0.0, TAU, 18, Color(RUNE_GLOW, 0.88), 2.0)
			draw_arc(center, 6.0, 0.0, TAU, 14, Color(RUNE_BASE, 0.76), 2.0)
			draw_line(center + Vector2(-3, -4), center + Vector2(0, 4), Color(RUNE_BASE, 0.9), 2.0)
			draw_line(center + Vector2(0, 4), center + Vector2(3, -4), Color(RUNE_BASE, 0.9), 2.0)

	var active_count: int = min(step, pulse_cells.size())
	var enhanced_from := 99
	if step >= 3:
		enhanced_from = 2
	for i in range(active_count):
		var grid: Vector2i = pulse_cells[i]
		var rect := Rect2(grid_origin + Vector2(float(grid.x) * cell, 0), Vector2(cell, cell))
		var enhanced := i >= enhanced_from
		if enhanced:
			draw_rect(rect.grow(-3.0), Color(PULSE_ENHANCED_GLOW, 0.12), true)
			draw_rect(rect.grow(-2.0), PULSE_ENHANCED, false, 2.0)
			draw_line(rect.get_center() + Vector2(-5, 0), rect.get_center() + Vector2(5, 0), PULSE_ENHANCED, 2.0)
			draw_line(rect.get_center() + Vector2(0, -5), rect.get_center() + Vector2(0, 5), PULSE_ENHANCED, 2.0)
		else:
			draw_rect(rect.grow(-2.0), PULSE_BASE, false, 2.0)
			draw_line(rect.get_center() + Vector2(-5, 0), rect.get_center() + Vector2(5, 0), Color(PULSE_BASE, 0.9), 2.0)

	_draw_text_centered_at("RUNE -> CHARGE -> PURGE", Vector2(VIEWPORT_SIZE.x * 0.5, baseline_y + 28), 13, Color("d8e6f0"), _ui_numeric_font)

func _draw_title_start_prompt(baseline_y: float, pulse: float) -> void:
	var w := 228.0
	var rect := Rect2(Vector2((VIEWPORT_SIZE.x - w) * 0.5, baseline_y - 24.0), Vector2(w, 42))
	draw_rect(rect, Color("132235", 0.55), true)
	draw_rect(rect, Color("9cffb5", 0.35 + pulse * 0.3), false, 2.0)
	_draw_center_text("SPACE TO START", baseline_y, 22, Color("9cffb5"), _ui_numeric_font)

func _is_adjacent_to_corruption(cell: Vector2i) -> bool:
	if world.is_corrupted(cell):
		return false
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if world.is_corrupted(cell + dir):
			return true
	return false

func _reset_game(seed_value: int) -> void:
	state.reset()
	player.reset(GRID_SIZE)
	world.reset(GRID_SIZE, seed_value)
	_throw_enhanced = false
	_purify_combo = 0
	_score_popups.clear()
	_rune_echoes.clear()
	_last_warning_cell = Vector2i(-1, -1)
	_conduction_audio_step = 0
	_menu_elapsed = 0.0
	_update_hud()
	queue_redraw()

func _start_run() -> void:
	_reset_game(randi())
	_screen_mode = MODE_PLAYING
	_update_hud()
	queue_redraw()

func enable_test_mode(enabled: bool) -> void:
	test_mode = enabled

func force_reset_for_test(test_seed: int) -> void:
	_reset_game(test_seed)
	_screen_mode = MODE_PLAYING

func step_for_test(delta: float, action_a: bool, action_b: bool, action_c: bool) -> void:
	var input := {
		"move_up": action_a,
		"move_down": action_b,
		"move_left": action_c,
		"move_right": false,
	}
	_simulate_frame(delta, input)

func step_for_test_dict(delta: float, inputs: Dictionary) -> void:
	_test_inputs = {
		"move_up": bool(inputs.get("move_up", false)),
		"move_down": bool(inputs.get("move_down", false)),
		"move_left": bool(inputs.get("move_left", false)),
		"move_right": bool(inputs.get("move_right", false)),
	}
	_simulate_frame(delta, _test_inputs)

func get_metrics() -> Dictionary:
	return {
		"score": state.score,
		"game_over": state.game_over,
		"elapsed": state.elapsed,
		"active_entities": state.active_entities.size(),
		"entity_type_counts": state.entity_type_counts.duplicate(true),
		"max_single_type_ratio": state.max_single_type_ratio,
		"behavior_event_counts": state.behavior_event_counts.duplicate(true),
		"avg_active_entities_30s": state.avg_active_entities_30s,
		"untelegraphed_fail_count": state.untelegraphed_fail_count,
	}

func get_test_input_channels() -> Array:
	return [
		{"name": "move_up", "type": "bool"},
		{"name": "move_down", "type": "bool"},
		{"name": "move_left", "type": "bool"},
		{"name": "move_right", "type": "bool"},
	]

func get_monotonous_policies() -> Array:
	return [
		{"name": "no_input", "policy": func(_f): return {}},
		{"name": "hold_action", "policy": func(_f): return {"move_up": true}},
		{"name": "spam_action", "policy": func(f): return {"move_up": (f % 4) < 2}},
	]

func get_exploration_policies() -> Array:
	return [
		{"name": "cardinal_cycle", "policy": _policy_cardinal_cycle},
		{"name": "burst_release", "policy": _policy_burst_release},
		{"name": "zigzag", "policy": _policy_zigzag},
	]

func _policy_cardinal_cycle(f: int) -> Dictionary:
	var phase := (f / 10) % 4
	return {
		"move_up": phase == 0,
		"move_right": phase == 1,
		"move_down": phase == 2,
		"move_left": phase == 3,
	}

func _policy_burst_release(f: int) -> Dictionary:
	return {
		"move_up": (f % 12) < 8,
		"move_right": (f % 18) >= 9 and (f % 18) < 13,
	}

func _policy_zigzag(f: int) -> Dictionary:
	return {
		"move_left": (f % 16) < 6,
		"move_down": (f % 16) >= 8 and (f % 16) < 12,
	}

func set_wave_for_test(_target_phase: int) -> void:
	pass
