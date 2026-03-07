extends RefCounted

static func reset_metric_trackers(threat_cost: Dictionary, synergy_template_keys: Array, behavior_event_keys: Array) -> Dictionary:
	var enemy_type_counts: Dictionary = {}
	for enemy_type in threat_cost.keys():
		enemy_type_counts[str(enemy_type)] = 0
	var synergy_event_counts: Dictionary = {}
	for key in synergy_template_keys:
		synergy_event_counts[str(key)] = 0
	var behavior_event_counts: Dictionary = {}
	for key in behavior_event_keys:
		behavior_event_counts[str(key)] = 0
	return {
		"enemy_type_counts": enemy_type_counts,
		"synergy_event_counts": synergy_event_counts,
		"behavior_event_counts": behavior_event_counts,
		"max_single_type_ratio": 0.0,
		"avg_active_enemies_30s": 0.0,
		"active_enemy_sample_sum": 0.0,
		"active_enemy_sample_frames": 0,
		"untelegraphed_hit_count": 0,
	}

static func update_max_single_type_ratio(chasers: Array, current_ratio: float) -> float:
	var active_total := chasers.size()
	if active_total < 5:
		return current_ratio
	var active_counts: Dictionary = {}
	for c in chasers:
		var enemy_type := str(c.type)
		active_counts[enemy_type] = int(active_counts.get(enemy_type, 0)) + 1
	var local_max := 0
	for count in active_counts.values():
		local_max = maxi(local_max, int(count))
	var ratio := float(local_max) / float(active_total)
	return ratio if ratio > current_ratio else current_ratio

static func update_test_metrics(elapsed_time: float, chasers: Array, active_enemy_sample_sum: float, active_enemy_sample_frames: int, max_single_type_ratio: float) -> Dictionary:
	var next_ratio := update_max_single_type_ratio(chasers, max_single_type_ratio)
	var next_sum := active_enemy_sample_sum
	var next_frames := active_enemy_sample_frames
	var next_avg := 0.0
	if elapsed_time <= 30.0:
		next_sum += float(chasers.size())
		next_frames += 1
		if next_frames > 0:
			next_avg = next_sum / float(next_frames)
	return {
		"max_single_type_ratio": next_ratio,
		"active_enemy_sample_sum": next_sum,
		"active_enemy_sample_frames": next_frames,
		"avg_active_enemies_30s": next_avg,
	}

static func record_spawned_enemy(enemy_type_counts: Dictionary, enemy_type: String) -> void:
	var key := str(enemy_type)
	enemy_type_counts[key] = int(enemy_type_counts.get(key, 0)) + 1

static func record_synergy_event(synergy_event_counts: Dictionary, type_a: String, type_b: String) -> void:
	var key := get_synergy_template_key(type_a, type_b)
	if key == "":
		return
	synergy_event_counts[key] = int(synergy_event_counts.get(key, 0)) + 1

static func inc_behavior_event(behavior_event_counts: Dictionary, key: String) -> void:
	behavior_event_counts[key] = int(behavior_event_counts.get(key, 0)) + 1

static func get_synergy_template_key(type_a: String, type_b: String) -> String:
	if (type_a == "orbiter" and type_b == "drifter") or (type_a == "drifter" and type_b == "orbiter"):
		return "orbiter_drifter"
	if (type_a == "anchor" and type_b == "lancer") or (type_a == "lancer" and type_b == "anchor"):
		return "anchor_lancer"
	if (type_a == "shepherd" and type_b == "splitter") or (type_a == "splitter" and type_b == "shepherd"):
		return "shepherd_splitter"
	if (type_a == "sniper" and type_b == "phase") or (type_a == "phase" and type_b == "sniper"):
		return "sniper_phase"
	return ""

static func is_hit_telegraphed(enemy: Dictionary) -> bool:
	var enemy_type := str(enemy.type)
	if enemy_type == "lancer":
		return float(enemy.get("charge_time", 0.0)) > 0.08
	if enemy_type == "sniper":
		return float(enemy.get("aim_time", 0.0)) > 0.06 or float(enemy.get("shot_time", 0.0)) > 0.01
	return true
