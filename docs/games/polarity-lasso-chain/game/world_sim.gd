extends RefCounted
class_name WorldSim

var viewport := Vector2(960.0, 540.0)
var center := Vector2(480.0, 270.0)

var beacons: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var loops: Array[Dictionary] = []

var spawn_timer := 0.0
var loop_cooldown := 0.0
var near_miss_pulses := 0
var auto_close_radius := 72.0

func reset() -> void:
	beacons.clear()
	sparks.clear()
	loops.clear()
	spawn_timer = 0.35
	loop_cooldown = 0.0
	near_miss_pulses = 0

func update(delta: float, player_pos: Vector2, shot_edge: bool, reverse_edge: bool, difficulty: float, heat: float) -> Dictionary:
	var out := {
		"spawned_types": [],
		"spawn_edges": [],
		"spawn_active_edges": [],
		"captured": 0,
		"initial_active_captured": 0,
		"post_awards": [],
		"post_award_positions": [],
		"capture_bursts": [],
		"player_hit": false,
		"telegraphed_fail": true,
		"near_miss": 0,
		"loop_closed": false,
		"loop_close_center": player_pos,
		"loop_close_radius": 84.0,
		"loop_vanished": false,
		"chain_events": 0,
	}

	spawn_timer -= delta
	var spawn_interval := maxf(0.14, (0.48 / sqrt(difficulty)) - heat * 0.08)
	while spawn_timer <= 0.0:
		var spawn_result: Dictionary = _spawn_spark(difficulty, heat)
		out["spawned_types"].append("spark")
		out["spawn_edges"].append(str(spawn_result.get("edge", "left")))
		if bool(spawn_result.get("active", false)):
			out["spawn_active_edges"].append(str(spawn_result.get("edge", "left")))
		spawn_timer += spawn_interval

	if reverse_edge:
		for b in beacons:
			b["vel"] = -b["vel"]

	if shot_edge:
		_spawn_beacon(player_pos)
		var close_result: Dictionary = _try_auto_close_loop()
		if bool(close_result.get("closed", false)):
			out["loop_closed"] = true
			out["captured"] = int(close_result.get("initial_captured", 0))
			out["initial_active_captured"] = int(close_result.get("initial_active_captured", 0))
			out["loop_close_center"] = Vector2(close_result.get("center", player_pos))
			out["loop_close_radius"] = float(close_result.get("radius", 84.0))
			for p in close_result.get("captured_positions", []):
				out["capture_bursts"].append(Vector2(p))
			if int(out["captured"]) > 0:
				out["chain_events"] = 1

	if loop_cooldown > 0.0:
		loop_cooldown -= delta

	for i in range(beacons.size() - 1, -1, -1):
		var beacon := beacons[i]
		beacon["age"] = float(beacon.get("age", 0.0)) + delta
		var speed_gain := 1.0 + minf(float(beacon["age"]) * 0.12, 5.0)
		beacon["pos"] = Vector2(beacon["pos"]) + Vector2(beacon["vel"]) * delta * speed_gain
		var bp := Vector2(beacon["pos"])
		if bp.x < -30.0 or bp.x > viewport.x + 30.0 or bp.y < -30.0 or bp.y > viewport.y + 30.0:
			beacons.remove_at(i)

	for i in range(sparks.size() - 1, -1, -1):
		var spark := sparks[i]
		var speed_factor := 0.8 if bool(spark.get("active", false)) else 0.5
		var speed_scale := (0.95 + 0.35 * sqrt(difficulty) + heat * 0.6) * speed_factor
		spark["pos"] = Vector2(spark["pos"]) + Vector2(spark["vel"]) * delta * speed_scale
		spark["age"] = float(spark.get("age", 0.0)) + delta
		var p := Vector2(spark["pos"])
		if p.x < -50.0 or p.x > viewport.x + 50.0 or p.y < -50.0 or p.y > viewport.y + 50.0:
			sparks.remove_at(i)
			continue
		var dist := p.distance_to(player_pos)
		if bool(spark.get("active", false)) and dist < 31.0 and dist > 16.0:
			near_miss_pulses += 1
			out["near_miss"] = int(out["near_miss"]) + 1
		if bool(spark.get("active", false)) and dist < 14.0:
			out["player_hit"] = true
			out["telegraphed_fail"] = float(spark.get("age", 0.0)) > 0.30

	for li in range(loops.size() - 1, -1, -1):
		var loop := loops[li]
		loop["life"] = float(loop["life"]) - delta
		if float(loop["life"]) <= 0.0:
			loops.remove_at(li)
			out["loop_vanished"] = true
			continue
		# Post-closure captures also award follow-up points.
		var follow := _capture_sparks_in_polygon(loop["poly"])
		if int(follow.get("count", 0)) > 0:
			out["post_awards"].append(int(loop.get("initial_captured", 1)))
			out["post_award_positions"].append(_calc_capture_center(follow.get("positions", []), Vector2(loop.get("center", center))))
			for p in follow.get("positions", []):
				out["capture_bursts"].append(Vector2(p))

	return out

func collect_active_entities() -> Array:
	var entities: Array = []
	for s in sparks:
		entities.append({"type": "spark", "pos": s["pos"]})
	for b in beacons:
		entities.append({"type": "beacon", "pos": b["pos"]})
	for l in loops:
		entities.append({"type": "loop", "pos": Vector2(l["center"])})
	return entities

func _spawn_spark(difficulty: float, heat: float) -> Dictionary:
	var edge := randi() % 4
	var pos := Vector2.ZERO
	var edge_name := "left"
	match edge:
		0:
			pos = Vector2(randf() * viewport.x, -20.0)
			edge_name = "top"
		1:
			pos = Vector2(viewport.x + 20.0, randf() * viewport.y)
			edge_name = "right"
		2:
			pos = Vector2(randf() * viewport.x, viewport.y + 20.0)
			edge_name = "bottom"
		_:
			pos = Vector2(-20.0, randf() * viewport.y)
			edge_name = "left"
	var toward := (center - pos).normalized()
	var tangent := Vector2(-toward.y, toward.x) * randf_range(-0.6, 0.6)
	var vel := (toward + tangent).normalized() * randf_range(68.0, 112.0) * (1.0 + heat * 0.25 + (difficulty - 1.0) * 0.12)
	var starts_active := randf() < 0.25
	sparks.append({
		"type": "spark",
		"pos": pos,
		"vel": vel,
		"radius": 5.0,
		"age": 0.0,
		"active": starts_active,
	})
	return {
		"edge": edge_name,
		"active": starts_active,
	}

func _spawn_beacon(player_pos: Vector2) -> void:
	var dir := (player_pos - center).normalized()
	var vel := dir * 30.0
	beacons.append({"type": "beacon", "pos": player_pos, "vel": vel, "age": 0.0})

func get_auto_close_hint(next_pos: Vector2) -> Dictionary:
	var visible := beacons.size() >= 2
	if not visible:
		return {
			"visible": false,
			"ready": false,
			"center": Vector2.ZERO,
			"radius": auto_close_radius,
			"target_index": -1,
		}
	var target_index := _pick_target_beacon_index(next_pos)
	if target_index < 0:
		return {
			"visible": false,
			"ready": false,
			"center": Vector2.ZERO,
			"radius": auto_close_radius,
			"target_index": -1,
		}
	var target := Vector2(beacons[target_index]["pos"])
	return {
		"visible": true,
		"ready": target.distance_to(next_pos) <= auto_close_radius,
		"center": target,
		"radius": auto_close_radius,
		"target_index": target_index,
	}

func _try_auto_close_loop() -> Dictionary:
	if beacons.size() < 3:
		return {"closed": false, "initial_captured": 0, "initial_active_captured": 0, "center": center, "radius": auto_close_radius, "captured_positions": []}
	if loop_cooldown > 0.0:
		return {"closed": false, "initial_captured": 0, "initial_active_captured": 0, "center": center, "radius": auto_close_radius, "captured_positions": []}
	var last := Vector2(beacons[beacons.size() - 1]["pos"])
	var target_index := _pick_target_beacon_index(last)
	if target_index < 0:
		return {"closed": false, "initial_captured": 0, "initial_active_captured": 0, "center": last, "radius": auto_close_radius, "captured_positions": []}
	var poly: Array[Vector2] = []
	for i in range(target_index, beacons.size()):
		poly.append(Vector2(beacons[i]["pos"]))
	if poly.size() < 3:
		return {"closed": false, "initial_captured": 0, "initial_active_captured": 0, "center": last, "radius": auto_close_radius, "captured_positions": []}
	var centroid := Vector2.ZERO
	for p in poly:
		centroid += p
	centroid /= float(poly.size())
	var radius := 0.0
	for p in poly:
		radius = maxf(radius, p.distance_to(centroid))
	var initial_capture := _capture_sparks_in_polygon(poly)
	var initial_captured := int(initial_capture.get("count", 0))
	var initial_active_captured := int(initial_capture.get("active_count", 0))
	loops.append({"poly": poly, "center": centroid, "life": 2.2, "initial_captured": initial_captured + 1})
	var remaining: Array[Dictionary] = []
	for i in range(target_index):
		remaining.append(beacons[i])
	beacons = remaining
	loop_cooldown = 0.22
	return {
		"closed": true,
		"initial_captured": initial_captured + 1,
		"initial_active_captured": initial_active_captured,
		"center": centroid,
		"radius": maxf(radius, 72.0),
		"captured_positions": initial_capture.get("positions", []),
	}

func _capture_sparks_in_polygon(poly: Array[Vector2]) -> Dictionary:
	var hit_indices: Array[int] = []
	for i in range(sparks.size()):
		var p := Vector2(sparks[i]["pos"])
		if Geometry2D.is_point_in_polygon(p, poly):
			hit_indices.append(i)
	if hit_indices.is_empty():
		return {"count": 0, "positions": [], "active_count": 0}
	var queue: Array[int] = hit_indices.duplicate()
	var captured: Dictionary = {}
	for idx in hit_indices:
		captured[idx] = true
	var chain_radius := 72.0
	while not queue.is_empty():
		var current: int = int(queue.pop_front())
		if current < 0 or current >= sparks.size():
			continue
		var origin := Vector2(sparks[current]["pos"])
		for i in range(sparks.size()):
			if captured.has(i):
				continue
			if origin.distance_to(Vector2(sparks[i]["pos"])) <= chain_radius:
				captured[i] = true
				queue.append(i)
	for i in captured.keys():
		sparks[i]["captured"] = true
	var captured_positions: Array[Vector2] = []
	var active_count := 0
	for idx in captured.keys():
		if int(idx) >= 0 and int(idx) < sparks.size():
			if bool(sparks[int(idx)].get("active", false)):
				active_count += 1
			captured_positions.append(Vector2(sparks[int(idx)]["pos"]))
	for i in range(sparks.size() - 1, -1, -1):
		if bool(sparks[i].get("captured", false)):
			sparks.remove_at(i)
	return {"count": captured.size(), "positions": captured_positions, "active_count": active_count}

func _polygon_area(poly: Array[Vector2]) -> float:
	var sum := 0.0
	for i in range(poly.size()):
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		sum += a.x * b.y - b.x * a.y
	return sum * 0.5

func _pick_target_beacon_index(probe_pos: Vector2) -> int:
	if beacons.size() < 2:
		return -1
	var best_index := -1
	var best_dist := INF
	# Exclude the newest existing beacon so a newly placed beacon can still form a polygon (>= 3 points).
	for i in range(beacons.size() - 1):
		var d := Vector2(beacons[i]["pos"]).distance_to(probe_pos)
		if d < best_dist:
			best_dist = d
			best_index = i
	if best_index >= 0 and best_dist <= auto_close_radius:
		return best_index
	return -1

func _calc_capture_center(positions: Array, fallback: Vector2) -> Vector2:
	if positions.is_empty():
		return fallback
	var sum := Vector2.ZERO
	for p in positions:
		sum += Vector2(p)
	return sum / float(positions.size())
