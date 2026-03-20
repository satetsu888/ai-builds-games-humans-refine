extends RefCounted

# --- Constants ---
const SCREEN_W := 540.0
const SCREEN_H := 960.0
const GAME_AREA_H := 720.0  # Game plays in top 720px, below is controls
const GROUND_Y := 680.0
const PLAYER_RADIUS := 16.0
const PLAYER_SPEED := 250.0
const GRAVITY := 600.0

# Slash: horizontal arc
const SLASH_REACH := 100.0
const SLASH_CENTER_Y_OFFSET := 70.0
const SLASH_HALF_H := 35.0
const SLASH_COOLDOWN_TIME := 0.35
const COMBO_TIMEOUT := 1.5

const GEN_RADIUS := {1: 25.0, 2: 15.0, 3: 9.0}
const GEN_SCORE := {1: 1, 2: 3, 3: 7}
const GEN_FALL_SPEED := {1: 100.0, 2: 140.0, 3: 180.0}
const GEN_ROT_SPEED_DEG := {1: 25.0, 2: 50.0, 3: 90.0}
const SPLIT_VY := {1: -340.0, 2: -240.0}
const SPLIT_VX := {1: 140.0, 2: 95.0}

# Ground debris (replaces shockwave)
const DEBRIS_RADIUS := 8.0
const DEBRIS_LIFETIME := 1.2
const DEBRIS_VX_RANGE := 250.0
const DEBRIS_VY := -320.0

# --- State ---
var player_x := SCREEN_W / 2.0
var crystals: Array = []
var ground_debris: Array = []
var slash_effects: Array = []
var sparkles: Array = []

var score := 0
var combo := 0
var combo_timer := 0.0
var slash_cooldown := 0.0
var spawn_timer := 1.0
var elapsed := 0.0
var game_over := false
var death_hit_pos := Vector2.ZERO  # Position of the thing that killed the player

var rng := RandomNumberGenerator.new()

# Metrics
var entity_type_counts := {"crystal": 0}
var behavior_event_counts := {
	"slash": 0, "hit": 0, "split": 0,
	"burst": 0, "ground_impact": 0,
}

func reset(s: int) -> void:
	rng.seed = s
	player_x = SCREEN_W / 2.0
	crystals.clear()
	ground_debris.clear()
	slash_effects.clear()
	sparkles.clear()
	score = 0
	combo = 0
	combo_timer = 0.0
	slash_cooldown = 0.0
	spawn_timer = 1.0
	elapsed = 0.0
	game_over = false
	death_hit_pos = Vector2.ZERO
	entity_type_counts = {"crystal": 0}
	behavior_event_counts = {
		"slash": 0, "hit": 0, "split": 0,
		"burst": 0, "ground_impact": 0,
	}

func difficulty() -> int:
	return 1 + int(elapsed / 20.0)

func spawn_interval() -> float:
	return maxf(0.25, 1.8 / float(difficulty()))

func slash_y() -> float:
	return GROUND_Y - PLAYER_RADIUS - SLASH_CENTER_Y_OFFSET

# --- Main update ---
func update(delta: float, move_left: bool, move_right: bool, do_slash: bool) -> Array:
	if game_over:
		return []
	var events: Array = []
	elapsed += delta

	# Player
	if move_left:
		player_x -= PLAYER_SPEED * delta
	if move_right:
		player_x += PLAYER_SPEED * delta
	player_x = clampf(player_x, PLAYER_RADIUS, SCREEN_W - PLAYER_RADIUS)

	# Slash
	slash_cooldown = maxf(0.0, slash_cooldown - delta)
	if do_slash and slash_cooldown <= 0.0:
		_perform_slash(events)

	# Combo timer
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	# Update crystals
	_update_crystals(delta, events)

	# Update ground debris
	_update_ground_debris(delta, events)

	# Update effects (visual only)
	_update_effects(delta)

	# Spawn
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_crystal()
		spawn_timer = spawn_interval() + rng.randf_range(-0.3, 0.3)

	return events

# --- Slash (horizontal arc) ---
func _perform_slash(events: Array) -> void:
	slash_cooldown = SLASH_COOLDOWN_TIME
	behavior_event_counts["slash"] = int(behavior_event_counts["slash"]) + 1

	var sy := slash_y()
	slash_effects.append({
		"x": player_x, "y": sy,
		"reach": SLASH_REACH,
		"age": 0.0, "duration": 0.18, "combo": combo,
	})

	var hits: Array = []
	for c in crystals:
		var cx: float = c["x"]
		var cy: float = c["y"]
		var cr: float = c["radius"]
		# Horizontal range check
		if absf(cx - player_x) < SLASH_REACH + cr:
			# Vertical band check
			if cy + cr > sy - SLASH_HALF_H and cy - cr < sy + SLASH_HALF_H:
				hits.append(c)

	# Also check ground debris
	var debris_hits: Array = []
	for d in ground_debris:
		var dx: float = d["x"]
		var dy: float = d["y"]
		var dr: float = d["radius"]
		if absf(dx - player_x) < SLASH_REACH + dr:
			if dy + dr > sy - SLASH_HALF_H and dy - dr < sy + SLASH_HALF_H:
				debris_hits.append(d)

	for c in hits:
		_hit_crystal(c, events)

	for d in debris_hits:
		_hit_debris(d, events)

	if hits.is_empty() and debris_hits.is_empty():
		events.append({"type": "slash_miss", "x": player_x})

func _hit_crystal(crystal: Dictionary, events: Array) -> void:
	combo += 1
	combo_timer = COMBO_TIMEOUT
	behavior_event_counts["hit"] = int(behavior_event_counts["hit"]) + 1

	var gen := int(crystal["generation"])
	var pts: int = int(GEN_SCORE[gen]) * combo
	score += pts
	events.append({
		"type": "hit", "x": float(crystal["x"]), "y": float(crystal["y"]),
		"generation": gen, "combo": combo, "points": pts,
	})

	crystals.erase(crystal)

	if gen < 3:
		_split_crystal(crystal, events)
	else:
		_burst_crystal(crystal, events)

func _split_crystal(crystal: Dictionary, events: Array) -> void:
	behavior_event_counts["split"] = int(behavior_event_counts["split"]) + 1
	var gen := int(crystal["generation"])
	var base_vy: float = SPLIT_VY[gen]
	var base_vx: float = SPLIT_VX[gen]
	# Sometimes split into 3 (30% chance)
	var num_fragments := 3 if rng.randf() < 0.3 else 2
	var new_gen := gen + 1
	for i in range(num_fragments):
		# Randomized directions: spread evenly then jitter
		var angle_base := 0.0
		if num_fragments == 2:
			angle_base = -1.0 if i == 0 else 1.0
		else:
			angle_base = float(i - 1)  # -1, 0, 1
		var vx := angle_base * (base_vx + rng.randf_range(-40.0, 40.0))
		# Add extra random horizontal variation
		vx += rng.randf_range(-30.0, 30.0)
		var vy := base_vy + rng.randf_range(-50.0, 50.0)
		crystals.append({
			"x": float(crystal["x"]) + rng.randf_range(-3.0, 3.0),
			"y": float(crystal["y"]) + rng.randf_range(-3.0, 3.0),
			"vx": vx,
			"vy": vy,
			"radius": GEN_RADIUS[new_gen],
			"generation": new_gen,
			"rotation": rng.randf() * TAU,
			"rotation_speed": deg_to_rad(GEN_ROT_SPEED_DEG[new_gen]) * (1.0 if rng.randf() > 0.5 else -1.0),
			"poly_seed": rng.randi(),
			"in_arc": true,
			"type": "crystal",
		})
	entity_type_counts["crystal"] = int(entity_type_counts["crystal"]) + num_fragments

func _burst_crystal(crystal: Dictionary, events: Array) -> void:
	behavior_event_counts["burst"] = int(behavior_event_counts["burst"]) + 1
	events.append({"type": "burst", "x": float(crystal["x"]), "y": float(crystal["y"])})
	for i in range(8):
		var angle := float(i) / 8.0 * TAU + rng.randf_range(-0.3, 0.3)
		var spd := rng.randf_range(80.0, 200.0)
		sparkles.append({
			"x": float(crystal["x"]), "y": float(crystal["y"]),
			"vx": cos(angle) * spd,
			"vy": sin(angle) * spd - 120.0,
			"age": 0.0, "lifetime": rng.randf_range(0.3, 0.6),
		})

func _hit_debris(debris: Dictionary, events: Array) -> void:
	# Slashing debris: small score + sparkles, extends combo
	combo += 1
	combo_timer = COMBO_TIMEOUT
	var pts: int = 2 * combo
	score += pts
	var dx: float = debris["x"]
	var dy: float = debris["y"]
	events.append({
		"type": "hit", "x": dx, "y": dy,
		"generation": 3, "combo": combo, "points": pts,
	})
	ground_debris.erase(debris)
	# Small sparkle burst
	for i in range(4):
		var angle := float(i) / 4.0 * TAU + rng.randf_range(-0.4, 0.4)
		var spd := rng.randf_range(50.0, 120.0)
		sparkles.append({
			"x": dx, "y": dy,
			"vx": cos(angle) * spd,
			"vy": sin(angle) * spd - 80.0,
			"age": 0.0, "lifetime": rng.randf_range(0.2, 0.4),
		})

# --- Crystal physics ---
func _update_crystals(delta: float, events: Array) -> void:
	var py := GROUND_Y - PLAYER_RADIUS
	var remove_list: Array = []
	for c in crystals:
		if bool(c.get("in_arc", false)):
			c["vy"] = float(c["vy"]) + GRAVITY * delta
		c["x"] = float(c["x"]) + float(c["vx"]) * delta
		c["y"] = float(c["y"]) + float(c["vy"]) * delta
		c["rotation"] = float(c["rotation"]) + float(c["rotation_speed"]) * delta

		var cy: float = c["y"]
		var cr: float = c["radius"]
		# Ground
		if cy + cr >= GROUND_Y:
			remove_list.append(c)
			_ground_impact(c, events)
			continue
		# Off screen
		if float(c["x"]) < -120 or float(c["x"]) > SCREEN_W + 120 or cy < -250:
			remove_list.append(c)
			continue
		# Player collision
		var dx := float(c["x"]) - player_x
		var dy := cy - py
		if dx * dx + dy * dy < (cr + PLAYER_RADIUS) * (cr + PLAYER_RADIUS):
			game_over = true
			death_hit_pos = Vector2(float(c["x"]), cy)
			events.append({"type": "game_over", "x": player_x, "y": py})

	for c in remove_list:
		crystals.erase(c)

# --- Ground impact: scatter debris left/right ---
func _ground_impact(crystal: Dictionary, events: Array) -> void:
	var gen := int(crystal["generation"])
	behavior_event_counts["ground_impact"] = int(behavior_event_counts["ground_impact"]) + 1
	var cx: float = crystal["x"]
	var num_debris := 2 + (3 - gen)  # gen1=4, gen2=3, gen3=2
	for i in range(num_debris):
		var side := -1.0 if i % 2 == 0 else 1.0
		var vx := side * (DEBRIS_VX_RANGE * 0.5 + rng.randf_range(0.0, DEBRIS_VX_RANGE * 0.5))
		ground_debris.append({
			"x": cx, "y": GROUND_Y - DEBRIS_RADIUS,
			"vx": vx,
			"vy": DEBRIS_VY + rng.randf_range(-60.0, 40.0),
			"radius": DEBRIS_RADIUS + rng.randf_range(-1.5, 1.5),
			"age": 0.0, "lifetime": DEBRIS_LIFETIME,
			"generation": gen,
		})
	events.append({"type": "ground_impact", "x": cx, "generation": gen})

func _update_ground_debris(delta: float, _events: Array) -> void:
	var py := GROUND_Y - PLAYER_RADIUS
	var i := ground_debris.size() - 1
	while i >= 0:
		var d: Dictionary = ground_debris[i]
		d["age"] = float(d["age"]) + delta
		if float(d["age"]) >= float(d["lifetime"]):
			ground_debris.remove_at(i)
			i -= 1
			continue
		d["vy"] = float(d["vy"]) + GRAVITY * delta
		d["x"] = float(d["x"]) + float(d["vx"]) * delta
		d["y"] = float(d["y"]) + float(d["vy"]) * delta
		# Bounce off ground — high bounce so debris can be slashed
		if float(d["y"]) + float(d["radius"]) >= GROUND_Y:
			d["y"] = GROUND_Y - float(d["radius"])
			d["vy"] = -absf(float(d["vy"])) * 0.55
			d["vx"] = float(d["vx"]) * 0.85
		# Player collision
		if not game_over:
			var dx := float(d["x"]) - player_x
			var dy := float(d["y"]) - py
			var r := float(d["radius"]) + PLAYER_RADIUS
			if dx * dx + dy * dy < r * r:
				game_over = true
				death_hit_pos = Vector2(float(d["x"]), float(d["y"]))
				_events.append({"type": "game_over", "x": player_x, "y": py})
		i -= 1

# --- Effects (visual only) ---
func _update_effects(delta: float) -> void:
	var i := slash_effects.size() - 1
	while i >= 0:
		slash_effects[i]["age"] = float(slash_effects[i]["age"]) + delta
		if float(slash_effects[i]["age"]) >= float(slash_effects[i]["duration"]):
			slash_effects.remove_at(i)
		i -= 1

	i = sparkles.size() - 1
	while i >= 0:
		var sp: Dictionary = sparkles[i]
		sp["age"] = float(sp["age"]) + delta
		sp["x"] = float(sp["x"]) + float(sp["vx"]) * delta
		sp["y"] = float(sp["y"]) + float(sp["vy"]) * delta
		sp["vy"] = float(sp["vy"]) + GRAVITY * 0.4 * delta
		if float(sp["age"]) >= float(sp["lifetime"]):
			sparkles.remove_at(i)
		i -= 1

# --- Spawning ---
func _spawn_crystal() -> void:
	var x := rng.randf_range(40.0, SCREEN_W - 40.0)
	var speed := GEN_FALL_SPEED[1] * (1.0 + 0.15 * float(difficulty()))
	crystals.append({
		"x": x, "y": -30.0,
		"vx": rng.randf_range(-15.0, 15.0),
		"vy": speed,
		"radius": GEN_RADIUS[1],
		"generation": 1,
		"rotation": rng.randf() * TAU,
		"rotation_speed": deg_to_rad(GEN_ROT_SPEED_DEG[1]) * (1.0 if rng.randf() > 0.5 else -1.0),
		"poly_seed": rng.randi(),
		"in_arc": false,
		"type": "crystal",
	})
	entity_type_counts["crystal"] = int(entity_type_counts["crystal"]) + 1
