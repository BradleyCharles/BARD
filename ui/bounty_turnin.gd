extends CanvasLayer

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG          := Color(0.09, 0.07, 0.05, 0.96)
const _C_BORDER      := Color(0.52, 0.40, 0.20, 1.0)
const _C_TITLE       := Color(0.88, 0.73, 0.38, 1.0)
const _C_SECTION     := Color(0.68, 0.55, 0.28, 1.0)
const _C_FLAVOR      := Color(0.82, 0.76, 0.64, 1.0)
const _C_HINT        := Color(0.42, 0.38, 0.30, 1.0)
const _C_COMPLETE    := Color(0.48, 0.74, 0.42, 1.0)
const _C_REWARD      := Color(0.55, 0.85, 0.45, 1.0)
const _C_BTN_BG      := Color(0.20, 0.14, 0.07, 1.0)
const _C_BTN_BORDER  := Color(0.52, 0.40, 0.20, 1.0)
const _C_BTN_TEXT    := Color(0.88, 0.73, 0.38, 1.0)
const _C_BTN_HOVER   := Color(0.30, 0.22, 0.10, 1.0)
const _C_BTN_PRESSED := Color(0.14, 0.10, 0.05, 1.0)

var _font       : Font
var _root       : Control
var _list       : VBoxContainer
var _is_open    : bool = false


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	layer = 20
	_build_ui()
	_root.hide()
	SceneManager.bounties_updated.connect(func() -> void:
		if _is_open:
			_refresh.call_deferred()
	)


# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	_refresh()
	_root.show()
	_is_open = true
	_set_player_input(false)


func close() -> void:
	_root.hide()
	_is_open = false
	_set_player_input(true)
	queue_free()


# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	get_viewport().set_input_as_handled()

	if event.keycode == KEY_ESCAPE:
		close()
		return

	const KEY_MAP := {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3}
	var idx : int = KEY_MAP.get(event.keycode, -1)
	if idx == -1:
		return
	var complete : Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool: return b.get("status") == "complete"
	)
	if idx < complete.size():
		SceneManager.turn_in_bounty(complete[idx].get("id", ""))


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.52)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.20
	panel.anchor_top    = 0.15
	panel.anchor_right  = 0.80
	panel.anchor_bottom = 0.85
	panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := _label("Completed Contracts", 28, _C_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := _label("Click a contract to turn it in and collect your Scripts.", 14, _C_HINT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	vbox.add_child(_sep())

	_list = VBoxContainer.new()
	_list.layout_mode = 2
	_list.add_theme_constant_override("separation", 8)
	vbox.add_child(_list)

	vbox.add_child(_sep())

	var hint := _label("[Esc]  to close", 13, _C_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_clear(_list)
	var complete : Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool: return b.get("status") == "complete"
	)
	if complete.is_empty():
		close()
		return
	for bounty in complete:
		_list.add_child(_bounty_row(bounty))


func _bounty_row(bounty: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 14)

	var flavor := _label(bounty.get("flavor", ""), 15, _C_FLAVOR)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flavor)

	var reward := SceneManager.scripts_for_bounty(bounty)
	var btn    := _button("+%d Scripts" % reward)
	var bid    : String = bounty.get("id", "")
	btn.pressed.connect(func() -> void: SceneManager.turn_in_bounty(bid))
	row.add_child(btn)
	return row


# ── Style Helpers ─────────────────────────────────────────────────────────────

func _label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.layout_mode = 2
	lbl.text = text
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _sep() -> HSeparator:
	var s := HSeparator.new()
	s.layout_mode = 2
	var style := StyleBoxFlat.new()
	style.bg_color              = Color(_C_BORDER.r, _C_BORDER.g, _C_BORDER.b, 0.55)
	style.content_margin_top    = 1.0
	style.content_margin_bottom = 1.0
	s.add_theme_stylebox_override("separator", style)
	return s


func _button(text: String) -> Button:
	var btn := Button.new()
	btn.layout_mode = 2
	btn.text = text
	if _font:
		btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color",         _C_REWARD)
	btn.add_theme_color_override("font_hover_color",   _C_REWARD)
	btn.add_theme_color_override("font_focus_color",   _C_REWARD)
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 1.0, 0.6, 1.0))
	btn.add_theme_stylebox_override("normal",  _btn_style(_C_BTN_BG))
	btn.add_theme_stylebox_override("hover",   _btn_style(_C_BTN_HOVER))
	btn.add_theme_stylebox_override("pressed", _btn_style(_C_BTN_PRESSED))
	btn.add_theme_stylebox_override("focus",   _btn_style(_C_BTN_BG))
	return btn


func _btn_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color            = bg
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_color               = _C_BTN_BORDER
	sb.corner_radius_top_left     = 3
	sb.corner_radius_top_right    = 3
	sb.corner_radius_bottom_left  = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left   = 12.0
	sb.content_margin_right  = 12.0
	sb.content_margin_top    = 6.0
	sb.content_margin_bottom = 6.0
	return sb


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


# ── Player Input ──────────────────────────────────────────────────────────────

func _set_player_input(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if not node is Area2D:
			node.set_process_input(enabled)
			break


# ── Internals ─────────────────────────────────────────────────────────────────

func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
