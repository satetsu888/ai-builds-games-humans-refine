extends Node

const AudioSynth = preload("res://audio_synth.gd")
const SFX_PLAYER_GAIN_DB := -0.8
const SFX_BUS_SIZE := 10

var _bus: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_ensure_bus()

func play_score(chain_level: int) -> void:
	var base := 420.0 + float(chain_level) * 28.0
	_play(_build_stream(0.24, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.24, 0.12, 0.64)
		var body := _blend_sine(base * 0.96, t, 0.18)
		var bloom := _blend_triangle(base * 1.48, t, 0.09 if chain_level >= 2 else 0.05)
		var air := AudioSynth.sine(base * 2.05 * t) * (0.045 if chain_level >= 4 else 0.025)
		var undertone := AudioSynth.sine(base * 0.52 * t) * 0.035
		return env * (body + bloom + air + undertone)
	))

func play_damage() -> void:
	_play(_build_stream(0.28, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.28, 0.05, 0.62)
		var low := AudioSynth.sine((118.0 - t * 22.0) * t) * 0.26
		var haze := AudioSynth.triangle(86.0 * t) * 0.08
		return env * (low + haze)
	))

func play_state_change() -> void:
	_play(_build_stream(0.18, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.18, 0.05, 0.5)
		return env * (_blend_sine(260.0, t, 0.2) + _blend_sine(390.0, t, 0.08))
	))

func play_throw() -> void:
	_play(_build_stream(0.16, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.16, 0.08, 0.62)
		var glide_freq := 176.0 + t * 42.0
		var body := _blend_sine(glide_freq, t, 0.16)
		var halo := _blend_triangle(glide_freq * 1.5, t, 0.06)
		return env * (body + halo)
	))

func play_enhance_charge() -> void:
	_play(_build_stream(0.26, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.26, 0.14, 0.62)
		var rise := _blend_triangle(280.0 + t * 180.0, t, 0.12)
		var top := _blend_sine(460.0 + t * 210.0, t, 0.09)
		var shimmer := AudioSynth.sine((760.0 + t * 120.0) * t) * 0.035
		var undertone := AudioSynth.sine((190.0 + t * 40.0) * t) * 0.03
		return env * (rise + top + shimmer + undertone)
	))

func play_conduction_step(step_index: int, scorable: bool) -> void:
	var freq := 260.0 + float(step_index % 6) * 34.0
	if not scorable:
		freq = 180.0 + float(step_index % 5) * 20.0
	_play(_build_stream(0.08, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.08, 0.03, 0.5)
		var tone := _blend_square(freq, t, 0.13) if scorable else _blend_sine(freq, t, 0.12)
		return env * (tone + AudioSynth.sine(freq * 2.0 * t) * (0.03 if scorable else 0.015))
	))

func play_spread_warning() -> void:
	_play(_build_stream(0.16, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.16, 0.06, 0.58)
		return env * (_blend_sine(196.0, t, 0.16) + _blend_triangle(246.0, t, 0.08))
	))

func play_spread_confirm() -> void:
	_play(_build_stream(0.24, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.24, 0.05, 0.6)
		return env * (_blend_triangle(168.0, t, 0.16) + _blend_sine(132.0, t, 0.14))
	))

func play_generator_break() -> void:
	_play(_build_stream(0.24, func(t: float) -> float:
		var env := AudioSynth.sfx_envelope(t, 0.24, 0.04, 0.58)
		var crack := _blend_square(260.0 - t * 80.0, t, 0.14)
		var body := _blend_triangle(180.0 - t * 30.0, t, 0.12)
		var tail := _blend_sine(120.0 - t * 18.0, t, 0.1)
		return env * (crack + body + tail)
	))

func _ensure_bus() -> void:
	if not _bus.is_empty():
		return
	for _i in range(SFX_BUS_SIZE):
		var player := AudioStreamPlayer.new()
		player.volume_db = SFX_PLAYER_GAIN_DB
		add_child(player)
		_bus.append(player)

func _play(stream: AudioStreamWAV) -> void:
	if not is_inside_tree():
		return
	_ensure_bus()
	var player := _bus[0]
	for candidate in _bus:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.play()

func _build_stream(duration: float, generator: Callable) -> AudioStreamWAV:
	var sample_rate := 22050
	var frames := maxi(1, int(duration * sample_rate))
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

func _blend_sine(freq: float, t: float, amp: float) -> float:
	return AudioSynth.sine(freq * t) * amp

func _blend_triangle(freq: float, t: float, amp: float) -> float:
	return (AudioSynth.triangle(freq * t) * 0.55 + AudioSynth.sine(freq * t) * 0.45) * amp

func _blend_square(freq: float, t: float, amp: float) -> float:
	return (AudioSynth.square(freq * t, 0.4) * 0.32 + AudioSynth.sine(freq * t) * 0.46 + AudioSynth.triangle(freq * t) * 0.22) * amp
