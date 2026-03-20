extends Node2D

const GameWorld = preload("res://scripts/game_world.gd")
const MetricsTracker = preload("res://metrics_tracker.gd")

var world: RefCounted = null
var renderer: Node2D = null
var sound_mgr: Node = null

# Game state: "title", "playing", "game_over"
var game_state := "title"

# Touch input state
var touch_left := false
var touch_right := false
var touch_slash := false
var touch_retry := false
var touch_start := false
var _active_touches := {}  # touch_index -> zone name
var has_touch := false  # True once first touch detected, stays true

var test_mode := false
var test_action_a := false
var test_action_b := false
var test_action_c := false

# Metric tracking
var active_entities: Array = []
var entity_type_counts: Dictionary = {}
var behavior_event_counts: Dictionary = {}
var max_single_type_ratio := 0.0
var avg_active_entities_30s := 0.0
var _entity_sample_sum := 0.0
var _entity_sample_frames := 0
var untelegraphed_fail_count := 0

# Proxy properties (test framework reads these from main)
var score: int:
	get: return world.score if world else 0
var elapsed: float:
	get: return world.elapsed if world else 0.0
var game_over: bool:
	get: return world.game_over if world else false

func _ready() -> void:
	world = GameWorld.new()

	var RendererScript = load("res://scripts/renderer.gd")
	renderer = Node2D.new()
	renderer.set_script(RendererScript)
	renderer.game_ref = self
	add_child(renderer)

	var SoundScript = load("res://scripts/sound_manager.gd")
	sound_mgr = Node.new()
	sound_mgr.set_script(SoundScript)
	add_child(sound_mgr)

	world.reset(randi())

func _input(event: InputEvent) -> void:
	if test_mode:
		return
	if event is InputEventScreenTouch:
		has_touch = true
		var te := event as InputEventScreenTouch
		if te.pressed:
			var zone := _touch_zone(te.position)
			_active_touches[te.index] = zone
		else:
			_active_touches.erase(te.index)
	elif event is InputEventScreenDrag:
		var de := event as InputEventScreenDrag
		var zone := _touch_zone(de.position)
		_active_touches[de.index] = zone
	elif event is InputEventMouseButton:
		var me := event as InputEventMouseButton
		if me.button_index == MOUSE_BUTTON_LEFT:
			if me.pressed:
				var zone := _touch_zone(me.position)
				_active_touches[999] = zone
			else:
				_active_touches.erase(999)
	_update_touch_state()

func _touch_zone(pos: Vector2) -> String:
	# Scale touch position to game coordinates (540x960)
	var vp_size := get_viewport().get_visible_rect().size
	var scale_x := 540.0 / maxf(vp_size.x, 1.0)
	var scale_y := 960.0 / maxf(vp_size.y, 1.0)
	var gx := pos.x * scale_x
	var gy := pos.y * scale_y
	# Control area: y > 730 (below game area)
	if gy > 730:
		if gx < 145:
			return "left"
		if gx < 285:
			return "right"
		if gx > 300:
			return "slash"
		return ""
	# Retry button: center of game over overlay
	if gx > 200 and gx < 340 and gy > 380 and gy < 430:
		return "retry"
	# Start button: center of title screen
	if gx > 180 and gx < 360 and gy > 465 and gy < 525:
		return "start"
	return ""

func _update_touch_state() -> void:
	touch_left = false
	touch_right = false
	touch_slash = false
	touch_retry = false
	touch_start = false
	for zone in _active_touches.values():
		match zone:
			"left": touch_left = true
			"right": touch_right = true
			"slash": touch_slash = true
			"retry": touch_retry = true
			"start": touch_start = true

func _physics_process(delta: float) -> void:
	if test_mode:
		return

	match game_state:
		"title":
			if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_Z) or touch_start or touch_slash:
				game_state = "playing"
				_reset_game()
				_active_touches.clear()
				_update_touch_state()
		"playing":
			var left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A) or touch_left
			var right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D) or touch_right
			var slash := Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_Z) or touch_slash
			_simulate_frame(delta, left, right, slash)
			if world.game_over:
				game_state = "game_over"
		"game_over":
			if Input.is_key_pressed(KEY_R) or touch_retry:
				game_state = "playing"
				_reset_game()
				_active_touches.clear()
				_update_touch_state()

func _simulate_frame(delta: float, move_left: bool, move_right: bool, do_slash: bool) -> void:
	if world.game_over:
		return
	var events: Array = world.update(delta, move_left, move_right, do_slash)
	_process_events(events)
	_update_metrics()

func _process_events(events: Array) -> void:
	for ev in events:
		var t: String = ev.get("type", "")
		if sound_mgr and sound_mgr.has_method("play_event"):
			sound_mgr.play_event(t, ev)

func _reset_game() -> void:
	world.reset(randi())
	active_entities.clear()
	var m := MetricsTracker.reset_metric_trackers({"crystal": true}, ["slash", "hit", "split", "burst", "ground_impact"])
	entity_type_counts = m["entity_type_counts"]
	behavior_event_counts = m["behavior_event_counts"]
	max_single_type_ratio = 0.0
	avg_active_entities_30s = 0.0
	_entity_sample_sum = 0.0
	_entity_sample_frames = 0
	untelegraphed_fail_count = 0

func _update_metrics() -> void:
	active_entities = world.crystals.duplicate()
	entity_type_counts = world.entity_type_counts.duplicate(true)
	behavior_event_counts = world.behavior_event_counts.duplicate(true)

	var update := MetricsTracker.update_test_metrics(
		world.elapsed, active_entities,
		_entity_sample_sum, _entity_sample_frames,
		max_single_type_ratio)
	max_single_type_ratio = float(update["max_single_type_ratio"])
	_entity_sample_sum = float(update["active_entity_sample_sum"])
	_entity_sample_frames = int(update["active_entity_sample_frames"])
	avg_active_entities_30s = float(update["avg_active_entities_30s"])

# --- Test hooks ---

func enable_test_mode(enabled: bool) -> void:
	test_mode = enabled
	game_state = "playing"

func force_reset_for_test(test_seed: int) -> void:
	seed(test_seed)
	if world == null:
		world = GameWorld.new()
	world.reset(test_seed)
	game_state = "playing"
	active_entities.clear()
	var m := MetricsTracker.reset_metric_trackers({"crystal": true}, ["slash", "hit", "split", "burst", "ground_impact"])
	entity_type_counts = m["entity_type_counts"]
	behavior_event_counts = m["behavior_event_counts"]
	max_single_type_ratio = 0.0
	avg_active_entities_30s = 0.0
	_entity_sample_sum = 0.0
	_entity_sample_frames = 0
	untelegraphed_fail_count = 0

func step_for_test(delta: float, action_a: bool, action_b: bool, action_c: bool) -> void:
	test_action_a = action_a
	test_action_b = action_b
	test_action_c = action_c
	_simulate_frame(delta, action_a, action_b, action_c)

func step_for_test_dict(delta: float, inputs: Dictionary) -> void:
	var a := bool(inputs.get("action_a", false))
	var b := bool(inputs.get("action_b", false))
	var c := bool(inputs.get("action_c", false))
	step_for_test(delta, a, b, c)

func get_metrics() -> Dictionary:
	return {
		"score": world.score,
		"game_over": world.game_over,
		"elapsed": world.elapsed,
		"active_entities": active_entities.size(),
		"entity_type_counts": entity_type_counts.duplicate(true),
		"max_single_type_ratio": max_single_type_ratio,
		"behavior_event_counts": behavior_event_counts.duplicate(true),
		"avg_active_entities_30s": avg_active_entities_30s,
		"untelegraphed_fail_count": untelegraphed_fail_count,
	}

func get_test_input_channels() -> Array:
	return [
		{"name": "action_a", "type": "bool"},
		{"name": "action_b", "type": "bool"},
		{"name": "action_c", "type": "bool"},
	]

func get_monotonous_policies() -> Array:
	return [
		{"name": "no_input", "policy": _mono_no_input},
		{"name": "spam_slash_still", "policy": _mono_spam_slash},
		{"name": "hold_left_spam_slash", "policy": _mono_left_slash},
		{"name": "hold_right_spam_slash", "policy": _mono_right_slash},
	]

func _mono_no_input(_f: int) -> Dictionary:
	return {"action_a": false, "action_b": false, "action_c": false}

func _mono_spam_slash(_f: int) -> Dictionary:
	return {"action_a": false, "action_b": false, "action_c": true}

func _mono_left_slash(_f: int) -> Dictionary:
	return {"action_a": true, "action_b": false, "action_c": true}

func _mono_right_slash(_f: int) -> Dictionary:
	return {"action_a": false, "action_b": true, "action_c": true}

func get_exploration_policies() -> Array:
	return [
		{"name": "roam_slash", "policy": _explore_roam_slash},
		{"name": "quick_burst", "policy": _explore_quick_burst},
		{"name": "wide_sweep", "policy": _explore_wide_sweep},
		{"name": "jitter_slash", "policy": _explore_jitter_slash},
	]

func _explore_roam_slash(f: int) -> Dictionary:
	var cycle := f % 360
	var a := cycle < 180
	var b := cycle >= 180
	var c := (f % 20) < 2
	return {"action_a": a, "action_b": b, "action_c": c}

func _explore_quick_burst(f: int) -> Dictionary:
	var cycle := f % 120
	var a := cycle < 60
	var b := cycle >= 60
	var c := (f % 12) < 2
	return {"action_a": a, "action_b": b, "action_c": c}

func _explore_wide_sweep(f: int) -> Dictionary:
	var cycle := f % 300
	var a := cycle < 150
	var b := cycle >= 150
	var c := (f % 15) < 3
	return {"action_a": a, "action_b": b, "action_c": c}

func _explore_jitter_slash(f: int) -> Dictionary:
	var move_cycle := f % 40
	var a := move_cycle < 20
	var b := move_cycle >= 20
	var c := (f % 10) < 2
	return {"action_a": a, "action_b": b, "action_c": c}

func set_wave_for_test(_target_phase: int) -> void:
	pass
