extends RefCounted

const SPAWN_PROFILES := {
	"hunter": {"base": 200.0, "second": 0.0, "dur": 0.042, "shape": "sine_hit", "slide": -20.0},
	"drifter": {"base": 305.0, "second": 0.0, "dur": 0.064, "shape": "airy", "slide": -38.0},
	"orbiter": {"base": 420.0, "second": 520.0, "dur": 0.074, "shape": "double_ping", "slide": 0.0},
	"lancer": {"base": 700.0, "second": 0.0, "dur": 0.032, "shape": "tick", "slide": 28.0},
	"splitter": {"base": 252.0, "second": 360.0, "dur": 0.056, "shape": "click_pair", "slide": 0.0},
	"anchor": {"base": 145.0, "second": 0.0, "dur": 0.072, "shape": "low_thud", "slide": -12.0},
	"sniper": {"base": 910.0, "second": 0.0, "dur": 0.028, "shape": "needle", "slide": 14.0},
	"shepherd": {"base": 332.0, "second": 282.0, "dur": 0.082, "shape": "command_duo", "slide": -10.0},
	"mine_layer": {"base": 170.0, "second": 0.0, "dur": 0.058, "shape": "damped_click", "slide": -8.0},
	"mirror": {"base": 482.0, "second": 522.0, "dur": 0.048, "shape": "dual_phase", "slide": 0.0},
	"phase": {"base": 262.0, "second": 0.0, "dur": 0.064, "shape": "phase_wisp", "slide": -18.0},
}
const DEFAULT_SPAWN_PROFILE := {"base": 220.0, "second": 0.0, "dur": 0.05, "shape": "sine_hit", "slide": -18.0}
const ENEMY_MOTIF_PROFILES := {
	"hunter": {"register": -10, "motif_steps": [0, 2, 4, 2, 0], "interval_far": 0.86, "interval_near": 0.46, "decay": 2.5, "attack": 0.14, "width": 0.68, "gain": 0.72, "noise": 0.018, "mix_tri": 0.54, "mix_sine": 0.38, "mix_square": 0.08, "priority": 0.54},
	"drifter": {"register": -7, "motif_steps": [0, 4, 2], "interval_far": 0.98, "interval_near": 0.55, "decay": 2.2, "attack": 0.11, "width": 0.6, "gain": 0.65, "noise": 0.012, "mix_tri": 0.22, "mix_sine": 0.72, "mix_square": 0.06, "priority": 0.5},
	"orbiter": {"register": -3, "motif_steps": [0, 7, 4, 9], "interval_far": 0.76, "interval_near": 0.36, "decay": 2.8, "attack": 0.18, "width": 0.88, "gain": 0.82, "noise": 0.024, "mix_tri": 0.62, "mix_sine": 0.32, "mix_square": 0.06, "priority": 0.76},
	"lancer": {"register": 2, "motif_steps": [0, 4, 7, 11, 7], "interval_far": 0.64, "interval_near": 0.22, "decay": 3.3, "attack": 0.24, "width": 0.94, "gain": 0.9, "noise": 0.03, "mix_tri": 0.2, "mix_sine": 0.24, "mix_square": 0.56, "priority": 0.95},
	"splitter": {"register": -4, "motif_steps": [0, 2, 4, 7, 4, 2], "interval_far": 0.72, "interval_near": 0.3, "decay": 2.7, "attack": 0.16, "width": 0.8, "gain": 0.76, "noise": 0.02, "mix_tri": 0.5, "mix_sine": 0.38, "mix_square": 0.12, "priority": 0.73},
	"anchor": {"register": -15, "motif_steps": [0, 0, 2], "interval_far": 1.16, "interval_near": 0.62, "decay": 1.9, "attack": 0.08, "width": 0.52, "gain": 0.84, "noise": 0.01, "mix_tri": 0.72, "mix_sine": 0.24, "mix_square": 0.04, "priority": 0.88},
	"sniper": {"register": 9, "motif_steps": [0, 11, 7], "interval_far": 0.56, "interval_near": 0.18, "decay": 3.7, "attack": 0.28, "width": 0.96, "gain": 0.94, "noise": 0.034, "mix_tri": 0.08, "mix_sine": 0.64, "mix_square": 0.28, "priority": 1.0},
	"shepherd": {"register": -6, "motif_steps": [0, 4, 2, 0], "interval_far": 0.94, "interval_near": 0.46, "decay": 1.8, "attack": 0.1, "width": 0.66, "gain": 0.58, "noise": 0.012, "mix_tri": 0.26, "mix_sine": 0.68, "mix_square": 0.06, "priority": 0.47},
	"mine_layer": {"register": -12, "motif_steps": [0, 2, 7, 2], "interval_far": 0.88, "interval_near": 0.4, "decay": 2.3, "attack": 0.12, "width": 0.74, "gain": 0.7, "noise": 0.018, "mix_tri": 0.58, "mix_sine": 0.34, "mix_square": 0.08, "priority": 0.69},
	"mirror": {"register": -1, "motif_steps": [0, 7, 11, 7], "interval_far": 0.74, "interval_near": 0.3, "decay": 2.7, "attack": 0.18, "width": 0.92, "gain": 0.84, "noise": 0.026, "mix_tri": 0.32, "mix_sine": 0.56, "mix_square": 0.12, "priority": 0.8},
	"phase": {"register": 1, "motif_steps": [0, 9, 4, 11, 7], "interval_far": 0.8, "interval_near": 0.28, "decay": 3.2, "attack": 0.2, "width": 0.9, "gain": 0.88, "noise": 0.03, "mix_tri": 0.36, "mix_sine": 0.48, "mix_square": 0.16, "priority": 0.91},
}
const DEFAULT_ENEMY_MOTIF_PROFILE := {"register": -5, "motif_steps": [0, 2, 4, 7], "interval_far": 0.84, "interval_near": 0.36, "decay": 2.4, "attack": 0.14, "width": 0.72, "gain": 0.7, "noise": 0.018, "mix_tri": 0.42, "mix_sine": 0.5, "mix_square": 0.08, "priority": 0.6}

class EnemyVoice extends RefCounted:
	var phase := 0.0
	var phase2 := 0.0
	var lfo := 0.0
	var noise_state := 0.0
	var env := 0.0
	var timer := 0.0
	var freq := 220.0
	var seq_idx := 0
	var dist := 340.0
	var pan := 0.0
	var target_dist := 340.0
	var target_pan := 0.0
	var slot := 0
	var profile: Dictionary = DEFAULT_ENEMY_MOTIF_PROFILE
	var motif_steps: Array = [0, 2, 4, 7]
	var interval_far := 0.84
	var interval_near := 0.36
	var decay := 2.4
	var attack := 0.14
	var width := 0.72
	var gain := 0.7
	var noise_mix := 0.018
	var mix_tri := 0.42
	var mix_sine := 0.5
	var mix_square := 0.08

	func apply_profile(next_profile: Dictionary) -> void:
		profile = next_profile
		motif_steps = next_profile.get("motif_steps", [0, 2, 4, 7])
		interval_far = float(next_profile.get("interval_far", 0.8))
		interval_near = float(next_profile.get("interval_near", 0.36))
		decay = float(next_profile.get("decay", 2.4))
		attack = float(next_profile.get("attack", 0.14))
		width = float(next_profile.get("width", 0.7))
		gain = float(next_profile.get("gain", 0.9))
		noise_mix = float(next_profile.get("noise", 0.018))
		mix_tri = float(next_profile.get("mix_tri", 0.42))
		mix_sine = float(next_profile.get("mix_sine", 0.5))
		mix_square = minf(0.12, float(next_profile.get("mix_square", 0.08)))

static func push_sample(playback: AudioStreamGeneratorPlayback, sample: float) -> bool:
	var v := clampf(sample, -1.0, 1.0)
	return playback.push_frame(Vector2(v, v))

static func push_stereo_sample(playback: AudioStreamGeneratorPlayback, left: float, right: float) -> bool:
	var l := clampf(left, -1.0, 1.0)
	var r := clampf(right, -1.0, 1.0)
	return playback.push_frame(Vector2(l, r))

static func sfx_envelope(t: float, duration: float, attack_ratio: float = 0.1, release_ratio: float = 0.45) -> float:
	if duration <= 0.0:
		return 0.0
	var attack_time: float = maxf(0.001, duration * attack_ratio)
	var release_time: float = maxf(0.001, duration * release_ratio)
	if t < attack_time:
		return t / attack_time
	if t > duration - release_time:
		return max(0.0, (duration - t) / release_time)
	return 1.0

static func sine(phase: float) -> float:
	return sin(phase * TAU)

static func square(phase: float, duty: float = 0.5) -> float:
	return 1.0 if fmod(phase, 1.0) < duty else -1.0

static func triangle(phase: float) -> float:
	var t := fmod(phase, 1.0)
	return 4.0 * absf(t - 0.5) - 1.0

static func noise(audio_rng: RandomNumberGenerator) -> float:
	return audio_rng.randf_range(-1.0, 1.0)

static func semantic_detune(audio_rng: RandomNumberGenerator, amount: float = 0.03) -> float:
	return 1.0 + audio_rng.randf_range(-amount, amount)

static func semantic_color(audio_rng: RandomNumberGenerator) -> float:
	return audio_rng.randf_range(-1.0, 1.0)

static func _push_samples(playback: AudioStreamGeneratorPlayback, samples: PackedFloat32Array) -> void:
	for s in samples:
		if not push_sample(playback, s):
			return

static func build_score_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.16 + 0.03 * maxf(0.0, color)
	var combo_multi := float(params.get("multiplier", 1))
	var chain := float(params.get("chain", 0))
	var impact_speed := clampf(float(params.get("impact_speed", 120.0)), 40.0, 420.0)
	var impact_ratio := impact_speed / 420.0
	var detune := semantic_detune(audio_rng, 0.055)
	var phase_low := 0.0
	var phase_high := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var low_freq := (180.0 + impact_ratio * 70.0 + combo_multi * 3.5) * detune
		var high_freq := (640.0 + combo_multi * 36.0 + chain * 18.0 + 280.0 * (t / duration)) * detune
		phase_low += low_freq / mix_rate
		phase_high += high_freq / mix_rate
		var body_env := sfx_envelope(t, duration, 0.025 + maxf(0.0, color) * 0.03, 0.5 + maxf(0.0, -color) * 0.18)
		var spark_env := sfx_envelope(t, duration * 0.62, 0.02, 0.72 + maxf(0.0, color) * 0.12)
		var burst_env := maxf(0.0, 1.0 - t / 0.024)
		var low_body := triangle(phase_low) * (0.42 + impact_ratio * 0.2)
		var duty := 0.22 + maxf(0.0, color) * 0.12
		var high_tail := (square(phase_high, duty) * 0.18 + sine(phase_high * (1.45 + maxf(0.0, -color) * 0.25)) * 0.2) * spark_env
		var burst := (noise(audio_rng) * 0.36 + square(phase_high * 0.5, 0.2) * 0.18) * burst_env
		out[i] = (low_body + high_tail + burst) * body_env * 0.56
	return out

static func gen_score_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_score_sfx_samples(params, audio_rng, mix_rate))

static func build_near_miss_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.085 + 0.02 * maxf(0.0, color)
	var combo_multi := float(params.get("multiplier", 1))
	var speed := clampf(float(params.get("speed", 0.0)), 0.0, 360.0)
	var speed_ratio := speed / 360.0
	var detune := semantic_detune(audio_rng, 0.06)
	var start_freq := (560.0 + combo_multi * 14.0) * detune
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := start_freq - 150.0 * (t / duration)
		phase += freq / mix_rate
		var env := sfx_envelope(t, duration, 0.04 + maxf(0.0, color) * 0.04, 0.58 + maxf(0.0, -color) * 0.2)
		var hiss_gate := maxf(0.0, 1.0 - t / 0.05)
		var duty := 0.14 + maxf(0.0, color) * 0.1
		var flutter := 1.0 + 0.12 * sine((t / maxf(0.001, duration)) * (2.0 + maxf(0.0, -color) * 2.0))
		out[i] = (square(phase, duty) * 0.26 + triangle(phase * 0.5) * 0.12 + noise(audio_rng) * 0.15 * hiss_gate) * env * (0.24 + speed_ratio * 0.14) * flutter
	return out

static func gen_near_miss_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_near_miss_sfx_samples(params, audio_rng, mix_rate))

static func build_danger_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.095 + 0.03 * maxf(0.0, color)
	var danger := clampf(float(params.get("danger", 0.7)), 0.0, 1.0)
	var difficulty_level := clampf(float(params.get("difficulty", 1.0)), 1.0, 4.0)
	var detune := semantic_detune(audio_rng, 0.05)
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := (520.0 + 180.0 * danger + difficulty_level * 10.0) * detune
		phase += freq / mix_rate
		var env := sfx_envelope(t, duration, 0.025 + maxf(0.0, color) * 0.03, 0.64 + maxf(0.0, -color) * 0.22)
		var pulse := square(phase, 0.16 + 0.03 * danger) * (0.22 + 0.14 * danger)
		var grit := noise(audio_rng) * (0.08 + danger * 0.1) * maxf(0.0, 1.0 - t / duration)
		var gate2 := 1.0 if t > duration * (0.48 + maxf(0.0, color) * 0.14) else 0.0
		var second := square(phase * 1.35, 0.12 + maxf(0.0, color) * 0.08) * (0.08 + 0.1 * danger) * gate2
		out[i] = (pulse + grit + second) * env * 0.52
	return out

static func gen_danger_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_danger_sfx_samples(params, audio_rng, mix_rate))

static func build_shield_break_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.2 + 0.06 * maxf(0.0, -color)
	var impact_speed := clampf(float(params.get("impact_speed", 120.0)), 20.0, 420.0)
	var difficulty_level := clampf(float(params.get("difficulty", 1.0)), 1.0, 4.0)
	var grit := impact_speed / 420.0
	var detune := semantic_detune(audio_rng, 0.05)
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := (260.0 - 145.0 * (t / duration) + difficulty_level * 10.0) * detune
		phase += freq / mix_rate
		var env := sfx_envelope(t, duration, 0.014 + maxf(0.0, color) * 0.03, 0.72 + maxf(0.0, -color) * 0.2)
		out[i] = (square(phase, 0.24 + 0.03 * grit) * 0.36 + noise(audio_rng) * (0.12 + grit * 0.2)) * env * 0.62
	return out

static func gen_shield_break_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_shield_break_sfx_samples(params, audio_rng, mix_rate))

static func build_ship_lost_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.32 + 0.1 * maxf(0.0, -color)
	var impact_speed := clampf(float(params.get("impact_speed", 140.0)), 20.0, 480.0)
	var difficulty_level := clampf(float(params.get("difficulty", 1.0)), 1.0, 4.0)
	var lives_left := maxi(0, int(params.get("lives", 0)))
	var grit := impact_speed / 480.0
	var detune := semantic_detune(audio_rng, 0.065)
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := (180.0 - 150.0 * (t / duration) + difficulty_level * 7.0 + float(lives_left) * 4.0) * detune
		phase += maxf(45.0, freq) / mix_rate
		var env := sfx_envelope(t, duration, 0.01 + maxf(0.0, color) * 0.02, 0.8 + maxf(0.0, -color) * 0.16)
		var burst := maxf(0.0, 1.0 - t / 0.035)
		var noisy_core := noise(audio_rng) * (0.34 + grit * 0.42)
		var rasp := square(phase, 0.21 + grit * 0.06) * (0.2 + grit * 0.12)
		var low_tail := triangle(phase * 0.52) * 0.16
		out[i] = (noisy_core + rasp + low_tail + noise(audio_rng) * 0.22 * burst) * env * 0.7
	return out

static func gen_ship_lost_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_ship_lost_sfx_samples(params, audio_rng, mix_rate))

static func build_shield_ready_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.14 + 0.03 * maxf(0.0, color)
	var difficulty_level := clampf(float(params.get("difficulty", 1.0)), 1.0, 4.0)
	var detune := semantic_detune(audio_rng, 0.04)
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := (780.0 + 180.0 * (t / duration) + difficulty_level * 15.0) * detune
		phase += freq / mix_rate
		var env := sfx_envelope(t, duration, 0.07 + maxf(0.0, color) * 0.05, 0.5 + maxf(0.0, -color) * 0.2)
		out[i] = (sine(phase) * 0.58 + sine(phase * 1.5) * 0.22) * env * 0.36
	return out

static func gen_shield_ready_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_shield_ready_sfx_samples(params, audio_rng, mix_rate))

static func build_wave_shift_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.17 + 0.04 * maxf(0.0, color)
	var difficulty_level := clampf(float(params.get("difficulty", 1.0)), 1.0, 4.0)
	var wave := int(params.get("wave", 0))
	var detune := semantic_detune(audio_rng, 0.045)
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := (420.0 + float(wave % 5) * 28.0 + 230.0 * (t / duration) + difficulty_level * 10.0) * detune
		phase += freq / mix_rate
		var env := sfx_envelope(t, duration, 0.03 + maxf(0.0, color) * 0.03, 0.58 + maxf(0.0, -color) * 0.18)
		out[i] = (triangle(phase) * 0.44 + sine(phase * 0.5) * 0.22) * env * 0.33
	return out

static func gen_wave_shift_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_wave_shift_sfx_samples(params, audio_rng, mix_rate))

static func gen_game_over_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	_push_samples(playback, build_game_over_sfx_samples(params, audio_rng, mix_rate))

static func render_sfx_event(playback: AudioStreamGeneratorPlayback, event_name: String, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> bool:
	if playback == null:
		return false
	if event_name.begins_with("spawn_"):
		gen_enemy_spawn_sfx(playback, params, audio_rng, mix_rate)
		return true
	match event_name:
		"score":
			gen_score_sfx(playback, params, audio_rng, mix_rate)
			return true
		"near_miss":
			gen_near_miss_sfx(playback, params, audio_rng, mix_rate)
			return true
		"danger":
			gen_danger_sfx(playback, params, audio_rng, mix_rate)
			return true
		"shield_break":
			gen_shield_break_sfx(playback, params, audio_rng, mix_rate)
			return true
		"ship_lost":
			gen_ship_lost_sfx(playback, params, audio_rng, mix_rate)
			return true
		"shield_ready":
			gen_shield_ready_sfx(playback, params, audio_rng, mix_rate)
			return true
		"wave_shift":
			gen_wave_shift_sfx(playback, params, audio_rng, mix_rate)
			return true
		"game_over":
			gen_game_over_sfx(playback, params, audio_rng, mix_rate)
			return true
		_:
			return false

static func build_game_over_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var color := semantic_color(audio_rng)
	var duration := 0.38 + 0.1 * maxf(0.0, -color)
	var difficulty_level := clampf(float(params.get("difficulty", 1.0)), 1.0, 4.0)
	var mult := clampf(float(params.get("multiplier", 1.0)), 1.0, 12.0)
	var detune := semantic_detune(audio_rng, 0.04)
	var phase := 0.0
	var total_samples := int(duration * mix_rate)
	var out := PackedFloat32Array()
	out.resize(maxi(1, total_samples))
	for i in range(out.size()):
		var t := float(i) / mix_rate
		var freq := ((440.0 + mult * 5.0) * pow(0.25, t / duration) - difficulty_level * 12.0) * detune
		phase += maxf(40.0, freq) / mix_rate
		var env := sfx_envelope(t, duration, 0.01 + maxf(0.0, color) * 0.02, 0.82 + maxf(0.0, -color) * 0.16)
		out[i] = (sine(phase) * 0.62 + triangle(phase * 0.5) * (0.22 + maxf(0.0, color) * 0.08) + noise(audio_rng) * 0.08) * env * 0.5
	return out

static func _spawn_profile(enemy_type: String) -> Dictionary:
	return SPAWN_PROFILES.get(enemy_type, DEFAULT_SPAWN_PROFILE)

static func build_enemy_spawn_sfx_samples(params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> PackedFloat32Array:
	var enemy_type := str(params.get("enemy_type", "hunter"))
	var profile := _spawn_profile(enemy_type)
	var color := semantic_color(audio_rng)
	var detune := semantic_detune(audio_rng, 0.02)
	var duration := float(profile.get("dur", 0.05)) + maxf(0.0, color) * 0.004
	var base := float(profile.get("base", 220.0)) * detune
	var second := float(profile.get("second", 0.0)) * detune
	var slide := float(profile.get("slide", 0.0))
	var shape := str(profile.get("shape", "sine_hit"))
	var base_volume := clampf(float(params.get("volume", 0.22)), 0.02, 0.35)
	var total_samples := maxi(1, int(duration * mix_rate))
	var out := PackedFloat32Array()
	out.resize(total_samples)
	var phase := 0.0
	var phase_b := 0.0
	for i in range(total_samples):
		var t := float(i) / mix_rate
		var progress := t / maxf(0.001, duration)
		var freq := base + slide * progress
		phase += maxf(30.0, freq) / mix_rate
		if second > 0.0:
			var second_freq := second + slide * 0.3 * progress
			phase_b += maxf(40.0, second_freq) / mix_rate
		var env := sfx_envelope(t, duration, 0.04, 0.62)
		var sample := 0.0
		match shape:
			"airy":
				var hiss_gate := maxf(0.0, 1.0 - progress * 1.2)
				sample = sine(phase) * 0.62 + noise(audio_rng) * 0.14 * hiss_gate
			"double_ping":
				var gate_a := 1.0 if progress < 0.38 else 0.0
				var gate_b := 1.0 if progress > 0.32 else 0.0
				sample = sine(phase) * 0.48 * gate_a + sine(phase_b) * 0.44 * gate_b
			"tick":
				var click := maxf(0.0, 1.0 - progress / 0.18)
				sample = square(phase, 0.12) * 0.42 + noise(audio_rng) * 0.22 * click
			"click_pair":
				var gate_1 := 1.0 if progress < 0.36 else 0.0
				var gate_2 := 1.0 if progress > 0.46 else 0.0
				sample = square(phase, 0.14) * 0.34 * gate_1 + triangle(phase_b) * 0.3 * gate_2 + noise(audio_rng) * 0.12
			"low_thud":
				sample = triangle(phase) * 0.6 + square(phase * 0.5, 0.22) * 0.2
			"needle":
				sample = sine(phase) * 0.56 + square(phase * 1.2, 0.1) * 0.14
			"command_duo":
				var duo_a := 1.0 if progress < 0.43 else 0.0
				var duo_b := 1.0 if progress > 0.34 else 0.0
				sample = triangle(phase) * 0.44 * duo_a + sine(phase_b) * 0.42 * duo_b
			"damped_click":
				var click_env := maxf(0.0, 1.0 - progress / 0.33)
				sample = square(phase, 0.2) * 0.36 + noise(audio_rng) * 0.18 * click_env
			"dual_phase":
				sample = sine(phase) * 0.35 + sine(phase_b + 0.16) * 0.35 + triangle(phase * 0.5) * 0.12
			"phase_wisp":
				var wobble := 1.0 + 0.12 * sine(progress * 4.6)
				sample = sine(phase * wobble) * 0.52 + triangle(phase * 0.48) * 0.18
			_:
				sample = sine(phase) * 0.6
		out[i] = sample * env * base_volume
	return out

static func gen_enemy_spawn_sfx(playback: AudioStreamGeneratorPlayback, params: Dictionary, audio_rng: RandomNumberGenerator, mix_rate: float) -> void:
	var samples := build_enemy_spawn_sfx_samples(params, audio_rng, mix_rate)
	var pan := clampf(float(params.get("pan", 0.0)), -0.4, 0.4)
	var frames := mini(samples.size(), playback.get_frames_available())
	for i in range(frames):
		var sample := samples[i]
		var left := sample * clampf(1.0 - pan, 0.6, 1.4)
		var right := sample * clampf(1.0 + pan, 0.6, 1.4)
		if not push_stereo_sample(playback, left, right):
			return

static func push_ambient_frames(
	playback: AudioStreamGeneratorPlayback,
	params: Dictionary,
	state: Dictionary,
	audio_rng: RandomNumberGenerator,
	mix_rate: float,
	max_fill_frames: int = 1024
) -> void:
	if playback == null:
		return
	var frames := mini(playback.get_frames_available(), maxi(1, max_fill_frames))
	if frames <= 0:
		return
	var lp_left := float(state.get("lp_left", 0.0))
	var lp_right := float(state.get("lp_right", 0.0))
	var enemy_motifs: Array = params.get("enemy_motifs", [])
	var enemy_amp := clampf(float(params.get("enemy_amp", 0.0)), 0.0, 1.2)
	var voices: Dictionary = state.get("enemy_voices", {})
	_sync_enemy_voices(voices, enemy_motifs, audio_rng)
	for _i in range(frames):
		var frame_pair := _enemy_voice_frame(voices, mix_rate)
		var left: float = float(frame_pair.get("left", 0.0)) * enemy_amp
		var right: float = float(frame_pair.get("right", 0.0)) * enemy_amp
		lp_left = lerpf(lp_left, left, 0.24)
		lp_right = lerpf(lp_right, right, 0.24)
		if not push_stereo_sample(playback, lp_left, lp_right):
			break
	state["enemy_voices"] = voices
	state["lp_left"] = lp_left
	state["lp_right"] = lp_right

static func _enemy_motif_profile(enemy_type: String) -> Dictionary:
	return ENEMY_MOTIF_PROFILES.get(enemy_type, DEFAULT_ENEMY_MOTIF_PROFILE)

static func _slot_chord_steps() -> Array:
	return [0, 4, 7, 11]

static func _safe_scale_steps() -> Array:
	# Safe bright scale (Lydian-ish): avoids harsh minor-second collisions.
	return [0, 2, 4, 6, 7, 9, 11]

static func _quantize_to_safe_scale(semitone: int) -> int:
	var oct := int(floor(float(semitone) / 12.0))
	var step := semitone - oct * 12
	var safe := _safe_scale_steps()
	var best := int(safe[0])
	var best_diff: int = abs(best - step)
	for s in safe:
		var si := int(s)
		var diff: int = abs(si - step)
		if diff < best_diff:
			best = si
			best_diff = diff
	return oct * 12 + best

static func _voice_freq_hz(profile: Dictionary, slot: int, phrase_step: int) -> float:
	var register := int(profile.get("register", -5))
	var chord := _slot_chord_steps()
	var chord_step := int(chord[slot % chord.size()])
	var semi := register + chord_step + phrase_step
	var quantized := _quantize_to_safe_scale(semi)
	return 220.0 * pow(2.0, float(quantized) / 12.0)

static func _sync_enemy_voices(voices: Dictionary, enemy_motifs: Array, audio_rng: RandomNumberGenerator) -> void:
	var top_motifs: Array = []
	for motif in enemy_motifs:
		var item: Dictionary = motif
		var enemy_type := str(item.get("type", "hunter"))
		var profile := _enemy_motif_profile(enemy_type)
		var dist := float(item.get("dist", 9999.0))
		var priority := float(profile.get("priority", 0.5))
		var rank := dist - priority * 90.0
		var inserted := false
		for i in range(top_motifs.size()):
			if rank < float((top_motifs[i] as Dictionary).get("rank", 9999.0)):
				top_motifs.insert(i, {"item": item, "type": enemy_type, "profile": profile, "rank": rank})
				inserted = true
				break
		if not inserted and top_motifs.size() < 4:
			top_motifs.append({"item": item, "type": enemy_type, "profile": profile, "rank": rank})
		if top_motifs.size() > 4:
			top_motifs.resize(4)
	var live_types: Dictionary = {}
	var slot_idx := 0
	for ranked in top_motifs:
		var ranked_item: Dictionary = ranked
		var item: Dictionary = ranked_item.get("item", {})
		var enemy_type := str(ranked_item.get("type", "hunter"))
		live_types[enemy_type] = true
		var profile: Dictionary = ranked_item.get("profile", _enemy_motif_profile(enemy_type))
		var voice_variant: Variant = voices.get(enemy_type, null)
		var voice: EnemyVoice
		if voice_variant is EnemyVoice:
			voice = voice_variant
		else:
			voice = EnemyVoice.new()
			if voice_variant is Dictionary and not (voice_variant as Dictionary).is_empty():
				var legacy: Dictionary = voice_variant
				voice.phase = float(legacy.get("phase", 0.0))
				voice.phase2 = float(legacy.get("phase2", 0.0))
				voice.lfo = float(legacy.get("lfo", 0.0))
				voice.noise_state = float(legacy.get("noise_state", 0.0))
				voice.env = float(legacy.get("env", 0.0))
				voice.timer = float(legacy.get("timer", 0.0))
				voice.freq = float(legacy.get("freq", 220.0))
				voice.seq_idx = int(legacy.get("seq_idx", 0))
				voice.dist = float(legacy.get("dist", 340.0))
				voice.pan = float(legacy.get("pan", 0.0))
				voice.target_dist = float(legacy.get("target_dist", voice.dist))
				voice.target_pan = float(legacy.get("target_pan", voice.pan))
				voice.slot = int(legacy.get("slot", slot_idx))
			else:
				var seed := float(abs(enemy_type.hash()) % 997) / 997.0
				voice.phase = seed
				voice.phase2 = fmod(seed * 1.414, 1.0)
				voice.lfo = audio_rng.randf()
				voice.noise_state = 0.0
				voice.env = 0.0
				voice.timer = audio_rng.randf_range(0.04, 0.24)
				voice.freq = _voice_freq_hz(profile, slot_idx, 0)
				voice.seq_idx = int(abs(enemy_type.hash())) % maxi(1, (profile.get("motif_steps", [0]) as Array).size())
				voice.dist = float(item.get("dist", 340.0))
				voice.pan = float(item.get("pan", 0.0))
				voice.target_dist = voice.dist
				voice.target_pan = voice.pan
				voice.slot = slot_idx
		voice.apply_profile(profile)
		voice.target_dist = float(item.get("dist", 340.0))
		voice.target_pan = float(item.get("pan", 0.0))
		voice.slot = slot_idx
		if voice.freq <= 0.0:
			voice.freq = _voice_freq_hz(profile, slot_idx, 0)
		voices[enemy_type] = voice
		slot_idx += 1
	for existing in voices.keys():
		var key := str(existing)
		if live_types.has(key):
			continue
		var stale_variant: Variant = voices[key]
		if stale_variant is EnemyVoice:
			var stale: EnemyVoice = stale_variant
			stale.target_dist = 340.0
			stale.target_pan = 0.0
			stale.timer = maxf(stale.timer, 0.08)
			voices[key] = stale
		elif stale_variant is Dictionary:
			var stale_dict: Dictionary = stale_variant
			stale_dict["target_dist"] = 340.0
			stale_dict["target_pan"] = 0.0
			stale_dict["timer"] = maxf(float(stale_dict.get("timer", 0.0)), 0.08)
			voices[key] = stale_dict

static func _enemy_voice_frame(voices: Dictionary, mix_rate: float) -> Dictionary:
	const MOTIF_AUDIBLE_DIST := 760.0
	const SILENT_ENV_EPS := 0.0008
	const SILENT_PROXIMITY_EPS := 0.001
	if voices.is_empty():
		return {"left": 0.0, "right": 0.0}
	var sum_left := 0.0
	var sum_right := 0.0
	var remove_keys: Array = []
	for key_variant in voices.keys():
		var enemy_type := str(key_variant)
		var voice_variant: Variant = voices[enemy_type]
		if not (voice_variant is EnemyVoice):
			remove_keys.append(enemy_type)
			continue
		var voice: EnemyVoice = voice_variant
		var profile := voice.profile
		var dist := clampf(voice.dist, 0.0, MOTIF_AUDIBLE_DIST)
		var target_dist := clampf(voice.target_dist, 0.0, MOTIF_AUDIBLE_DIST)
		var pan := clampf(voice.pan, -1.0, 1.0)
		var target_pan := clampf(voice.target_pan, -1.0, 1.0)
		dist = lerpf(dist, target_dist, 0.1)
		pan = lerpf(pan, target_pan, 0.12)
		var proximity := 1.0 - dist / MOTIF_AUDIBLE_DIST
		if proximity <= 0.0:
			proximity = 0.0
		var interval_far := voice.interval_far
		var interval_near := voice.interval_near
		var decay := voice.decay
		var attack := voice.attack
		var width := voice.width
		var gain := voice.gain
		var noise_mix := voice.noise_mix
		var mix_tri := voice.mix_tri
		var mix_sine := voice.mix_sine
		var mix_square := voice.mix_square
		var motif_steps: Array = voice.motif_steps
		var timer := voice.timer - 1.0 / mix_rate
		var env := voice.env
		var seq_idx := voice.seq_idx
		var slot := voice.slot
		var freq := voice.freq
		if proximity <= SILENT_PROXIMITY_EPS and env <= SILENT_ENV_EPS and target_dist >= MOTIF_AUDIBLE_DIST - 4.0:
			remove_keys.append(enemy_type)
			continue
		if timer <= 0.0 and proximity > 0.0 and not motif_steps.is_empty():
			seq_idx = (seq_idx + 1) % motif_steps.size()
			var step := int(motif_steps[seq_idx])
			freq = _voice_freq_hz(profile, slot, step)
			var interval := lerpf(interval_far, interval_near, proximity) * 0.68
			var pulse_mod := 0.9 + 0.2 * float((seq_idx % 3)) / 2.0
			timer += interval * pulse_mod
			env = min(1.0, env + attack)
		var phase := fmod(voice.phase + freq / mix_rate, 1.0)
		var phase2 := fmod(voice.phase2 + (freq * 1.47) / mix_rate, 1.0)
		var lfo := fmod(voice.lfo + 0.28 / mix_rate, 1.0)
		var noise_state := lerpf(voice.noise_state, triangle(phase * 7.0 + lfo * 0.37), 0.08)
		env = move_toward(env, 0.0, decay / mix_rate)
		var tone := sine(phase) * (mix_sine + 0.2)
		tone += triangle(phase2) * (mix_tri * 0.78)
		tone += square(phase * 0.5, 0.22) * (mix_square * 0.45)
		var space := sine(lfo) * 0.05
		var voice_sample := (tone + space + noise_state * (noise_mix * 0.45)) * env * (0.1 + proximity * 0.38) * gain * 1.35
		sum_left += voice_sample * clampf(1.0 - pan * width, 0.2, 1.9)
		sum_right += voice_sample * clampf(1.0 + pan * width, 0.2, 1.9)
		voice.dist = dist
		voice.pan = pan
		voice.timer = timer
		voice.env = env
		voice.seq_idx = seq_idx
		voice.freq = freq
		voice.phase = phase
		voice.phase2 = phase2
		voice.lfo = lfo
		voice.noise_state = noise_state
		voices[enemy_type] = voice
		if target_dist >= MOTIF_AUDIBLE_DIST - 1.0 and env <= 0.001:
			remove_keys.append(enemy_type)
	for key in remove_keys:
		voices.erase(key)
	return {
		"left": clampf(sum_left, -0.58, 0.58),
		"right": clampf(sum_right, -0.58, 0.58),
	}
