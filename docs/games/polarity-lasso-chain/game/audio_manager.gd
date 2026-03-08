extends RefCounted
class_name AudioManager

const AudioSynth = preload("res://audio_synth.gd")

var _root: Node
var _sfx_player: AudioStreamPlayer
var _hum_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback
var _hum_playback: AudioStreamGeneratorPlayback

var _hum_phase := 0.0
var _hum_amp := 0.0

func setup(root: Node) -> void:
	_root = root
	_sfx_player = AudioStreamPlayer.new()
	var sfx_stream := AudioStreamGenerator.new()
	sfx_stream.mix_rate = 22050.0
	sfx_stream.buffer_length = 0.2
	_sfx_player.stream = sfx_stream
	_root.add_child(_sfx_player)
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback()

	_hum_player = AudioStreamPlayer.new()
	var hum_stream := AudioStreamGenerator.new()
	hum_stream.mix_rate = 22050.0
	hum_stream.buffer_length = 0.25
	_hum_player.stream = hum_stream
	_root.add_child(_hum_player)
	_hum_player.play()
	_hum_playback = _hum_player.get_stream_playback()

func update(delta: float, heat: float, danger: float) -> void:
	if _hum_playback == null:
		return
	var target := clampf(0.03 + heat * 0.06 + danger * 0.05, 0.0, 0.12)
	_hum_amp = lerpf(_hum_amp, target, clampf(delta * 6.0, 0.0, 1.0))
	var frames := mini(_hum_playback.get_frames_available(), 256)
	for _i in range(frames):
		var lfo := sin(_hum_phase * TAU * 0.13) * 0.15
		var sample := AudioSynth.triangle(_hum_phase) * _hum_amp + AudioSynth.sine(_hum_phase * 0.5) * _hum_amp * 0.4
		sample += AudioSynth.square(_hum_phase * 0.5 + lfo, 0.45) * _hum_amp * 0.15
		AudioSynth.push_sample(_hum_playback, sample)
		_hum_phase = fmod(_hum_phase + (84.0 / 22050.0), 1.0)

func score(points: int, combo: int) -> void:
	var base := 270.0 + minf(float(points), 110.0) * 0.66 + combo * 12.0
	var duration := clampf(0.18 + combo * 0.013, 0.18, 0.30)
	var gain := clampf(0.22 + combo * 0.012, 0.22, 0.31)
	_emit_space_rise(base, duration, gain)

func damage() -> void:
	_emit_space_impact(0.34, 0.32)

func state_change() -> void:
	_emit_tone(190.0, 0.12, 0.18, false)

func danger(level: float) -> void:
	_emit_tone(140.0 + 45.0 * level, 0.07, 0.11 + level * 0.12, false)

func _emit_tone(freq: float, duration: float, gain: float, bright: bool) -> void:
	if _sfx_playback == null:
		return
	var frames := int(duration * 22050.0)
	var phase := 0.0
	for i in range(frames):
		if _sfx_playback.get_frames_available() <= 0:
			break
		var t := float(i) / 22050.0
		var env := AudioSynth.sfx_envelope(t, duration, 0.07, 0.55)
		var sample := AudioSynth.sine(phase)
		if bright:
			sample += AudioSynth.square(phase, 0.38) * 0.35
		else:
			sample += AudioSynth.triangle(phase * 0.5) * 0.25
		AudioSynth.push_sample(_sfx_playback, sample * env * gain)
		phase = fmod(phase + (freq / 22050.0), 1.0)

func _emit_noise_drop(duration: float, gain: float) -> void:
	if _sfx_playback == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var frames := int(duration * 22050.0)
	var phase := 0.0
	for i in range(frames):
		if _sfx_playback.get_frames_available() <= 0:
			break
		var t := float(i) / 22050.0
		var env := AudioSynth.sfx_envelope(t, duration, 0.02, 0.7)
		var sweep := 220.0 - 130.0 * (t / duration)
		phase = fmod(phase + (sweep / 22050.0), 1.0)
		var sample := AudioSynth.sine(phase) * 0.65 + AudioSynth.noise(rng) * 0.35
		AudioSynth.push_sample(_sfx_playback, sample * env * gain)

func _emit_space_rise(base_freq: float, duration: float, gain: float) -> void:
	if _sfx_playback == null:
		return
	var frames := int(duration * 22050.0)
	var phase := 0.0
	var phase_high := 0.0
	var phase_air := 0.0
	for i in range(frames):
		if _sfx_playback.get_frames_available() <= 0:
			break
		var t := float(i) / 22050.0
		var progress := clampf(t / maxf(duration, 0.001), 0.0, 1.0)
		var rise := lerpf(1.0, 1.66, progress)
		var fm := sin(t * TAU * (2.0 + progress * 3.6)) * 0.020
		var drift := sin(t * TAU * 0.37) * 0.008
		var freq := base_freq * rise * (1.0 + fm + drift)
		phase = fmod(phase + (freq / 22050.0), 1.0)
		phase_high = fmod(phase_high + (freq * 2.35 / 22050.0), 1.0)
		phase_air = fmod(phase_air + (freq * 3.9 / 22050.0), 1.0)
		var env := AudioSynth.sfx_envelope(t, duration, 0.05, 0.33)
		var transient := AudioSynth.square(phase_air + sin(t * TAU * 9.6) * 0.008, 0.30) * 0.22 * (1.0 - progress)
		var shimmer := AudioSynth.sine(phase_high + sin(t * TAU * 4.8) * 0.012) * 0.36
		var body := AudioSynth.sine(phase) * 0.88
		var support := AudioSynth.sine(fmod(phase * 0.51 + 0.22, 1.0)) * 0.07
		var sample := body + shimmer + transient + support
		AudioSynth.push_sample(_sfx_playback, sample * env * gain)

func _emit_space_impact(duration: float, gain: float) -> void:
	if _sfx_playback == null:
		return
	var frames := int(duration * 22050.0)
	var phase := 0.0
	var phase_ring := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	for i in range(frames):
		if _sfx_playback.get_frames_available() <= 0:
			break
		var t := float(i) / 22050.0
		var progress := clampf(t / maxf(duration, 0.001), 0.0, 1.0)
		var fall := lerpf(1.0, 0.42, progress)
		var wobble := sin(t * TAU * (2.4 + progress * 1.2)) * 0.018
		var freq := 220.0 * fall * (1.0 + wobble)
		phase = fmod(phase + (freq / 22050.0), 1.0)
		phase_ring = fmod(phase_ring + (freq * 2.8 / 22050.0), 1.0)
		var env := AudioSynth.sfx_envelope(t, duration, 0.03, 0.62)
		var thump := AudioSynth.sine(phase) * 0.78
		var ring := AudioSynth.sine(phase_ring + sin(t * TAU * 6.2) * 0.012) * (0.38 + (1.0 - progress) * 0.12)
		var dust := AudioSynth.noise(rng) * (0.16 * (1.0 - progress))
		var sample := thump + ring + dust
		AudioSynth.push_sample(_sfx_playback, sample * env * gain)
