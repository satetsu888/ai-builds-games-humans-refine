extends RefCounted
class_name PlayerController

var center := Vector2(480.0, 270.0)
var orbit_radius := 176.0
var angle := 0.0
var angular_speed := 1.55
var position := Vector2.ZERO
var collision_radius := 13.0

func reset() -> void:
	angle = 0.0
	position = center + Vector2.RIGHT * orbit_radius

func update(delta: float, polarity: int, difficulty: float) -> void:
	angle += delta * angular_speed * float(polarity) * (0.9 + 0.2 * sqrt(difficulty))
	position = center + Vector2(cos(angle), sin(angle)) * orbit_radius
