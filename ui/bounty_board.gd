extends CanvasLayer

signal board_opened
signal board_closed

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG        := Color(0.09, 0.07, 0.05, 0.97)
const _C_BORDER    := Color(0.52, 0.40, 0.20, 1.0)
const _C_GOLD      := Color(0.88, 0.73, 0.38, 1.0)
const _C_SECTION   := Color(0.60, 0.50, 0.28, 1.0)
const _C_TEXT      := Color(0.82, 0.76, 0.64, 1.0)
const _C_DIMMED    := Color(0.48, 0.42, 0.32, 0.40)
const _C_EMPTY     := Color(0.50, 0.46, 0.38, 1.0)
const _C_HINT      := Color(0.42, 0.38, 0.30, 1.0)
const _C_PROGRESS  := Color(0.78, 0.70, 0.38, 1.0)
const _C_COMPLETE  := Color(0.48, 0.74, 0.42, 1.0)
const _C_WARNING   := Color(0.85, 0.35, 0.25, 1.0)

const _ZONES       := ["zone_a", "zone_b", "zone_c"]
const _ZONE_LABELS := {"zone_a": "Zone A", "zone_b": "Zone B", "zone_c": "Zone C"}

var _font          : Font
var _root          : Control
var _scroll        : ScrollContainer
var _list          : VBoxContainer
var _active_label  : Label
var _is_open       : bool  = false

var _selectable    : Array      = []
var _selected_idx  : int        = 0
var _row_map       : Dictionary = {}

var _detail_panel  : Control = null
var _detail_open   : bool    = false


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
	_selected_idx = 0
	_refresh()
	_root.show()
	_is_open = true
	_set_player_active(false)
	board_opened.emit()


func close() -> void:
	_close_detail()
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
	if _detail_open:
		if Input.is_action_just_pressed(PlayerInput.MENU_CANCEL):
			_close_detail()
		elif Input.is_action_just_pressed(PlayerInput.INTERACT):
			_accept_from_detail()
		return
	if Input.is_action_just_pressed(PlayerInput.MENU_CANCEL):
		close()
	elif Input.is_action_just_pressed(PlayerInput.MENU_UP):
		_navigate(-1)
	elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
		_navigate(1)
	elif Input.is_action_just_pressed(PlayerInput.INTERACT):
		_open_detail()


func _navigate(dir: int) -> void:
	var count: int = _selectable.size()
	if count == 0:
		return
	_selected_idx = (_selected_idx + dir + count) % count
	_update_cursor()
	var bid: String  = _selectable[_selected_idx].get("id", "")
	var row: Control = _row_map.get(bid, null)
	if _scroll and row:
		_scroll.ensure_control_visible(row)


# ── Detail modal ──────────────────────────────────────────────────────────────

func _open_detail() -> void:
	if _selectable.is_empty():
		return
	var bounty: Dictionary = _selectable[_selected_idx]
	_close_detail()

	_detail_open  = true
	_detail_panel = Control.new()
	_detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_detail_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_panel.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal     = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical       = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(580, 0)
	panel.add_theme_stylebox_override("panel", _modal_style())
	_detail_panel.add_child(panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var display_name: String = bounty.get("display_name", bounty.get("id", ""))
	var monster_type: String = bounty.get("monster_type", "")
	var quantity    : int    = int(bounty.get("quantity", 0))
	var zone        : String = bounty.get("zone", "")
	var flavor      : String = bounty.get("flavor", "")

	var diff  : String = SceneManager.difficulty_label(monster_type)
	var size_s: String = SceneManager.size_label(quantity)
	var zone_s: String = _ZONE_LABELS.get(zone, zone)

	var title_lbl := _lbl(display_name, 30, _C_GOLD)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var tags_lbl := _lbl("%s  ·  %s  ·  %s" % [zone_s, diff, size_s], 18, _C_SECTION)
	tags_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tags_lbl)

	vbox.add_child(_sep())

	var flavor_lbl := _lbl(flavor, 20, _C_TEXT)
	flavor_lbl.autowrap_mode      = TextServer.AUTOWRAP_WORD_SMART
	flavor_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(flavor_lbl)

	vbox.add_child(_sep())

	vbox.add_child(_lbl("Target:  %d slimes" % quantity, 20, _C_TEXT))

	var reward: String = bounty.get("reward_text", "")
	vbox.add_child(_lbl("Reward:  %s" % reward, 20, _C_GOLD))

	vbox.add_child(_sep())

	if _is_zone_occupied(zone):
		var warn := _lbl("Zone contract already active", 18, _C_WARNING)
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(warn)
		var hint := _lbl("[B]  Back", 16, _C_HINT)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hint)
	else:
		var hint := _lbl("[A]  Accept Contract          [B]  Back", 18, _C_HINT)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hint)


func _close_detail() -> void:
	if _detail_panel:
		_detail_panel.queue_free()
		_detail_panel = null
	_detail_open = false


func _accept_from_detail() -> void:
	if _selectable.is_empty():
		return
	var bounty: Dictionary = _selectable[_selected_idx]
	if _is_zone_occupied(bounty.get("zone", "")):
		return
	SceneManager.accept_bounty(bounty.get("id", ""))
	_close_detail()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.10
	panel.anchor_top    = 0.05
	panel.anchor_right  = 0.90
	panel.anchor_bottom = 0.95
	panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(panel)

	var outer := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	outer.add_child(vbox)

	# ── Header: title + active counter ──
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := _lbl("The Bounty Board", 32, _C_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_active_label = _lbl("ACTIVE  0 / 3", 22, _C_GOLD)
	_active_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_active_label)

	vbox.add_child(_sep())

	# ── Scrollable zone list ──
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical        = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode     = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)

	vbox.add_child(_sep())

	var hint := _lbl("↑↓  Navigate     [A]  Details     [B]  Close", 15, _C_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_selectable.clear()
	_row_map.clear()

	var available: Array = SceneManager.available_bounties
	var active   : Array = SceneManager.active_bounties

	_update_active_counter(active)

	var by_zone: Dictionary = {}
	for z: String in _ZONES:
		by_zone[z] = []
	for bounty: Dictionary in available:
		var z: String = bounty.get("zone", "")
		if z in by_zone:
			by_zone[z].append(bounty)

	for z: String in _ZONES:
		var zone_bounties: Array = by_zone[z]
		var occupied     : bool  = _is_zone_occupied(z)

		var header_text: String = "── %s%s" % [
			_ZONE_LABELS.get(z, z),
			"  [Occupied]" if occupied else ""
		]
		var zone_header := _lbl(header_text, 18, _C_SECTION if not occupied else _C_DIMMED)
		zone_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(zone_header)

		if zone_bounties.is_empty():
			_list.add_child(_lbl("  No contracts posted.", 18, _C_EMPTY))
		else:
			for bounty: Dictionary in zone_bounties:
				var row: HBoxContainer = _bounty_row(bounty, occupied)
				_list.add_child(row)
				if not occupied:
					var bid: String = bounty.get("id", "")
					_row_map[bid] = row
					_selectable.append(bounty)

		_list.add_child(_zone_gap())

	# ── Active contracts section ──
	_list.add_child(_sep())
	_list.add_child(_lbl("ACTIVE CONTRACTS", 18, _C_SECTION))

	var real_active: Array = active.filter(
		func(b: Dictionary) -> bool: return b.get("status") != "turned_in")
	if real_active.is_empty():
		_list.add_child(_lbl("  None.", 18, _C_EMPTY))
	else:
		for bounty: Dictionary in real_active:
			_list.add_child(_active_row(bounty))

	_selected_idx = clampi(_selected_idx, 0, max(0, _selectable.size() - 1))
	_update_cursor()


func _bounty_row(bounty: Dictionary, dimmed: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var display_name: String = bounty.get("display_name", bounty.get("id", ""))
	var monster_type: String = bounty.get("monster_type", "")
	var quantity    : int    = int(bounty.get("quantity", 0))
	var color       : Color  = _C_DIMMED if dimmed else _C_TEXT

	var name_lbl := _lbl(display_name + " spotted", 24, color)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var diff  : String = SceneManager.difficulty_label(monster_type)
	var size_s: String = SceneManager.size_label(quantity)
	var tag_color: Color = _C_DIMMED if dimmed else _C_SECTION
	row.add_child(_lbl("%s · %s" % [diff, size_s], 18, tag_color))

	return row


func _active_row(bounty: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var display_name: String = bounty.get("display_name", bounty.get("id", ""))
	var zone        : String = _ZONE_LABELS.get(bounty.get("zone", ""), bounty.get("zone", ""))
	var killed      : int    = int(bounty.get("killed", 0))
	var total       : int    = int(bounty.get("quantity", 0))

	var name_lbl := _lbl(display_name + "  —  " + zone, 20, _C_TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var status: String = bounty.get("status", "active")
	var prog_text : String
	var prog_color: Color
	if status == "complete":
		prog_text  = "Complete"
		prog_color = _C_COMPLETE
	else:
		prog_text  = "%d / %d" % [killed, total]
		prog_color = _C_PROGRESS

	var prog_lbl := _lbl(prog_text, 20, prog_color)
	prog_lbl.custom_minimum_size   = Vector2(96, 0)
	prog_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(prog_lbl)

	return row


func _update_cursor() -> void:
	if _selectable.is_empty():
		return
	var sel_bounty: Dictionary = _selectable[_selected_idx]
	for bounty: Dictionary in _selectable:
		var bid: String  = bounty.get("id", "")
		var row: Control = _row_map.get(bid, null)
		if not row:
			continue
		var name_lbl: Label = row.get_child(0) as Label if row.get_child_count() > 0 else null
		if not (name_lbl is Label):
			continue
		var is_sel : bool   = (bounty == sel_bounty)
		var display: String = bounty.get("display_name", bounty.get("id", ""))
		name_lbl.text = ("▶  " if is_sel else "    ") + display + " spotted"
		name_lbl.add_theme_color_override("font_color", _C_GOLD if is_sel else _C_TEXT)


func _update_active_counter(active: Array) -> void:
	var occupied: Array = []
	for b: Dictionary in active:
		var z: String = b.get("zone", "")
		if b.get("status") != "turned_in" and not (z in occupied):
			occupied.append(z)
	_active_label.text = "ACTIVE  %d / 3" % occupied.size()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _is_zone_occupied(zone: String) -> bool:
	for b: Dictionary in SceneManager.active_bounties:
		if b.get("zone") == zone and b.get("status") != "turned_in":
			return true
	return false


func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _sep() -> HSeparator:
	var s     := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color              = Color(_C_BORDER.r, _C_BORDER.g, _C_BORDER.b, 0.45)
	style.content_margin_top    = 1.0
	style.content_margin_bottom = 1.0
	s.add_theme_stylebox_override("separator", style)
	return s


func _zone_gap() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	return spacer


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _C_BG
	sb.set_border_width_all(2)
	sb.border_color = _C_BORDER
	sb.set_corner_radius_all(6)
	return sb


func _modal_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.03, 1.0)
	sb.set_border_width_all(2)
	sb.border_color = _C_BORDER
	sb.set_corner_radius_all(8)
	return sb


# ── Player Control ────────────────────────────────────────────────────────────

func _set_player_active(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node.has_method("set_gameplay_active"):
			node.set_gameplay_active(enabled)
