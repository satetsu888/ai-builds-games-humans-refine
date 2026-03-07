extends Node2D

const PLAYER_SIZE := Vector2(24.0, 30.0)
const GRAVITY := 1800.0
const MOVE_REPEAT := 0.11
const GLYPH_COLORS := [
	Color8(255, 122, 89),
	Color8(94, 212, 200),
	Color8(255, 209, 102),
]

var column := 4
var pos := Vector2.ZERO
var velocity_y := 0.0
var repeat_timer := 0.0
var alive := true
var grounded := true
var focus_glyph := 0

func reset(start_column: int, anchor: Vector2) -> void:
	column = start_column
	pos = anchor + Vector2(0.0, -PLAYER_SIZE.y * 0.55)
	velocity_y = 0.0
	repeat_timer = 0.0
	alive = true
	grounded = true
	queue_redraw()

func step(delta: float, move_dir: int, field: Node) -> void:
	if not alive:
		return
	repeat_timer = maxf(0.0, repeat_timer - delta)
	if move_dir != 0 and repeat_timer <= 0.0:
		var target := clampi(column + move_dir, 0, field.COLS - 1)
		if field.can_step_between(column, target):
			column = target
			repeat_timer = MOVE_REPEAT
	var has_support: bool = field.is_column_standable(column)
	var surface_y: float = field.get_surface_y(column) - PLAYER_SIZE.y * 0.55
	if not has_support or pos.y < surface_y - 2.0:
		grounded = false
		velocity_y += GRAVITY * delta
		pos.y += velocity_y * delta
	else:
		pos.y = surface_y
		velocity_y = 0.0
		grounded = true
	var anchor_x: float = field.get_player_anchor(column).x
	pos.x = lerpf(pos.x, anchor_x, minf(1.0, delta * 18.0))
	queue_redraw()

func is_near_void(field: Node) -> bool:
	return pos.y > field.get_void_y() - 80.0

func has_fallen_into_void(field: Node) -> bool:
	return pos.y > field.get_void_y() + PLAYER_SIZE.y * 0.25

func set_focus_glyph(next_focus_glyph: int) -> void:
	focus_glyph = clampi(next_focus_glyph, 0, GLYPH_COLORS.size() - 1)
	queue_redraw()

func _draw() -> void:
	var base := Rect2(pos - Vector2(14.0, 18.0), Vector2(28.0, 34.0))
	var frame_color := Color8(245, 238, 220)
	var ink_color: Color = GLYPH_COLORS[focus_glyph]
	draw_rect(base, Color8(20, 20, 28))
	draw_rect(base, frame_color, false, 2.0)
	var stamp := Rect2(base.position + Vector2(6.0, 4.0), Vector2(16.0, 18.0))
	draw_rect(stamp, ink_color.darkened(0.18))
	draw_rect(stamp, frame_color, false, 1.5)
	_draw_glyph_mark(stamp, focus_glyph)
	var carriage := Rect2(base.position + Vector2(4.0, 24.0), Vector2(20.0, 6.0))
	draw_rect(carriage, Color8(178, 172, 154))
	draw_line(carriage.position + Vector2(1.0, 1.0), carriage.end - Vector2(1.0, 5.0), Color8(40, 38, 44), 1.0)

func _draw_glyph_mark(rect: Rect2, glyph: int) -> void:
	var c := rect.get_center()
	var color := Color8(245, 238, 220)
	if glyph == 0:
		draw_line(c + Vector2(-4, 5), c, color, 2.0)
		draw_line(c, c + Vector2(4, 5), color, 2.0)
		draw_line(c + Vector2(-3, 1), c + Vector2(3, 1), color, 2.0)
	elif glyph == 1:
		draw_line(c + Vector2(4, -5), c + Vector2(-4, -5), color, 2.0)
		draw_line(c + Vector2(-4, -5), c + Vector2(-4, 5), color, 2.0)
		draw_line(c + Vector2(-4, 0), c + Vector2(3, 0), color, 2.0)
		draw_line(c + Vector2(-4, 5), c + Vector2(4, 5), color, 2.0)
	else:
		draw_arc(c, 4.5, 0.0, TAU, 16, color, 2.0)
