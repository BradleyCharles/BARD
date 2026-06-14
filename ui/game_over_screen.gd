extends CanvasLayer

const _FONT_BOLD := "res://fonts/almendra.bold.ttf"
const _FONT_REG  := "res://fonts/almendra.regular.ttf"
const _C_BG      := Color(0.0, 0.0, 0.0, 0.82)
const _C_GOLD    := Color(0.95, 0.85, 0.45, 1.0)
const _C_DIM     := Color(0.60, 0.55, 0.45, 1.0)

var _font_bold      : Font  = null
var _font_reg       : Font  = null
var _can_confirm    : bool  = false
var _continue_label : Label = null


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

	if ResourceLoader.exists(_FONT_BOLD):
		_font_bold = load(_FONT_BOLD)
	if ResourceLoader.exists(_FONT_REG):
		_font_reg = load(_FONT_REG)

	_build()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.color = _C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", _C_GOLD)
	if _font_bold:
		title.add_theme_font_override("font", _font_bold)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.grow_vertical   = Control.GROW_DIRECTION_BOTH
	title.scale           = Vector2(0.05, 0.05)
	root.add_child(title)

	_continue_label = Label.new()
	_continue_label.text = "[ Continue ]"
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_label.add_theme_font_size_override("font_size", 32)
	_continue_label.add_theme_color_override("font_color", _C_DIM)
	if _font_reg:
		_continue_label.add_theme_font_override("font", _font_reg)
	_continue_label.set_anchors_preset(Control.PRESET_CENTER)
	_continue_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_continue_label.grow_vertical   = Control.GROW_DIRECTION_BOTH
	_continue_label.modulate        = Color(1.0, 1.0, 1.0, 0.0)
	root.add_child(_continue_label)

	_animate(title)


func _animate(title: Label) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	title.pivot_offset = title.size / 2.0

	var tw: Tween = create_tween()
	tw.tween_property(title, "scale", Vector2.ONE, 1.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished

	_continue_label.position.y = title.position.y + title.size.y + 40.0

	await get_tree().create_timer(0.5).timeout

	var tw2: Tween = create_tween()
	tw2.tween_property(_continue_label, "modulate:a", 1.0, 0.6)
	await tw2.finished

	_can_confirm = true


func _unhandled_input(event: InputEvent) -> void:
	# Absorb pause/cancel so the pause menu cannot open over game over.
	if event.is_action_pressed(PlayerInput.PAUSE) \
			or event.is_action_pressed(PlayerInput.MENU_CANCEL):
		get_viewport().set_input_as_handled()
		return

	if not _can_confirm:
		return

	var mouse_clicked: bool = event is InputEventMouseButton \
		and (event as InputEventMouseButton).pressed \
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT

	if event.is_action_pressed(PlayerInput.INTERACT) or mouse_clicked:
		_can_confirm = false
		get_viewport().set_input_as_handled()
		SceneManager.load_game(0)
