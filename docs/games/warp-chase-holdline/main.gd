extends Node2D
const AudioSynth = preload("res://audio_synth.gd")
const AudioRuntime = preload("res://audio_runtime.gd")
const EnemyCatalog = preload("res://enemy_catalog.gd")
const WavePlanner = preload("res://wave_planner.gd")
const MetricsTracker = preload("res://metrics_tracker.gd")

const PLAYER_RADIUS := 12.0
const PLAYER_WRAP_RADIUS := 18.0
const CHASER_RADIUS := 10.0
const ARENA_MARGIN := 26.0
const PLAYTEST_FORCE_ENEMY_TYPES := [] # set [] to disable
const SHEPHERD_AURA_RADIUS := 210.0
const SHEPHERD_COMMAND_BUFF_TIME := 0.9
const SHEPHERD_COMMAND_ACCEL_MULT := 1.35
const SHEPHERD_COMMAND_SPEED_MULT := 1.22
const SHEPHERD_COMMAND_TRACK_BLEND := 0.2
const SHEPHERD_COMMAND_INTERVAL_MIN := 2.15
const SHEPHERD_COMMAND_INTERVAL_MAX := 2.85
const SHEPHERD_COMMAND_PUSH_FORCE := 210.0
const MIRROR_TRACE_BASE := 0.66
const MIRROR_TRACE_EXTRA := 0.28
const MIRROR_BOOST_TIME := 0.4
const MIRROR_BOOST_SPEED_MULT := 1.24
const MIRROR_TURN_RATE := 3.6
const MIRROR_TURN_RATE_BOOST := 2.4
const PHASE_ON_MIN := 1.24
const PHASE_ON_MAX := 1.88
const PHASE_OFF_MIN := 1.04
const PHASE_OFF_MAX := 1.64
const PHASE_TELEGRAPH_TIME := 0.66
const PLAYER_THRUST := 520.0
const PLAYER_TURN_SPEED := 2.8
const PLAYER_DRAG := 0.985
const CHASER_ACCEL := 260.0
const CHASER_DRAG := 0.992
const ENEMY_SPEED_SCALE := 0.75
const NEAR_MISS_DISTANCE := 72.0
const WAVE_DURATION := 14.0
const MAX_THREAT_BUDGET := 18.0
const THREAT_COST := {
	"hunter": 1.0,
	"drifter": 1.35,
	"orbiter": 1.65,
	"lancer": 1.95,
	"splitter": 1.55,
	"anchor": 1.70,
	"sniper": 1.85,
	"shepherd": 2.00,
	"mine_layer": 2.10,
	"mirror": 2.20,
	"phase": 2.25,
}
const ENEMY_UNLOCK_ORDER := [
	"hunter",
	"drifter",
	"orbiter",
	"lancer",
	"splitter",
	"anchor",
	"sniper",
	"shepherd",
	"mine_layer",
	"mirror",
	"phase",
]
const TYPE_MAX_RATIO := {
	"hunter": 0.56,
	"drifter": 0.46,
	"orbiter": 0.40,
	"lancer": 0.34,
	"splitter": 0.28,
	"anchor": 0.24,
	"sniper": 0.22,
	"shepherd": 0.20,
	"mine_layer": 0.18,
	"mirror": 0.16,
	"phase": 0.16,
}
const TYPE_SPAWN_COOLDOWN := {
	"hunter": 0.0,
	"drifter": 0.8,
	"orbiter": 1.0,
	"lancer": 1.2,
	"splitter": 1.4,
	"anchor": 2.0,
	"sniper": 2.4,
	"shepherd": 2.8,
	"mine_layer": 3.0,
	"mirror": 3.2,
	"phase": 3.4,
}
const SYNERGY_TEMPLATE_KEYS := [
	"orbiter_drifter",
	"anchor_lancer",
	"shepherd_splitter",
	"sniper_phase",
]
const BEHAVIOR_EVENT_KEYS := [
	"splitter_split",
	"anchor_hold",
	"sniper_shot",
	"shepherd_push",
	"mine_drop",
	"mirror_trace",
	"phase_toggle",
]
const AUDIO_MIX_RATE := 22050.0
const AUDIO_BUFFER_LENGTH := 0.5
const ENGINE_BUFFER_LENGTH := 0.12
const AMBIENT_BUFFER_LENGTH := 0.35
const BGM_STREAM_PATH := "res://assets/audio/bgm.mp3"
const BGM_PLAYER_GAIN := 0.15
const BGM_AMBIENT_MIX_SCALE := 0.58
const ENGINE_MAX_FILL_FRAMES := 1024
const AMBIENT_MAX_FILL_FRAMES := 1280
const BASE_CACHED_SFX_EVENTS := {
	"score": true,
	"near_miss": true,
	"danger": true,
	"shield_break": true,
	"ship_lost": true,
	"shield_ready": true,
	"extra_life": true,
	"wave_shift": true,
	"game_over": true,
}
const THRUST_LOOP_LEVEL := 0.22
const THRUST_LOOP_PLAYER_GAIN := 0.78
const THRUST_LOOP_FADE_SPEED := 7.5
const THRUST_LOOP_RELEASE_SPEED := 2.8
const THRUST_STOP_AMP_EPS := 0.012
const THRUST_HISS_BASE := 0.018
const THRUST_HISS_SPEED_LEVEL := 0.055
const THRUST_HISS_SPEED_GATE := 0.2
const AMBIENT_BASE_LEVEL := 0.26
const AMBIENT_DANGER_LEVEL := 0.14
const AMBIENT_MULTIPLIER_LEVEL := 0.05
const AMBIENT_THRUST_LEVEL := 0.04
const AMBIENT_SHIELD_DOWN_PENALTY := 0.03
const AMBIENT_FADE_SPEED := 5.2
const AMBIENT_RELEASE_SPEED := 1.7
const AMBIENT_STOP_AMP_EPS := 0.004
const ENEMY_MOTIF_BASE_LEVEL := 0.86
const ENEMY_MOTIF_DANGER_LEVEL := 0.34
const ENEMY_MOTIF_REFRESH_INTERVAL := 0.08
const ENEMY_COLLISION_CELL_SIZE := 112.0
const ENEMY_SPAWN_SFX_COOLDOWN := 0.1
const ENEMY_SPAWN_SFX_GLOBAL_COOLDOWN := 0.022
const ENEMY_SPAWN_SFX_PER_FRAME_LIMIT := 2
const VECTOR_GLOW_BASE := 1.0
const VECTOR_GLOW_INNER_ALPHA := 0.32
const VECTOR_GLOW_OUTER_ALPHA := 0.2

var rng := RandomNumberGenerator.new()
var arena_size := Vector2(1280, 720)

var player_pos := Vector2.ZERO
var player_vel := Vector2.ZERO
var player_angle := -PI * 0.5

var chasers: Array = []
var pulses: Array = []
var mines: Array = []
var player_explosion_lines: Array = []

var spawn_timer := 0.0
var spawn_interval := 2.2
var elapsed_time := 0.0
var difficulty := 1.0

var score := 0
var game_over := false
var near_miss_count := 0
var active_timer := 0.0
var game_over_elapsed := 0.0
var enemy_type_counts: Dictionary = {}
var synergy_event_counts: Dictionary = {}
var behavior_event_counts: Dictionary = {}
var max_single_type_ratio := 0.0
var avg_active_enemies_30s := 0.0
var _active_enemy_sample_sum := 0.0
var _active_enemy_sample_frames := 0
var untelegraphed_hit_count := 0
var wrap_grace_timer := 0.0
var current_wave_name := "W00"
var wave_index := 0
var wave_state: Dictionary = {}
var wave_rng_seed := 0
var enemy_last_spawn_time: Dictionary = {}
var multiplier := 1
var multiplier_decay_timer := 2.0
const MULTIPLIER_DECAY_INTERVAL := 2.0
const MULTIPLIER_MAX := 12
const PROXIMITY_FREEZE_RADIUS := 86.0
const NEAR_MISS_DECAY_EXTEND := 0.34
var chain_streak := 0
const INITIAL_LIVES := 3
const MAX_LIVES := 5
const EXTRA_LIFE_THRESHOLDS := [1000, 2000, 4000, 8000]
var lives := INITIAL_LIVES
var shield_active := true
var shield_recharge_timer := 0.0
const SHIELD_RECHARGE_TIME := 15.0
const SHIP_RESPAWN_DELAY := 0.62
var ship_respawn_pending := false
var ship_respawn_timer := 0.0
var hit_invuln_timer := 0.0

var test_mode := false
var test_left := false
var test_right := false
var test_thrust := false
var sfx_players: Dictionary = {}
var cached_sfx_players: Dictionary = {}
var cached_sfx_streams: Dictionary = {}
var cached_sfx_cursor: Dictionary = {}
var cached_sfx_event_map: Dictionary = {}
var pending_sfx: Array = []
var enemy_spawn_sfx_last_time: Dictionary = {}
var enemy_spawn_sfx_global_last_time := -999.0
var enemy_spawn_sfx_frame := -1
var enemy_spawn_sfx_count_in_frame := 0
var audio_rng := RandomNumberGenerator.new()
var engine_player: AudioStreamPlayer
var engine_playback: AudioStreamGeneratorPlayback
var engine_should_play := false
var engine_amp := 0.0
var engine_target_amp := 0.0
var engine_phase := 0.0
var engine_lfo_phase := 0.0
var engine_noise_state := 0.0
var engine_lp_state := 0.0
var ambient_player: AudioStreamPlayer
var ambient_playback: AudioStreamGeneratorPlayback
var ambient_amp := 0.0
var ambient_target_amp := 0.0
var ambient_state := {}
var bgm_player: AudioStreamPlayer
var bgm_enabled := false
var app_audio_focus := true
var bgm_resume_position := 0.0
var bgm_paused_by_focus := false
var enemy_motif_cache: Array = []
var enemy_motif_refresh_timer := 0.0
var danger_sfx_cooldown := 0.0
var danger_peak_hold := 0.0
var anchor_field_cache: Array = []
var vector_glow_budget_scale := 1.0
var warp_detail_scale := 1.0
var ui_font_base: Font
var ui_font_display: Font
var ui_font_numeric: Font
var ui_tokens: Dictionary = {}
var next_extra_life_index := 0
var score_flash := 0.0
var near_miss_flash := 0.0
var danger_flash := 0.0
var score_burst_flash := 0.0
var score_burst_pos := Vector2.ZERO
var damage_flash := 0.0
var anchor_slow_ratio := 0.0
var anchor_slow_feedback := 0.0
var title_screen_active := true
var title_blink_t := 0.0
var space_prev_down := false

func _ready() -> void:
	rng.randomize()
	audio_rng.randomize()
	wave_rng_seed = int(rng.randi())
	arena_size = get_viewport_rect().size
	if arena_size.x < 200.0:
		arena_size = Vector2(1280, 720)
	_setup_typography_theme()
	_setup_audio()
	_reset_game()

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
	_simulate_frame(delta)

func _process(_delta: float) -> void:
	_flush_pending_sfx()
	_update_engine_loop(_delta)
	_update_ambient_loop(_delta)

func _simulate_frame(delta: float) -> void:
	if title_screen_active and not test_mode:
		engine_should_play = false
		title_blink_t += delta
		if _is_start_pressed():
			title_screen_active = false
			_reset_game()
		queue_redraw()
		return

	if game_over:
		engine_should_play = false
		game_over_elapsed += delta
		damage_flash = maxf(0.0, damage_flash - delta * 3.0)
		var can_leave_game_over := _is_game_over_overlay_visible()
		if can_leave_game_over and _is_back_to_title_pressed():
			_return_to_title()
			return
		if not can_leave_game_over:
			space_prev_down = Input.is_physical_key_pressed(KEY_SPACE)
		_update_pulses(delta)
		_update_player_explosion_lines(delta)
		queue_redraw()
		return

	elapsed_time += delta
	difficulty = 1.0 + sqrt(elapsed_time / 100.0)
	score_flash = maxf(0.0, score_flash - delta * 2.3)
	near_miss_flash = maxf(0.0, near_miss_flash - delta * 2.8)
	danger_flash = maxf(0.0, danger_flash - delta * 1.9)
	score_burst_flash = maxf(0.0, score_burst_flash - delta * 2.4)
	damage_flash = maxf(0.0, damage_flash - delta * 2.6)
	anchor_slow_feedback = maxf(0.0, anchor_slow_feedback - delta * 1.9)
	danger_sfx_cooldown = maxf(0.0, danger_sfx_cooldown - delta)
	danger_peak_hold = maxf(0.0, danger_peak_hold - delta)
	if ship_respawn_pending:
		engine_should_play = false
		ship_respawn_timer = maxf(0.0, ship_respawn_timer - delta)
		_update_player_explosion_lines(delta)
		_update_pulses(delta)
		if ship_respawn_timer <= 0.0 and player_explosion_lines.is_empty():
			_finish_ship_respawn()
		queue_redraw()
		return

	_refresh_anchor_field_cache()
	_update_player(delta)
	wrap_grace_timer = max(0.0, wrap_grace_timer - delta)
	hit_invuln_timer = max(0.0, hit_invuln_timer - delta)
	if not shield_active:
		shield_recharge_timer -= delta
		if shield_recharge_timer <= 0.0:
			shield_active = true
			shield_recharge_timer = 0.0
			_spawn_pulse(player_pos, Color(0.46, 0.96, 1.0, 0.85), 36.0, 0.28)
			_play_sfx("shield_ready", {"difficulty": difficulty})
	_update_activity_state(delta)
	_update_chasers(delta)
	_update_mines(delta)
	_update_player_explosion_lines(delta)
	_update_multiplier_decay(delta)
	_handle_mine_collisions()
	_handle_collisions()
	_update_spawning(delta)
	_update_test_metrics()
	_update_pulses(delta)
	space_prev_down = Input.is_physical_key_pressed(KEY_SPACE)
	queue_redraw()

func _update_player(delta: float) -> void:
	var turn_axis := _get_turn_axis()
	var thrusting := _is_thrusting()
	var anchor_slow := _get_anchor_slow_ratio(player_pos)
	if anchor_slow > anchor_slow_ratio + 0.08:
		_spawn_pulse(player_pos, Color(1.0, 0.67, 0.4, 0.44), 22.0 + anchor_slow * 30.0, 0.2)
	anchor_slow_ratio = anchor_slow
	if anchor_slow > 0.01:
		anchor_slow_feedback = maxf(anchor_slow_feedback, anchor_slow)

	player_angle += turn_axis * PLAYER_TURN_SPEED * delta

	if thrusting:
		var forward := Vector2.RIGHT.rotated(player_angle)
		var thrust_scale := lerpf(1.0, 0.52, anchor_slow)
		player_vel += forward * PLAYER_THRUST * delta * thrust_scale
		active_timer = max(active_timer, 1.3)
		_spawn_pulse(player_pos - forward * 10.0, Color(0.463, 0.969, 1.0, 0.5), 18.0, 0.18)
	elif absf(turn_axis) > 0.2:
		active_timer = max(active_timer, 0.7)
	engine_should_play = thrusting and not game_over and not test_mode

	player_vel *= pow(PLAYER_DRAG, delta * 60.0)
	if anchor_slow > 0.01:
		player_vel *= pow(lerpf(1.0, 0.86, anchor_slow), delta * 60.0)
	player_pos += player_vel * delta
	var before_wrap := player_pos
	player_pos = _wrap_in_arena(player_pos, PLAYER_WRAP_RADIUS)
	if before_wrap.distance_to(player_pos) > 120.0:
		wrap_grace_timer = 0.22
		_spawn_pulse(player_pos, Color(0.463, 0.969, 1.0, 0.55), 24.0, 0.18)

func _update_activity_state(delta: float) -> void:
	active_timer = max(0.0, active_timer - delta)

func _get_anchor_slow_ratio(pos: Vector2) -> float:
	var ratio := 0.0
	for field in anchor_field_cache:
		var data: Dictionary = field
		var rr := float(data.get("radius", 0.0))
		var center := Vector2(data.get("pos", Vector2.ZERO))
		var d: float = center.distance_to(pos)
		if d < rr:
			ratio = maxf(ratio, clampf(1.0 - d / rr, 0.0, 1.0))
	return ratio

func _refresh_anchor_field_cache() -> void:
	anchor_field_cache.clear()
	for c in chasers:
		if str(c.type) != "anchor":
			continue
		if float(c.anchor_hold) <= 0.0:
			continue
		anchor_field_cache.append({
			"pos": Vector2(c.pos),
			"radius": float(c.anchor_radius),
		})

func _tick_chaser_timers(chaser: Dictionary, delta: float) -> void:
	chaser.near_cd = max(0.0, chaser.near_cd - delta)
	chaser.split_no_collide = max(0.0, float(chaser.get("split_no_collide", 0.0)) - delta)
	chaser.command_buff = max(0.0, float(chaser.get("command_buff", 0.0)) - delta)

func _default_enemy_motion(to_player: Vector2) -> Dictionary:
	var accel_dir: Vector2 = to_player.normalized() if to_player.length() > 0.001 else Vector2.ZERO
	return {
		"accel_dir": accel_dir,
		"accel": CHASER_ACCEL * (0.65 + difficulty * 0.30),
		"drag": CHASER_DRAG,
		"max_speed": 120.0 + difficulty * 70.0,
	}

func _apply_enemy_type_motion(chaser: Dictionary, enemy_type: String, to_player: Vector2, orbiters: Array, delta: float, motion: Dictionary) -> void:
	var accel_dir: Vector2 = motion["accel_dir"]
	var accel: float = float(motion["accel"])
	var drag: float = float(motion["drag"])
	var max_speed: float = float(motion["max_speed"])

	match enemy_type:
		"drifter":
			var predict_pos: Vector2 = player_pos + player_vel * 0.45
			var stab_target: Vector2 = predict_pos
			if not orbiters.is_empty():
				var nearest_orbiter: Dictionary = _find_nearest_orbiter(chaser.pos, orbiters)
				var block_vec: Vector2 = (player_pos - nearest_orbiter.pos).normalized()
				stab_target = player_pos + block_vec * 96.0 - player_vel * 0.2
				accel *= 1.16
				max_speed *= 1.18
			var toward_stab: Vector2 = (stab_target - chaser.pos).normalized()
			accel_dir = toward_stab if toward_stab.length() > 0.001 else accel_dir
			accel *= 0.78
			drag = 0.996
			max_speed *= 1.25
		"splitter", "splitter_shard":
			var bait_target: Vector2 = player_pos + player_vel * 0.25
			var to_bait: Vector2 = (bait_target - chaser.pos).normalized()
			accel_dir = to_bait if to_bait.length() > 0.001 else accel_dir
			if enemy_type == "splitter_shard":
				accel *= 0.98
				drag = 0.995
				max_speed *= 1.14
			else:
				accel *= 0.92
				drag = 0.994
				max_speed *= 1.08
		"orbiter":
			var orbit_dir: float = float(chaser.orbit_dir)
			if to_player.length() < 155.0:
				orbit_dir = -orbit_dir
				chaser.orbit_dir = orbit_dir
			var escape_axis := player_vel.normalized() if player_vel.length() > 25.0 else Vector2.RIGHT.rotated(player_angle)
			var block_center: Vector2 = player_pos + escape_axis * 118.0
			var block_target: Vector2 = block_center + escape_axis.orthogonal() * orbit_dir * 62.0
			var to_block: Vector2 = (block_target - chaser.pos).normalized()
			accel_dir = (to_block * 0.72 + accel_dir * 0.28).normalized()
			accel *= 1.12
			drag = 0.989
			max_speed *= 1.1
		"lancer":
			chaser.charge_cd = float(chaser.charge_cd) - delta
			chaser.charge_time = max(0.0, float(chaser.charge_time) - delta)
			if chaser.charge_cd <= 0.0 and chaser.charge_time <= 0.0:
				chaser.charge_time = 0.42
				chaser.charge_cd = 1.95 + rng.randf_range(0.0, 0.55)
				chaser.charge_dir = (player_pos + player_vel * 0.35 - chaser.pos).normalized()
			if float(chaser.charge_time) > 0.0:
				accel_dir = chaser.charge_dir
				accel *= 2.18
				drag = 0.998
				max_speed *= 1.52
			else:
				accel *= 0.55
				drag = 0.988
				max_speed *= 0.9
		"anchor":
			chaser.anchor_hold = max(0.0, float(chaser.anchor_hold) - delta)
			chaser.anchor_cycle = max(0.0, float(chaser.anchor_cycle) - delta)
			if float(chaser.anchor_hold) <= 0.0 and float(chaser.anchor_cycle) <= 0.0 and to_player.length() < 240.0:
				chaser.anchor_hold = 1.55 + rng.randf_range(0.0, 0.35)
				chaser.anchor_cycle = 2.5 + rng.randf_range(0.1, 0.7)
				_inc_behavior_event("anchor_hold")
			if float(chaser.anchor_hold) > 0.0:
				accel *= 0.22
				drag = 0.95
				max_speed *= 0.42
			else:
				accel *= 0.74
				drag = 0.992
				max_speed *= 0.82
		"sniper":
			var was_aiming := float(chaser.aim_time) > 0.0
			chaser.aim_time = max(0.0, float(chaser.aim_time) - delta)
			chaser.shot_cd = max(0.0, float(chaser.shot_cd) - delta)
			chaser.shot_time = max(0.0, float(chaser.shot_time) - delta)
			if float(chaser.shot_cd) <= 0.0 and float(chaser.aim_time) <= 0.0 and float(chaser.shot_time) <= 0.0:
				chaser.aim_time = 0.52
				chaser.shot_cd = 2.4 + rng.randf_range(0.1, 0.8)
				chaser.shot_dir = (player_pos + player_vel * 0.42 - chaser.pos).normalized()
			if was_aiming and float(chaser.aim_time) <= 0.0 and float(chaser.shot_time) <= 0.0:
				chaser.shot_time = 0.82
				_inc_behavior_event("sniper_shot")
				_spawn_pulse(chaser.pos, Color(1.0, 0.76, 0.52, 0.62), 30.0, 0.2)
			if float(chaser.aim_time) > 0.0:
				accel *= 0.22
				max_speed *= 0.55
			if float(chaser.shot_time) > 0.0:
				var dash_speed := (428.0 + difficulty * 56.0) * ENEMY_SPEED_SCALE
				chaser.vel = Vector2(chaser.shot_dir) * dash_speed
				accel = 0.0
				drag = 1.0
				max_speed = dash_speed
		"shepherd":
			chaser.shepherd_cmd_cd = max(0.0, float(chaser.get("shepherd_cmd_cd", 0.0)) - delta)
			if float(chaser.shepherd_cmd_cd) <= 0.0:
				var command_hits := _emit_shepherd_command(chaser)
				chaser.shepherd_cmd_cd = rng.randf_range(SHEPHERD_COMMAND_INTERVAL_MIN, SHEPHERD_COMMAND_INTERVAL_MAX)
				if command_hits > 0:
					_inc_behavior_event("shepherd_push")
			var flock_center := Vector2.ZERO
			var flock_count := 0
			for other in chasers:
				if other == chaser:
					continue
				var d: float = chaser.pos.distance_to(other.pos)
				if d <= SHEPHERD_AURA_RADIUS:
					flock_center += other.pos
					flock_count += 1
			if flock_count > 0:
				flock_center /= float(flock_count)
				var herd_dir := (player_pos - flock_center).normalized()
				accel_dir = (accel_dir * 0.35 + herd_dir * 0.65).normalized()
			accel *= 0.78
			max_speed *= 0.92
		"mine_layer":
			chaser.mine_cd = max(0.0, float(chaser.mine_cd) - delta)
			if float(chaser.mine_cd) <= 0.0:
				chaser.mine_cd = 2.1 + rng.randf_range(0.0, 0.9)
				_spawn_mine(chaser.pos, chaser.vel * 0.12)
				_inc_behavior_event("mine_drop")
			accel *= 0.66
			drag = 0.994
			max_speed *= 0.9
		"mirror":
			var axis := _get_turn_axis()
			var axis_abs := absf(axis)
			chaser.trace_timer = max(0.0, float(chaser.trace_timer) - delta)
			chaser.mirror_boost = max(0.0, float(chaser.get("mirror_boost", 0.0)) - delta)
			if axis_abs > 0.04:
				chaser.mirror_dir = sign(axis)
			if axis_abs > 0.22 and float(chaser.trace_timer) <= 0.0:
				chaser.trace_timer = 0.36
				chaser.mirror_boost = MIRROR_BOOST_TIME
				_inc_behavior_event("mirror_trace")
			var md := float(chaser.mirror_dir)
			var trace_strength := 0.0 if axis_abs <= 0.04 else axis_abs * (MIRROR_TRACE_BASE + MIRROR_TRACE_EXTRA)
			var mirror_base_dir := Vector2(chaser.get("mirror_heading", Vector2.ZERO))
			if mirror_base_dir.length() <= 0.001:
				mirror_base_dir = Vector2(chaser.vel).normalized() if Vector2(chaser.vel).length() > 0.01 else Vector2.RIGHT
			var target_dir := mirror_base_dir.rotated(md * trace_strength).normalized()
			var max_turn := (MIRROR_TURN_RATE + axis_abs * MIRROR_TURN_RATE_BOOST) * delta
			var turn_angle := clampf(mirror_base_dir.angle_to(target_dir), -max_turn, max_turn)
			mirror_base_dir = mirror_base_dir.rotated(turn_angle).normalized()
			accel_dir = mirror_base_dir
			chaser.mirror_heading = mirror_base_dir
			accel *= lerpf(1.14, 0.78, axis_abs)
			max_speed *= lerpf(1.12, 0.86, axis_abs)
			drag = 0.995
			if float(chaser.mirror_boost) > 0.0:
				accel *= 0.92
				max_speed *= 0.96
				drag = 0.997
		"phase":
			var phase_state := str(chaser.get("phase_state", "on"))
			chaser.phase_timer = max(0.0, float(chaser.phase_timer) - delta)
			if phase_state == "on":
				chaser.phase_on = true
				chaser.phase_telegraph = false
				if float(chaser.phase_timer) <= 0.0:
					chaser.phase_state = "off"
					chaser.phase_on = false
					chaser.phase_telegraph = false
					chaser.phase_timer = rng.randf_range(PHASE_OFF_MIN, PHASE_OFF_MAX)
					_inc_behavior_event("phase_toggle")
			elif phase_state == "off":
				chaser.phase_on = false
				chaser.phase_telegraph = false
				if float(chaser.phase_timer) <= 0.0:
					chaser.phase_state = "telegraph"
					chaser.phase_on = false
					chaser.phase_telegraph = true
					chaser.phase_timer = PHASE_TELEGRAPH_TIME
			else:
				chaser.phase_on = false
				chaser.phase_telegraph = true
				if float(chaser.phase_timer) <= 0.0:
					chaser.phase_state = "on"
					chaser.phase_on = true
					chaser.phase_telegraph = false
					chaser.phase_timer = rng.randf_range(PHASE_ON_MIN, PHASE_ON_MAX)
					_inc_behavior_event("phase_toggle")
			if not bool(chaser.phase_on):
				accel *= 0.74
				drag = 0.996
				max_speed *= 1.06

	motion["accel_dir"] = accel_dir
	motion["accel"] = accel
	motion["drag"] = drag
	motion["max_speed"] = max_speed

func _apply_anchor_field_modifier(enemy_type: String, chaser: Dictionary, motion: Dictionary) -> void:
	if enemy_type == "anchor":
		return
	var anchor_slow := _get_anchor_slow_ratio(chaser.pos)
	if anchor_slow <= 0.01:
		return
	motion["accel"] = float(motion["accel"]) * lerpf(1.0, 0.50, anchor_slow)
	motion["max_speed"] = float(motion["max_speed"]) * lerpf(1.0, 0.58, anchor_slow)
	motion["drag"] = lerpf(float(motion["drag"]), 0.980, anchor_slow)

func _apply_shepherd_command_modifier(enemy_type: String, chaser: Dictionary, motion: Dictionary) -> void:
	if enemy_type == "shepherd":
		return
	var command_buff := float(chaser.get("command_buff", 0.0))
	if command_buff <= 0.01:
		return
	var command_ratio := clampf(command_buff / SHEPHERD_COMMAND_BUFF_TIME, 0.0, 1.0)
	var push_dir: Vector2 = (player_pos - chaser.pos).normalized()
	var accel_dir: Vector2 = motion["accel_dir"]
	motion["accel_dir"] = (accel_dir * (1.0 - SHEPHERD_COMMAND_TRACK_BLEND) + push_dir * SHEPHERD_COMMAND_TRACK_BLEND).normalized()
	motion["accel"] = float(motion["accel"]) * lerpf(1.0, SHEPHERD_COMMAND_ACCEL_MULT, command_ratio)
	motion["max_speed"] = float(motion["max_speed"]) * lerpf(1.0, SHEPHERD_COMMAND_SPEED_MULT, command_ratio)

func _integrate_chaser_motion(chaser: Dictionary, enemy_type: String, motion: Dictionary, delta: float) -> void:
	var accel_dir: Vector2 = motion["accel_dir"]
	var accel := float(motion["accel"]) * ENEMY_SPEED_SCALE
	var drag := float(motion["drag"])
	var max_speed := float(motion["max_speed"]) * ENEMY_SPEED_SCALE
	chaser.vel += accel_dir * accel * delta
	chaser.vel *= pow(drag, delta * 60.0)
	if chaser.vel.length() > max_speed:
		chaser.vel = chaser.vel.normalized() * max_speed
	chaser.pos += chaser.vel * delta
	chaser.pos = _wrap_in_arena(chaser.pos, _get_enemy_wrap_radius(enemy_type))
	if enemy_type == "anchor" and float(chaser.anchor_hold) > 0.0:
		chaser.vel *= 0.82

func _apply_danger_feedback(nearest_threat: float) -> void:
	if nearest_threat >= 88.0:
		return
	var danger_level := clampf((88.0 - nearest_threat) / 88.0, 0.0, 1.0)
	danger_flash = maxf(danger_flash, danger_level)
	if danger_level >= 0.7 and danger_sfx_cooldown <= 0.0 and danger_peak_hold <= 0.05:
		_play_sfx("danger", {"danger": danger_level, "distance": nearest_threat, "difficulty": difficulty})
		danger_sfx_cooldown = 0.32
		danger_peak_hold = 0.28

func _update_chasers(delta: float) -> void:
	var orbiters: Array = []
	var nearest_threat := INF
	for e in chasers:
		if str(e.type) == "orbiter":
			orbiters.append(e)

	for chaser in chasers:
		_tick_chaser_timers(chaser, delta)
		var to_player: Vector2 = player_pos - chaser.pos
		var enemy_type: String = str(chaser.type)
		var motion := _default_enemy_motion(to_player)
		_apply_enemy_type_motion(chaser, enemy_type, to_player, orbiters, delta, motion)
		_apply_anchor_field_modifier(enemy_type, chaser, motion)
		_apply_shepherd_command_modifier(enemy_type, chaser, motion)
		_integrate_chaser_motion(chaser, enemy_type, motion, delta)
		var threat_d: float = chaser.pos.distance_to(player_pos) - _get_enemy_radius(enemy_type) - PLAYER_RADIUS
		if threat_d < nearest_threat:
			nearest_threat = threat_d

	_apply_danger_feedback(nearest_threat)

func _emit_shepherd_command(shepherd: Dictionary) -> int:
	var center := Vector2(shepherd.pos)
	var affected := 0
	for target in chasers:
		if target == shepherd:
			continue
		var distance_to_shepherd: float = center.distance_to(Vector2(target.pos))
		if distance_to_shepherd > SHEPHERD_AURA_RADIUS:
			continue
		target.command_buff = max(float(target.get("command_buff", 0.0)), SHEPHERD_COMMAND_BUFF_TIME)
		var away_dir: Vector2 = (Vector2(target.pos) - center).normalized()
		if away_dir.length() <= 0.001:
			away_dir = Vector2.RIGHT.rotated(rng.randf() * TAU)
		var push_ratio := clampf(1.0 - distance_to_shepherd / SHEPHERD_AURA_RADIUS, 0.0, 1.0)
		var push_impulse := SHEPHERD_COMMAND_PUSH_FORCE * (0.45 + push_ratio * 0.55) * ENEMY_SPEED_SCALE
		target.vel = Vector2(target.vel) + away_dir * push_impulse
		_spawn_pulse(Vector2(target.pos), Color(0.72, 1.0, 0.65, 0.28), 16.0, 0.18)
		affected += 1
	if affected > 0:
		_spawn_pulse(center, Color(0.72, 1.0, 0.65, 0.5), SHEPHERD_AURA_RADIUS, 0.32)
	return affected

func _spawn_mine(pos: Vector2, inherited_vel: Vector2) -> void:
	mines.append({
		"pos": pos,
		"vel": inherited_vel,
		"timer": 1.25 + rng.randf_range(0.0, 0.45),
		"armed": false,
		"life": 4.2,
		"armed_life_max": 0.0,
		"radius": 11.0,
	})

func _update_mines(delta: float) -> void:
	var next_mines: Array = []
	for m in mines:
		m.timer = float(m.timer) - delta
		m.life = float(m.life) - delta
		m.vel = Vector2(m.vel) * pow(0.965, delta * 60.0)
		m.pos = _wrap_in_arena(Vector2(m.pos) + Vector2(m.vel) * delta, float(m.radius) * 1.12)
		if float(m.timer) <= 0.0:
			if not bool(m.armed):
				m.armed = true
				m.armed_life_max = maxf(0.01, float(m.life))
		if float(m.life) > 0.0:
			next_mines.append(m)
	mines = next_mines

func _handle_mine_collisions() -> void:
	if mines.is_empty():
		return
	var next_mines: Array = []
	var enemy_removed: Array = []
	enemy_removed.resize(chasers.size())
	for i in range(enemy_removed.size()):
		enemy_removed[i] = false
	for m in mines:
		var mine_pos := Vector2(m.pos)
		var mine_r := float(m.radius)
		var consumed := false
		if bool(m.armed):
			if player_pos.distance_to(mine_pos) <= mine_r + PLAYER_RADIUS and hit_invuln_timer <= 0.0:
				consumed = true
				_on_player_hit({"pos": mine_pos, "vel": Vector2.ZERO, "type": "mine"}, player_pos.distance_to(mine_pos))
			for i in range(chasers.size()):
				if enemy_removed[i]:
					continue
				var c = chasers[i]
				if not _is_enemy_tangible(c):
					continue
				var rr := _get_enemy_radius(str(c.type))
				if Vector2(c.pos).distance_to(mine_pos) <= rr + mine_r:
					enemy_removed[i] = true
					consumed = true
					_add_score(7)
					_spawn_pulse(mine_pos, Color(1.0, 0.55, 0.32, 0.82), 34.0, 0.22)
		if not consumed:
			next_mines.append(m)
	mines = next_mines
	if enemy_removed.any(func(v): return bool(v)):
		var survivors: Array = []
		for i in range(chasers.size()):
			if not enemy_removed[i]:
				survivors.append(chasers[i])
		chasers = survivors

func _init_false_flags(count: int) -> Array:
	var flags: Array = []
	flags.resize(count)
	for i in range(flags.size()):
		flags[i] = false
	return flags

func _apply_near_miss(c: Dictionary, c_radius: float, d_player: float) -> void:
	if d_player > NEAR_MISS_DISTANCE + c_radius * 0.55 or c.near_cd > 0.0:
		return
	_add_score(6)
	_on_near_miss_bonus()
	near_miss_count += 1
	c.near_cd = 0.65
	near_miss_flash = 1.0
	_spawn_pulse(player_pos, Color(1.0, 0.784, 0.341, 0.5), 28.0, 0.22)
	_play_sfx("near_miss", {"multiplier": multiplier, "speed": player_vel.length()})

func _handle_player_enemy_contacts(remove_flags: Array) -> bool:
	for i in range(chasers.size()):
		if remove_flags[i]:
			continue
		var c = chasers[i]
		if not _is_enemy_tangible(c):
			continue
		var c_radius := _get_enemy_radius(str(c.type))
		var d_player: float = c.pos.distance_to(player_pos)
		if wrap_grace_timer <= 0.0 and hit_invuln_timer <= 0.0 and d_player <= c_radius + PLAYER_RADIUS:
			if not _is_hit_telegraphed(c):
				untelegraphed_hit_count += 1
			_on_player_hit(c, d_player)
			return true
		_apply_near_miss(c, c_radius, d_player)
	return false

func _can_enemy_pair_collide(ci: Dictionary, cj: Dictionary) -> bool:
	if not _is_enemy_tangible(ci) or not _is_enemy_tangible(cj):
		return false
	if (str(ci.type) == "splitter" or str(ci.type) == "splitter_shard") and float(ci.get("split_no_collide", 0.0)) > 0.0:
		return false
	if (str(cj.type) == "splitter" or str(cj.type) == "splitter_shard") and float(cj.get("split_no_collide", 0.0)) > 0.0:
		return false
	var ri := _get_enemy_radius(str(ci.type))
	var rj := _get_enemy_radius(str(cj.type))
	return ci.pos.distance_to(cj.pos) <= ri + rj

func _apply_enemy_pair_collision(ci: Dictionary, cj: Dictionary, remove_flags: Array, i: int, j: int, pending_split_events: Array) -> void:
	remove_flags[i] = true
	remove_flags[j] = true
	var type_i := str(ci.type)
	var type_j := str(cj.type)
	_add_score(_get_enemy_collision_score(type_i) + _get_enemy_collision_score(type_j))
	_on_enemy_chain_kill()
	_record_synergy_event(type_i, type_j)
	if type_i == "splitter":
		pending_split_events.append({"splitter": ci, "axis": cj.pos - ci.pos})
	if type_j == "splitter":
		pending_split_events.append({"splitter": cj, "axis": ci.pos - cj.pos})
	var impact_speed: float = (float(ci.vel.length()) + float(cj.vel.length())) * 0.5
	_play_sfx("score", {"multiplier": multiplier, "chain": chain_streak, "impact_speed": impact_speed})
	var center: Vector2 = (ci.pos + cj.pos) * 0.5
	score_burst_pos = center
	score_burst_flash = 1.0
	_spawn_pulse(center, Color(0.78, 1.0, 0.31, 0.95), 46.0, 0.36)

func _handle_enemy_enemy_contacts(remove_flags: Array, pending_split_events: Array) -> void:
	var grid := _build_enemy_spatial_grid()
	for i in range(chasers.size()):
		if remove_flags[i]:
			continue
		var ci = chasers[i]
		var cell := _enemy_grid_cell(Vector2(ci.pos))
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				var key := Vector2i(cell.x + ox, cell.y + oy)
				var bucket: Array = grid.get(key, [])
				for idx in bucket:
					var j := int(idx)
					if j <= i or remove_flags[j]:
						continue
					var cj = chasers[j]
					if not _can_enemy_pair_collide(ci, cj):
						continue
					_apply_enemy_pair_collision(ci, cj, remove_flags, i, j, pending_split_events)
					break
				if remove_flags[i]:
					break
			if remove_flags[i]:
				break

func _enemy_grid_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / ENEMY_COLLISION_CELL_SIZE)),
		int(floor(pos.y / ENEMY_COLLISION_CELL_SIZE))
	)

func _build_enemy_spatial_grid() -> Dictionary:
	var grid: Dictionary = {}
	for i in range(chasers.size()):
		var c = chasers[i]
		var cell := _enemy_grid_cell(Vector2(c.pos))
		if not grid.has(cell):
			grid[cell] = []
		var bucket: Array = grid[cell]
		bucket.append(i)
		grid[cell] = bucket
	return grid

func _collect_survivors(remove_flags: Array) -> Array:
	var survivors: Array = []
	for i in range(chasers.size()):
		if not remove_flags[i]:
			survivors.append(chasers[i])
	return survivors

func _handle_collisions() -> void:
	var remove_flags := _init_false_flags(chasers.size())
	var pending_split_events: Array = []
	if _handle_player_enemy_contacts(remove_flags):
		return
	_handle_enemy_enemy_contacts(remove_flags, pending_split_events)
	chasers = _collect_survivors(remove_flags)
	for evt in pending_split_events:
		_split_splitter(evt["splitter"], evt["axis"])

func _is_enemy_tangible(chaser: Dictionary) -> bool:
	if str(chaser.type) == "phase":
		return bool(chaser.phase_on)
	return true

func _split_splitter(splitter: Dictionary, axis: Vector2) -> void:
	var gen := int(splitter.get("split_gen", 0))
	if gen >= 1:
		return
	_inc_behavior_event("splitter_split")
	var center := Vector2(splitter.pos)
	var dir := axis.normalized() if axis.length() > 0.01 else Vector2.RIGHT.rotated(rng.randf() * TAU)
	var lateral := dir.orthogonal()
	for s in [-1.0, 1.0]:
		var child_pos := _wrap_in_arena(center + lateral * s * 14.0, CHASER_RADIUS)
		var child_vel: Vector2 = (Vector2(splitter.vel) * 0.35 + (dir * 44.0 + lateral * s * 112.0)) * ENEMY_SPEED_SCALE
		_spawn_splitter_shard(child_pos, child_vel, gen + 1)

func _spawn_splitter_shard(pos: Vector2, vel: Vector2, generation: int) -> void:
	var toward_player := vel.normalized() if vel.length() > 0.01 else Vector2.RIGHT
	var shard := _new_enemy_state("splitter_shard", pos, vel, toward_player)
	shard["split_gen"] = generation
	shard["anchor_cycle"] = 0.0
	shard["anchor_radius"] = 96.0
	shard["shot_cd"] = 0.0
	shard["shot_dir"] = Vector2.RIGHT
	shard["mine_cd"] = 2.0
	shard["mirror_dir"] = 1.0
	shard["phase_on"] = true
	shard["phase_state"] = "on"
	shard["phase_timer"] = rng.randf_range(PHASE_ON_MIN, PHASE_ON_MAX)
	shard["split_no_collide"] = 0.34
	shard["shepherd_cmd_cd"] = 1.0
	chasers.append(shard)
	_record_spawned_enemy("splitter_shard")

func _update_spawning(delta: float) -> void:
	if ship_respawn_pending:
		return
	if elapsed_time >= float(wave_state["end"]):
		wave_index += 1
		wave_state = _generate_wave(wave_index)
		current_wave_name = str(wave_state["name"])
		_spawn_pulse(player_pos, Color(1.0, 0.63, 0.55, 0.75), 52.0, 0.35)
		_play_sfx("wave_shift", {"difficulty": difficulty, "wave": wave_index})

	var wave_interval := float(wave_state["spawn_interval"])
	var wave_cap := int(wave_state["max_enemies"])
	var wave_weights: Dictionary = wave_state["weights"]

	spawn_interval = max(0.62, wave_interval / (1.0 + (difficulty - 1.0) * 0.26))
	spawn_timer += delta
	var max_chasers := wave_cap + int(floor((difficulty - 1.0) * 1.15))
	if spawn_timer >= spawn_interval and chasers.size() < max_chasers:
		spawn_timer = 0.0
		var spawn_type := _pick_spawnable_enemy_type(wave_weights, max_chasers)
		var forced_type := _pick_forced_enemy_type()
		if forced_type != "":
			spawn_type = forced_type
		_spawn_chaser(spawn_type)
		if chasers.size() < max_chasers and rng.randf() < 0.16 + (difficulty - 1.0) * 0.05:
			var spawn_type_extra := _pick_spawnable_enemy_type(wave_weights, max_chasers)
			var forced_type_extra := _pick_forced_enemy_type()
			if forced_type_extra != "":
				spawn_type_extra = forced_type_extra
			_spawn_chaser(spawn_type_extra)

func _update_multiplier_decay(delta: float) -> void:
	if _should_pause_decay():
		return
	multiplier_decay_timer -= delta
	while multiplier_decay_timer <= 0.0:
		multiplier = maxi(1, multiplier - 1)
		multiplier_decay_timer += _get_decay_interval_for_multiplier(multiplier)
		chain_streak = 0

func _on_enemy_chain_kill() -> void:
	multiplier = mini(MULTIPLIER_MAX, multiplier + 1)
	multiplier_decay_timer = _get_decay_interval_for_multiplier(multiplier)
	chain_streak += 1

func _on_player_hit(enemy: Dictionary, distance_to_enemy: float) -> void:
	if shield_active:
		_on_player_hit_with_shield(enemy, distance_to_enemy)
		return
	_on_player_ship_lost(enemy, distance_to_enemy)

func _on_player_hit_with_shield(enemy: Dictionary, distance_to_enemy: float) -> void:
	shield_active = false
	shield_recharge_timer = SHIELD_RECHARGE_TIME
	hit_invuln_timer = 0.32
	chain_streak = 0
	var away: Vector2 = (player_pos - enemy.pos).normalized() if distance_to_enemy > 0.001 else Vector2.RIGHT.rotated(player_angle + PI)
	player_vel += away * 360.0
	damage_flash = 1.0
	_spawn_pulse(player_pos, Color(0.28, 0.86, 1.0, 0.95), 44.0, 0.32)
	_play_sfx("shield_break", {"impact_speed": enemy.vel.length(), "difficulty": difficulty})

func _on_player_ship_lost(enemy: Dictionary, distance_to_enemy: float) -> void:
	lives = maxi(0, lives - 1)
	hit_invuln_timer = 0.0
	multiplier = 1
	chain_streak = 0
	multiplier_decay_timer = _get_decay_interval_for_multiplier(multiplier)
	var away: Vector2 = (player_pos - enemy.pos).normalized() if distance_to_enemy > 0.001 else Vector2.RIGHT.rotated(player_angle + PI)
	_spawn_player_explosion(player_pos, away)
	damage_flash = 1.0
	_spawn_pulse(player_pos, Color(1.0, 0.56, 0.5, 0.95), 38.0, 0.24)
	_play_sfx("ship_lost", {"impact_speed": enemy.vel.length(), "difficulty": difficulty, "lives": lives})
	chasers.clear()
	mines.clear()
	spawn_timer = 0.0
	if lives <= 0:
		_trigger_game_over()
		return
	ship_respawn_pending = true
	ship_respawn_timer = SHIP_RESPAWN_DELAY

func _finish_ship_respawn() -> void:
	ship_respawn_pending = false
	ship_respawn_timer = 0.0
	player_pos = arena_size * 0.5
	player_vel = Vector2.ZERO
	player_angle = -PI * 0.5
	shield_active = true
	shield_recharge_timer = 0.0
	hit_invuln_timer = 0.7
	wrap_grace_timer = 0.38
	active_timer = 0.85

func _on_near_miss_bonus() -> void:
	var cap := _get_decay_interval_for_multiplier(multiplier) * 1.35
	multiplier_decay_timer = min(cap, multiplier_decay_timer + NEAR_MISS_DECAY_EXTEND)

func _get_decay_interval_for_multiplier(multi: int) -> float:
	if multi <= 2:
		return MULTIPLIER_DECAY_INTERVAL * 1.3
	if multi <= 5:
		return MULTIPLIER_DECAY_INTERVAL
	if multi <= 8:
		return MULTIPLIER_DECAY_INTERVAL * 0.8
	return MULTIPLIER_DECAY_INTERVAL * 0.62

func _should_pause_decay() -> bool:
	if player_vel.length() < 34.0 and active_timer < 0.2:
		return false
	for c in chasers:
		var rr := _get_enemy_radius(str(c.type)) + PLAYER_RADIUS + PROXIMITY_FREEZE_RADIUS
		if c.pos.distance_to(player_pos) <= rr:
			return true
	return false

func _update_pulses(delta: float) -> void:
	var next_pulses: Array = []
	for p in pulses:
		p.age += delta
		if p.age < p.life:
			next_pulses.append(p)
	pulses = next_pulses

func _spawn_player_explosion(pos: Vector2, direction_hint: Vector2 = Vector2.ZERO) -> void:
	for i in range(16):
		var base_angle := float(i) / 16.0 * TAU + rng.randf_range(-0.15, 0.15)
		var dir := Vector2.RIGHT.rotated(base_angle)
		if direction_hint.length() > 0.01:
			dir = (dir * 0.62 + direction_hint.normalized() * 0.38).normalized()
		player_explosion_lines.append({
			"pos": pos,
			"dir": dir,
			"speed": rng.randf_range(120.0, 240.0),
			"len": rng.randf_range(8.0, 18.0),
			"life": 0.34 + rng.randf_range(0.0, 0.18),
			"age": 0.0,
			"width": rng.randf_range(0.9, 1.8),
		})

func _update_player_explosion_lines(delta: float) -> void:
	var next_lines: Array = []
	for seg in player_explosion_lines:
		seg.age += delta
		if float(seg.age) >= float(seg.life):
			continue
		seg.pos = _wrap_in_arena(Vector2(seg.pos) + Vector2(seg.dir) * float(seg.speed) * delta, 2.0)
		next_lines.append(seg)
	player_explosion_lines = next_lines

func _random_spawn_edge_position(radius: float) -> Vector2:
	var side := rng.randi_range(0, 3)
	var min_x := ARENA_MARGIN + radius + 2.0
	var max_x := arena_size.x - ARENA_MARGIN - radius - 2.0
	var min_y := ARENA_MARGIN + radius + 2.0
	var max_y := arena_size.y - ARENA_MARGIN - radius - 2.0
	if side == 0:
		return Vector2(min_x, rng.randf_range(min_y, max_y))
	if side == 1:
		return Vector2(max_x, rng.randf_range(min_y, max_y))
	if side == 2:
		return Vector2(rng.randf_range(min_x, max_x), min_y)
	return Vector2(rng.randf_range(min_x, max_x), max_y)

func _new_enemy_state(enemy_type: String, pos: Vector2, vel: Vector2, toward_player: Vector2) -> Dictionary:
	var phase_on := rng.randf() > 0.45
	var phase_timer := rng.randf_range(PHASE_ON_MIN, PHASE_ON_MAX) if phase_on else rng.randf_range(PHASE_OFF_MIN, PHASE_OFF_MAX)
	return {
		"pos": pos,
		"vel": vel,
		"near_cd": 0.35,
		"type": enemy_type,
		"split_gen": 0,
		"orbit_dir": -1.0 if rng.randf() < 0.5 else 1.0,
		"charge_cd": rng.randf_range(0.8, 1.6),
		"charge_time": 0.0,
		"charge_dir": toward_player,
		"anchor_hold": 0.0,
		"anchor_cycle": rng.randf_range(0.3, 1.4),
		"anchor_radius": 122.0,
		"aim_time": 0.0,
		"shot_cd": rng.randf_range(0.6, 1.8),
		"shot_time": 0.0,
		"shot_dir": toward_player,
		"mine_cd": rng.randf_range(0.8, 2.0),
		"trace_timer": 0.0,
		"mirror_dir": -1.0 if rng.randf() < 0.5 else 1.0,
		"mirror_boost": 0.0,
		"mirror_heading": vel.normalized() if vel.length() > 0.01 else toward_player,
		"phase_timer": phase_timer,
		"phase_on": phase_on,
		"phase_state": "on" if phase_on else "off",
		"phase_telegraph": false,
		"command_buff": 0.0,
		"shepherd_cmd_cd": rng.randf_range(0.7, 1.5),
	}

func _spawn_chaser(enemy_type: String = "") -> void:
	var p := _random_spawn_edge_position(CHASER_RADIUS)
	var toward_player := (player_pos - p).normalized()
	var tangent := toward_player.orthogonal() * rng.randf_range(-35.0, 35.0)
	var init_vel := (toward_player * rng.randf_range(18.0, 55.0) + tangent) * ENEMY_SPEED_SCALE
	var final_type := enemy_type if enemy_type != "" else "hunter"
	chasers.append(_new_enemy_state(final_type, p, init_vel, toward_player))
	_record_spawned_enemy(final_type)
	enemy_last_spawn_time[final_type] = elapsed_time
	_play_enemy_spawn_sfx(final_type, p)

func _spawn_pulse(pos: Vector2, color: Color, max_radius: float, life: float) -> void:
	pulses.append({"pos": pos, "color": color, "max_r": max_radius, "life": life, "age": 0.0})

func _setup_audio() -> void:
	cached_sfx_event_map = _build_cached_sfx_event_map()
	_build_cached_sfx_streams()
	for event_name in _all_runtime_sfx_events():
		_create_sfx_player(str(event_name))
	_create_engine_player()
	_create_bgm_player()
	_create_ambient_player()

func _build_cached_sfx_event_map() -> Dictionary:
	var map := BASE_CACHED_SFX_EVENTS.duplicate(true)
	for enemy_type in ENEMY_UNLOCK_ORDER:
		map[_enemy_spawn_event_name(str(enemy_type))] = true
	return map

func _all_runtime_sfx_events() -> Array:
	return AudioRuntime.all_runtime_sfx_events(ENEMY_UNLOCK_ORDER)

func _create_sfx_player(event_name: String) -> void:
	if cached_sfx_event_map.has(event_name):
		var variants: Array = cached_sfx_streams.get(event_name, [])
		if variants.is_empty():
			return
		var pool: Array = AudioRuntime.create_cached_player_pool(variants, 6, "Master")
		for player_cached in pool:
			add_child(player_cached)
		cached_sfx_players[event_name] = pool
		cached_sfx_cursor[event_name] = 0
		return
	var player := AudioRuntime.create_generator_player(AUDIO_MIX_RATE, AUDIO_BUFFER_LENGTH, "Master")
	add_child(player)
	sfx_players[event_name] = player

func _build_cached_sfx_streams() -> void:
	cached_sfx_streams = AudioRuntime.build_cached_sfx_streams(cached_sfx_event_map, AUDIO_MIX_RATE)

func _create_engine_player() -> void:
	engine_player = AudioStreamPlayer.new()
	engine_player.stream = AudioRuntime.build_thrust_loop_stream(AUDIO_MIX_RATE)
	engine_player.bus = "Master"
	engine_player.volume_db = linear_to_db(0.0001)
	add_child(engine_player)

func _create_ambient_player() -> void:
	ambient_player = AudioRuntime.create_generator_player(AUDIO_MIX_RATE, AMBIENT_BUFFER_LENGTH, "Master", 8.0)
	add_child(ambient_player)

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

func _stop_all_sfx() -> void:
	AudioRuntime.stop_audio_players(sfx_players.values())
	for pool_item in cached_sfx_players.values():
		var pool: Array = pool_item
		AudioRuntime.stop_audio_players(pool)
	AudioRuntime.stop_if_valid(engine_player)
	AudioRuntime.stop_if_valid(ambient_player)
	AudioRuntime.stop_if_valid(bgm_player)
	bgm_resume_position = 0.0
	bgm_paused_by_focus = false
	engine_playback = null
	ambient_playback = null
	var state := AudioRuntime.reset_audio_runtime_state()
	engine_amp = float(state["engine_amp"])
	engine_target_amp = float(state["engine_target_amp"])
	engine_should_play = bool(state["engine_should_play"])
	ambient_amp = float(state["ambient_amp"])
	ambient_target_amp = float(state["ambient_target_amp"])
	ambient_state.clear()
	enemy_motif_cache.clear()
	enemy_motif_refresh_timer = 0.0
	enemy_spawn_sfx_global_last_time = -999.0
	enemy_spawn_sfx_frame = -1
	enemy_spawn_sfx_count_in_frame = 0
	pending_sfx.clear()
	cached_sfx_cursor.clear()

func _play_sfx(event_name: String, params: Dictionary = {}) -> void:
	if test_mode:
		return
	if _try_play_cached_sfx(event_name, params):
		return
	_enqueue_pending_sfx(event_name, params)

func _try_play_cached_sfx(event_name: String, params: Dictionary) -> bool:
	if not cached_sfx_event_map.has(event_name):
		return false
	var pool: Array = cached_sfx_players.get(event_name, [])
	if pool.is_empty():
		return true
	var cursor := int(cached_sfx_cursor.get(event_name, 0))
	var player_cached: AudioStreamPlayer = pool[cursor % pool.size()]
	cached_sfx_cursor[event_name] = (cursor + 1) % pool.size()
	player_cached.pitch_scale = _cached_event_pitch_scale(event_name, params)
	player_cached.volume_db = _cached_event_volume_db(event_name, params)
	if player_cached.playing:
		player_cached.stop()
	player_cached.play()
	return true

func _enqueue_pending_sfx(event_name: String, params: Dictionary) -> void:
	pending_sfx.append(AudioRuntime.make_pending_sfx_item(event_name, params, 4))

func _flush_pending_sfx() -> void:
	if pending_sfx.is_empty():
		return
	var keep: Array = []
	for item in pending_sfx:
		if _try_render_pending_sfx_item(item):
			keep.append(item)
	pending_sfx = keep

func _try_render_pending_sfx_item(item: Dictionary) -> bool:
	var event_name: String = str(item["event"])
	var params: Dictionary = item["params"]
	var player: AudioStreamPlayer = sfx_players.get(event_name)
	if player == null:
		return false
	if player.playing:
		player.stop()
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback == null or playback.get_frames_available() <= 0:
		return AudioRuntime.consume_retry(item)
	_render_sfx(playback, event_name, params)
	return false

func _render_sfx(playback: AudioStreamGeneratorPlayback, event_name: String, params: Dictionary) -> void:
	var player: AudioStreamPlayer = sfx_players.get(event_name)
	if player == null or playback == null:
		return
	AudioSynth.render_sfx_event(playback, event_name, params, audio_rng, AUDIO_MIX_RATE)

func _cached_event_pitch_scale(event_name: String, params: Dictionary) -> float:
	return AudioRuntime.cached_event_pitch_scale(event_name, params)

func _cached_event_volume_db(event_name: String, params: Dictionary) -> float:
	return AudioRuntime.cached_event_volume_db(event_name, params)

func _enemy_spawn_event_name(enemy_type: String) -> String:
	return AudioRuntime.enemy_spawn_event_name(enemy_type)

func _play_enemy_spawn_sfx(enemy_type: String, spawn_pos: Vector2) -> void:
	if enemy_type == "":
		return
	if not _can_emit_enemy_spawn_sfx():
		return
	var key := str(enemy_type)
	var last_t := float(enemy_spawn_sfx_last_time.get(key, -999.0))
	if not AudioRuntime.should_emit_spawn_sfx(last_t, elapsed_time, ENEMY_SPAWN_SFX_COOLDOWN):
		return
	if not AudioRuntime.should_emit_spawn_sfx(enemy_spawn_sfx_global_last_time, elapsed_time, ENEMY_SPAWN_SFX_GLOBAL_COOLDOWN):
		return
	enemy_spawn_sfx_last_time[key] = elapsed_time
	enemy_spawn_sfx_global_last_time = elapsed_time
	enemy_spawn_sfx_count_in_frame += 1
	var pan := AudioRuntime.spawn_pan(spawn_pos.x, arena_size.x)
	_play_sfx(_enemy_spawn_event_name(key), {"enemy_type": key, "pan": pan, "volume": 0.22})

func _can_emit_enemy_spawn_sfx() -> bool:
	var frame := Engine.get_physics_frames()
	if frame != enemy_spawn_sfx_frame:
		enemy_spawn_sfx_frame = frame
		enemy_spawn_sfx_count_in_frame = 0
	return enemy_spawn_sfx_count_in_frame < ENEMY_SPAWN_SFX_PER_FRAME_LIMIT

func _update_engine_loop(delta: float) -> void:
	if not _is_runtime_audio_active() or not is_instance_valid(engine_player):
		return
	_update_engine_envelope(delta)
	_apply_engine_loop_controls()

func _is_runtime_audio_active() -> bool:
	return AudioRuntime.is_runtime_audio_active(test_mode)

func _is_live_thrust_active() -> bool:
	return AudioRuntime.live_thrust_active(_is_thrusting(), title_screen_active, game_over, ship_respawn_pending)

func _update_engine_envelope(delta: float) -> void:
	engine_should_play = _is_live_thrust_active()
	if engine_should_play:
		engine_target_amp = THRUST_LOOP_LEVEL
		var blend := clampf(delta * THRUST_LOOP_FADE_SPEED, 0.0, 1.0)
		engine_amp = lerpf(engine_amp, engine_target_amp, blend)
		return
	engine_target_amp = 0.0
	engine_amp = move_toward(engine_amp, 0.0, delta * THRUST_LOOP_RELEASE_SPEED)

func _apply_engine_loop_controls() -> void:
	if engine_amp <= THRUST_STOP_AMP_EPS and not engine_should_play:
		if engine_player.playing:
			engine_player.stop()
		return
	if not engine_player.playing:
		engine_player.play()
	var speed_factor: float = clampf(player_vel.length() / 300.0, 0.0, 1.0)
	var pitch := lerpf(0.86, 1.26, speed_factor) * (1.0 + (difficulty - 1.0) * 0.025)
	engine_player.pitch_scale = clampf(pitch, 0.75, 1.45)
	var amp_ratio := clampf(engine_amp / maxf(0.001, THRUST_LOOP_LEVEL), 0.0, 1.0)
	var gain_linear := maxf(0.0001, amp_ratio * THRUST_LOOP_PLAYER_GAIN)
	engine_player.volume_db = linear_to_db(gain_linear)

func _update_ambient_loop(delta: float) -> void:
	if not _is_runtime_audio_active() or not is_instance_valid(ambient_player):
		return
	if bgm_enabled:
		_update_bgm_loop()
	if _can_play_ambient_content():
		_update_ambient_gameplay(delta)
		return
	_update_ambient_release(delta)

func _update_bgm_loop() -> void:
	if not is_instance_valid(bgm_player):
		return
	if not app_audio_focus:
		if bgm_player.playing:
			bgm_resume_position = maxf(0.0, bgm_player.get_playback_position())
			bgm_paused_by_focus = true
			bgm_player.stop()
		return
	if _can_play_bgm_content():
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

func _can_play_bgm_content() -> bool:
	return not title_screen_active and not game_over

func _can_play_ambient_content() -> bool:
	return AudioRuntime.can_play_ambient_content(title_screen_active, game_over, ship_respawn_pending)

func _ensure_ambient_playback_ready() -> bool:
	if not ambient_player.playing:
		ambient_player.play()
	ambient_playback = ambient_player.get_stream_playback()
	return ambient_playback != null

func _update_ambient_gameplay(delta: float) -> void:
	var params := _build_ambient_params(delta)
	var danger := float(params.get("danger", 0.0))
	var enemy_motifs: Array = params.get("enemy_motifs", [])
	ambient_target_amp = 0.0
	if not enemy_motifs.is_empty():
		ambient_target_amp = ENEMY_MOTIF_BASE_LEVEL + danger * ENEMY_MOTIF_DANGER_LEVEL
		if bgm_enabled:
			ambient_target_amp *= BGM_AMBIENT_MIX_SCALE
	ambient_amp = lerpf(ambient_amp, ambient_target_amp, clampf(delta * AMBIENT_FADE_SPEED, 0.0, 1.0))
	if not _ensure_ambient_playback_ready():
		return
	params["master_amp"] = 0.0
	params["enemy_amp"] = ambient_amp
	params["bed_enabled"] = false
	AudioSynth.push_ambient_frames(ambient_playback, params, ambient_state, audio_rng, AUDIO_MIX_RATE, AMBIENT_MAX_FILL_FRAMES)

func _ambient_release_params() -> Dictionary:
	return AudioRuntime.ambient_release_params(elapsed_time)
func _update_ambient_release(delta: float) -> void:
	ambient_target_amp = 0.0
	ambient_amp = move_toward(ambient_amp, 0.0, delta * AMBIENT_RELEASE_SPEED)
	if ambient_amp <= AMBIENT_STOP_AMP_EPS:
		if ambient_player.playing:
			ambient_player.stop()
		ambient_playback = null
		ambient_state.clear()
		return
	if not _ensure_ambient_playback_ready():
		return
	var release_params := _ambient_release_params()
	AudioSynth.push_ambient_frames(ambient_playback, release_params, ambient_state, audio_rng, AUDIO_MIX_RATE, AMBIENT_MAX_FILL_FRAMES)

func _build_ambient_params(delta: float) -> Dictionary:
	var nearest_threat := _get_nearest_threat_distance()
	var danger := 0.0
	if nearest_threat < 180.0:
		danger = clampf((180.0 - nearest_threat) / 180.0, 0.0, 1.0)
	var wave_ratio := clampf(float(wave_index) / 10.0, 0.0, 1.0)
	var shield_ratio := 1.0
	if not shield_active:
		shield_ratio = clampf(1.0 - shield_recharge_timer / SHIELD_RECHARGE_TIME, 0.0, 1.0)
	var enemy_density := clampf(float(chasers.size()) / 12.0, 0.0, 1.0)
	return {
		"danger": danger,
		"speed": player_vel.length(),
		"turn": absf(_get_turn_axis()),
		"multiplier": float(multiplier),
		"time": elapsed_time,
		"wave_ratio": wave_ratio,
		"shield_ratio": shield_ratio,
		"shield_up": shield_active,
		"thrust": 1.0 if _is_thrusting() else 0.0,
		"anchor_slow": anchor_slow_ratio,
		"enemy_density": enemy_density,
		"enemy_motifs": _get_cached_enemy_motif_params(delta),
	}

func _get_cached_enemy_motif_params(delta: float) -> Array:
	if enemy_motif_refresh_timer <= 0.0:
		enemy_motif_cache = _collect_enemy_motif_params()
		enemy_motif_refresh_timer = ENEMY_MOTIF_REFRESH_INTERVAL
	else:
		enemy_motif_refresh_timer = maxf(0.0, enemy_motif_refresh_timer - delta)
	return enemy_motif_cache

func _get_nearest_threat_distance() -> float:
	var nearest := 9999.0
	for chaser in chasers:
		var enemy_type := str(chaser.get("type", "hunter"))
		var d := Vector2(chaser.pos).distance_to(player_pos) - _get_enemy_radius(enemy_type) - PLAYER_RADIUS
		if d < nearest:
			nearest = d
	for mine in mines:
		var d_mine := Vector2(mine.pos).distance_to(player_pos) - float(mine.get("radius", 11.0)) - PLAYER_RADIUS
		if d_mine < nearest:
			nearest = d_mine
	return nearest

func _collect_enemy_motif_params() -> Array:
	const MOTIF_AUDIBLE_DIST := 760.0
	var nearest_by_type: Dictionary = {}
	for chaser in chasers:
		var enemy_type := str(chaser.get("type", "hunter"))
		var offset := Vector2(chaser.pos) - player_pos
		var dist := maxf(0.0, offset.length() - _get_enemy_radius(enemy_type) - PLAYER_RADIUS)
		var has_current := nearest_by_type.has(enemy_type)
		if not has_current or dist < float(nearest_by_type[enemy_type]["dist"]):
			nearest_by_type[enemy_type] = {
				"type": enemy_type,
				"dist": dist,
				"pan": clampf(offset.x / maxf(180.0, arena_size.x * 0.45), -1.0, 1.0),
			}
	var motifs: Array = []
	for value in nearest_by_type.values():
		var item: Dictionary = value
		if float(item.get("dist", 9999.0)) > MOTIF_AUDIBLE_DIST:
			continue
		motifs.append(item)
	return motifs

func _reset_game() -> void:
	_stop_all_sfx()
	engine_should_play = false
	score = 0
	game_over = false
	game_over_elapsed = 0.0
	near_miss_count = 0
	active_timer = 0.8
	wrap_grace_timer = 0.0
	elapsed_time = 0.0
	difficulty = 1.0
	wave_index = 0
	wave_state = _generate_wave(wave_index)
	current_wave_name = str(wave_state["name"])
	spawn_timer = 0.0
	spawn_interval = float(wave_state["spawn_interval"])
	player_pos = arena_size * 0.5
	player_vel = Vector2.ZERO
	player_angle = -PI * 0.5
	multiplier = 1
	multiplier_decay_timer = _get_decay_interval_for_multiplier(multiplier)
	chain_streak = 0
	lives = INITIAL_LIVES
	next_extra_life_index = 0
	anchor_slow_ratio = 0.0
	anchor_slow_feedback = 0.0
	shield_active = true
	shield_recharge_timer = 0.0
	ship_respawn_pending = false
	ship_respawn_timer = 0.0
	hit_invuln_timer = 0.0
	danger_sfx_cooldown = 0.0
	danger_peak_hold = 0.0
	_reset_metric_trackers()
	enemy_last_spawn_time.clear()
	enemy_spawn_sfx_last_time.clear()
	enemy_spawn_sfx_global_last_time = -999.0
	enemy_spawn_sfx_frame = -1
	enemy_spawn_sfx_count_in_frame = 0
	enemy_motif_cache.clear()
	enemy_motif_refresh_timer = 0.0
	chasers.clear()
	mines.clear()
	pulses.clear()
	player_explosion_lines.clear()
	for _i in range(3):
		var initial_type := "hunter"
		var forced_initial := _pick_forced_enemy_type()
		if forced_initial != "":
			initial_type = forced_initial
		_spawn_chaser(initial_type)

func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	game_over_elapsed = 0.0
	multiplier = 1
	multiplier_decay_timer = _get_decay_interval_for_multiplier(multiplier)
	chain_streak = 0
	engine_should_play = false
	damage_flash = 0.0
	_spawn_pulse(player_pos, Color(1.0, 0.37, 0.43, 0.9), 54.0, 0.45)
	_play_sfx("game_over", {"difficulty": difficulty, "multiplier": multiplier})

func _is_back_to_title_pressed() -> bool:
	if test_mode:
		return false
	if game_over_elapsed < 0.12:
		return false
	return _is_space_just_pressed()

func _is_start_pressed() -> bool:
	return _is_space_just_pressed()

func _return_to_title() -> void:
	title_screen_active = true
	title_blink_t = 0.0
	_reset_game()

func _is_space_just_pressed() -> bool:
	var down := Input.is_physical_key_pressed(KEY_SPACE)
	var just := down and not space_prev_down
	space_prev_down = down
	return just

func _is_game_over_overlay_visible() -> bool:
	# Show GAME OVER roughly when the ship explosion has settled.
	return game_over_elapsed >= 0.28 and player_explosion_lines.is_empty()

func _is_outside_arena(pos: Vector2, radius: float) -> bool:
	return pos.x < ARENA_MARGIN + radius or pos.x > arena_size.x - ARENA_MARGIN - radius or pos.y < ARENA_MARGIN + radius or pos.y > arena_size.y - ARENA_MARGIN - radius

func _wrap_in_arena(pos: Vector2, radius: float) -> Vector2:
	# Wrap only after the object's visual radius has mostly exited the arena.
	var min_x := ARENA_MARGIN - radius
	var max_x := arena_size.x - ARENA_MARGIN + radius
	var min_y := ARENA_MARGIN - radius
	var max_y := arena_size.y - ARENA_MARGIN + radius
	var wrapped := pos
	if wrapped.x < min_x:
		wrapped.x = max_x - (min_x - wrapped.x)
	elif wrapped.x > max_x:
		wrapped.x = min_x + (wrapped.x - max_x)
	if wrapped.y < min_y:
		wrapped.y = max_y - (min_y - wrapped.y)
	elif wrapped.y > max_y:
		wrapped.y = min_y + (wrapped.y - max_y)
	return wrapped

func _get_turn_axis() -> float:
	if test_mode:
		return float(int(test_right)) - float(int(test_left))
	var left_pressed := Input.is_action_pressed("ui_left")
	var right_pressed := Input.is_action_pressed("ui_right")
	if InputMap.has_action("move_left"):
		left_pressed = left_pressed or Input.is_action_pressed("move_left")
	if InputMap.has_action("move_right"):
		right_pressed = right_pressed or Input.is_action_pressed("move_right")
	left_pressed = left_pressed or Input.is_physical_key_pressed(KEY_A)
	right_pressed = right_pressed or Input.is_physical_key_pressed(KEY_D)
	return float(int(right_pressed)) - float(int(left_pressed))

func _is_thrusting() -> bool:
	if test_mode:
		return test_thrust
	var thrusting := Input.is_action_pressed("ui_accept")
	if InputMap.has_action("thrust"):
		thrusting = thrusting or Input.is_action_pressed("thrust")
	thrusting = thrusting or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	return thrusting

func _draw() -> void:
	if chasers.size() >= 8 or mines.size() >= 8:
		vector_glow_budget_scale = 0.58
		warp_detail_scale = 0.62
	else:
		vector_glow_budget_scale = 1.0
		warp_detail_scale = 1.0
	draw_rect(Rect2(Vector2.ZERO, arena_size), Color(0.05, 0.075, 0.13, 1.0), true)
	_draw_warped_grid()
	_draw_atmosphere_overlay()
	draw_rect(Rect2(Vector2(ARENA_MARGIN, ARENA_MARGIN), arena_size - Vector2.ONE * ARENA_MARGIN * 2.0), Color(0.15, 0.2, 0.3, 0.8), false, 2.0)
	if title_screen_active:
		_draw_title_screen()
		return
	_draw_threat_links()
	_draw_chasers()
	_draw_mines()
	_draw_player()
	_draw_player_explosion_lines()
	_draw_pulses()
	_draw_score_burst_feedback()
	_draw_ui()

func _draw_warped_grid() -> void:
	_draw_warped_grid_layer(72.0, 1.3, 0.62, Vector2(8.0, -6.0), 0.42)
	if warp_detail_scale > 0.9:
		_draw_warped_grid_layer(48.0, 2.2, 1.0, Vector2(-11.0, 9.0), 1.0)

func _draw_warped_grid_layer(spacing: float, warp_amp: float, flow_speed: float, flow_dir: Vector2, alpha_scale: float) -> void:
	var period := spacing * 2.0
	var flow := flow_dir * elapsed_time * flow_speed
	var offset_x := fposmod(flow.x, period)
	var offset_y := fposmod(flow.y, period)
	var min_x := ARENA_MARGIN - period
	var max_x := arena_size.x - ARENA_MARGIN + period
	var min_y := ARENA_MARGIN - period
	var max_y := arena_size.y - ARENA_MARGIN + period
	for x in range(int(min_x), int(max_x) + 1, int(spacing)):
		var x_pos := float(x) + offset_x
		var p1 := _warp_point(Vector2(x_pos, ARENA_MARGIN), warp_amp)
		var p2 := _warp_point(Vector2(x_pos, arena_size.y - ARENA_MARGIN), warp_amp)
		var lane_weight := 0.12 + 0.2 * absf((x_pos / maxf(1.0, arena_size.x)) - 0.5)
		draw_line(p1, p2, Color(0.17, 0.22, 0.33, (0.16 + lane_weight) * alpha_scale), 1.0)
	for y in range(int(min_y), int(max_y) + 1, int(spacing)):
		var y_pos := float(y) + offset_y
		var q1 := _warp_point(Vector2(ARENA_MARGIN, y_pos), warp_amp)
		var q2 := _warp_point(Vector2(arena_size.x - ARENA_MARGIN, y_pos), warp_amp)
		var lane_weight := 0.12 + 0.2 * absf((y_pos / maxf(1.0, arena_size.y)) - 0.5)
		draw_line(q1, q2, Color(0.17, 0.22, 0.33, (0.16 + lane_weight) * alpha_scale), 1.0)

func _draw_atmosphere_overlay() -> void:
	var speed_ratio := clampf(player_vel.length() / 300.0, 0.0, 1.0)
	var core_r := 120.0 + speed_ratio * 64.0
	var core_col := Color(0.1, 0.33, 0.46, 0.08 + speed_ratio * 0.07)
	draw_circle(player_pos, core_r, core_col)
	if anchor_slow_feedback > 0.01:
		var slow_col := Color(1.0, 0.62, 0.38, 0.09 + anchor_slow_feedback * 0.18)
		draw_circle(player_pos, 76.0 + anchor_slow_feedback * 72.0, slow_col)
		var edge := 14.0 + anchor_slow_feedback * 24.0
		var edge_col := Color(1.0, 0.46, 0.34, 0.05 + anchor_slow_feedback * 0.08)
		draw_rect(Rect2(Vector2.ZERO, Vector2(arena_size.x, edge)), edge_col, true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(edge, arena_size.y)), edge_col, true)
		draw_rect(Rect2(Vector2(0.0, arena_size.y - edge), Vector2(arena_size.x, edge)), edge_col, true)
		draw_rect(Rect2(Vector2(arena_size.x - edge, 0.0), Vector2(edge, arena_size.y)), edge_col, true)
	if near_miss_flash > 0.01:
		draw_circle(player_pos, 96.0 + near_miss_flash * 46.0, Color(1.0, 0.784, 0.341, 0.06 + near_miss_flash * 0.09))
	if danger_flash > 0.01:
		var edge := 36.0 + danger_flash * 18.0
		draw_rect(Rect2(Vector2.ZERO, Vector2(arena_size.x, edge)), Color(1.0, 0.31, 0.4, 0.07 * danger_flash), true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(edge, arena_size.y)), Color(1.0, 0.31, 0.4, 0.07 * danger_flash), true)
		draw_rect(Rect2(Vector2(0.0, arena_size.y - edge), Vector2(arena_size.x, edge)), Color(1.0, 0.31, 0.4, 0.07 * danger_flash), true)
		draw_rect(Rect2(Vector2(arena_size.x - edge, 0.0), Vector2(edge, arena_size.y)), Color(1.0, 0.31, 0.4, 0.07 * danger_flash), true)
	if damage_flash > 0.01:
		draw_rect(Rect2(Vector2.ZERO, arena_size), Color(1.0, 0.27, 0.36, 0.12 * damage_flash), true)

func _draw_threat_links() -> void:
	if chasers.is_empty():
		return
	var nearest: Array = []
	for c in chasers:
		var d: float = c.pos.distance_to(player_pos)
		nearest.append({"pos": c.pos, "d": d})
	nearest.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var max_links := mini(3, nearest.size())
	for i in range(max_links):
		var t: Dictionary = nearest[i]
		var dist := float(t["d"])
		var close_ratio := clampf(1.0 - dist / 320.0, 0.0, 1.0)
		if close_ratio <= 0.02:
			continue
		var line_col := Color(1.0, 0.49, 0.42, 0.1 + close_ratio * 0.28)
		var from := _warp_point(player_pos, 1.1)
		var to := _warp_point(t["pos"], 1.1)
		_draw_vector_line(from, to, line_col, 0.8 + close_ratio * 1.5, 1.15)

func _draw_player() -> void:
	if ship_respawn_pending or game_over:
		return
	_draw_player_shield()
	if anchor_slow_feedback > 0.01:
		var slow_ring := PLAYER_RADIUS + 13.0 + anchor_slow_feedback * 10.0
		draw_arc(player_pos, slow_ring, 0.0, TAU, 40, Color(1.0, 0.72, 0.46, 0.22 + anchor_slow_feedback * 0.36), 1.9)
	if near_miss_flash > 0.01:
		draw_arc(player_pos, PLAYER_RADIUS + 15.0 + near_miss_flash * 8.0, 0.0, TAU, 42, Color(1.0, 0.84, 0.42, 0.28 * near_miss_flash), 1.8)
	if shield_active:
		var circle := _circle_poly(player_pos, PLAYER_RADIUS, 20)
		_draw_warped_polyline(circle, Color(0.463, 0.969, 1.0), 2.4, 1.6, 1.35)
	var fwd := Vector2.RIGHT.rotated(player_angle)
	var left := Vector2.RIGHT.rotated(player_angle + 2.5)
	var right := Vector2.RIGHT.rotated(player_angle - 2.5)
	var tri := [player_pos + fwd * 16.0, player_pos + left * 9.5, player_pos + right * 9.5, player_pos + fwd * 16.0]
	_draw_warped_polyline(tri, Color(0.463, 0.969, 1.0, 0.85), 2.0, 1.3, 1.2)
	var speed_ratio := clampf(player_vel.length() / 320.0, 0.0, 1.0)
	if speed_ratio > 0.02:
		var trail_dir := player_vel.normalized()
		for i in range(4):
			var t := float(i + 1) / 4.0
			var trail_pos := player_pos - trail_dir * (10.0 + t * 20.0)
			draw_circle(trail_pos, 1.0 + (1.0 - t) * 2.1, Color(0.463, 0.969, 1.0, speed_ratio * (0.24 - t * 0.04)))

func _draw_player_shield() -> void:
	var shield_r := PLAYER_RADIUS + 10.0
	if shield_active:
		var pulse := 0.82 + 0.18 * sin(elapsed_time * 8.0)
		var col := Color(0.46, 0.96, 1.0, 0.72 * pulse)
		draw_arc(player_pos, shield_r, 0.0, TAU, 48, col, 2.2)
		draw_arc(player_pos, shield_r + 2.5, 0.0, TAU, 48, col * Color(1, 1, 1, 0.45), 1.0)
	else:
		var t := clampf(1.0 - shield_recharge_timer / SHIELD_RECHARGE_TIME, 0.0, 1.0)
		if t > 0.01:
			var end_angle := -PI * 0.5 + TAU * t
			draw_arc(player_pos, shield_r, -PI * 0.5, end_angle, 40, Color(0.46, 0.96, 1.0, 0.88), 2.0)

func _draw_chasers() -> void:
	for c in chasers:
		var enemy_type := str(c.type)
		if enemy_type == "phase" and not bool(c.get("phase_on", false)) and not bool(c.get("phase_telegraph", false)):
			continue
		var enemy_color := _get_enemy_color(enemy_type)
		var r := _get_enemy_radius(enemy_type)
		var dist_to_player: float = c.pos.distance_to(player_pos)
		var threat_ratio := clampf(1.0 - dist_to_player / 260.0, 0.0, 1.0)
		var command_ratio := clampf(float(c.get("command_buff", 0.0)) / SHEPHERD_COMMAND_BUFF_TIME, 0.0, 1.0)
		var alpha_mul := 1.0
		enemy_color.a *= alpha_mul
		if threat_ratio > 0.01:
			draw_circle(c.pos, r + 6.0 + threat_ratio * 4.0, enemy_color * Color(1, 1, 1, 0.06 + threat_ratio * 0.1))
		if command_ratio > 0.01 and enemy_type != "shepherd":
			draw_arc(c.pos, r + 6.0 + command_ratio * 5.0, 0.0, TAU, 28, Color(0.72, 1.0, 0.65, 0.34 + command_ratio * 0.22), 1.3)
		_draw_chaser_shape(c, enemy_type, enemy_color, r, threat_ratio)

func _draw_chaser_shape(c: Dictionary, enemy_type: String, enemy_color: Color, r: float, threat_ratio: float) -> void:
	if enemy_type == "drifter":
		var dia := _diamond_poly(c.pos, r * 2.0)
		_draw_warped_polyline(dia, enemy_color, 1.9 + threat_ratio * 0.9, 2.1)
		draw_circle(c.pos, 2.2, enemy_color * Color(1, 1, 1, 0.75))
	elif enemy_type == "splitter" or enemy_type == "splitter_shard":
		if enemy_type == "splitter_shard":
			var shard_scale := 1.22
			var head: Vector2 = c.pos + Vector2(0.0, -r * 0.9 * shard_scale)
			var left: Vector2 = c.pos + Vector2(-r * 0.75 * shard_scale, r * 0.72 * shard_scale)
			var right: Vector2 = c.pos + Vector2(r * 0.75 * shard_scale, r * 0.72 * shard_scale)
			_draw_warped_polyline([left, head, right], enemy_color, 1.6 + threat_ratio * 0.55, 1.8, 0.92)
			_draw_vector_line(c.pos, head, enemy_color * Color(1, 1, 1, 0.62), 1.0, 0.85)
		else:
			var h := r * 1.16
			var in_x := h * 0.28
			var left_bracket := [
				c.pos + Vector2(-h, -h),
				c.pos + Vector2(-in_x, -h),
				c.pos + Vector2(-in_x, h),
				c.pos + Vector2(-h, h),
			]
			var right_bracket := [
				c.pos + Vector2(h, -h),
				c.pos + Vector2(in_x, -h),
				c.pos + Vector2(in_x, h),
				c.pos + Vector2(h, h),
			]
			_draw_warped_polyline(left_bracket, enemy_color, 2.0 + threat_ratio * 0.85, 1.8, 1.08)
			_draw_warped_polyline(right_bracket, enemy_color, 2.0 + threat_ratio * 0.85, 1.8, 1.08)
			var split_top: Vector2 = c.pos + Vector2(-h * 0.22, -h * 0.74)
			var split_bottom: Vector2 = c.pos + Vector2(h * 0.22, h * 0.74)
			_draw_vector_line(split_top, split_bottom, enemy_color * Color(1, 1, 1, 0.78), 1.5, 1.05)
			draw_circle(c.pos + Vector2(h * 0.46, 0.0), 1.8 + threat_ratio * 0.9, enemy_color * Color(1, 1, 1, 0.8))
	elif enemy_type == "orbiter":
		var ring := _circle_poly(c.pos, r * 1.28, 22)
		_draw_warped_polyline(ring, enemy_color, 1.9 + threat_ratio * 0.8, 1.9)
		draw_arc(c.pos, r + 5.0, 0.0, TAU, 26, enemy_color * Color(1, 1, 1, 0.32), 1.1)
		var tangent_dir := Vector2(c.vel).normalized() if Vector2(c.vel).length() > 0.01 else Vector2.RIGHT
		var bead_pos: Vector2 = c.pos + tangent_dir.orthogonal() * r * 1.05
		draw_circle(bead_pos, 2.2, enemy_color * Color(1, 1, 1, 0.74))
	elif enemy_type == "lancer":
		var arrow := _chevron_poly(c.pos, r * 2.1, c.vel.angle())
		_draw_warped_polyline(arrow, enemy_color, 2.0 + threat_ratio * 1.0, 1.7)
		if float(c.charge_time) > 0.0:
			draw_arc(c.pos, r + 6.0, 0.0, TAU, 20, enemy_color * Color(1, 1, 1, 0.55), 1.4)
	elif enemy_type == "anchor":
		var diamond := _diamond_poly(c.pos, r * 2.0)
		_draw_warped_polyline(diamond, enemy_color, 2.0 + threat_ratio * 0.9, 2.0)
		if float(c.anchor_hold) > 0.0:
			draw_arc(c.pos, float(c.anchor_radius), 0.0, TAU, 36, enemy_color * Color(1, 1, 1, 0.22), 1.4)
	elif enemy_type == "sniper":
		var tri := _triangle_poly(c.pos, r * 1.8, c.vel.angle())
		_draw_warped_polyline(tri, enemy_color, 1.9 + threat_ratio * 0.8, 1.8)
		if float(c.aim_time) > 0.0:
			var aim_end: Vector2 = c.pos + Vector2(c.shot_dir) * 170.0
			draw_line(c.pos, aim_end, enemy_color * Color(1, 1, 1, 0.52), 1.3)
		elif float(c.shot_time) > 0.0:
			var trail_end: Vector2 = c.pos - Vector2(c.shot_dir) * (r * 2.9)
			draw_line(c.pos, trail_end, enemy_color * Color(1, 1, 1, 0.58), 1.6)
	elif enemy_type == "shepherd":
		var ring := _circle_poly(c.pos, r * 1.6, 18)
		_draw_warped_polyline(ring, enemy_color, 1.9 + threat_ratio * 0.7, 2.0)
		draw_circle(c.pos, 2.8, enemy_color * Color(1, 1, 1, 0.75))
		draw_arc(c.pos, SHEPHERD_AURA_RADIUS, 0.0, TAU, 40, enemy_color * Color(1, 1, 1, 0.16), 1.1)
	elif enemy_type == "mine_layer":
		var dia := _diamond_poly(c.pos, r * 1.9)
		_draw_warped_polyline(dia, enemy_color, 1.8 + threat_ratio * 0.8, 1.8)
		var rear: Vector2
		if Vector2(c.vel).length() > 0.01:
			rear = c.pos - Vector2(c.vel).normalized() * r * 0.8
		else:
			rear = c.pos
		draw_circle(rear, 2.0, enemy_color * Color(1, 1, 1, 0.68))
	elif enemy_type == "mirror":
		var ch := _chevron_poly(c.pos, r * 1.9, c.vel.angle() + float(c.mirror_dir) * 0.4)
		_draw_warped_polyline(ch, enemy_color, 1.9 + threat_ratio * 0.8, 1.8)
		if float(c.get("mirror_boost", 0.0)) > 0.01:
			draw_arc(c.pos, r + 5.0, 0.0, TAU, 24, enemy_color * Color(1, 1, 1, 0.42), 1.2)
	elif enemy_type == "phase":
		if bool(c.get("phase_telegraph", false)):
			var warn_col := enemy_color * Color(1, 1, 1, 0.42)
			var poly_warn := _triangle_poly(c.pos, r * 2.1, c.vel.angle())
			_draw_warped_polyline(poly_warn, warn_col, 1.5, 1.7)
		else:
			var poly := _triangle_poly(c.pos, r * 1.85, c.vel.angle())
			_draw_warped_polyline(poly, enemy_color, 1.9 + threat_ratio * 0.8, 1.7)
	else:
		var sq := _square_poly(c.pos, r * 1.8)
		_draw_warped_polyline(sq, enemy_color, 1.9 + threat_ratio * 0.9, 1.8)
		draw_circle(c.pos, 2.5, enemy_color * Color(1, 1, 1, 0.88))

func _draw_mines() -> void:
	for m in mines:
		var p := Vector2(m.pos)
		var r := float(m.radius)
		var armed := bool(m.armed)
		var poly := _diamond_poly(p, r * 1.9)
		if armed:
			var pulse := 0.72 + 0.28 * sin(elapsed_time * 12.0)
			var armed_col := Color(1.0, 0.36, 0.28, 0.86)
			_draw_warped_polyline(poly, armed_col, 1.9, 1.7)
			draw_circle(p, r * 0.34, armed_col * Color(1, 1, 1, 0.85))
			draw_line(p + Vector2(-r * 0.38, -r * 0.38), p + Vector2(r * 0.38, r * 0.38), armed_col * Color(1, 1, 1, 0.82), 1.2)
			draw_line(p + Vector2(-r * 0.38, r * 0.38), p + Vector2(r * 0.38, -r * 0.38), armed_col * Color(1, 1, 1, 0.82), 1.2)
			draw_arc(p, r + 6.5, 0.0, TAU, 24, Color(1.0, 0.28, 0.25, 0.34 + pulse * 0.28), 1.4)
			var armed_life_max := maxf(0.01, float(m.get("armed_life_max", 0.01)))
			var life_ratio := clampf(float(m.life) / armed_life_max, 0.0, 1.0)
			var life_end_angle := -PI * 0.5 + TAU * life_ratio
			draw_arc(p, r + 9.4, -PI * 0.5, life_end_angle, 28, Color(1.0, 0.78, 0.42, 0.86), 1.6)
		else:
			var safe_col := Color(0.58, 0.9, 1.0, 0.74)
			_draw_warped_polyline(poly, safe_col, 1.5, 1.7)
			draw_line(p + Vector2(-r * 0.32, 0), p + Vector2(r * 0.32, 0), safe_col * Color(1, 1, 1, 0.72), 1.1)
			draw_line(p + Vector2(0, -r * 0.32), p + Vector2(0, r * 0.32), safe_col * Color(1, 1, 1, 0.72), 1.1)
			var arm_progress := 1.0 - clampf(float(m.timer) / 1.7, 0.0, 1.0)
			if arm_progress > 0.01:
				var end_angle := -PI * 0.5 + TAU * arm_progress
				draw_arc(p, r + 5.8, -PI * 0.5, end_angle, 24, Color(0.66, 0.96, 1.0, 0.72), 1.2)

func _draw_player_explosion_lines() -> void:
	for seg in player_explosion_lines:
		var t := float(seg.age) / float(seg.life)
		var alpha := 1.0 - t
		var col := Color(1.0, 0.74, 0.55, 0.22 + alpha * 0.68)
		var start := Vector2(seg.pos) - Vector2(seg.dir) * float(seg.len) * 0.35
		var fin := Vector2(seg.pos) + Vector2(seg.dir) * float(seg.len) * (0.65 + t * 0.45)
		draw_line(start, fin, col, float(seg.width))

func _draw_pulses() -> void:
	for p in pulses:
		var t: float = p.age / p.life
		var r: float = lerpf(2.0, p.max_r, t)
		var col: Color = p.color
		col.a *= (1.0 - t)
		draw_arc(p.pos, r, 0.0, TAU, 40, col, 2.0)

func _draw_score_burst_feedback() -> void:
	if score_burst_flash <= 0.01:
		return
	var t := score_burst_flash
	var r := 16.0 + (1.0 - t) * 34.0
	var col := Color(0.78, 1.0, 0.31, 0.22 + t * 0.42)
	draw_arc(score_burst_pos, r, 0.0, TAU, 28, col, 1.8)
	var cross := 8.0 + (1.0 - t) * 15.0
	_draw_vector_line(score_burst_pos + Vector2(-cross, 0), score_burst_pos + Vector2(cross, 0), col, 1.5, 1.05)
	_draw_vector_line(score_burst_pos + Vector2(0, -cross), score_burst_pos + Vector2(0, cross), col, 1.5, 1.05)

func _setup_typography_theme() -> void:
	var fallback_font := ThemeDB.fallback_font
	ui_font_base = _load_font_or_fallback("res://assets/fonts/DejaVuSans.ttf", fallback_font)
	ui_font_display = _load_font_or_fallback("res://assets/fonts/DejaVuSans-Bold.ttf", ui_font_base)
	ui_font_numeric = _load_font_or_fallback("res://assets/fonts/NotoSansMono-Bold.ttf", ui_font_base)
	ui_tokens = {
		"size_xs": 13,
		"size_sm": 14,
		"size_md": 16,
		"size_lg": 22,
		"size_xl": 30,
		"text_primary": Color(0.84, 0.95, 1.0, 0.95),
		"text_muted": Color(0.74, 0.84, 0.92, 0.9),
		"text_positive": Color(0.78, 1.0, 0.31, 0.97),
		"text_warning": Color(1.0, 0.784, 0.341, 0.96),
		"text_danger": Color(1.0, 0.373, 0.427, 0.98),
		"text_info": Color(0.463, 0.969, 1.0, 0.95),
		"outline_color": Color(0.03, 0.06, 0.11, 0.95),
		"shadow_color": Color(0.0, 0.0, 0.0, 0.45),
		"panel_bg": Color(0.04, 0.08, 0.14, 0.62),
		"panel_border": Color(0.28, 0.38, 0.55, 0.7),
	}

func _load_font_or_fallback(path: String, fallback_font: Font) -> Font:
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is Font:
			return loaded
	return fallback_font

func _draw_styled_text(font: Font, text: String, pos: Vector2, align: HorizontalAlignment, size: int, color: Color, outline_px: int = 1, line_noise_strength: float = 0.0) -> void:
	if font == null:
		return
	var draw_pos := pos
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			draw_pos.x -= text_w * 0.5
		elif align == HORIZONTAL_ALIGNMENT_RIGHT:
			draw_pos.x -= text_w
	var shadow_col: Color = ui_tokens.get("shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	var outline_col: Color = ui_tokens.get("outline_color", Color(0.03, 0.06, 0.11, 0.95))
	draw_string(font, draw_pos + Vector2(1.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, shadow_col)
	if outline_px > 0:
		var dirs := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
		for d in dirs:
			draw_string(font, draw_pos + d * float(outline_px), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_col)
	_draw_line_noise_text(font, text, draw_pos, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, line_noise_strength)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_emphasis_text(font: Font, text: String, pos: Vector2, align: HorizontalAlignment, size: int, color: Color, accent: Color, strength: float, line_noise_strength: float = 0.0) -> void:
	var s := clampf(strength, 0.0, 1.0)
	var draw_pos := pos
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			draw_pos.x -= text_w * 0.5
		elif align == HORIZONTAL_ALIGNMENT_RIGHT:
			draw_pos.x -= text_w
	if s > 0.001:
		var off := 1.0 + s * 1.5
		draw_string(font, draw_pos + Vector2(-off, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, accent * Color(1, 1, 1, 0.5 + s * 0.35))
		draw_string(font, draw_pos + Vector2(off, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 0.37, 0.43, 0.35 + s * 0.45))
	_draw_styled_text(font, text, draw_pos, HORIZONTAL_ALIGNMENT_LEFT, size, color, 1, line_noise_strength)

func _draw_emphasis_text_screen_center(font: Font, text: String, y: float, size: int, color: Color, accent: Color, strength: float, line_noise_strength: float = 0.0) -> void:
	if font == null:
		return
	var s := clampf(strength, 0.0, 1.0)
	var width := arena_size.x
	var shadow_col: Color = ui_tokens.get("shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	var outline_col: Color = ui_tokens.get("outline_color", Color(0.03, 0.06, 0.11, 0.95))
	if s > 0.001:
		var off := 1.0 + s * 1.5
		draw_string(font, Vector2(-off, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, accent * Color(1, 1, 1, 0.5 + s * 0.35))
		draw_string(font, Vector2(off, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(1.0, 0.37, 0.43, 0.35 + s * 0.45))
	draw_string(font, Vector2(1.0, y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, shadow_col)
	var dirs := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for d in dirs:
		draw_string(font, Vector2(d.x, y + d.y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline_col)
	_draw_line_noise_text(font, text, Vector2(0.0, y), HORIZONTAL_ALIGNMENT_CENTER, width, size, line_noise_strength)
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)

func _draw_line_noise_text(font: Font, text: String, pos: Vector2, align: HorizontalAlignment, width: float, size: int, strength: float) -> void:
	if font == null:
		return
	var s := clampf(strength, 0.0, 1.0)
	if s <= 0.001:
		return
	var text_key := absf(float(hash(text)))
	var phase := text_key * 0.0043
	var drift := elapsed_time * (1.2 + s * 1.4)
	var n_x := sin(phase + drift * 1.9) * (0.42 + s * 0.75)
	var n_y := cos(phase * 1.3 + drift * 2.2) * (0.32 + s * 0.6)
	var amber := Color(1.0, 0.784, 0.341, (0.055 + s * 0.08))
	var cyan := Color(0.46, 0.96, 1.0, (0.05 + s * 0.08))
	draw_string(font, pos + Vector2(-n_x, n_y), text, align, width, size, amber)
	draw_string(font, pos + Vector2(n_x, -n_y), text, align, width, size, cyan)

func _draw_life_ship_icon(center: Vector2, size: float, color: Color) -> void:
	var nose := center + Vector2(size, 0.0)
	var top := center + Vector2(-size * 0.72, -size * 0.58)
	var bottom := center + Vector2(-size * 0.72, size * 0.58)
	var tri := [nose, top, bottom, nose]
	_draw_warped_polyline(tri, color, 1.4, 0.9)
	draw_circle(center + Vector2(-size * 0.34, 0.0), 1.5, color * Color(1, 1, 1, 0.78))

func _draw_title_screen() -> void:
	var center_y := arena_size.y * 0.5
	var panel_w := mini(640.0, arena_size.x - 80.0)
	var panel_h := 238.0
	var panel_pos := Vector2((arena_size.x - panel_w) * 0.5, center_y - 156.0)
	var pulse := 0.5 + 0.5 * sin(title_blink_t * 2.2)
	draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), Color(0.03, 0.06, 0.12, 0.76), true)
	draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), Color(0.29, 0.45, 0.68, 0.78), false, 1.6)
	var scan_y := panel_pos.y + 22.0 + fmod(title_blink_t * 42.0, panel_h - 44.0)
	draw_rect(Rect2(Vector2(panel_pos.x + 4.0, scan_y), Vector2(panel_w - 8.0, 2.0)), Color(0.46, 0.96, 1.0, 0.2 + 0.24 * pulse), true)
	for i in range(4):
		var y := panel_pos.y + 34.0 + float(i) * 44.0 + sin(title_blink_t * 1.8 + float(i) * 0.8) * 5.0
		draw_line(Vector2(panel_pos.x + 12.0, y), Vector2(panel_pos.x + panel_w - 12.0, y), Color(0.19, 0.31, 0.48, 0.2), 1.0)
	var ring_r := 74.0 + 7.0 * pulse
	draw_arc(Vector2(arena_size.x * 0.5, center_y - 4.0), ring_r, 0.0, TAU, 72, Color(0.46, 0.96, 1.0, 0.16), 1.2)
	draw_line(panel_pos + Vector2(16, 16), panel_pos + Vector2(56, 16), Color(0.46, 0.96, 1.0, 0.64), 1.0)
	draw_line(panel_pos + Vector2(16, 16), panel_pos + Vector2(16, 40), Color(0.46, 0.96, 1.0, 0.64), 1.0)
	draw_line(panel_pos + Vector2(panel_w - 16, panel_h - 16), panel_pos + Vector2(panel_w - 56, panel_h - 16), Color(1.0, 0.63, 0.55, 0.64), 1.0)
	draw_line(panel_pos + Vector2(panel_w - 16, panel_h - 16), panel_pos + Vector2(panel_w - 16, panel_h - 40), Color(1.0, 0.63, 0.55, 0.64), 1.0)

	var title_fx := clampf(0.62 + 0.34 * sin(title_blink_t * 3.4), 0.0, 1.0)
	_draw_emphasis_text_screen_center(ui_font_display, "WARP CHASE HOLDLINE", center_y - 64.0, 42, Color(0.46, 0.96, 1.0, 0.99), Color(1.0, 0.63, 0.55, 0.95), title_fx)
	_draw_emphasis_text_screen_center(ui_font_base, "DRIFT, WARP, OUTPLAY THE SWARM", center_y - 38.0, 15, Color(0.86, 0.94, 1.0, 0.88), Color(0.46, 0.96, 1.0, 0.72), 0.12)
	_draw_emphasis_text_screen_center(ui_font_numeric, "TURN: A D / <- ->   THRUST: SPACE / W / UP", center_y + 14.0, 14, Color(0.78, 1.0, 0.31, 0.92), Color(0.46, 0.96, 1.0, 0.7), 0.08)

	var blink := 0.45 + 0.55 * (0.5 + 0.5 * sin(title_blink_t * 5.2))
	var cta_y := center_y + 54.0
	var cta_w := 286.0
	var cta_h := 32.0
	var cta_pos := Vector2(arena_size.x * 0.5 - cta_w * 0.5, cta_y - 22.0)
	draw_rect(Rect2(cta_pos, Vector2(cta_w, cta_h)), Color(0.08, 0.12, 0.2, 0.46 + 0.18 * blink), true)
	draw_rect(Rect2(cta_pos, Vector2(cta_w, cta_h)), Color(1.0, 0.784, 0.341, 0.55 + 0.3 * blink), false, 1.2)
	_draw_emphasis_text_screen_center(ui_font_base, "PRESS SPACE TO START", cta_y, 19, Color(1.0, 0.784, 0.341, blink), Color(0.46, 0.96, 1.0, 0.6 * blink), 0.24)

func _draw_ui() -> void:
	if ui_font_base == null and ThemeDB.fallback_font == null:
		return
	if ui_font_base == null:
		_setup_typography_theme()
	var base_font: Font = ui_font_base
	var display_font: Font = ui_font_display
	var numeric_font: Font = ui_font_numeric

	var score_text := "%d" % score
	var score_pulse := 1.0 + score_flash * 0.22
	var score_size := int(round(float(ui_tokens.get("size_xl", 30)) * score_pulse))
	var score_box := Rect2(Vector2(14, 10), Vector2(120, 48))
	draw_rect(score_box, Color(0.04, 0.08, 0.14, 0.48), true)
	draw_rect(score_box, Color(0.2, 0.34, 0.48, 0.55), false, 1.1)
	_draw_emphasis_text(numeric_font, score_text, Vector2(20, 44), HORIZONTAL_ALIGNMENT_LEFT, score_size, ui_tokens.get("text_positive", Color(0.78, 1.0, 0.31, 0.97)), Color(0.46, 0.96, 1.0, 0.9), score_flash, 0.36)
	var reserve_lives := maxi(0, lives - 1)
	for i in range(reserve_lives):
		_draw_life_ship_icon(Vector2(30 + float(i) * 25.0, 83.0), 11.0, Color(0.46, 0.96, 1.0, 0.88))

	if multiplier > 1:
		var hud_w := 220.0
		var hud_h := 10.0
		var decay_interval := _get_decay_interval_for_multiplier(multiplier)
		var decay_ratio := clampf(multiplier_decay_timer / decay_interval, 0.0, 1.0)
		var hud_pos := Vector2(arena_size.x * 0.5 - hud_w * 0.5, 20.0)
		draw_rect(Rect2(hud_pos, Vector2(hud_w, hud_h)), Color(0.1, 0.13, 0.2, 0.72), true)
		draw_rect(Rect2(hud_pos, Vector2(hud_w * decay_ratio, hud_h)), Color(0.98, 0.95, 0.62, 0.92), true)
		var chain_text := "x%d" % multiplier
		var chain_center := Vector2(arena_size.x * 0.5, 16.0)
		draw_line(chain_center + Vector2(-118.0, 0.0), chain_center + Vector2(-82.0, 0.0), Color(1.0, 0.86, 0.38, 0.8), 1.4)
		draw_line(chain_center + Vector2(82.0, 0.0), chain_center + Vector2(118.0, 0.0), Color(1.0, 0.86, 0.38, 0.8), 1.4)
		var chain_fx := clampf(0.45 + 0.3 * sin(elapsed_time * 8.5), 0.0, 1.0)
		_draw_emphasis_text(display_font, chain_text, chain_center, HORIZONTAL_ALIGNMENT_CENTER, 15, Color(1.0, 0.86, 0.38, 0.98), Color(0.46, 0.96, 1.0, 0.88), chain_fx, 0.32)
	if game_over:
		if not _is_game_over_overlay_visible():
			return
		var game_over_fx := clampf(0.52 + 0.36 * sin(elapsed_time * 6.0), 0.0, 1.0)
		var center_y := arena_size.y * 0.5
		_draw_emphasis_text_screen_center(display_font, "GAME OVER", center_y, int(ui_tokens.get("size_xl", 30)), ui_tokens.get("text_danger", Color(1.0, 0.373, 0.427, 0.98)), Color(0.46, 0.96, 1.0, 0.95), game_over_fx, 0.34)
		_draw_emphasis_text_screen_center(base_font, "PRESS SPACE FOR TITLE", center_y + 28.0, int(ui_tokens.get("size_md", 16)), ui_tokens.get("text_warning", Color(1.0, 0.784, 0.341, 0.96)), Color(0.46, 0.96, 1.0, 0.65), 0.18, 0.24)

func _draw_warped_polyline(points: Array, color: Color, width: float, amp: float, glow_strength: float = VECTOR_GLOW_BASE) -> void:
	if points.size() < 2:
		return
	var step := 1
	# Keep small enemy silhouettes intact; decimate only high-segment polylines.
	if warp_detail_scale < 0.8 and points.size() > 10:
		step = 2
	var i := 0
	while i < points.size() - 1:
		var next_i := mini(i + step, points.size() - 1)
		var a: Vector2 = _warp_point(points[i], amp)
		var b: Vector2 = _warp_point(points[next_i], amp)
		_draw_vector_line(a, b, color, width, glow_strength)
		i = next_i

func _draw_vector_line(a: Vector2, b: Vector2, color: Color, width: float, glow_strength: float = VECTOR_GLOW_BASE) -> void:
	var g := clampf(glow_strength * vector_glow_budget_scale, 0.0, 1.0)
	if g > 0.001:
		var outer_col := color
		outer_col.a *= VECTOR_GLOW_OUTER_ALPHA * g
		draw_line(a, b, outer_col, width + 7.0 * g)
		if g >= 0.75:
			var inner_col := color
			inner_col.a *= VECTOR_GLOW_INNER_ALPHA * g
			draw_line(a, b, inner_col, width + 3.8 * g)
	draw_line(a, b, color, width)

func _warp_point(p: Vector2, amp: float) -> Vector2:
	var t := elapsed_time * 2.0
	var ox := sin(p.y * 0.043 + t + p.x * 0.002) * amp
	var oy := cos(p.x * 0.039 + t * 1.12 + p.y * 0.002) * amp
	return p + Vector2(ox, oy)

func _circle_poly(center: Vector2, radius: float, segments: int) -> Array:
	var pts: Array = []
	for i in range(segments + 1):
		var a := float(i) / float(segments) * TAU
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts

func _square_poly(center: Vector2, size: float) -> Array:
	var h := size * 0.5
	return [
		center + Vector2(-h, -h),
		center + Vector2(h, -h),
		center + Vector2(h, h),
		center + Vector2(-h, h),
		center + Vector2(-h, -h),
	]

func _diamond_poly(center: Vector2, size: float) -> Array:
	var h := size * 0.5
	return [
		center + Vector2(0, -h),
		center + Vector2(h, 0),
		center + Vector2(0, h),
		center + Vector2(-h, 0),
		center + Vector2(0, -h),
	]

func _triangle_poly(center: Vector2, size: float, angle: float) -> Array:
	var a := Vector2.RIGHT.rotated(angle) * size
	var b := Vector2.RIGHT.rotated(angle + 2.35) * (size * 0.62)
	var c := Vector2.RIGHT.rotated(angle - 2.35) * (size * 0.62)
	return [center + a, center + b, center + c, center + a]

func _chevron_poly(center: Vector2, size: float, angle: float) -> Array:
	var tip := Vector2.RIGHT.rotated(angle) * size
	var wing_a := Vector2.RIGHT.rotated(angle + 2.55) * (size * 0.72)
	var inner := Vector2.RIGHT.rotated(angle + PI) * (size * 0.18)
	var wing_b := Vector2.RIGHT.rotated(angle - 2.55) * (size * 0.72)
	return [center + tip, center + wing_a, center + inner, center + wing_b, center + tip]

func _get_enemy_radius(enemy_type: String) -> float:
	return EnemyCatalog.get_enemy_radius(enemy_type, CHASER_RADIUS)

func _get_enemy_wrap_radius(enemy_type: String) -> float:
	return EnemyCatalog.get_enemy_wrap_radius(enemy_type, CHASER_RADIUS)

func _get_enemy_color(enemy_type: String) -> Color:
	return EnemyCatalog.get_enemy_color(enemy_type)

func _get_enemy_collision_score(enemy_type: String) -> int:
	return EnemyCatalog.get_enemy_collision_score(enemy_type)

func _find_nearest_orbiter(from_pos: Vector2, orbiters: Array) -> Dictionary:
	var nearest: Dictionary = orbiters[0]
	var best_d: float = INF
	for o in orbiters:
		var d: float = from_pos.distance_to(o.pos)
		if d < best_d:
			best_d = d
			nearest = o
	return nearest

func _generate_wave(index: int) -> Dictionary:
	return WavePlanner.generate_wave(index, wave_rng_seed, ENEMY_UNLOCK_ORDER, MAX_THREAT_BUDGET, THREAT_COST, TYPE_MAX_RATIO, WAVE_DURATION)

func _pick_enemy_type(weights: Dictionary) -> String:
	return WavePlanner.pick_weighted_enemy_type(weights, rng)

func _pick_spawnable_enemy_type(weights: Dictionary, max_chasers: int) -> String:
	for _i in range(16):
		var candidate := _pick_enemy_type(weights)
		if _can_spawn_type(candidate, max_chasers):
			return candidate
	# Never inject enemies outside this wave's selected type set.
	if not weights.is_empty():
		for key in weights.keys():
			return str(key)
	return "hunter"

func _pick_forced_enemy_type() -> String:
	if PLAYTEST_FORCE_ENEMY_TYPES.is_empty():
		return ""
	var available: Array = []
	for t in PLAYTEST_FORCE_ENEMY_TYPES:
		var enemy_type := str(t)
		if THREAT_COST.has(enemy_type):
			available.append(enemy_type)
	if available.is_empty():
		return ""
	return str(available[rng.randi_range(0, available.size() - 1)])

func _can_spawn_type(enemy_type: String, max_chasers: int) -> bool:
	var cooldown := float(TYPE_SPAWN_COOLDOWN.get(enemy_type, 0.0))
	var last_spawn := float(enemy_last_spawn_time.get(enemy_type, -999.0))
	if elapsed_time - last_spawn < cooldown:
		return false
	var total_after := chasers.size() + 1
	if total_after < 3:
		return true
	var current_count := 0
	for c in chasers:
		if str(c.type) == enemy_type:
			current_count += 1
	var ratio_after := float(current_count + 1) / float(total_after)
	var cap_ratio := float(TYPE_MAX_RATIO.get(enemy_type, 0.56))
	if max_chasers > 0 and ratio_after > cap_ratio:
		return false
	return true

func _add_score(base: int) -> void:
	score += int(round(base * float(multiplier)))
	score_flash = clampf(score_flash + 0.62, 0.0, 1.0)
	_try_award_extra_life()

func _try_award_extra_life() -> void:
	while next_extra_life_index < EXTRA_LIFE_THRESHOLDS.size():
		var threshold := int(EXTRA_LIFE_THRESHOLDS[next_extra_life_index])
		if score < threshold:
			return
		next_extra_life_index += 1
		if lives >= MAX_LIVES:
			continue
		lives += 1
		_spawn_pulse(player_pos, Color(0.78, 1.0, 0.31, 0.85), 34.0, 0.28)
		_play_sfx("extra_life", {"difficulty": difficulty, "lives": lives})

func _reset_metric_trackers() -> void:
	var m := MetricsTracker.reset_metric_trackers(THREAT_COST, SYNERGY_TEMPLATE_KEYS, BEHAVIOR_EVENT_KEYS)
	enemy_type_counts = m["enemy_type_counts"]
	synergy_event_counts = m["synergy_event_counts"]
	behavior_event_counts = m["behavior_event_counts"]
	max_single_type_ratio = float(m["max_single_type_ratio"])
	avg_active_enemies_30s = float(m["avg_active_enemies_30s"])
	_active_enemy_sample_sum = float(m["active_enemy_sample_sum"])
	_active_enemy_sample_frames = int(m["active_enemy_sample_frames"])
	untelegraphed_hit_count = int(m["untelegraphed_hit_count"])

func _update_test_metrics() -> void:
	var update := MetricsTracker.update_test_metrics(elapsed_time, chasers, _active_enemy_sample_sum, _active_enemy_sample_frames, max_single_type_ratio)
	max_single_type_ratio = float(update["max_single_type_ratio"])
	_active_enemy_sample_sum = float(update["active_enemy_sample_sum"])
	_active_enemy_sample_frames = int(update["active_enemy_sample_frames"])
	avg_active_enemies_30s = float(update["avg_active_enemies_30s"])

func _record_spawned_enemy(enemy_type: String) -> void:
	MetricsTracker.record_spawned_enemy(enemy_type_counts, enemy_type)

func _record_synergy_event(type_a: String, type_b: String) -> void:
	MetricsTracker.record_synergy_event(synergy_event_counts, type_a, type_b)

func _inc_behavior_event(key: String) -> void:
	MetricsTracker.inc_behavior_event(behavior_event_counts, key)

func _is_hit_telegraphed(enemy: Dictionary) -> bool:
	return MetricsTracker.is_hit_telegraphed(enemy)

# --- test hooks ---
func enable_test_mode(enabled: bool) -> void:
	test_mode = enabled
	set_physics_process(not enabled)

func step_for_test(delta: float, left: bool, right: bool, thrust: bool) -> void:
	test_left = left
	test_right = right
	test_thrust = thrust
	_simulate_frame(delta)

func get_metrics() -> Dictionary:
	return {
		"score": score,
		"game_over": game_over,
		"near_miss_count": near_miss_count,
		"elapsed": elapsed_time,
		"chasers": chasers.size(),
		"enemy_type_counts": enemy_type_counts.duplicate(true),
		"max_single_type_ratio": max_single_type_ratio,
		"synergy_event_counts": synergy_event_counts.duplicate(true),
		"behavior_event_counts": behavior_event_counts.duplicate(true),
		"avg_active_enemies_30s": avg_active_enemies_30s,
		"untelegraphed_hit_count": untelegraphed_hit_count,
	}

func force_reset_for_test(seed: int) -> void:
	rng.seed = seed
	title_screen_active = false
	title_blink_t = 0.0
	_reset_game()

func set_wave_for_test(target_wave: int) -> void:
	var w := maxi(0, target_wave)
	wave_index = w
	elapsed_time = float(w) * WAVE_DURATION + 0.01
	difficulty = 1.0 + sqrt(elapsed_time / 100.0)
	wave_state = _generate_wave(wave_index)
	current_wave_name = str(wave_state["name"])
	spawn_interval = float(wave_state["spawn_interval"])
	spawn_timer = 0.0
	next_extra_life_index = 0
	ship_respawn_pending = false
	ship_respawn_timer = 0.0
	enemy_last_spawn_time.clear()
	enemy_spawn_sfx_last_time.clear()
	chasers.clear()
	mines.clear()
	pulses.clear()
	var weights: Dictionary = wave_state.get("weights", {})
	var initial_count := 3 + mini(3, int(w / 2))
	for _i in range(initial_count):
		_spawn_chaser(_pick_enemy_type(weights))
