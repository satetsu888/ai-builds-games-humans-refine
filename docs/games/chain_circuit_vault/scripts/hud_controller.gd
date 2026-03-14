extends CanvasLayer

var _score_label := Label.new()
var _ui_base_font: FontFile = null
var _ui_numeric_font: FontFile = null

func _ready() -> void:
	layer = 10
	_ui_base_font = load("res://assets/fonts/NotoSansMono-Regular.ttf") as FontFile
	_ui_numeric_font = load("res://assets/fonts/NotoSansMono-Bold.ttf") as FontFile
	var theme := Theme.new()
	var base_font_size := 30
	if _ui_base_font != null:
		theme.set_font("font", "Label", _ui_base_font)
	theme.set_font_size("font_size", "Label", base_font_size)
	theme.set_color("font_color", "Label", Color("d9f3ff"))
	theme.set_constant("outline_size", "Label", 2)
	theme.set_color("font_outline_color", "Label", Color("102032"))

	_score_label.position = Vector2(0, 2)
	_score_label.size = Vector2(540, 34)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.theme = theme
	if _ui_numeric_font != null:
		_score_label.add_theme_font_override("font", _ui_numeric_font)
	add_child(_score_label)

func set_values(score: int, _game_over: bool, _reason: String) -> void:
	_score_label.text = str(score)
