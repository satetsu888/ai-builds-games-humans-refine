extends RefCounted

var grid_size := Vector2i(12, 7)
var corruption: Dictionary = {}
var runes: Array[Vector2i] = []
var generator_cell := Vector2i.ZERO
var pulse_cells: Array[Vector2i] = []
var pulse_enhanced: Dictionary = {}
var detached_cable_cells: Array[Vector2i] = []
var _conduction_queue: Array[Vector2i] = []
var _conduction_active := false
var _conduction_tick := 0.0
var _conduction_interval := 0.05
var _conduction_cross_mode := true
var _conduction_scorable := true
var _rune_respawn_block: Dictionary = {}
var pulse_timer := 0.0
var _spread_clock := 0.0
var _pending_spread_cell := Vector2i(-1, -1)
var _spread_warning_timer := 0.0
const SPREAD_WARNING_DURATION := 0.55
const GENERATOR_RESPAWN_MIN_DISTANCE := 3
var _rng := RandomNumberGenerator.new()

func reset(size: Vector2i, seed_value: int) -> void:
	grid_size = size
	corruption.clear()
	runes.clear()
	generator_cell = Vector2i.ZERO
	pulse_cells.clear()
	pulse_enhanced.clear()
	detached_cable_cells.clear()
	_conduction_queue.clear()
	_conduction_active = false
	_conduction_tick = 0.0
	_conduction_cross_mode = true
	_conduction_scorable = true
	_rune_respawn_block.clear()
	pulse_timer = 0.0
	_spread_clock = 0.0
	_pending_spread_cell = Vector2i(-1, -1)
	_spread_warning_timer = 0.0
	_rng.seed = seed_value
	generator_cell = _find_generator_spawn({})
	corruption[generator_cell] = true

func tick(delta: float) -> void:
	if pulse_timer > 0.0:
		pulse_timer = maxf(0.0, pulse_timer - delta)
		if pulse_timer <= 0.0:
			pulse_cells.clear()
			pulse_enhanced.clear()
	for blocked_cell in _rune_respawn_block.keys():
		_rune_respawn_block[blocked_cell] = int(_rune_respawn_block[blocked_cell]) - 1
		if int(_rune_respawn_block[blocked_cell]) <= 0:
			_rune_respawn_block.erase(blocked_cell)

func clear_pulse_visuals() -> void:
	pulse_cells.clear()
	pulse_enhanced.clear()
	pulse_timer = 0.0

func step_conduction(delta: float) -> Dictionary:
	var out := {
		"triggered": false,
		"purified_count": 0,
		"purified_cells": [],
		"finished": false,
		"scorable": false,
	}
	if not _conduction_active:
		return out
	_conduction_tick += delta
	if _conduction_tick < _conduction_interval:
		return out
	_conduction_tick = 0.0
	if _conduction_queue.is_empty():
		_conduction_active = false
		detached_cable_cells.clear()
		out["finished"] = true
		return out
	var cell: Vector2i = _conduction_queue.pop_front()
	if not pulse_cells.has(cell):
		pulse_cells.append(cell)
	pulse_enhanced[cell] = true
	out["triggered"] = true
	var purified_cells: Array[Vector2i] = []
	if _conduction_cross_mode:
		purified_cells = _purify_cross(cell)
	else:
		purified_cells = _purify_single(cell)
	out["scorable"] = _conduction_scorable
	out["purified_cells"] = purified_cells
	out["purified_count"] = purified_cells.size()
	pulse_timer = 0.28
	if _conduction_queue.is_empty():
		_conduction_active = false
		detached_cable_cells.clear()
		out["finished"] = true
	return out

func ensure_runes(cable_cells: Dictionary) -> Array[Vector2i]:
	while runes.size() < 2:
		var cell := _find_empty_cell(cable_cells)
		if cell == Vector2i(-1, -1):
			break
		runes.append(cell)
	return runes

func resolve_throw_step(origin: Vector2i, dir: Vector2i, step: int, cable_cells: Dictionary, enhanced: bool) -> Dictionary:
	var result := {
		"valid": false,
		"score": 0,
		"risky": false,
		"friendly_hits": 0,
		"new_corruption": [],
		"destroyed_runes": 0,
		"destroyed_corruption": 0,
		"hit_rune": false,
		"cable_conducted": false,
		"cable_hit_cell": Vector2i(-1, -1),
		"cable_cross_mode": false,
		"stop_throw": false,
		"destroyed_generator": false,
		"purified_cells": [],
	}
	var cell := origin + dir * step
	if not _in_bounds(cell):
		return result
	result["valid"] = true

	# If the first pulse is blocked by cable, nothing should be picked or triggered on that tile.
	if cable_cells.has(cell) and not enhanced:
		result["friendly_hits"] = int(result["friendly_hits"]) + 1
		result["stop_throw"] = true
		return result

	# Rune pickup should upgrade this exact panel immediately.
	var step_enhanced := enhanced
	var rune_idx := runes.find(cell)
	if rune_idx >= 0:
		runes.remove_at(rune_idx)
		_rune_respawn_block[cell] = 120
		result["destroyed_runes"] = int(result["destroyed_runes"]) + 1
		result["hit_rune"] = true
		step_enhanced = true

	if not pulse_cells.has(cell):
		pulse_cells.append(cell)
	if step_enhanced:
		pulse_enhanced[cell] = true
	if cable_cells.has(cell):
		result["friendly_hits"] = int(result["friendly_hits"]) + 1
		if step_enhanced:
			result["cable_conducted"] = true
			result["cable_hit_cell"] = cell
			result["cable_cross_mode"] = true
		else:
			result["stop_throw"] = true
	if corruption.has(cell):
		result["risky"] = true
		if step_enhanced:
			corruption.erase(cell)
			result["destroyed_corruption"] = 1
			(result["purified_cells"] as Array).append(cell)
	if cell == generator_cell and step_enhanced:
		result["destroyed_generator"] = true
		generator_cell = _find_generator_respawn(origin, cable_cells)
		corruption[generator_cell] = true
	for dirty_cell: Vector2i in result["new_corruption"]:
		corruption[dirty_cell] = true
	pulse_timer = 0.2
	return result

func conduct_enhanced_on_cable(cable_path: Array[Vector2i], start_cell: Vector2i) -> Dictionary:
	detached_cable_cells = cable_path.duplicate()
	_conduction_queue = _build_conduction_order(cable_path, start_cell)
	_conduction_active = not _conduction_queue.is_empty()
	_conduction_tick = _conduction_interval
	_conduction_cross_mode = true
	_conduction_scorable = true
	return {"queued_count": _conduction_queue.size()}

func conduct_emergency_on_cable(cable_path: Array[Vector2i], start_cell: Vector2i) -> Dictionary:
	detached_cable_cells = cable_path.duplicate()
	_conduction_queue = _build_conduction_order(cable_path, start_cell)
	_conduction_active = not _conduction_queue.is_empty()
	_conduction_tick = _conduction_interval
	_conduction_cross_mode = false
	_conduction_scorable = false
	return {"queued_count": _conduction_queue.size()}

func _build_conduction_order(cable_path: Array[Vector2i], start_cell: Vector2i) -> Array[Vector2i]:
	var cable_set := {}
	for cell in cable_path:
		cable_set[cell] = true
	var seed := start_cell
	if not cable_set.has(seed):
		if cable_path.is_empty():
			return []
		seed = cable_path[0]
	var order: Array[Vector2i] = []
	var queue: Array[Vector2i] = [seed]
	var visited := {seed: true}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		order.append(current)
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = current + dir
			if cable_set.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	return order

func _purify_cross(center: Vector2i) -> Array[Vector2i]:
	var removed_cells: Array[Vector2i] = []
	for offset in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var target: Vector2i = center + offset
		if not _in_bounds(target):
			continue
		if not pulse_cells.has(target):
			pulse_cells.append(target)
		pulse_enhanced[target] = true
		if corruption.has(target):
			corruption.erase(target)
			removed_cells.append(target)
		if target == generator_cell:
			generator_cell = _find_generator_respawn(_current_cable_tip(), _detached_cable_set())
			corruption[generator_cell] = true
		if target == _pending_spread_cell:
			_pending_spread_cell = Vector2i(-1, -1)
			_spread_warning_timer = 0.0
	return removed_cells

func _purify_single(cell: Vector2i) -> Array[Vector2i]:
	var removed_cells: Array[Vector2i] = []
	if not _in_bounds(cell):
		return removed_cells
	if not pulse_cells.has(cell):
		pulse_cells.append(cell)
	pulse_enhanced[cell] = true
	if corruption.has(cell):
		corruption.erase(cell)
		removed_cells.append(cell)
	if cell == generator_cell:
		generator_cell = _find_generator_respawn(_current_cable_tip(), _detached_cable_set())
		corruption[generator_cell] = true
	return removed_cells

func spread_corruption(delta: float, cable_cells: Dictionary, difficulty_level: int, cable_length_ratio: float) -> Dictionary:
	var result := {
		"spread": false,
		"warning": false,
		"collapse": false,
	}
	if _pending_spread_cell != Vector2i(-1, -1):
		_spread_warning_timer = maxf(0.0, _spread_warning_timer - delta)
		result["warning"] = true
		if _spread_warning_timer <= 0.0:
			if _in_bounds(_pending_spread_cell):
				corruption[_pending_spread_cell] = true
				result["spread"] = true
			_pending_spread_cell = Vector2i(-1, -1)
		if corruption.size() >= int(grid_size.x * grid_size.y * 0.8):
			result["collapse"] = true
		return result
	var spread_interval := (4.0 / float(difficulty_level)) / cable_length_ratio
	_spread_clock += delta
	if _spread_clock < spread_interval:
		return result
	_spread_clock = 0.0
	var frontier := _frontier_cells()
	if not frontier.is_empty():
		_pending_spread_cell = frontier[_rng.randi_range(0, frontier.size() - 1)]
		_spread_warning_timer = SPREAD_WARNING_DURATION
		result["warning"] = true
	if corruption.size() >= int(grid_size.x * grid_size.y * 0.8):
		result["collapse"] = true
	return result

func is_corrupted(cell: Vector2i) -> bool:
	return corruption.has(cell)

func is_generator(cell: Vector2i) -> bool:
	return cell == generator_cell

func get_spread_warning_cell() -> Vector2i:
	return _pending_spread_cell

func _find_empty_cell(cable_cells: Dictionary) -> Vector2i:
	for _i in range(30):
		var candidate := Vector2i(_rng.randi_range(0, grid_size.x - 1), _rng.randi_range(0, grid_size.y - 1))
		if _rune_respawn_block.has(candidate):
			continue
		if candidate == generator_cell:
			continue
		if cable_cells.has(candidate):
			continue
		if runes.has(candidate):
			continue
		return candidate
	return Vector2i(-1, -1)

func _find_generator_spawn(cable_cells: Dictionary) -> Vector2i:
	for _i in range(80):
		var candidate := Vector2i(_rng.randi_range(1, grid_size.x - 2), _rng.randi_range(1, grid_size.y - 2))
		if corruption.has(candidate):
			continue
		if cable_cells.has(candidate):
			continue
		if runes.has(candidate):
			continue
		return candidate
	return Vector2i(grid_size.x / 2, grid_size.y / 2)

func _find_generator_respawn(avoid_cell: Vector2i, cable_cells: Dictionary) -> Vector2i:
	var best_candidate := Vector2i(-1, -1)
	var best_dist := -1
	for _i in range(160):
		var candidate := Vector2i(_rng.randi_range(0, grid_size.x - 1), _rng.randi_range(0, grid_size.y - 1))
		if cable_cells.has(candidate):
			continue
		if runes.has(candidate):
			continue
		var dist := _manhattan(candidate, avoid_cell)
		if dist < GENERATOR_RESPAWN_MIN_DISTANCE:
			continue
		return candidate
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var candidate := Vector2i(x, y)
			if cable_cells.has(candidate):
				continue
			if runes.has(candidate):
				continue
			var dist := _manhattan(candidate, avoid_cell)
			if dist > best_dist:
				best_dist = dist
				best_candidate = candidate
	if best_candidate != Vector2i(-1, -1):
		return best_candidate
	return Vector2i(grid_size.x / 2, grid_size.y / 2)

func _current_cable_tip() -> Vector2i:
	if detached_cable_cells.is_empty():
		return Vector2i(-1, -1)
	return detached_cable_cells[0]

func _detached_cable_set() -> Dictionary:
	var out := {}
	for cell in detached_cable_cells:
		out[cell] = true
	return out

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	if b == Vector2i(-1, -1):
		return 999
	return absi(a.x - b.x) + absi(a.y - b.y)

func _frontier_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for key in corruption.keys():
		var base: Vector2i = key
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var cell: Vector2i = base + dir
			if _in_bounds(cell) and not corruption.has(cell) and not out.has(cell):
				out.append(cell)
	return out

func _adjacent_to_corruption(cell: Vector2i) -> bool:
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if corruption.has(cell + dir):
			return true
	return false

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_size.x and cell.y >= 0 and cell.y < grid_size.y
