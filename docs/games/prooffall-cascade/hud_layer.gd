extends CanvasLayer

const DISPLAY_FONT: FontFile = preload("res://assets/fonts/SpecialElite-Regular.ttf")
const INFO_FONT: FontFile = preload("res://assets/fonts/IBMPlexSans-Variable.ttf")
const NUMERIC_FONT: FontFile = preload("res://assets/fonts/IBMPlexMono-SemiBold.ttf")

var score_label := Label.new()
var pressure_label := Label.new()
var game_over_panel := Panel.new()
var game_over_title := Label.new()
var game_over_subtitle := Label.new()
var game_over_hint := Label.new()
var title_overlay := Control.new()
var title_card := Panel.new()
var title_label := Label.new()
var title_subtitle := Label.new()
var title_prompt := Label.new()
var ui_theme := Theme.new()

func _ready() -> void:
	_build_theme()
	score_label.position = Vector2(260.0, 8.0)
	score_label.theme = ui_theme
	score_label.add_theme_font_override("font", ui_theme.get_font("font", "ScoreLabel"))
	score_label.add_theme_font_size_override("font_size", ui_theme.get_font_size("font_size", "ScoreLabel"))
	score_label.add_theme_color_override("font_color", ui_theme.get_color("font_color", "ScoreLabel"))
	score_label.add_theme_color_override("font_outline_color", ui_theme.get_color("font_outline_color", "ScoreLabel"))
	score_label.add_theme_constant_override("outline_size", ui_theme.get_constant("outline_size", "ScoreLabel"))
	score_label.text = "Score 0"
	add_child(score_label)

	pressure_label.position = Vector2(560.0, 8.0)
	pressure_label.theme = ui_theme
	pressure_label.add_theme_font_override("font", ui_theme.get_font("font", "ScoreLabel"))
	pressure_label.add_theme_font_size_override("font_size", ui_theme.get_font_size("font_size", "ScoreLabel"))
	pressure_label.add_theme_color_override("font_color", ui_theme.get_color("font_color", "ScoreLabel"))
	pressure_label.add_theme_color_override("font_outline_color", ui_theme.get_color("font_outline_color", "ScoreLabel"))
	pressure_label.add_theme_constant_override("outline_size", ui_theme.get_constant("outline_size", "ScoreLabel"))
	pressure_label.text = "Pressure 1"
	add_child(pressure_label)

	_build_game_over_card()
	_build_title_card()

func update_state(score_value: int, pressure: int) -> void:
	score_label.text = "Score %d" % score_value
	pressure_label.text = "Pressure %d" % pressure

func show_game_over(score_value: int) -> void:
	game_over_subtitle.text = "Final Score %d" % score_value
	game_over_panel.visible = true

func clear_game_over() -> void:
	game_over_panel.visible = false

func show_title_screen() -> void:
	title_overlay.visible = true

func hide_title_screen() -> void:
	title_overlay.visible = false

func is_title_visible() -> bool:
	return title_overlay.visible

func _build_game_over_card() -> void:
	game_over_panel.position = Vector2(320.0, 236.0)
	game_over_panel.size = Vector2(320.0, 152.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color8(20, 18, 28, 236)
	panel_style.border_color = Color8(245, 238, 220, 190)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 3
	panel_style.corner_radius_top_right = 3
	panel_style.corner_radius_bottom_left = 3
	panel_style.corner_radius_bottom_right = 3
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	game_over_panel.visible = false
	add_child(game_over_panel)

	var content := MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 16)
	content.add_theme_constant_override("margin_top", 12)
	content.add_theme_constant_override("margin_right", 16)
	content.add_theme_constant_override("margin_bottom", 12)
	game_over_panel.add_child(content)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	content.add_child(stack)

	game_over_title.theme = ui_theme
	game_over_title.add_theme_font_override("font", ui_theme.get_font("font", "DisplayLabel"))
	game_over_title.add_theme_font_size_override("font_size", 24)
	game_over_title.add_theme_color_override("font_color", ui_theme.get_color("font_color", "DisplayLabel"))
	game_over_title.add_theme_color_override("font_outline_color", ui_theme.get_color("font_outline_color", "DisplayLabel"))
	game_over_title.add_theme_constant_override("outline_size", ui_theme.get_constant("outline_size", "DisplayLabel"))
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title.text = "VOID CLAIMED THE PROOF"
	stack.add_child(game_over_title)

	game_over_subtitle.theme = ui_theme
	game_over_subtitle.add_theme_font_override("font", ui_theme.get_font("font", "ScoreLabel"))
	game_over_subtitle.add_theme_font_size_override("font_size", 20)
	game_over_subtitle.add_theme_color_override("font_color", ui_theme.get_color("font_color", "ScoreLabel"))
	game_over_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_subtitle.text = "Final Score 0"
	stack.add_child(game_over_subtitle)

	game_over_hint.theme = ui_theme
	game_over_hint.add_theme_font_override("font", ui_theme.get_font("font", "InfoLabel"))
	game_over_hint.add_theme_font_size_override("font_size", 16)
	game_over_hint.add_theme_color_override("font_color", ui_theme.get_color("font_color", "InfoLabel"))
	game_over_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_hint.text = "Press Space/Down/S for title"
	stack.add_child(game_over_hint)

func _build_title_card() -> void:
	title_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_overlay)

	var overlay_back := ColorRect.new()
	overlay_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_back.color = Color8(12, 10, 18, 168)
	title_overlay.add_child(overlay_back)

	title_card.custom_minimum_size = Vector2(640.0, 210.0)
	title_card.set_anchors_preset(Control.PRESET_CENTER)
	title_card.position = Vector2(-320.0, -105.0)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color8(16, 16, 24, 236)
	title_style.border_color = Color8(245, 238, 220, 220)
	title_style.border_width_left = 2
	title_style.border_width_top = 2
	title_style.border_width_right = 2
	title_style.border_width_bottom = 2
	title_style.corner_radius_top_left = 4
	title_style.corner_radius_top_right = 4
	title_style.corner_radius_bottom_left = 4
	title_style.corner_radius_bottom_right = 4
	title_card.add_theme_stylebox_override("panel", title_style)
	title_overlay.add_child(title_card)

	var content := MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 28)
	content.add_theme_constant_override("margin_top", 18)
	content.add_theme_constant_override("margin_right", 28)
	content.add_theme_constant_override("margin_bottom", 18)
	title_card.add_child(content)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(center)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(stack)

	title_label.theme = ui_theme
	title_label.add_theme_font_override("font", ui_theme.get_font("font", "DisplayLabel"))
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", ui_theme.get_color("font_color", "DisplayLabel"))
	title_label.add_theme_color_override("font_outline_color", ui_theme.get_color("font_outline_color", "DisplayLabel"))
	title_label.add_theme_constant_override("outline_size", ui_theme.get_constant("outline_size", "DisplayLabel"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text = "PROOFFALL CASCADE"
	stack.add_child(title_label)

	title_subtitle.theme = ui_theme
	title_subtitle.add_theme_font_override("font", ui_theme.get_font("font", "InfoLabel"))
	title_subtitle.add_theme_font_size_override("font_size", 16)
	title_subtitle.add_theme_color_override("font_color", Color8(218, 214, 202))
	title_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_subtitle.text = "Move: Arrow / WASD   Rise: Up / W   Pulse: Space / Down / S"
	stack.add_child(title_subtitle)

	title_prompt.theme = ui_theme
	title_prompt.add_theme_font_override("font", ui_theme.get_font("font", "ScoreLabel"))
	title_prompt.add_theme_font_size_override("font_size", 22)
	title_prompt.add_theme_color_override("font_color", Color8(245, 238, 220))
	title_prompt.add_theme_color_override("font_outline_color", Color8(16, 16, 24, 220))
	title_prompt.add_theme_constant_override("outline_size", 1)
	title_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_prompt.text = "Press Space/Down/S to Begin Proof"
	stack.add_child(title_prompt)

func _build_theme() -> void:
	if DISPLAY_FONT == null or INFO_FONT == null or NUMERIC_FONT == null:
		push_warning("HUD fonts are missing; using fallback font.")
		return

	ui_theme.set_font("font", "DisplayLabel", DISPLAY_FONT)
	ui_theme.set_font_size("font_size", "DisplayLabel", 38)
	ui_theme.set_color("font_color", "DisplayLabel", Color8(245, 238, 220))
	ui_theme.set_color("font_outline_color", "DisplayLabel", Color8(16, 16, 24, 230))
	ui_theme.set_constant("outline_size", "DisplayLabel", 2)

	ui_theme.set_font("font", "InfoLabel", INFO_FONT)
	ui_theme.set_font_size("font_size", "InfoLabel", 14)
	ui_theme.set_color("font_color", "InfoLabel", Color8(218, 214, 202))

	ui_theme.set_font("font", "ScoreLabel", NUMERIC_FONT)
	ui_theme.set_font_size("font_size", "ScoreLabel", 22)
	ui_theme.set_color("font_color", "ScoreLabel", Color8(245, 238, 220))
	ui_theme.set_color("font_outline_color", "ScoreLabel", Color8(16, 16, 24, 220))
	ui_theme.set_constant("outline_size", "ScoreLabel", 1)
