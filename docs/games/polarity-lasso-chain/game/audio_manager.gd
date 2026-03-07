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
	_emit_tone(320.0 + minf(float(points), 80.0) + combo * 16.0, 0.10 + combo * 0.01, 0.20, true)

func damage() -> void:
	_emit_noise_drop(0.28, 0.34)

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
