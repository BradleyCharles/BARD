extends CanvasLayer

signal closed

const _TURNIN_SCENE := preload("res://ui/bounty_turnin.tscn")
const _FONT_PATH    := "res://fonts/almendra.regular.ttf"

# ── Shared palette ─────────────────────────────────────────────────────────────
const _C_BG     := Color(0.09, 0.07, 0.05, 0.96)
const _C_BORDER := Color(0.52, 0.40, 0.20, 1.0)
const _C_GOLD   := Color(0.88, 0.73, 0.38, 1.0)
const _C_TEXT   := Color(0.82, 0.76, 0.64, 1.0)
const _C_DIMMED := Color(0.48, 0.42, 0.32, 0.55)
const _C_HINT   := Color(0.42, 0.38, 0.30, 1.0)

@onready var _panel      : PanelContainer = $Panel
@onready var _name_label : Label          = $Panel/MarginContainer/VBox/NameLabel
@onready var _text_label : RichTextLabel  = $Panel/MarginContainer/VBox/TextLabel
@onready var _responses  : VBoxContainer  = $Panel/MarginContainer/VBox/Responses
@onready var _timer      : Timer          = $TypingTimer

const TYPING_SPEED := 0.028

var _font       : Font
var _nodes      : Dictionary = {}
var _current    : Dictionary = {}
var _full_text  : String     = ""
var _char_index : int        = 0
var _is_typing  : bool       = false
var _npc_name   : String     = ""

var _selected_idx       : int   = 0
var _response_labels    : Array = []
var _response_underlines: Array = []


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)

	_panel.add_theme_stylebox_override("panel", _panel_style())

	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", _C_GOLD)
	if _font:
		_name_label.add_theme_font_override("font", _font)

	_text_label.add_theme_font_size_override("normal_font_size", 18)
	_text_label.add_theme_color_override("default_color", _C_TEXT)
	if _font:
		_text_label.add_theme_font_override("normal_font", _font)

	var sep_style := _sep_style()
	for sep in [$Panel/MarginContainer/VBox/HSeparator,
				$Panel/MarginContainer/VBox/HSeparator2]:
		sep.add_theme_stylebox_override("separator", sep_style)

	var hint := Label.new()
	hint.text = "↑↓  Navigate     [A]  Select"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", _C_HINT)
	if _font:
		hint.add_theme_font_override("font", _font)
	_name_label.get_parent().add_child(hint)

	_panel.hide()


# ── Public API ────────────────────────────────────────────────────────────────

func open(nodes: Dictionary, start_node_id: String, npc_name: String = "") -> void:
	_nodes    = nodes.duplicate(true)
	_npc_name = npc_name
	_nodes["_insufficient_funds"] = {
		"text": "You don't have enough Scripts or Slime Goop for that.",
		"responses": [{"text": "Understood.", "next": "root"}]
	}
	_lock_player(true)
	_panel.show()
	_go_to(start_node_id)


func close() -> void:
	_timer.stop()
	_is_typing = false
	_clear_responses()
	_panel.hide()
	_lock_player(false)
	closed.emit()


func is_open() -> bool:
	return _panel.visible


# ── Navigation ────────────────────────────────────────────────────────────────

func _go_to(node_id: String) -> void:
	if not _nodes.has(node_id):
		close()
		return
	_current          = _nodes[node_id]
	_name_label.text  = _npc_name
	_clear_responses()
	_start_typeout(_current.get("text", "..."))


# ── Typeout ───────────────────────────────────────────────────────────────────

func _start_typeout(text: String) -> void:
	_full_text  = text
	_char_index = 0
	_is_typing  = true
	_text_label.text = ""
	_timer.wait_time = TYPING_SPEED
	_timer.start()


func _on_typing_timer_timeout() -> void:
	if _char_index >= _full_text.length():
		_is_typing = false
		_show_responses()
		return
	_text_label.text = _full_text.substr(0, _char_index + 1)
	_char_index += 1
	_timer.start()


func _skip_typing() -> void:
	_timer.stop()
	_char_index      = _full_text.length()
	_text_label.text = _full_text
	_is_typing       = false
	_show_responses()


# ── Responses ─────────────────────────────────────────────────────────────────

func _show_responses() -> void:
	_clear_responses()
	var list: Array = _current.get("responses", [])
	_selected_idx = 0

	for r in list:
		var row := VBoxContainer.new()
		row.layout_mode = 2
		row.add_theme_constant_override("separation", 0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl := Label.new()
		lbl.text = r.get("text", "")
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 19)
		if _font:
			lbl.add_theme_font_override("font", _font)
		row.add_child(lbl)

		var underline := ColorRect.new()
		underline.custom_minimum_size = Vector2(0.0, 2.0)
		underline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		underline.color = Color.TRANSPARENT
		row.add_child(underline)

		_response_labels.append(lbl)
		_response_underlines.append(underline)
		_responses.add_child(row)

	_update_cursor()


func _clear_responses() -> void:
	_response_labels.clear()
	_response_underlines.clear()
	for child in _responses.get_children():
		child.queue_free()


func _update_cursor() -> void:
	for i in _response_labels.size():
		var sel := (i == _selected_idx)
		_response_labels[i].add_theme_color_override(
			"font_color", _C_GOLD if sel else _C_DIMMED)
		_response_underlines[i].color = _C_GOLD if sel else Color.TRANSPARENT


func _navigate(dir: int) -> void:
	if _response_labels.is_empty():
		return
	_selected_idx = (_selected_idx + dir + _response_labels.size()) \
		% _response_labels.size()
	_update_cursor()


func _confirm_selected() -> void:
	var list: Array = _current.get("responses", [])
	if list.is_empty():
		close()
		return
	if _selected_idx < list.size():
		_handle_response(list[_selected_idx])


# ── Input ─────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _panel.visible or _is_typing:
		return
	if Input.is_action_just_pressed(PlayerInput.MENU_UP):
		_navigate(-1)
	elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
		_navigate(1)
	elif Input.is_action_just_pressed(PlayerInput.INTERACT):
		_confirm_selected()


func _input(event: InputEvent) -> void:
	if not _panel.visible or not _is_typing:
		return
	var is_press: bool = \
		(event is InputEventKey and event.pressed and not event.echo) or \
		(event is InputEventJoypadButton and event.pressed) or \
		event.is_action_pressed(PlayerInput.MENU_UP) or \
		event.is_action_pressed(PlayerInput.MENU_DOWN) or \
		event.is_action_pressed(PlayerInput.INTERACT)
	if is_press:
		get_viewport().set_input_as_handled()
		_skip_typing()


func _handle_response(r: Dictionary) -> void:
	var action: String = r.get("action", "")
	var next           = r.get("next", null)

	match action:
		"end_day":
			close()
			SceneManager.end_day()
			return
		"go_to_field":
			close()
			SceneManager.go_to_field()
			return
		"go_to_town":
			close()
			SceneManager.go_to_town()
			return
		"open_turn_in":
			close()
			call_deferred(&"_open_turnin_panel")
			return
		"buy_axe":
			if SceneManager.scripts >= 50:
				SceneManager.buy_weapon("axe", 50)
				close()
			else:
				_go_to("_insufficient_funds")
			return
		"upgrade_sword":
			if SceneManager.scripts >= 100 and SceneManager.slime_goop >= 5:
				SceneManager.upgrade_weapon("sword", 100, 5)
				close()
			else:
				_go_to("_insufficient_funds")
			return
		"upgrade_axe":
			if "axe" in SceneManager.owned_weapons \
					and SceneManager.scripts >= 150 \
					and SceneManager.slime_goop >= 10:
				SceneManager.upgrade_weapon("axe", 150, 10)
				close()
			else:
				_go_to("_insufficient_funds")
			return

	if next == null:
		close()
	else:
		_go_to(str(next))


func _open_turnin_panel() -> void:
	var turnin := _TURNIN_SCENE.instantiate()
	get_tree().root.add_child(turnin)
	turnin.open()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _lock_player(lock: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		node.set_gameplay_active(not lock)


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color            = _C_BG
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.border_color               = _C_BORDER
	sb.corner_radius_top_left     = 5
	sb.corner_radius_top_right    = 5
	sb.corner_radius_bottom_left  = 5
	sb.corner_radius_bottom_right = 5
	return sb


func _sep_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color             = Color(_C_BORDER.r, _C_BORDER.g, _C_BORDER.b, 0.55)
	sb.content_margin_top    = 1.0
	sb.content_margin_bottom = 1.0
	return sb
