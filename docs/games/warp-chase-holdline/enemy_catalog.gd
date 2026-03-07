extends RefCounted

static func get_enemy_radius(enemy_type: String, chaser_radius: float) -> float:
	if enemy_type == "drifter":
		return chaser_radius * 1.1
	if enemy_type == "splitter":
		return chaser_radius * 1.08
	if enemy_type == "splitter_shard":
		return chaser_radius * 0.8
	if enemy_type == "orbiter":
		return chaser_radius * 0.9
	if enemy_type == "lancer":
		return chaser_radius * 1.02
	if enemy_type == "anchor":
		return chaser_radius * 1.08
	if enemy_type == "sniper":
		return chaser_radius * 0.94
	if enemy_type == "shepherd":
		return chaser_radius * 1.03
	if enemy_type == "mine_layer":
		return chaser_radius * 0.98
	if enemy_type == "mirror":
		return chaser_radius * 0.95
	if enemy_type == "phase":
		return chaser_radius * 0.9
	return chaser_radius

static func get_enemy_color(enemy_type: String) -> Color:
	if enemy_type == "drifter":
		return Color(1.0, 0.63, 0.33, 0.95)
	if enemy_type == "splitter":
		return Color(1.0, 0.57, 0.57, 0.95)
	if enemy_type == "splitter_shard":
		return Color(1.0, 0.72, 0.72, 0.86)
	if enemy_type == "orbiter":
		return Color(1.0, 0.41, 0.84, 0.95)
	if enemy_type == "lancer":
		return Color(1.0, 0.92, 0.35, 0.95)
	if enemy_type == "anchor":
		return Color(0.66, 0.83, 1.0, 0.95)
	if enemy_type == "sniper":
		return Color(0.98, 0.78, 0.45, 0.95)
	if enemy_type == "shepherd":
		return Color(0.71, 1.0, 0.58, 0.95)
	if enemy_type == "mine_layer":
		return Color(1.0, 0.64, 0.4, 0.95)
	if enemy_type == "mirror":
		return Color(0.69, 0.86, 1.0, 0.95)
	if enemy_type == "phase":
		return Color(0.76, 0.72, 1.0, 0.95)
	return Color(1.0, 0.373, 0.427, 0.95)

static func get_enemy_collision_score(enemy_type: String) -> int:
	if enemy_type == "drifter":
		return 9
	if enemy_type == "splitter":
		return 10
	if enemy_type == "splitter_shard":
		return 6
	if enemy_type == "orbiter":
		return 11
	if enemy_type == "lancer":
		return 14
	if enemy_type == "anchor":
		return 13
	if enemy_type == "sniper":
		return 12
	if enemy_type == "shepherd":
		return 14
	if enemy_type == "mine_layer":
		return 12
	if enemy_type == "mirror":
		return 15
	if enemy_type == "phase":
		return 16
	return 6

static func get_enemy_wrap_radius(enemy_type: String, chaser_radius: float) -> float:
	var r := get_enemy_radius(enemy_type, chaser_radius)
	match enemy_type:
		"lancer", "mirror":
			return r * 1.95
		"sniper", "phase":
			return r * 1.75
		"orbiter":
			return r * 1.38
		_:
			return r * 1.2
