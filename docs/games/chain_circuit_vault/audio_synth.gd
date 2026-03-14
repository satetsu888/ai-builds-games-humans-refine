extends RefCounted

static func push_sample(playback: AudioStreamGeneratorPlayback, sample: float) -> bool:
	var v := clampf(sample, -1.0, 1.0)
	return playback.push_frame(Vector2(v, v))

static func sfx_envelope(t: float, duration: float, attack_ratio: float = 0.1, release_ratio: float = 0.45) -> float:
	if duration <= 0.0:
		return 0.0
	var attack_time: float = maxf(0.001, duration * attack_ratio)
	var release_time: float = maxf(0.001, duration * release_ratio)
	var sustain_level: float = 0.68
	if t < attack_time:
		var attack_progress: float = t / attack_time
		return sin(attack_progress * PI * 0.5) * sustain_level
	if t > duration - release_time:
		var release_progress: float = maxf(0.0, (duration - t) / release_time)
		return sustain_level * release_progress * release_progress * release_progress
	return sustain_level

static func sine(phase: float) -> float:
	return sin(phase * TAU)

static func square(phase: float, duty: float = 0.5) -> float:
	return 1.0 if fmod(phase, 1.0) < duty else -1.0

static func triangle(phase: float) -> float:
	var t := fmod(phase, 1.0)
	return 4.0 * absf(t - 0.5) - 1.0

static func noise(audio_rng: RandomNumberGenerator) -> float:
	return audio_rng.randf_range(-1.0, 1.0)
