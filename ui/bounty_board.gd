extends CanvasLayer

signal board_opened
signal board_closed

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG          := Color(0.09, 0.07, 0.05, 0.96)
const _C_BORDER      := Color(0.52, 0.40, 0.20, 1.0)
const _C_GOLD        := Color(0.88, 0.73, 0.38, 1.0)
const _C_SECTION     := Color(0.68, 0.55, 0.28, 1.0)
const _C_TEXT        := Color(0.82, 0.76, 0.64, 1.0)
const _C_DIMMED      := Color(0.48, 0.42, 0.32, 0.55)
const _C_EMPTY       := Color(0.50, 0.46, 0.38, 1.0)
const _C_HINT        := Color(0.42, 0.38, 0.30, 1.0)
const _C_PROGRESS    := Color(0.78, 0.70, 0.38, 1.0)
const _C_COMPLETE    := Color(0.48, 0.74, 0.42, 1.0)

var _font        : Font
var _root        : Control
var _avail_list  : VBoxContainer
var _active_list : VBoxContainer
var _is_open     : bool = false

var _selected_avail    : int   = 0
var _avail_labels      : Array = []
var _avail_underlines  : Array = []


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	_root.hide()
	SceneManager.bounties_updated.connect(func() -> void:
		if _is_open:
			_refresh.call_deferred()
	)


# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	_selected_avail = 0
	_refresh()
	_root.show()
	_is_open = true
	_set_player_active(false)
	board_opened.emit()


func close() -> void:
	_root.hide()
	_is_open = false
	_set_player_active(true)
	board_closed.emit()


func is_board_open() -> bool:
	return _is_open


# ── Input ─────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		close()
	elif Input.is_action_just_pressed("menu_up"):
		_navigate(-1)
	elif Input.is_action_just_pressed("menu_down"):
		_navigate(1)
	elif Input.is_action_just_pressed("interact"):
		_accept_selected()


func _navigate(dir: int) -> void:
	var count := _avail_labels.size()
	if count == 0:
		return
	_selected_avail = (_selected_avail + dir + count) % count
	_update_avail_cursor()


func _accept_selected() -> void:
	var available: Array = SceneManager.available_bounties
	if _selected_avail < available.size():
		var bid: String = available[_selected_avail].get("id", "")
		SceneManager.accept_bounty(bid)


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
	panel.anchor_left   = 0.15
	panel.anchor_top    = 0.06
	panel.anchor_right  = 0.85
	panel.anchor_bottom = 0.94
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

	var title := _label("The Bounty Board", 30, _C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(_sep())

	vbox.add_child(_label("AVAILABLE", 17, _C_SECTION))
	_avail_list = VBoxContainer.new()
	_avail_list.layout_mode = 2
	_avail_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_avail_list)
	vbox.add_child(_sep())

	vbox.add_child(_label("ACTIVE", 17, _C_SECTION))
	_active_list = VBoxContainer.new()
	_active_list.layout_mode = 2
	_active_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_active_list)

	vbox.add_child(_sep())
	var hint := _label("↑↓  Navigate     [A]  Accept     [B]  Close", 13, _C_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_clear(_avail_list)
	_clear(_active_list)
	_avail_labels.clear()
	_avail_underlines.clear()

	var available : Array = SceneManager.available_bounties
	var active    : Array = SceneManager.active_bounties

	if available.is_empty():
		_avail_list.add_child(_label("No bounties posted today.", 15, _C_EMPTY))
	else:
		for i in available.size():
			_avail_list.add_child(_avail_row(available[i], i))
		_selected_avail = clampi(_selected_avail, 0, available.size() - 1)
		_update_avail_cursor()

	if active.is_empty():
		_active_list.add_child(
			_label("You have no active bounties.", 15, _C_EMPTY))
	else:
		for bounty in active:
			_active_list.add_child(_active_row(bounty))


func _avail_row(bounty: Dictionary, idx: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.layout_mode = 2
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := _label(bounty.get("flavor", ""), 15, _C_TEXT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(lbl)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(0.0, 2.0)
	underline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	underline.color = _C_GOLD if idx == _selected_avail else Color.TRANSPARENT
	col.add_child(underline)

	_avail_labels.append(lbl)
	_avail_underlines.append(underline)
	return col


func _update_avail_cursor() -> void:
	for i in _avail_labels.size():
		var sel := (i == _selected_avail)
		_avail_labels[i].add_theme_color_override(
			"font_color", _C_GOLD if sel else _C_TEXT)
		_avail_underlines[i].color = _C_GOLD if sel else Color.TRANSPARENT


func _active_row(bounty: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 14)

	var flavor := _label(bounty.get("flavor", ""), 15, _C_TEXT)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(flavor)

	var status      : String = bounty.get("status", "active")
	var badge_text  : String
	var badge_color : Color
	match status:
		"complete", "turned_in":
			badge_text  = "Complete"
			badge_color = _C_COMPLETE
		_:
			badge_text  = "In Progress"
			badge_color = _C_PROGRESS

	var badge := _label(badge_text, 15, badge_color)
	badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.custom_minimum_size  = Vector2(96.0, 0.0)
	row.add_child(badge)
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


# ── Player Control ────────────────────────────────────────────────────────────

func _set_player_active(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node.has_method("set_gameplay_active"):
			node.set_gameplay_active(enabled)


# ── Internals ─────────────────────────────────────────────────────────────────

func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
