extends CanvasLayer

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG       := Color(0.09, 0.07, 0.05, 0.96)
const _C_BORDER   := Color(0.52, 0.40, 0.20, 1.0)
const _C_GOLD     := Color(0.88, 0.73, 0.38, 1.0)
const _C_TEXT     := Color(0.82, 0.76, 0.64, 1.0)
const _C_DIMMED   := Color(0.48, 0.42, 0.32, 0.55)
const _C_HINT     := Color(0.42, 0.38, 0.30, 1.0)
const _C_COMPLETE := Color(0.48, 0.74, 0.42, 1.0)
const _C_REWARD   := Color(0.55, 0.85, 0.45, 1.0)

var _font      : Font
var _root      : Control
var _list      : VBoxContainer
var _is_open   : bool = false

var _selected_idx    : int   = 0
var _row_labels      : Array = []
var _row_underlines  : Array = []
var _row_rewards     : Array = []


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
	_selected_idx = 0
	_refresh()
	_root.show()
	_is_open = true
	_set_player_active(false)


func close() -> void:
	_root.hide()
	_is_open = false
	_set_player_active(true)
	queue_free()


# ── Input ─────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed(PlayerInput.MENU_CANCEL):
		close()
	elif Input.is_action_just_pressed(PlayerInput.MENU_UP):
		_navigate(-1)
	elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
		_navigate(1)
	elif Input.is_action_just_pressed(PlayerInput.INTERACT):
		_turn_in_selected()


func _navigate(dir: int) -> void:
	var count := _row_labels.size()
	if count == 0:
		return
	_selected_idx = (_selected_idx + dir + count) % count
	_update_cursor()


func _turn_in_selected() -> void:
	var complete: Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool: return b.get("status") == "complete"
	)
	if _selected_idx < complete.size():
		SceneManager.turn_in_bounty(complete[_selected_idx].get("id", ""))


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

	var title := _label("Completed Contracts", 28, _C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := _label("Select a contract to turn it in and collect your Scripts.", 14, _C_HINT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	vbox.add_child(_sep())

	_list = VBoxContainer.new()
	_list.layout_mode = 2
	_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_list)

	vbox.add_child(_sep())

	var hint := _label("↑↓  Navigate     [A]  Turn In     [B]  Close", 13, _C_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_clear(_list)
	_row_labels.clear()
	_row_underlines.clear()
	_row_rewards.clear()

	var complete: Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool: return b.get("status") == "complete"
	)
	if complete.is_empty():
		close()
		return

	for i in complete.size():
		_list.add_child(_bounty_row(complete[i], i))

	_selected_idx = clampi(_selected_idx, 0, complete.size() - 1)
	_update_cursor()


func _bounty_row(bounty: Dictionary, idx: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.layout_mode = 2
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.layout_mode = 2
	hbox.add_theme_constant_override("separation", 14)
	col.add_child(hbox)

	var flavor := _label(bounty.get("flavor", ""), 15, _C_TEXT)
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(flavor)

	var reward    := SceneManager.scripts_for_bounty(bounty)
	var reward_lbl := _label("+%d Scripts" % reward, 15, _C_REWARD)
	reward_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(reward_lbl)

	var underline := ColorRect.new()
	underline.custom_minimum_size   = Vector2(0.0, 2.0)
	underline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	underline.color = _C_GOLD if idx == _selected_idx else Color.TRANSPARENT
	col.add_child(underline)

	_row_labels.append(flavor)
	_row_rewards.append(reward_lbl)
	_row_underlines.append(underline)
	return col


func _update_cursor() -> void:
	for i in _row_labels.size():
		var sel := (i == _selected_idx)
		_row_labels[i].add_theme_color_override(
			"font_color", _C_GOLD if sel else _C_TEXT)
		_row_rewards[i].add_theme_color_override(
			"font_color", _C_GOLD if sel else _C_REWARD)
		_row_underlines[i].color = _C_GOLD if sel else Color.TRANSPARENT


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
