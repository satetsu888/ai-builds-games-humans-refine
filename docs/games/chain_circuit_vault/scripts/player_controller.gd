extends RefCounted

const DIRS := {
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
}
const INITIAL_TRAIL_LENGTH := 5

var grid_size := Vector2i(12, 7)
var head_cell := Vector2i.ZERO
var trail_cells: Array[Vector2i] = []
var trail_length := INITIAL_TRAIL_LENGTH

var facing_direction := "up"
var move_cooldown := 0.0
var idle_throw_active := false
var idle_throw_origin := Vector2i.ZERO
var idle_throw_step := 0
var idle_throw_tick := 0.0
var idle_throw_interval := 0.1
var _prev_inputs := {
	"move_up": false,
	"move_down": false,
	"move_left": false,
	"move_right": false,
}

func reset(size: Vector2i) -> void:
	grid_size = size
	head_cell = Vector2i(size.x / 2, size.y / 2)
	trail_cells = [head_cell]
	facing_direction = "up"
	move_cooldown = 0.0
	idle_throw_active = false
	idle_throw_origin = head_cell
	idle_throw_step = 0
	idle_throw_tick = 0.0
	for key in _prev_inputs.keys():
		_prev_inputs[key] = false

func step(delta: float, inputs: Dictionary) -> Dictionary:
	move_cooldown = maxf(0.0, move_cooldown - delta)
	var events := {
		"moved": false,
		"throw_step": null,
	}

	var pressed_direction := _pressed_direction(inputs)
	if pressed_direction != "" and move_cooldown <= 0.0:
		var dir: Vector2i = DIRS[pressed_direction]
		var next_cell := _clamp_to_grid(head_cell + dir)
		if next_cell != head_cell:
			head_cell = next_cell
			trail_cells.push_front(head_cell)
			if trail_cells.size() > trail_length:
				trail_cells.resize(trail_length)
			events["moved"] = true
			facing_direction = pressed_direction
		move_cooldown = 0.1
		_stop_idle_throw()

	var any_pressed_now := pressed_direction != ""
	var any_pressed_prev := _had_any_input(_prev_inputs)
	if not any_pressed_now and any_pressed_prev:
		_start_idle_throw()
	if idle_throw_active and not any_pressed_now:
		idle_throw_tick += delta
		if idle_throw_tick >= idle_throw_interval:
			idle_throw_tick = 0.0
			idle_throw_step += 1
			events["throw_step"] = {
				"origin": idle_throw_origin,
				"dir": DIRS[facing_direction],
				"step": idle_throw_step,
			}

	for key in _prev_inputs.keys():
		_prev_inputs[key] = bool(inputs.get(key, false))
	return events

func get_cable_set() -> Dictionary:
	var out := {}
	for cell in trail_cells:
		out[cell] = true
	return out

func _pressed_direction(inputs: Dictionary) -> String:
	if bool(inputs.get("move_up", false)):
		return "up"
	if bool(inputs.get("move_down", false)):
		return "down"
	if bool(inputs.get("move_left", false)):
		return "left"
	if bool(inputs.get("move_right", false)):
		return "right"
	return ""

func _clamp_to_grid(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, grid_size.x - 1),
		clampi(cell.y, 0, grid_size.y - 1)
	)

func _start_idle_throw() -> void:
	idle_throw_active = true
	idle_throw_origin = head_cell
	idle_throw_step = 0
	idle_throw_tick = 0.0

func _stop_idle_throw() -> void:
	idle_throw_active = false
	idle_throw_step = 0
	idle_throw_tick = 0.0

func cancel_idle_throw() -> void:
	_stop_idle_throw()

func grow(amount: int = 1) -> void:
	if amount <= 0:
		return
	trail_length += amount

func reset_length_to_initial() -> void:
	trail_length = INITIAL_TRAIL_LENGTH
	if trail_cells.size() > trail_length:
		trail_cells.resize(trail_length)

func sever_and_reset_to_initial() -> void:
	trail_length = INITIAL_TRAIL_LENGTH
	trail_cells = [head_cell]
	_stop_idle_throw()

func _had_any_input(input_state: Dictionary) -> bool:
	for key in input_state.keys():
		if bool(input_state[key]):
			return true
	return false
