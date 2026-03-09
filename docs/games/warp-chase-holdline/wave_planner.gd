extends RefCounted

static func generate_wave(index: int, wave_rng_seed: int, enemy_unlock_order: Array, max_threat_budget: float, threat_cost: Dictionary, type_max_ratio: Dictionary, wave_duration: float) -> Dictionary:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(wave_rng_seed + index * 7919 + 17)

	var unlocked_count: int = mini(enemy_unlock_order.size(), 2 + int(index / 3))
	var unlocked: Array = enemy_unlock_order.slice(0, unlocked_count)
	var all_unlocked := unlocked_count >= enemy_unlock_order.size()
	var cycle_phase: int = posmod(index, 3)
	var target_type_count: int = clampi(cycle_phase + 1, 1, 3)
	target_type_count = mini(target_type_count, unlocked.size())
	var is_tutorial_wave := target_type_count == 1
	var tutorial_type := str(unlocked[unlocked_count - 1])
	if all_unlocked and not unlocked.is_empty():
		tutorial_type = str(unlocked[local_rng.randi_range(0, unlocked.size() - 1)])
	var budget: float = minf(max_threat_budget, 4.9 + sqrt(float(index) + 1.0) * 1.75 + float(index) * 0.38 + local_rng.randf_range(-0.25, 0.45))
	if is_tutorial_wave:
		budget = minf(max_threat_budget, 4.4 + sqrt(float(index) + 1.0) * 1.45 + local_rng.randf_range(-0.15, 0.25))
	var wave_pool: Array = [tutorial_type] if is_tutorial_wave else _build_mix_pool(unlocked, index, target_type_count, local_rng, tutorial_type)
	if wave_pool.is_empty():
		wave_pool = [tutorial_type]
	var target_counts: Dictionary = {}
	var spent: float = 0.0
	var total_units: int = 0
	for t in wave_pool:
		target_counts[t] = 0

	var guard: int = 0
	while guard < 256:
		guard += 1
		var choice: String = tutorial_type if is_tutorial_wave else pick_weighted_enemy_type(_build_dynamic_weights(wave_pool, index, local_rng), local_rng)
		var cost := float(threat_cost[choice])
		if spent + cost > budget + 0.15:
			break
		var next_units := total_units + 1
		var next_count := int(target_counts[choice]) + 1
		var type_cap := 1.0 if is_tutorial_wave else float(type_max_ratio.get(choice, 0.56))
		if next_units >= 3 and float(next_count) / float(next_units) > type_cap:
			continue
		target_counts[choice] = next_count
		spent += cost
		total_units = next_units

	if total_units == 0:
		var fallback_type := tutorial_type
		if not wave_pool.is_empty():
			fallback_type = str(wave_pool[0])
		target_counts[fallback_type] = 1
		total_units = 1

	var weights: Dictionary = {}
	for t in target_counts.keys():
		weights[t] = float(target_counts[t]) / float(maxi(total_units, 1))

	var spawn_base: float = clampf(1.95 - float(index) * 0.055 + local_rng.randf_range(-0.1, 0.08), 0.75, 2.05)
	if is_tutorial_wave:
		spawn_base = clampf(spawn_base * 1.12, 0.85, 2.2)
	var cap_base: int = clampi(int(round(3.0 + spent * 0.25 + float(index) * 0.05)), 4, 10)
	if is_tutorial_wave:
		cap_base = clampi(cap_base - 1, 3, 8)
	var phase_tag := "SOLO" if target_type_count == 1 else ("DUO" if target_type_count == 2 else "TRIO")
	var wave_name: String = "W%02d %s-%s B%.1f" % [index + 1, phase_tag, tutorial_type if is_tutorial_wave else "MIX", spent]
	return {
		"name": wave_name,
		"start": float(index) * wave_duration,
		"end": float(index + 1) * wave_duration,
		"spawn_interval": spawn_base,
		"max_enemies": cap_base,
		"weights": weights,
	}

static func _build_mix_pool(unlocked: Array, index: int, target_count: int, local_rng: RandomNumberGenerator, focus_type: String = "") -> Array:
	var pool: Array = []
	var others: Array = []
	for t in unlocked:
		others.append(str(t))
	if others.is_empty():
		return pool
	var desired := clampi(target_count, 1, 3)
	if focus_type != "" and others.has(focus_type):
		pool.append(focus_type)
	var start_idx := posmod(index + int(local_rng.randi() % others.size()), others.size())
	for i in range(others.size()):
		if pool.size() >= desired:
			break
		var pick := str(others[posmod(start_idx + i, others.size())])
		if not pool.has(pick):
			pool.append(pick)
	return pool

static func _build_dynamic_weights(unlocked: Array, index: int, local_rng: RandomNumberGenerator) -> Dictionary:
	var w: Dictionary = {}
	for t in unlocked:
		if t == "hunter":
			w[t] = max(0.2, 1.1 - float(index) * 0.07 + local_rng.randf_range(-0.08, 0.08))
		elif t == "drifter":
			w[t] = 0.35 + float(index) * 0.05 + local_rng.randf_range(-0.05, 0.08)
		elif t == "orbiter":
			w[t] = 0.22 + float(index) * 0.06 + local_rng.randf_range(-0.05, 0.09)
		elif t == "lancer":
			w[t] = 0.15 + float(index) * 0.05 + local_rng.randf_range(-0.05, 0.08)
		elif t == "splitter":
			w[t] = 0.18 + float(index) * 0.04 + local_rng.randf_range(-0.04, 0.07)
		elif t == "anchor":
			w[t] = 0.16 + float(index) * 0.04 + local_rng.randf_range(-0.04, 0.06)
		elif t == "sniper":
			w[t] = 0.15 + float(index) * 0.035 + local_rng.randf_range(-0.04, 0.06)
		elif t == "shepherd":
			w[t] = 0.14 + float(index) * 0.03 + local_rng.randf_range(-0.03, 0.05)
		elif t == "mine_layer":
			w[t] = 0.12 + float(index) * 0.03 + local_rng.randf_range(-0.03, 0.05)
		elif t == "mirror":
			w[t] = 0.11 + float(index) * 0.028 + local_rng.randf_range(-0.03, 0.05)
		elif t == "phase":
			w[t] = 0.1 + float(index) * 0.03 + local_rng.randf_range(-0.03, 0.05)
	return w

static func pick_weighted_enemy_type(weights: Dictionary, local_rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for key in weights.keys():
		total += max(0.0, float(weights[key]))
	if total <= 0.001:
		return "hunter"
	var r := local_rng.randf() * total
	var accum := 0.0
	for key in weights.keys():
		accum += max(0.0, float(weights[key]))
		if r <= accum:
			return str(key)
	return "hunter"
