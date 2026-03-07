extends Node2D

signal score_event(points: int, world_pos: Vector2)
signal pulse_event(world_pos: Vector2, glyph: int, cluster_size: int)
signal rise_event(world_pos: Vector2)
signal danger_event(world_pos: Vector2)
signal jam_fail(column: int)
signal pressure_step(level: int)

const SCORE_POPUP_FONT: FontFile = preload("res://assets/fonts/IBMPlexMono-SemiBold.ttf")

const COLS := 10
const VISIBLE_ROWS := 11
const TILE_SIZE := 44.0
const FIELD_WIDTH := COLS * TILE_SIZE
const FIELD_ORIGIN := Vector2(260.0, 28.0)
const VOID_HEIGHT := 72.0
const DIFFICULTY_PRESETS := {
	"easy": {
		"base_rise_interval": 5.2,
		"pressure_step_seconds": 12.0,
		"jam_fail_seconds": 12.0,
		"jam_fail_seconds_min": 6.0,
	},
	"normal": {
		"base_rise_interval": 4.4,
		"pressure_step_seconds": 10.0,
		"jam_fail_seconds": 10.0,
		"jam_fail_seconds_min": 5.0,
	},
	"hard": {
		"base_rise_interval": 3.6,
		"pressure_step_seconds": 8.0,
		"jam_fail_seconds": 8.0,
		"jam_fail_seconds_min": 4.0,
	},
}

const GLYPH_CHARS := ["A", "E", "O"]
const GLYPH_COLORS := [
	Color8(255, 122, 89),
	Color8(94, 212, 200),
	Color8(255, 209, 102),
]

var columns: Array = []
var collapse_events: Array = []
var ripple_events: Array = []
var score_popups: Array = []
var print_shards: Array = []
var focus_glyph := 0
var preview_cells: Dictionary = {}
var field_pressure := 1
var elapsed := 0.0
var difficulty_id := "normal"
var base_rise_interval := 4.4
var pressure_step_seconds := 10.0
var jam_fail_seconds := 10.0
var jam_fail_seconds_min := 5.0
var rise_timer := base_rise_interval
var rng := RandomNumberGenerator.new()
var current_seed := 1
var recent_danger_ping := false
var rising_row_serial := 0
var jam_timers: Array = []
var print_offset_timers: Array = []

func setup(seed_value: int) -> void:
	current_seed = seed_value
	rng.seed = seed_value
	_apply_difficulty_preset()
	reset_field()

func reset_field() -> void:
	columns.clear()
	collapse_events.clear()
	ripple_events.clear()
	score_popups.clear()
	print_shards.clear()
	focus_glyph = 0
	preview_cells.clear()
	field_pressure = 1
	elapsed = 0.0
	rise_timer = base_rise_interval
	recent_danger_ping = false
	rising_row_serial = 0
	jam_timers.clear()
	print_offset_timers.clear()
	var base_height := 5
	for col in range(COLS):
		var height := base_height + ((col + 1) % 3)
		var stack: Array = []
		for row in range(height):
				var glyph := _seeded_glyph(col, row)
				stack.append(glyph)
		columns.append(stack)
		jam_timers.append(0.0)
		print_offset_timers.append(0.0)
	queue_redraw()

func step(delta: float, player_column: int, player_near_void: bool) -> void:
	elapsed += delta
	var next_pressure := 1 + int(floor(elapsed / pressure_step_seconds))
	if next_pressure != field_pressure:
		field_pressure = next_pressure
		pressure_step.emit(field_pressure)
	rise_timer -= delta
	if rise_timer <= 0.0:
		_push_rising_row()
		rise_timer = maxf(1.0, base_rise_interval - 0.22 * float(field_pressure - 1))
	for event in collapse_events:
		event["timer"] = float(event["timer"]) - delta
	var resolved: Array = []
	for event in collapse_events:
		if float(event["timer"]) <= 0.0:
			resolved.append(event)
	for event in resolved:
		collapse_events.erase(event)
		_resolve_collapse(event)
	for ripple in ripple_events:
		ripple["age"] = float(ripple["age"]) + delta
	for i in range(ripple_events.size() - 1, -1, -1):
		if float(ripple_events[i]["age"]) >= float(ripple_events[i]["life"]):
			ripple_events.remove_at(i)
	for popup in score_popups:
		popup["age"] = float(popup["age"]) + delta
		popup["pos"] = Vector2(popup["pos"]) + Vector2(0.0, -16.0 * delta)
	for i in range(score_popups.size() - 1, -1, -1):
		if float(score_popups[i]["age"]) >= float(score_popups[i]["life"]):
			score_popups.remove_at(i)
	for shard in print_shards:
		shard["age"] = float(shard["age"]) + delta
		shard["vel"] = Vector2(shard["vel"]) + Vector2(0.0, 580.0 * delta)
		shard["pos"] = Vector2(shard["pos"]) + Vector2(shard["vel"]) * delta
	for i in range(print_shards.size() - 1, -1, -1):
		if float(print_shards[i]["age"]) >= float(print_shards[i]["life"]):
			print_shards.remove_at(i)
	for i in range(print_offset_timers.size()):
		print_offset_timers[i] = maxf(0.0, float(print_offset_timers[i]) - delta)
	if player_near_void and not recent_danger_ping:
		recent_danger_ping = true
		danger_event.emit(get_player_anchor(player_column))
	elif not player_near_void:
		recent_danger_ping = false
	_update_jam_state(delta)
	_update_preview(player_column)
	queue_redraw()

func trigger_pulse(player_column: int) -> bool:
	if player_column < 0 or player_column >= columns.size():
		return false
	var stack: Array = columns[player_column]
	if stack.is_empty():
		return false
	var row := stack.size() - 1
	focus_glyph = int(stack[row])
	var cluster := _connected_cluster(player_column, row, focus_glyph)
	if cluster.is_empty():
		return false
	var world_pos := get_player_anchor(player_column)
	collapse_events.append({
		"cells": cluster,
		"timer": 0.18,
		"manual": true,
	})
	pulse_event.emit(world_pos, focus_glyph, cluster.size())
	queue_redraw()
	return true

func force_rise(player_column: int) -> bool:
	var changed := _push_rising_row()
	if changed:
		rise_event.emit(get_player_anchor(clampi(player_column, 0, COLS - 1)))
	return changed

func can_step_between(from_column: int, to_column: int) -> bool:
	if to_column < 0 or to_column >= columns.size():
		return false
	if from_column < 0 or from_column >= columns.size():
		return false
	var from_height: int = columns[from_column].size()
	var to_height: int = columns[to_column].size()
	if to_height >= VISIBLE_ROWS:
		return false
	if to_height <= 0:
		return from_height <= 2
	return abs(to_height - from_height) <= 2

func is_column_standable(column: int) -> bool:
	if column < 0 or column >= columns.size():
		return false
	var height: int = columns[column].size()
	return height < VISIBLE_ROWS

func get_surface_y(column: int) -> float:
	if column < 0 or column >= columns.size():
		return get_void_y()
	var stack: Array = columns[column]
	if stack.is_empty():
		return FIELD_ORIGIN.y + float(VISIBLE_ROWS) * TILE_SIZE
	return FIELD_ORIGIN.y + float(VISIBLE_ROWS - stack.size()) * TILE_SIZE

func get_player_anchor(column: int) -> Vector2:
	return Vector2(
		FIELD_ORIGIN.x + (float(column) + 0.5) * TILE_SIZE,
		get_surface_y(column)
	)

func get_void_y() -> float:
	return FIELD_ORIGIN.y + VISIBLE_ROWS * TILE_SIZE + VOID_HEIGHT

func get_player_focus_glyph() -> int:
	return focus_glyph

func update_focus_from_column(player_column: int) -> void:
	_update_preview(player_column)
	queue_redraw()

func get_pressure_ratio() -> float:
	return clampf(float(field_pressure - 1) / 5.0, 0.0, 1.0)

func get_jam_ratio(column: int) -> float:
	if column < 0 or column >= jam_timers.size():
		return 0.0
	return clampf(float(jam_timers[column]) / _current_jam_fail_seconds(), 0.0, 1.0)

func get_tile_entities() -> Array:
	var out: Array = []
	for col in range(columns.size()):
		for glyph in columns[col]:
			out.append({"type": "glyph_%d" % int(glyph)})
	for event in collapse_events:
		out.append({"type": "collapse"})
	return out

func get_column_heights() -> Array:
	var out: Array = []
	for stack in columns:
		out.append(stack.size())
	return out

func get_type_counts() -> Dictionary:
	var out := {
		"glyph_0": 0,
		"glyph_1": 0,
		"glyph_2": 0,
		"collapse": collapse_events.size(),
	}
	for stack in columns:
		for glyph in stack:
			var key := "glyph_%d" % int(glyph)
			out[key] = int(out.get(key, 0)) + 1
	return out

func _push_rising_row() -> bool:
	rising_row_serial += 1
	var changed := false
	for col in range(columns.size()):
		var stack: Array = columns[col]
		if stack.size() >= VISIBLE_ROWS:
			continue
		stack.insert(0, _seeded_glyph(col, 1000 + rising_row_serial))
		changed = true
	for event in collapse_events:
		var shifted: Array = []
		for cell in event["cells"]:
			var pos := cell as Vector2i
			shifted.append(Vector2i(pos.x, pos.y + 1))
		event["cells"] = shifted
	if changed:
		for col in range(print_offset_timers.size()):
			print_offset_timers[col] = maxf(float(print_offset_timers[col]), 0.25)
	queue_redraw()
	return changed

func _resolve_collapse(event: Dictionary) -> void:
	var cells: Array = event["cells"]
	if cells.is_empty():
		return
	var grouped := {}
	var centroid := Vector2.ZERO
	for cell in cells:
		var pos := cell as Vector2i
		centroid += Vector2(float(pos.x), float(pos.y))
		if not grouped.has(pos.x):
			grouped[pos.x] = []
		grouped[pos.x].append(pos.y)
	for col in grouped.keys():
		var rows: Array = grouped[col]
		rows.sort()
		rows.reverse()
		for row in rows:
			var stack: Array = columns[int(col)]
			if int(row) >= 0 and int(row) < stack.size():
				stack.remove_at(int(row))
		print_offset_timers[int(col)] = maxf(float(print_offset_timers[int(col)]), 0.55)
	var removed_count := cells.size()
	var effective_removed := maxi(0, removed_count - 2)
	var score_value := effective_removed * effective_removed
	centroid /= maxf(1.0, float(cells.size()))
	var world_pos := Vector2(
		FIELD_ORIGIN.x + (centroid.x + 0.5) * TILE_SIZE,
		FIELD_ORIGIN.y + (float(VISIBLE_ROWS) - centroid.y - 0.5) * TILE_SIZE
	)
	ripple_events.append({
		"pos": world_pos,
		"age": 0.0,
		"life": 0.41,
		"split": 1.0,
	})
	var shard_budget := mini(24, removed_count * 2)
	for i in range(shard_budget):
		var src: Vector2i = cells[i % cells.size()]
		var src_pos := Vector2(
			FIELD_ORIGIN.x + (float(src.x) + 0.5) * TILE_SIZE,
			FIELD_ORIGIN.y + (float(VISIBLE_ROWS - src.y) - 0.5) * TILE_SIZE
		)
		var angle := randf_range(-2.5, -0.5)
		var speed := randf_range(80.0, 220.0)
		var glyph := int(columns[clampi(src.x, 0, columns.size() - 1)].back()) if not columns[clampi(src.x, 0, columns.size() - 1)].is_empty() else (i % 3)
		print_shards.append({
			"pos": src_pos + Vector2(randf_range(-7.0, 7.0), randf_range(-8.0, 8.0)),
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": Vector2(randf_range(4.0, 9.0), randf_range(3.0, 7.0)),
			"color": GLYPH_COLORS[glyph].lightened(0.08),
			"age": 0.0,
			"life": randf_range(0.22, 0.46),
		})
	if score_value > 0:
		score_popups.append({
			"pos": world_pos,
			"text": "+%d" % score_value,
			"age": 0.0,
			"life": 0.55,
		})
		score_event.emit(score_value, world_pos)
	queue_redraw()

func _connected_cluster(start_col: int, start_row: int, glyph: int) -> Array:
	var out: Array = []
	var stack: Array = [Vector2i(start_col, start_row)]
	var visited := {}
	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		if visited.has(cell):
			continue
		visited[cell] = true
		if cell.x < 0 or cell.x >= columns.size():
			continue
		var col_stack: Array = columns[cell.x]
		if cell.y < 0 or cell.y >= col_stack.size():
			continue
		if int(col_stack[cell.y]) != glyph:
			continue
		out.append(cell)
		stack.append(Vector2i(cell.x + 1, cell.y))
		stack.append(Vector2i(cell.x - 1, cell.y))
		stack.append(Vector2i(cell.x, cell.y + 1))
		stack.append(Vector2i(cell.x, cell.y - 1))
	return out

func _seeded_glyph(col: int, row: int) -> int:
	var value := int(abs(sin(float(current_seed + col * 17 + row * 31))) * 1000.0)
	return value % 3

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(960.0, 540.0)), Color8(58, 58, 64))
	var bg_rect := Rect2(FIELD_ORIGIN - Vector2(28.0, 20.0), Vector2(FIELD_WIDTH + 56.0, VISIBLE_ROWS * TILE_SIZE + VOID_HEIGHT + 40.0))
	draw_rect(bg_rect, Color8(16, 16, 24))
	draw_rect(bg_rect, Color8(245, 238, 220, 72), false, 2.0)
	var plate_rect := Rect2(FIELD_ORIGIN, Vector2(FIELD_WIDTH, VISIBLE_ROWS * TILE_SIZE + VOID_HEIGHT))
	draw_rect(plate_rect, Color8(245, 238, 220, 36), false, 1.0)
	for line in range(VISIBLE_ROWS + 1):
		var y := FIELD_ORIGIN.y + line * TILE_SIZE
		draw_line(
			Vector2(FIELD_ORIGIN.x, y),
			Vector2(FIELD_ORIGIN.x + FIELD_WIDTH, y),
			Color(1.0, 1.0, 1.0, 0.04),
			1.0
		)
	var pressure_alpha := 0.22 + get_pressure_ratio() * 0.25
	var void_rect := Rect2(
		Vector2(FIELD_ORIGIN.x - 8.0, FIELD_ORIGIN.y + VISIBLE_ROWS * TILE_SIZE),
		Vector2(FIELD_WIDTH + 16.0, VOID_HEIGHT)
	)
	draw_rect(void_rect, Color(0.7, 0.12, 0.18, pressure_alpha))
	var floor_rect := Rect2(
		Vector2(FIELD_ORIGIN.x - 8.0, FIELD_ORIGIN.y + VISIBLE_ROWS * TILE_SIZE),
		Vector2(FIELD_WIDTH + 16.0, 8.0)
	)
	draw_rect(floor_rect, Color(0.92, 0.88, 0.76, 0.75))
	for col in range(columns.size()):
		var stack: Array = columns[col]
		var print_offset := _column_print_offset(col)
		for row in range(stack.size()):
			var glyph := int(stack[row])
			var rect := _tile_rect(col, row)
			rect.position.x += _jam_offset(col, row) + print_offset
			var color: Color = GLYPH_COLORS[glyph]
			var cell_key := Vector2i(col, row)
			var tint := 0.24
			if preview_cells.has(cell_key):
				tint = 0.0
			color = color.darkened(tint)
			var jam_ratio := get_jam_ratio(col)
			if jam_ratio > 0.0:
				color = color.lerp(Color(1.0, 0.38, 0.22, color.a), jam_ratio * 0.6)
			var pending := _pending_factor(col, row)
			if pending > 0.0:
				# Pre-collapse "ink drain": interior loses pigment while edge remains.
				color = color.lerp(Color8(245, 238, 220), pending * 0.74)
			draw_rect(rect, color)
			draw_rect(rect.grow(-2.0), color.lightened(0.12), false, 1.0)
			draw_line(rect.position + Vector2(2.0, 2.0), rect.position + Vector2(rect.size.x - 2.0, 2.0), Color(1.0, 1.0, 1.0, 0.2), 1.5)
			draw_line(rect.position + Vector2(2.0, rect.size.y - 2.0), rect.position + Vector2(rect.size.x - 2.0, rect.size.y - 2.0), Color(0.05, 0.05, 0.08, 0.45), 1.5)
			draw_rect(rect.grow(-4.0), Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.88), false, 2.0)
			var split := _print_history_strength(col)
			if split > 0.0:
				var split_r := Rect2(rect.position + Vector2(1.6, 0.0), rect.size).grow(-3.0)
				var split_c := Rect2(rect.position + Vector2(-1.6, 0.0), rect.size).grow(-3.0)
				draw_rect(split_r, Color(1.0, 0.35, 0.35, 0.12 * split), false, 1.0)
				draw_rect(split_c, Color(0.35, 1.0, 1.0, 0.12 * split), false, 1.0)
			if pending > 0.0:
				var drain := rect.grow(-6.0)
				draw_rect(drain, Color(0.98, 0.96, 0.9, 0.35 * pending))
				draw_rect(drain, Color(0.98, 0.96, 0.9, 0.5 * pending), false, 1.0)
			_draw_glyph_mark(rect, glyph)
		var jam_ratio := get_jam_ratio(col)
		if jam_ratio > 0.0:
			var top_rect := Rect2(
				Vector2(FIELD_ORIGIN.x + float(col) * TILE_SIZE, FIELD_ORIGIN.y - 6.0),
				Vector2(TILE_SIZE, 6.0)
			)
			draw_rect(top_rect, Color(1.0, 0.35, 0.25, 0.2 + jam_ratio * 0.5))
	for ripple in ripple_events:
		var age := float(ripple["age"])
		var life := float(ripple["life"])
		var t := age / maxf(life, 0.001)
		var radius := lerpf(10.0, 64.0, t)
		var alpha := 1.0 - t
		var pos := ripple["pos"] as Vector2
		var split := float(ripple.get("split", 0.0))
		var split_px := 1.5 + 3.0 * split * (1.0 - t)
		draw_arc(pos + Vector2(split_px, 0.0), radius, 0.0, TAU, 36, Color(1.0, 0.3, 0.3, alpha * 0.35), 2.0)
		draw_arc(pos - Vector2(split_px, 0.0), radius, 0.0, TAU, 36, Color(0.3, 1.0, 1.0, alpha * 0.35), 2.0)
		draw_arc(pos, radius * 0.92, 0.0, TAU, 36, Color(1.0, 0.86, 0.62, alpha * 0.18), 1.0)
	for shard in print_shards:
		var life := float(shard["life"])
		var t := float(shard["age"]) / maxf(life, 0.001)
		var alpha := 1.0 - t
		var rect := Rect2(Vector2(shard["pos"]) - Vector2(shard["size"]) * 0.5, Vector2(shard["size"]))
		var shard_color: Color = Color(shard["color"])
		shard_color.a = 0.85 * alpha
		draw_rect(rect, shard_color)
		draw_rect(rect.grow(-1.0), Color(0.95, 0.92, 0.84, 0.18 * alpha), false, 1.0)
	for popup in score_popups:
		var font := SCORE_POPUP_FONT if SCORE_POPUP_FONT != null else ThemeDB.fallback_font
		if font == null:
			continue
		var font_size := 18
		var alpha := 1.0 - float(popup["age"]) / float(popup["life"])
		var text := str(popup["text"])
		var base_pos: Vector2 = popup["pos"]
		draw_string(font, base_pos + Vector2(1.2, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, Color(1.0, 0.34, 0.34, 0.38 * alpha))
		draw_string(font, base_pos + Vector2(-1.2, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, Color(0.34, 1.0, 1.0, 0.38 * alpha))
		draw_string(font, base_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, Color(0.96, 0.93, 0.86, alpha))

func _tile_rect(col: int, row: int) -> Rect2:
	return Rect2(
		Vector2(
			FIELD_ORIGIN.x + float(col) * TILE_SIZE,
			FIELD_ORIGIN.y + float(VISIBLE_ROWS - row - 1) * TILE_SIZE
		),
		Vector2(TILE_SIZE, TILE_SIZE)
	)

func _draw_glyph_mark(rect: Rect2, glyph: int) -> void:
	var c := rect.get_center()
	var color := Color(1.0, 1.0, 1.0, 0.45)
	if glyph == 0:
		draw_line(c + Vector2(-9, 10), c, color, 2.0)
		draw_line(c, c + Vector2(9, 10), color, 2.0)
		draw_line(c + Vector2(-5, 2), c + Vector2(5, 2), color, 2.0)
	elif glyph == 1:
		draw_line(c + Vector2(8, -10), c + Vector2(-8, -10), color, 2.0)
		draw_line(c + Vector2(-8, -10), c + Vector2(-8, 10), color, 2.0)
		draw_line(c + Vector2(-8, 0), c + Vector2(6, 0), color, 2.0)
		draw_line(c + Vector2(-8, 10), c + Vector2(8, 10), color, 2.0)
	else:
		draw_arc(c, 10.0, 0.0, TAU, 20, color, 2.0)

func _is_pending(col: int, row: int) -> bool:
	var cell := Vector2i(col, row)
	for event in collapse_events:
		if (event["cells"] as Array).has(cell):
			return true
	return false

func _pending_factor(col: int, row: int) -> float:
	var cell := Vector2i(col, row)
	var out := 0.0
	for event in collapse_events:
		if (event["cells"] as Array).has(cell):
			var timer := float(event.get("timer", 0.0))
			var life := 0.18
			out = maxf(out, clampf(1.0 - timer / life, 0.0, 1.0))
	return out

func _update_preview(player_column: int) -> void:
	preview_cells.clear()
	if player_column < 0 or player_column >= columns.size():
		return
	var stack: Array = columns[player_column]
	if stack.is_empty():
		return
	var row := stack.size() - 1
	focus_glyph = int(stack[row])
	var cluster := _connected_cluster(player_column, row, focus_glyph)
	for cell in cluster:
		preview_cells[cell] = true

func _update_jam_state(delta: float) -> void:
	var jam_limit := _current_jam_fail_seconds()
	for col in range(columns.size()):
		var stack: Array = columns[col]
		if stack.size() >= VISIBLE_ROWS:
			jam_timers[col] = float(jam_timers[col]) + delta
			if float(jam_timers[col]) >= jam_limit:
				jam_fail.emit(col)
				return
		else:
			jam_timers[col] = 0.0

func _jam_offset(col: int, row: int) -> float:
	var jam_ratio := get_jam_ratio(col)
	if jam_ratio <= 0.0:
		return 0.0
	var freq := 10.0 + jam_ratio * 12.0 + float(row) * 0.15
	var amp := jam_ratio * 4.0
	return sin(elapsed * freq + float(col) * 1.7 + float(row) * 0.3) * amp

func _current_jam_fail_seconds() -> float:
	return maxf(jam_fail_seconds_min, jam_fail_seconds - float(field_pressure - 1) * 0.5)

func set_difficulty(next_difficulty_id: String) -> void:
	difficulty_id = next_difficulty_id
	_apply_difficulty_preset()

func _apply_difficulty_preset() -> void:
	var preset: Dictionary = DIFFICULTY_PRESETS.get(difficulty_id, DIFFICULTY_PRESETS["normal"])
	base_rise_interval = float(preset.get("base_rise_interval", 4.4))
	pressure_step_seconds = float(preset.get("pressure_step_seconds", 10.0))
	jam_fail_seconds = float(preset.get("jam_fail_seconds", 10.0))
	jam_fail_seconds_min = float(preset.get("jam_fail_seconds_min", 5.0))

func _column_print_offset(col: int) -> float:
	var strength := _print_history_strength(col)
	if strength <= 0.0:
		return 0.0
	var phase := elapsed * 18.0 + float(col) * 0.9
	return sin(phase) * 1.6 * strength

func _print_history_strength(col: int) -> float:
	if col < 0 or col >= print_offset_timers.size():
		return 0.0
	return clampf(float(print_offset_timers[col]) / 0.55, 0.0, 1.0)
