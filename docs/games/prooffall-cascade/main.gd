extends Node2D

const MetricsTracker = preload("res://metrics_tracker.gd")
const FieldController = preload("res://field_controller.gd")
const PlayerController = preload("res://player_controller.gd")
const HudLayer = preload("res://hud_layer.gd")
const FxAudio = preload("res://fx_audio.gd")

const GLYPH_NAMES := ["A", "E", "O"]
const GAME_OVER_INPUT_LOCK_SECONDS := 0.5
const BGM_STREAM_PATH := "res://assets/audio/bgm.mp3"
const BGM_PLAYER_GAIN := 0.18

var test_mode := false
var score := 0
var elapsed := 0.0
var game_over := false
var test_inputs := {
	"left": false,
	"right": false,
	"pulse": false,
	"rise": false,
}
var pulse_was_down := false
var rise_was_down := false
var waiting_for_title_start := false
var game_over_input_lock_remaining := 0.0

var field: FieldController
var player: PlayerController
var hud: HudLayer
var fx_audio: FxAudio
var bgm_player: AudioStreamPlayer
var bgm_enabled := false
var app_audio_focus := true
var bgm_resume_position := 0.0
var bgm_paused_by_focus := false

var active_entities: Array = []
var entity_type_counts: Dictionary = {}
var behavior_event_counts: Dictionary = {}
var max_single_type_ratio := 0.0
var avg_active_entities_30s := 0.0
var active_entity_sample_sum := 0.0
var active_entity_sample_frames := 0
var untelegraphed_fail_count := 0

func _ready() -> void:
	_ensure_actions()
	_ensure_runtime_nodes()
	_reset_game()
	_show_title_if_needed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		app_audio_focus = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		app_audio_focus = false
		if is_instance_valid(bgm_player) and bgm_player.playing:
			bgm_resume_position = maxf(0.0, bgm_player.get_playback_position())
			bgm_paused_by_focus = true
			bgm_player.stop()

func _physics_process(delta: float) -> void:
	_update_bgm_loop()
	if waiting_for_title_start:
		if test_mode or Input.is_action_just_pressed("pulse"):
			_start_from_title()
		return
	if game_over:
		game_over_input_lock_remaining = maxf(0.0, game_over_input_lock_remaining - delta)
		if not test_mode and game_over_input_lock_remaining <= 0.0 and Input.is_action_just_pressed("pulse"):
			_return_to_title()
		return
	_simulate_frame(delta)

func _simulate_frame(delta: float) -> void:
	if game_over:
		return
	_ensure_runtime_nodes()
	elapsed += delta
	var move_dir := _read_move_dir()
	var pulse_down := _read_pulse_down()
	var pulse_pressed := pulse_down and not pulse_was_down
	pulse_was_down = pulse_down
	var rise_down := _read_rise_down()
	var rise_pressed := rise_down and not rise_was_down
	rise_was_down = rise_down
	player.step(delta, move_dir, field)
	if player.has_fallen_into_void(field):
		_on_jam_fail(player.column)
		return
	if rise_pressed:
		if field.force_rise(player.column):
			MetricsTracker.inc_behavior_event(behavior_event_counts, "rise")
	if game_over:
		return
	if pulse_pressed:
		if field.trigger_pulse(player.column):
			MetricsTracker.inc_behavior_event(behavior_event_counts, "pulse")
	field.step(delta, player.column, player.is_near_void(field))
	fx_audio.update_jam_critical(delta, _max_jam_ratio())
	_refresh_focus_from_player()
	_update_test_metrics()
	hud.update_state(score, field.field_pressure)

func _refresh_focus_from_player() -> void:
	field.update_focus_from_column(player.column)
	player.set_focus_glyph(field.get_player_focus_glyph())

func _reset_game() -> void:
	_ensure_runtime_nodes()
	score = 0
	elapsed = 0.0
	game_over = false
	game_over_input_lock_remaining = 0.0
	pulse_was_down = false
	rise_was_down = false
	field.setup(100 + randi())
	player.reset(4, field.get_player_anchor(4))
	hud.clear_game_over()
	var metrics := MetricsTracker.reset_metric_trackers(
		{"glyph_0": true, "glyph_1": true, "glyph_2": true, "collapse": true},
		["pulse", "rise", "score", "danger", "death"]
		)
	entity_type_counts = metrics["entity_type_counts"]
	behavior_event_counts = metrics["behavior_event_counts"]
	max_single_type_ratio = float(metrics["max_single_type_ratio"])
	avg_active_entities_30s = float(metrics["avg_active_entities_30s"])
	active_entity_sample_sum = float(metrics["active_entity_sample_sum"])
	active_entity_sample_frames = int(metrics["active_entity_sample_frames"])
	untelegraphed_fail_count = int(metrics["untelegraphed_fail_count"])
	for key in field.get_type_counts().keys():
		entity_type_counts[key] = field.get_type_counts()[key]
	if test_mode:
		waiting_for_title_start = false
		hud.hide_title_screen()

func _read_move_dir() -> int:
	var left_down := bool(test_inputs["left"]) if test_mode else Input.is_action_pressed("move_left")
	var right_down := bool(test_inputs["right"]) if test_mode else Input.is_action_pressed("move_right")
	if left_down == right_down:
		return 0
	return -1 if left_down else 1

func _read_pulse_down() -> bool:
	return bool(test_inputs["pulse"]) if test_mode else Input.is_action_pressed("pulse")

func _read_rise_down() -> bool:
	return bool(test_inputs["rise"]) if test_mode else Input.is_action_pressed("rise")

func _update_test_metrics() -> void:
	active_entities = field.get_tile_entities()
	var update := MetricsTracker.update_test_metrics(
		elapsed,
		active_entities,
		active_entity_sample_sum,
		active_entity_sample_frames,
		max_single_type_ratio
	)
	max_single_type_ratio = float(update["max_single_type_ratio"])
	active_entity_sample_sum = float(update["active_entity_sample_sum"])
	active_entity_sample_frames = int(update["active_entity_sample_frames"])
	avg_active_entities_30s = float(update["avg_active_entities_30s"])
	entity_type_counts = field.get_type_counts()

func _on_score_event(points: int, _world_pos: Vector2) -> void:
	score += points
	MetricsTracker.inc_behavior_event(behavior_event_counts, "score")
	fx_audio.play_score(points, field.get_pressure_ratio())

func _on_pulse_event(_world_pos: Vector2, glyph: int, cluster_size: int) -> void:
	fx_audio.play_pulse(glyph, cluster_size)

func _on_rise_event(_world_pos: Vector2) -> void:
	fx_audio.play_danger(0.45)

func _on_danger_event(_world_pos: Vector2) -> void:
	MetricsTracker.inc_behavior_event(behavior_event_counts, "danger")
	fx_audio.play_danger(1.0)

func _on_pressure_step(level: int) -> void:
	fx_audio.play_pressure_step(level)

func _on_jam_fail(_column: int) -> void:
	if game_over:
		return
	game_over = true
	game_over_input_lock_remaining = GAME_OVER_INPUT_LOCK_SECONDS
	MetricsTracker.inc_behavior_event(behavior_event_counts, "death")
	fx_audio.play_game_over()
	hud.show_game_over(score)

func _ensure_actions() -> void:
	_register_action("move_left", [KEY_LEFT, KEY_A])
	_register_action("move_right", [KEY_RIGHT, KEY_D])
	_register_action("rise", [KEY_UP, KEY_W])
	_register_action("pulse", [KEY_SPACE, KEY_ENTER, KEY_DOWN, KEY_S])

func _register_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var exists := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == keycode:
				exists = true
				break
		if not exists:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)

# --- test hooks ---
func enable_test_mode(enabled: bool) -> void:
	test_mode = enabled
	if enabled:
		waiting_for_title_start = false
		if hud != null:
			hud.hide_title_screen()

func force_reset_for_test(test_seed: int) -> void:
	_ensure_runtime_nodes()
	seed(test_seed)
	field.setup(test_seed)
	player.reset(4, field.get_player_anchor(4))
	score = 0
	elapsed = 0.0
	game_over = false
	pulse_was_down = false
	rise_was_down = false
	for key in behavior_event_counts.keys():
		behavior_event_counts[key] = 0
	untelegraphed_fail_count = 0

func step_for_test(delta: float, action_a: bool, action_b: bool, action_c: bool) -> void:
	test_inputs["left"] = action_a
	test_inputs["right"] = action_b
	test_inputs["pulse"] = action_c
	test_inputs["rise"] = false
	_simulate_frame(delta)

func step_for_test_dict(delta: float, inputs: Dictionary) -> void:
	test_inputs["left"] = bool(inputs.get("left", false))
	test_inputs["right"] = bool(inputs.get("right", false))
	test_inputs["pulse"] = bool(inputs.get("pulse", false))
	test_inputs["rise"] = bool(inputs.get("rise", false))
	_simulate_frame(delta)

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

func get_test_input_channels() -> Array:
	return [
		{"name": "left", "type": "bool"},
		{"name": "right", "type": "bool"},
		{"name": "rise", "type": "bool"},
		{"name": "pulse", "type": "bool"},
	]

func get_monotonous_policies() -> Array:
	return [
		{"name": "no_input", "policy": Callable(self, "_policy_no_input")},
		{"name": "hold_pulse", "policy": Callable(self, "_policy_hold_pulse")},
		{"name": "hold_left", "policy": Callable(self, "_policy_hold_left")},
	]

func get_exploration_policies() -> Array:
	return [
		{"name": "patrol_burst", "policy": Callable(self, "_policy_patrol_burst")},
		{"name": "center_weave", "policy": Callable(self, "_policy_center_weave")},
		{"name": "slow_dive", "policy": Callable(self, "_policy_slow_dive")},
	]

func set_wave_for_test(_target_phase: int) -> void:
	pass

func _ensure_runtime_nodes() -> void:
	if field == null:
		field = FieldController.new()
		add_child(field)
		field.score_event.connect(_on_score_event)
		field.pulse_event.connect(_on_pulse_event)
		field.rise_event.connect(_on_rise_event)
		field.danger_event.connect(_on_danger_event)
		field.jam_fail.connect(_on_jam_fail)
		field.pressure_step.connect(_on_pressure_step)
	if player == null:
		player = PlayerController.new()
		add_child(player)
	if hud == null:
		hud = HudLayer.new()
		add_child(hud)
	if fx_audio == null:
		fx_audio = FxAudio.new()
		add_child(fx_audio)
	if bgm_player == null:
		_create_bgm_player()

func _create_bgm_player() -> void:
	if not ResourceLoader.exists(BGM_STREAM_PATH):
		bgm_enabled = false
		return
	var stream := load(BGM_STREAM_PATH)
	if not (stream is AudioStream):
		bgm_enabled = false
		return
	if stream is AudioStreamMP3:
		var mp3_stream := stream as AudioStreamMP3
		mp3_stream.loop = true
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = stream
	bgm_player.bus = "Master"
	bgm_player.volume_db = linear_to_db(BGM_PLAYER_GAIN)
	add_child(bgm_player)
	bgm_enabled = true

func _update_bgm_loop() -> void:
	if not bgm_enabled or not is_instance_valid(bgm_player):
		return
	if not app_audio_focus:
		if bgm_player.playing:
			bgm_resume_position = maxf(0.0, bgm_player.get_playback_position())
			bgm_paused_by_focus = true
			bgm_player.stop()
		return
	var should_play := not waiting_for_title_start and not game_over
	if should_play:
		if not bgm_player.playing:
			if bgm_paused_by_focus:
				bgm_player.play(bgm_resume_position)
				bgm_paused_by_focus = false
			else:
				bgm_player.play()
		return
	if bgm_player.playing:
		bgm_resume_position = 0.0
		bgm_paused_by_focus = false
		bgm_player.stop()

func _show_title_if_needed() -> void:
	if test_mode:
		waiting_for_title_start = false
		hud.hide_title_screen()
		return
	waiting_for_title_start = true
	hud.show_title_screen()

func _start_from_title() -> void:
	waiting_for_title_start = false
	hud.hide_title_screen()
	# Consume the start key so holding Space does not immediately trigger pulse.
	pulse_was_down = _read_pulse_down()
	rise_was_down = _read_rise_down()

func _return_to_title() -> void:
	_reset_game()
	waiting_for_title_start = true
	hud.show_title_screen()

func _max_jam_ratio() -> float:
	var max_ratio := 0.0
	var heights := field.get_column_heights()
	for col in range(heights.size()):
		max_ratio = maxf(max_ratio, field.get_jam_ratio(col))
	return max_ratio

func _policy_no_input(_frame: int) -> Dictionary:
	return {"left": false, "right": false, "rise": false, "pulse": false}

func _policy_hold_pulse(_frame: int) -> Dictionary:
	return {"left": false, "right": false, "rise": false, "pulse": true}

func _policy_hold_left(_frame: int) -> Dictionary:
	return {"left": true, "right": false, "rise": false, "pulse": false}

func _policy_patrol_burst(frame: int) -> Dictionary:
	var cycle := frame % 180
	return {
		"left": cycle < 45,
		"right": cycle >= 90 and cycle < 135,
		"rise": cycle % 90 == 54,
		"pulse": cycle % 36 == 0 or cycle % 36 == 18,
	}

func _policy_center_weave(frame: int) -> Dictionary:
	var cycle := frame % 150
	return {
		"left": cycle >= 40 and cycle < 70,
		"right": cycle < 28 or cycle >= 110,
		"rise": cycle % 120 == 35,
		"pulse": cycle % 30 == 0,
	}

func _policy_slow_dive(frame: int) -> Dictionary:
	var cycle := frame % 240
	return {
		"left": cycle >= 80 and cycle < 120,
		"right": cycle >= 140 and cycle < 210,
		"rise": cycle % 150 == 60,
		"pulse": cycle % 48 == 0,
	}
