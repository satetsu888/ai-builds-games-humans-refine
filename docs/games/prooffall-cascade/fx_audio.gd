extends Node

const AudioSynth = preload("res://audio_synth.gd")
const GLYPH_PULSE_FREQS := [390.0, 470.0, 540.0]

var bus: Array[AudioStreamPlayer] = []
var jam_tick_timer := 0.0
var jam_critical_active := false

func _ready() -> void:
	_ensure_bus()

func _ensure_bus() -> void:
	if not bus.is_empty():
		return
	for _i in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -7.0
		add_child(player)
		bus.append(player)

func play_pulse(glyph: int = 0, cluster_size: int = 1) -> void:
	var duration: float = 0.11
	var center_freq: float = float(GLYPH_PULSE_FREQS[clampi(glyph, 0, 2)])
	var cluster_gain: float = clampf(float(cluster_size - 1) / 7.0, 0.0, 1.0)
	_play(_build_stream(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.04, 0.42)
		var click := AudioSynth.noise(_rng_for(t + center_freq * 0.001)) * 0.26
		var sweep_phase: float = center_freq * (1.0 + t * (0.2 + cluster_gain * 0.35))
		var tonal := AudioSynth.sine(sweep_phase * t) * (0.14 + cluster_gain * 0.05)
		var inhale := AudioSynth.noise(_rng_for(t * 1.9 + 0.23)) * (t / duration) * 0.07
		return env * (click + tonal + inhale)
	))

func play_score(points: int = 1, pressure_ratio: float = 0.0) -> void:
	var duration := 0.13
	var tier := clampi(int(floor(sqrt(float(maxi(points, 1))))), 1, 5)
	var pressure := clampf(pressure_ratio, 0.0, 1.0)
	_play(_build_stream(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.08, 0.35)
		var freq_a := 430.0 + t * (110.0 + pressure * 45.0)
		var freq_b := freq_a * (1.02 + pressure * 0.01)
		var body := AudioSynth.sine(freq_a * t) * 0.21 + AudioSynth.sine(freq_b * t) * 0.16
		var overtone := 0.0
		if tier >= 2:
			overtone += AudioSynth.sine(freq_a * 1.5 * t) * 0.09
		if tier >= 3:
			overtone += AudioSynth.sine(freq_a * 2.0 * t) * 0.06
		if tier >= 4:
			overtone += AudioSynth.sine((freq_a + 50.0) * 2.6 * t) * 0.04
		if tier >= 5:
			overtone += AudioSynth.noise(_rng_for(t * 3.1 + 0.9)) * 0.03
		return env * (body + overtone)
	))

func play_danger(intensity: float = 0.6) -> void:
	var scaled := clampf(intensity, 0.0, 1.0)
	var duration := lerpf(0.06, 0.1, scaled)
	_play(_build_stream(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.03, 0.42)
		var hiss := AudioSynth.noise(_rng_for(t * 3.0 + 0.17)) * (0.16 + scaled * 0.11)
		var edge := AudioSynth.sine((980.0 + scaled * 260.0) * t) * (0.05 + scaled * 0.03)
		var body := AudioSynth.sine((620.0 + scaled * 140.0) * t) * (0.06 + scaled * 0.04)
		return env * (hiss + edge + body)
	))

func play_pressure_step(level: int) -> void:
	var duration := 0.14
	var step: int = maxi(0, level - 1)
	_play(_build_stream(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.04, 0.32)
		var root := 300.0 + float(step) * 28.0
		var second_on := 1.0 if t > 0.055 else 0.0
		var a := AudioSynth.sine((root + t * 60.0) * t) * 0.18
		var b := AudioSynth.sine((root * 1.24 + t * 90.0) * t) * 0.14 * second_on
		return env * (a + b)
	))

func play_game_over() -> void:
	jam_tick_timer = 0.0
	jam_critical_active = false
	_play(_build_stream(0.42, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.42, 0.03, 0.5)
		var freq := 220.0 - 140.0 * t
		return env * (AudioSynth.sine(freq * t) * 0.26 + AudioSynth.noise(_rng_for(t * 5.0)) * 0.08)
	))

func update_jam_critical(delta: float, max_jam_ratio: float) -> void:
	var ratio := clampf(max_jam_ratio, 0.0, 1.0)
	var active := ratio >= 0.02
	if not active:
		if jam_critical_active:
			_play_jam_release()
		jam_tick_timer = 0.0
		jam_critical_active = false
		return
	jam_critical_active = true
	jam_tick_timer -= delta
	if jam_tick_timer > 0.0:
		return
	var tier := clampf((ratio - 0.02) / 0.98, 0.0, 1.0)
	_play_jam_tick(tier)
	jam_tick_timer = lerpf(0.34, 0.12, tier)

func _play(stream: AudioStreamWAV) -> void:
	if not is_inside_tree():
		return
	_ensure_bus()
	var player := bus[0]
	for candidate in bus:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.play()

func _build_stream(duration: float, generator: Callable) -> AudioStreamWAV:
	var sample_rate := 11025
	var frames := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(sample_rate)
		var sample := clampf(float(generator.call(t)), -1.0, 1.0)
		var pcm := int(round(sample * 32767.0))
		bytes[i * 2] = pcm & 255
		bytes[i * 2 + 1] = (pcm >> 8) & 255
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _play_jam_tick(tier: float) -> void:
	var duration := 0.065
	var tint := clampf(tier, 0.0, 1.0)
	_play(_build_stream(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.02, 0.55)
		var hiss := AudioSynth.noise(_rng_for(t * 2.7 + 0.61)) * (0.14 + tint * 0.1)
		var ring := AudioSynth.sine((840.0 + 200.0 * tint) * t) * (0.06 + tint * 0.04)
		var body := AudioSynth.sine((520.0 + 120.0 * tint) * t) * (0.05 + tint * 0.03)
		return env * (hiss + ring + body)
	))

func _play_jam_release() -> void:
	var duration := 0.07
	_play(_build_stream(duration, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, duration, 0.04, 0.7)
		var tone := AudioSynth.sine((300.0 - t * 70.0) * t) * 0.12
		return env * tone
	))

func _rng_for(seed_value: float) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_value * 1000000.0) + 77
	return rng
