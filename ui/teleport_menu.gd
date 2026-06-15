extends CanvasLayer

## Testing teleport menu. Opened with SELECT (Back button / Tab) while
## testing_mode is ON. Lets the player jump to the entrance of any zone.
## Only instantiated by field.gd while testing_mode is active.

signal menu_closed

const _FONT_PATH := "res://fonts/almendra.regular.ttf"
const _C_BG      := Color(0.0,  0.0,  0.0,  0.88)
const _C_PANEL   := Color(0.07, 0.05, 0.03, 1.0)
const _C_BORDER  := Color(0.50, 0.40, 0.20, 0.90)
const _C_GOLD    := Color(0.95, 0.85, 0.45, 1.0)
const _C_DIM     := Color(0.60, 0.55, 0.45, 1.0)

var _font        : Font
var _rows        : Array[Label]    = []
var _actions     : Array[Callable] = []
var _selection   : int             = 0
var _is_open     : bool            = false

var _zone_rects  : Dictionary = {}
var _player      : Node2D     = null


func _ready() -> void:
	layer        = 260
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)


func init(zone_rects: Dictionary, player_node: Node2D) -> void:
	_zone_rects = zone_rects
	_player     = player_node
	_build_ui()
	_is_open = true
	get_tree().paused = true


# ── UI ────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var bg := ColorRect.new()
	bg.color = _C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color     = _C_PANEL
	style.border_color = _C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(340.0, 0.0)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "TELEPORT TO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", _C_GOLD)
	if _font:
		title.add_theme_font_override("font", _font)
	vbox.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.50, 0.40, 0.20, 0.60))
	vbox.add_child(sep)

	_add_zone_option(vbox, "Zone A  (Orcs & Plants)", "zone_a")
	_add_zone_option(vbox, "Zone B  (Vampires)", "zone_b")
	_add_zone_option(vbox, "Zone C  (Slimes)", "zone_c")
	_add_label_option(vbox, "Town", _go_to_town)

	var cancel := Label.new()
	cancel.text = "Cancel"
	cancel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel.add_theme_font_size_override("font_size", 28)
	cancel.add_theme_color_override("font_color", _C_DIM)
	if _font:
		cancel.add_theme_font_override("font", _font)
	vbox.add_child(cancel)
	_rows.append(cancel)
	_actions.append(_close)

	_highlight(_selection)


func _add_zone_option(vbox: VBoxContainer, label_text: String, zone: String) -> void:
	var z := zone
	_add_label_option(vbox, label_text, func() -> void: _teleport_to(z))


func _add_label_option(vbox: VBoxContainer, label_text: String, action: Callable) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", _C_DIM)
	if _font:
		lbl.add_theme_font_override("font", _font)
	vbox.add_child(lbl)
	_rows.append(lbl)
	_actions.append(action)


func _highlight(idx: int) -> void:
	for i: int in _rows.size():
		_rows[i].add_theme_color_override(
			"font_color", _C_GOLD if i == idx else _C_DIM
		)


# ── Input ─────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed(PlayerInput.MENU_UP):
		_selection = (_selection - 1 + _rows.size()) % _rows.size()
		_highlight(_selection)
	elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
		_selection = (_selection + 1) % _rows.size()
		_highlight(_selection)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed(PlayerInput.INTERACT):
		_actions[_selection].call()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.MENU_CANCEL) \
			or event.is_action_pressed(PlayerInput.SELECT):
		_close()
		get_viewport().set_input_as_handled()


# ── Teleport ──────────────────────────────────────────────────────────────────

func _teleport_to(zone: String) -> void:
	if _player == null or not is_instance_valid(_player):
		_close()
		return
	if not zone in _zone_rects:
		_close()
		return
	var rect: Rect2 = _zone_rects[zone]
	# Place player just inside the edge of the zone nearest its center
	_player.position = rect.get_center()
	_close()


func _go_to_town() -> void:
	_close()
	SceneManager.go_to_town()


func _close() -> void:
	_is_open = false
	get_tree().paused = false
	menu_closed.emit()
