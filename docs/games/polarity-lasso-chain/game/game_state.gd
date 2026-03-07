extends RefCounted
class_name GameState

var score := 0
var elapsed := 0.0
var difficulty := 1.0
var game_over := false
var combo := 1
var heat := 0.0
var polarity := 1

func reset() -> void:
	score = 0
	elapsed = 0.0
	difficulty = 1.0
	game_over = false
	combo = 1
	heat = 0.0
	polarity = 1

func tick(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	difficulty = 1.0 + (elapsed / 60.0)
	heat = maxf(0.0, heat - delta * (0.18 + 0.03 * difficulty))

func register_shot() -> void:
	heat = minf(1.4, heat + 0.16)

func register_reverse() -> void:
	polarity *= -1
	heat = minf(1.4, heat + 0.10)

func register_capture(captured: int, initial_active_captured: int = 0) -> int:
	if captured <= 0:
		return 0
	combo = clampi(1 + maxi(initial_active_captured, 0), 1, 8)
	var points := captured
	score += points
	heat = maxf(0.0, heat - 0.08)
	return points

func set_game_over() -> void:
	game_over = true

func reset_combo() -> void:
	combo = 1

func register_followup_capture(initial_captured: int) -> int:
	if initial_captured <= 0:
		return 0
	combo = mini(combo + 1, 8)
	var points := initial_captured * combo
	score += points
	heat = maxf(0.0, heat - 0.03)
	return points
