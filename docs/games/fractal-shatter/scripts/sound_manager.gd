extends Node

const AudioSynth = preload("res://audio_synth.gd")

const MIX_RATE := 22050
const MAX_VOICES := 6

var _players: Array[AudioStreamPlayer] = []
var _cache := {}
var _audio_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_audio_rng.seed = 12345
	for i in range(MAX_VOICES):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_precache_sounds()

func _precache_sounds() -> void:
	# Pre-generate common sounds
	for gen in [1, 2, 3]:
		_cache["hit_%d" % gen] = _generate_hit_sound(gen)
	_cache["burst"] = _generate_burst_sound()
	_cache["shockwave_1"] = _generate_shockwave_sound(1)
	_cache["shockwave_2"] = _generate_shockwave_sound(2)
	_cache["shockwave_3"] = _generate_shockwave_sound(3)
	_cache["game_over"] = _generate_game_over_sound()
	_cache["slash_miss"] = _generate_slash_miss_sound()

func play_event(event_type: String, params: Dictionary = {}) -> void:
	var key := ""
	match event_type:
		"hit":
			var gen := int(params.get("generation", 1))
			key = "hit_%d" % gen
		"burst":
			key = "burst"
		"ground_impact":
			var gen := int(params.get("generation", 1))
			key = "shockwave_%d" % gen
		"game_over":
			key = "game_over"
		"slash_miss":
			key = "slash_miss"
		_:
			return

	if not _cache.has(key):
		return
	_play_cached(key, params)

func _play_cached(key: String, params: Dictionary) -> void:
	var player := _get_free_player()
	if player == null:
		return
	player.stream = _cache[key]
	# Dynamic pitch for combo
	var combo := int(params.get("combo", 0))
	player.pitch_scale = 1.0 + clampf(float(combo) * 0.04, 0.0, 0.5)
	player.volume_db = -6.0
	player.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	# All busy, steal oldest
	return _players[0]

# --- Sound generation ---

func _generate_hit_sound(gen: int) -> AudioStreamWAV:
	var duration := 0.08
	var base_freq := 500.0 + float(gen - 1) * 200.0
	var samples := _make_samples(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.02, 0.78)
		var s := sin(t * base_freq * TAU) * 0.5
		s += sin(t * base_freq * 3.0 * TAU) * 0.25
		# Noise transient
		if t < 0.008:
			s += _audio_rng.randf_range(-0.4, 0.4)
		return s * env
	)
	return _to_wav(samples)

func _generate_burst_sound() -> AudioStreamWAV:
	var duration := 0.15
	var samples := _make_samples(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.02, 0.65)
		var s := sin(t * 900.0 * TAU) * 0.35
		s += sin(t * 1350.0 * TAU) * 0.25
		s += sin(t * 2700.0 * TAU) * 0.15
		# Shimmer
		s += sin(t * 2700.0 * TAU + sin(t * 8.0 * TAU) * 2.0) * 0.1
		return s * env
	)
	return _to_wav(samples)

func _generate_shockwave_sound(gen: int) -> AudioStreamWAV:
	var duration := 0.12
	var low_freq := 120.0
	var samples := _make_samples(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.04, 0.85)
		var s := sin(t * low_freq * TAU) * 0.4
		# Noise burst
		if t < 0.03:
			s += _audio_rng.randf_range(-0.5, 0.5) * (1.0 - t / 0.03)
		var vol := 1.0 - float(gen - 1) * 0.25
		return s * env * vol
	)
	return _to_wav(samples)

func _generate_game_over_sound() -> AudioStreamWAV:
	var duration := 0.5
	var samples := _make_samples(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.01, 0.6)
		var freq := lerpf(300.0, 80.0, t / duration)
		var s := sin(t * freq * TAU) * 0.5
		# Add noise
		if t < 0.05:
			s += _audio_rng.randf_range(-0.3, 0.3)
		return s * env
	)
	return _to_wav(samples)

func _generate_slash_miss_sound() -> AudioStreamWAV:
	var duration := 0.04
	var samples := _make_samples(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.1, 0.8)
		return _audio_rng.randf_range(-0.15, 0.15) * env
	)
	return _to_wav(samples)

# --- Helpers ---

func _make_samples(duration: float, generator: Callable) -> PackedFloat32Array:
	var count := int(float(MIX_RATE) * duration)
	var out := PackedFloat32Array()
	out.resize(count)
	for i in range(count):
		var t := float(i) / float(MIX_RATE)
		out[i] = clampf(generator.call(t), -1.0, 1.0)
	return out

func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := int(samples[i] * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
