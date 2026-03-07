extends RefCounted
const AudioSynth = preload("res://audio_synth.gd")

static func all_runtime_sfx_events(enemy_unlock_order: Array) -> Array:
	var events: Array = [
		"score",
		"near_miss",
		"danger",
		"shield_break",
		"ship_lost",
		"shield_ready",
		"wave_shift",
		"game_over",
	]
	for enemy_type in enemy_unlock_order:
		events.append(enemy_spawn_event_name(str(enemy_type)))
	return events

static func build_cached_sfx_streams(cached_sfx_events: Dictionary, mix_rate: float) -> Dictionary:
	var out: Dictionary = {}
	for event_name in cached_sfx_events.keys():
		var event_key := str(event_name)
		var variants: Array = []
		for vi in range(3):
			var vrng := RandomNumberGenerator.new()
			vrng.seed = 9000 + vi * 101 + int(event_key.hash()) % 997
			var params := _cached_base_params(event_key)
			var samples := PackedFloat32Array()
			match event_key:
				"score":
					samples = AudioSynth.build_score_sfx_samples(params, vrng, mix_rate)
				"near_miss":
					samples = AudioSynth.build_near_miss_sfx_samples(params, vrng, mix_rate)
				"danger":
					samples = AudioSynth.build_danger_sfx_samples(params, vrng, mix_rate)
				"shield_break":
					samples = AudioSynth.build_shield_break_sfx_samples(params, vrng, mix_rate)
				"ship_lost":
					samples = AudioSynth.build_ship_lost_sfx_samples(params, vrng, mix_rate)
				"shield_ready":
					samples = AudioSynth.build_shield_ready_sfx_samples(params, vrng, mix_rate)
				"wave_shift":
					samples = AudioSynth.build_wave_shift_sfx_samples(params, vrng, mix_rate)
				"game_over":
					samples = AudioSynth.build_game_over_sfx_samples(params, vrng, mix_rate)
				_:
					if event_key.begins_with("spawn_"):
						samples = AudioSynth.build_enemy_spawn_sfx_samples(params, vrng, mix_rate)
					else:
						samples = PackedFloat32Array()
			variants.append(_samples_to_wav(samples, mix_rate))
		out[event_key] = variants
	return out

static func _cached_base_params(event_name: String) -> Dictionary:
	if event_name.begins_with("spawn_"):
		return {
			"enemy_type": event_name.trim_prefix("spawn_"),
			"volume": 0.22,
		}
	match event_name:
		"score":
			return {"multiplier": 3, "chain": 2, "impact_speed": 180.0}
		"near_miss":
			return {"multiplier": 2, "speed": 180.0}
		"danger":
			return {"danger": 0.75, "difficulty": 1.7}
		"shield_break":
			return {"impact_speed": 160.0, "difficulty": 1.8}
		"ship_lost":
			return {"impact_speed": 200.0, "difficulty": 2.0, "lives": 1}
		"shield_ready":
			return {"difficulty": 2.0}
		"wave_shift":
			return {"difficulty": 2.0, "wave": 8}
		"game_over":
			return {"difficulty": 2.0, "multiplier": 3.0}
		_:
			return {}

static func _samples_to_wav(samples: PackedFloat32Array, mix_rate: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	var write_idx := 0
	for s in samples:
		var iv := int(round(clampf(s, -1.0, 1.0) * 32767.0))
		var u16 := iv & 0xffff
		bytes[write_idx] = u16 & 0xff
		bytes[write_idx + 1] = (u16 >> 8) & 0xff
		write_idx += 2
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(mix_rate)
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = bytes
	return wav

static func cached_event_pitch_scale(event_name: String, params: Dictionary) -> float:
	match event_name:
		"score":
			var m := clampf(float(params.get("multiplier", 1.0)), 1.0, 12.0)
			return 0.96 + (m - 1.0) * 0.03
		"near_miss":
			var speed := clampf(float(params.get("speed", 0.0)), 0.0, 360.0)
			return 0.95 + speed / 2400.0
		"danger":
			var danger := clampf(float(params.get("danger", 0.7)), 0.0, 1.0)
			return 0.94 + danger * 0.16
		"game_over":
			var mult := clampf(float(params.get("multiplier", 1.0)), 1.0, 12.0)
			return 0.98 + (mult - 1.0) * 0.01
		_:
			return 1.0

static func cached_event_volume_db(event_name: String, params: Dictionary) -> float:
	match event_name:
		"score":
			var impact := clampf(float(params.get("impact_speed", 120.0)), 40.0, 420.0)
			return linear_to_db(0.18 + impact / 2200.0)
		"near_miss":
			return linear_to_db(0.18)
		"danger":
			var danger := clampf(float(params.get("danger", 0.7)), 0.0, 1.0)
			return linear_to_db(0.16 + danger * 0.12)
		"game_over":
			return linear_to_db(0.3)
		_:
			return linear_to_db(0.22)

static func enemy_spawn_event_name(enemy_type: String) -> String:
	return "spawn_%s" % enemy_type

static func make_pending_sfx_item(event_name: String, params: Dictionary, retries: int = 4) -> Dictionary:
	return {
		"event": event_name,
		"params": params,
		"retries": retries,
	}

static func create_generator_player(mix_rate: float, buffer_length: float, bus_name: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = buffer_length
	player.stream = stream
	player.bus = bus_name
	player.volume_db = volume_db
	return player

static func build_thrust_loop_stream(mix_rate: float) -> AudioStreamWAV:
	var duration := 0.5
	var total_samples := maxi(1, int(duration * mix_rate))
	var out := PackedFloat32Array()
	out.resize(total_samples)
	var pulse_count := 4.0
	var pulse_duty := 0.34
	var phase_a := 0.0 # voiced body
	var phase_b := 0.0 # overtone
	var lfo_phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var pulse_pos := fposmod(t * pulse_count, 1.0)
		var pulse_env := 0.0
		if pulse_pos < pulse_duty:
			var in_pulse := pulse_pos / pulse_duty
			var attack := clampf(in_pulse / 0.14, 0.0, 1.0)
			var release := clampf((1.0 - in_pulse) / 0.35, 0.0, 1.0)
			pulse_env = minf(attack, release)
		phase_a += 118.0 / mix_rate
		phase_b += 236.0 / mix_rate
		lfo_phase += 2.1 / mix_rate
		var body := AudioSynth.sine(phase_a) * 0.68 + AudioSynth.sine(phase_b) * 0.22
		var breath := AudioSynth.sine(phase_a * 9.0) * 0.03
		var flutter := 0.92 + 0.08 * AudioSynth.sine(lfo_phase)
		out[i] = (body + breath) * flutter * pulse_env * 0.58
	# Remove tiny DC offset.
	var dc := 0.0
	for s in out:
		dc += s
	dc /= float(total_samples)
	for i in range(total_samples):
		out[i] = out[i] - dc
	# Force hard-zero edges to avoid loop boundary clicks.
	out[0] = 0.0
	out[total_samples - 1] = 0.0
	var wav := _samples_to_wav(out, mix_rate)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples - 1
	return wav

static func create_cached_player_pool(variants: Array, pool_size: int, bus_name: String) -> Array:
	var pool: Array = []
	if variants.is_empty() or pool_size <= 0:
		return pool
	for i in range(pool_size):
		var player_cached := AudioStreamPlayer.new()
		player_cached.stream = variants[i % variants.size()]
		player_cached.bus = bus_name
		pool.append(player_cached)
	return pool

static func stop_audio_players(players: Array) -> void:
	for player_item in players:
		var player: AudioStreamPlayer = player_item
		player.stop()

static func stop_if_valid(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()

static func reset_audio_runtime_state() -> Dictionary:
	return {
		"engine_amp": 0.0,
		"engine_target_amp": 0.0,
		"engine_should_play": false,
		"ambient_amp": 0.0,
		"ambient_target_amp": 0.0,
	}

static func consume_retry(item: Dictionary) -> bool:
	var retries: int = int(item.get("retries", 0)) - 1
	if retries <= 0:
		return false
	item["retries"] = retries
	return true

static func should_emit_spawn_sfx(last_time: float, elapsed_time: float, cooldown: float) -> bool:
	return elapsed_time - last_time >= cooldown

static func spawn_pan(spawn_x: float, arena_width: float) -> float:
	return clampf((spawn_x / maxf(1.0, arena_width)) * 2.0 - 1.0, -0.25, 0.25)

static func is_runtime_audio_active(test_mode: bool) -> bool:
	return not test_mode

static func can_play_ambient_content(title_screen_active: bool, game_over: bool, ship_respawn_pending: bool) -> bool:
	return not title_screen_active and not game_over and not ship_respawn_pending

static func live_thrust_active(
	thrusting: bool,
	title_screen_active: bool,
	game_over: bool,
	ship_respawn_pending: bool
) -> bool:
	return thrusting and not title_screen_active and not game_over and not ship_respawn_pending

static func ambient_release_params(elapsed_time: float) -> Dictionary:
	return {
		"danger": 0.0,
		"speed": 0.0,
		"turn": 0.0,
		"multiplier": 1.0,
		"time": elapsed_time,
		"wave_ratio": 0.0,
		"shield_ratio": 0.0,
		"shield_up": false,
		"thrust": 0.0,
		"anchor_slow": 0.0,
		"enemy_density": 0.0,
		"enemy_motifs": [],
		"master_amp": 0.0,
		"enemy_amp": 0.0,
		"bed_enabled": false,
	}
