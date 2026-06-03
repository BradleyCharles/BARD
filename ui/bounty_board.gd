extends CanvasLayer

signal board_opened
signal board_closed

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG       := Color(0.09, 0.07, 0.05, 0.97)
const _C_BORDER   := Color(0.52, 0.40, 0.20, 1.0)
const _C_GOLD     := Color(0.88, 0.73, 0.38, 1.0)
const _C_SECTION  := Color(0.60, 0.50, 0.28, 1.0)
const _C_TEXT     := Color(0.82, 0.76, 0.64, 1.0)
const _C_DIMMED   := Color(0.48, 0.42, 0.32, 0.45)
const _C_EMPTY    := Color(0.50, 0.46, 0.38, 1.0)
const _C_HINT     := Color(0.42, 0.38, 0.30, 1.0)
const _C_PROGRESS := Color(0.78, 0.70, 0.38, 1.0)
const _C_COMPLETE := Color(0.48, 0.74, 0.42, 1.0)
const _C_WARNING  := Color(0.85, 0.35, 0.25, 1.0)

const _ZONES      := ["zone_a", "zone_b", "zone_c"]
const _ZONE_LABELS: Dictionary = {
	"zone_a": "Zone A", "zone_b": "Zone B", "zone_c": "Zone C"
}

var _tex_slime1 : Texture2D
var _tex_slime2 : Texture2D
var _tex_slime3 : Texture2D

var _font         : Font
var _root         : Control
var _scroll       : ScrollContainer
var _list         : VBoxContainer
var _active_label : Label
var _detail_pane  : VBoxContainer
var _is_open      : bool = false

var _selectable   : Array      = []
var _selected_idx : int        = 0
var _row_map      : Dictionary = {}
var _input_guard  : bool       = false


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_tex_slime1 = _load_tex("res://assets/Bounty_Board/Slime1_bounty.png")
	_tex_slime2 = _load_tex("res://assets/Bounty_Board/Slime2_bounty.png")
	_tex_slime3 = _load_tex("res://assets/Bounty_Board/Slime3_bounty.png")
	_build_ui()
	_root.hide()
	SceneManager.bounties_updated.connect(func() -> void:
		if _is_open:
			_refresh.call_deferred()
	)


# ── Public API ────────────────────────────────────────────────────────────────

func open() -> void:
	_selected_idx = 0
	_input_guard  = true
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
	if _input_guard:
		_input_guard = false
		return
	if Input.is_action_just_pressed(PlayerInput.MENU_CANCEL):
		close()
	elif Input.is_action_just_pressed(PlayerInput.MENU_UP):
		_navigate(-1)
	elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
		_navigate(1)
	elif Input.is_action_just_pressed(PlayerInput.INTERACT):
		_try_accept()


func _navigate(dir: int) -> void:
	var count: int = _selectable.size()
	if count == 0:
		return
	_selected_idx = (_selected_idx + dir + count) % count
	_update_cursor()
	_update_detail(_selectable[_selected_idx])
	var bid: String  = _selectable[_selected_idx].get("id", "")
	var row: Control = _row_map.get(bid, null)
	if _scroll and row:
		_scroll.ensure_control_visible(row)


func _try_accept() -> void:
	if _selectable.is_empty():
		return
	var bounty: Dictionary = _selectable[_selected_idx]
	if _is_zone_occupied(bounty.get("zone", "")):
		return
	SceneManager.accept_bounty(bounty.get("id", ""))


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.60)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.04
	panel.anchor_top    = 0.04
	panel.anchor_right  = 0.96
	panel.anchor_bottom = 0.96
	panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(panel)

	var outer := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(outer)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	outer.add_child(main_vbox)

	# ── Header ──
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := _lbl("The Bounty Board", 30, _C_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_active_label = _lbl("ACTIVE  0 / 3", 20, _C_GOLD)
	_active_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_active_label)

	main_vbox.add_child(_hsep())

	# ── Content split ──
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	main_vbox.add_child(content)

	# Left: scrollable list
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical      = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_stretch_ratio = 3.0
	_scroll.horizontal_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)

	# Vertical divider
	content.add_child(_vsep())

	# Right: detail pane
	var right_margin := MarginContainer.new()
	right_margin.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	right_margin.size_flags_vertical      = Control.SIZE_EXPAND_FILL
	right_margin.size_flags_stretch_ratio = 2.5
	right_margin.add_theme_constant_override("margin_left",   18)
	right_margin.add_theme_constant_override("margin_right",  6)
	right_margin.add_theme_constant_override("margin_top",    6)
	right_margin.add_theme_constant_override("margin_bottom", 6)
	content.add_child(right_margin)

	_detail_pane = VBoxContainer.new()
	_detail_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_pane.add_theme_constant_override("separation", 10)
	right_margin.add_child(_detail_pane)

	main_vbox.add_child(_hsep())

	var hint := _lbl("↑↓  Navigate     [A]  Accept Contract     [B]  Close", 14, _C_HINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(hint)


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
		var zone_hdr := _lbl(header_text, 15, _C_SECTION if not occupied else _C_DIMMED)
		zone_hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(zone_hdr)

		if zone_bounties.is_empty():
			_list.add_child(_lbl("  No contracts posted.", 15, _C_EMPTY))
		else:
			for bounty: Dictionary in zone_bounties:
				var row: HBoxContainer = _bounty_row(bounty, occupied)
				_list.add_child(row)
				if not occupied:
					var bid: String = bounty.get("id", "")
					_row_map[bid] = row
					_selectable.append(bounty)

		_list.add_child(_zone_gap())

	_list.add_child(_hsep())
	_list.add_child(_lbl("ACTIVE CONTRACTS", 15, _C_SECTION))

	var real_active: Array = active.filter(
		func(b: Dictionary) -> bool: return b.get("status") != "turned_in")
	if real_active.is_empty():
		_list.add_child(_lbl("  None.", 15, _C_EMPTY))
	else:
		for bounty: Dictionary in real_active:
			_list.add_child(_active_row(bounty))

	_selected_idx = clampi(_selected_idx, 0, max(0, _selectable.size() - 1))
	_update_cursor()
	_update_detail(_selectable[_selected_idx] if not _selectable.is_empty() else {})


# ── Row builders ──────────────────────────────────────────────────────────────

func _bounty_row(bounty: Dictionary, dimmed: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 76)

	var monster_type: String = bounty.get("monster_type", "")
	var display     : String = bounty.get("display_name", bounty.get("id", ""))
	var quantity    : int    = int(bounty.get("quantity", 0))

	var thumb := TextureRect.new()
	thumb.texture             = _get_texture(monster_type)
	thumb.custom_minimum_size = Vector2(96, 72)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if dimmed:
		thumb.modulate = Color(1.0, 1.0, 1.0, 0.25)
	row.add_child(thumb)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 3)
	row.add_child(text_col)

	var col    : Color = _C_DIMMED if dimmed else _C_TEXT
	var tagcol : Color = _C_DIMMED if dimmed else _C_SECTION

	text_col.add_child(_lbl(display + " spotted", 20, col))
	var diff  : String = SceneManager.difficulty_label(monster_type)
	var size_s: String = SceneManager.size_label(quantity)
	text_col.add_child(_lbl("%s · %s" % [diff, size_s], 14, tagcol))

	return row


func _active_row(bounty: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var thumb := TextureRect.new()
	thumb.texture             = _get_texture(bounty.get("monster_type", ""))
	thumb.custom_minimum_size = Vector2(56, 42)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.modulate            = Color(1.0, 1.0, 1.0, 0.55)
	row.add_child(thumb)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)

	var display: String = bounty.get("display_name", bounty.get("id", ""))
	var zone   : String = _ZONE_LABELS.get(bounty.get("zone", ""), bounty.get("zone", ""))
	var killed : int    = int(bounty.get("killed", 0))
	var total  : int    = int(bounty.get("quantity", 0))
	var status : String = bounty.get("status", "active")

	text_col.add_child(_lbl(display + "  —  " + zone, 16, _C_TEXT))

	var prog_text : String
	var prog_color: Color
	if status == "complete":
		prog_text  = "Complete"
		prog_color = _C_COMPLETE
	else:
		prog_text  = "%d / %d" % [killed, total]
		prog_color = _C_PROGRESS
	text_col.add_child(_lbl(prog_text, 14, prog_color))

	return row


# ── Detail pane ───────────────────────────────────────────────────────────────

func _update_detail(bounty: Dictionary) -> void:
	for child in _detail_pane.get_children():
		_detail_pane.remove_child(child)
		child.queue_free()

	if bounty.is_empty():
		var empty := _lbl("No contracts available.", 18, _C_EMPTY)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail_pane.add_child(empty)
		return

	var monster_type: String = bounty.get("monster_type", "")
	var quantity    : int    = int(bounty.get("quantity", 0))
	var zone        : String = bounty.get("zone", "")
	var flavor      : String = bounty.get("flavor", "")
	var display     : String = bounty.get("display_name", bounty.get("id", ""))
	var diff        : String = SceneManager.difficulty_label(monster_type)
	var size_s      : String = SceneManager.size_label(quantity)
	var zone_s      : String = _ZONE_LABELS.get(zone, zone)
	var reward      : String = bounty.get("reward_text", "")

	var tex: Texture2D = _get_texture(monster_type)
	if tex:
		var img := TextureRect.new()
		img.texture               = tex
		img.custom_minimum_size   = Vector2(0, 190)
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_detail_pane.add_child(img)

	var name_lbl := _lbl(display, 24, _C_GOLD)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_pane.add_child(name_lbl)

	_detail_pane.add_child(_lbl("%s  ·  %s  ·  %s" % [zone_s, diff, size_s], 15, _C_SECTION))

	_detail_pane.add_child(_hsep())

	var flavor_lbl := _lbl(flavor, 16, _C_TEXT)
	flavor_lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	flavor_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_pane.add_child(flavor_lbl)

	_detail_pane.add_child(_hsep())

	_detail_pane.add_child(_lbl("Target:  %d slimes" % quantity, 16, _C_TEXT))
	_detail_pane.add_child(_lbl("Reward:  %s" % reward, 16, _C_GOLD))

	_detail_pane.add_child(_hsep())

	if _is_zone_occupied(zone):
		var warn := _lbl("Zone contract already active", 15, _C_WARNING)
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail_pane.add_child(warn)
	else:
		var accept_lbl := _lbl("[A]  Accept Contract", 15, _C_HINT)
		accept_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail_pane.add_child(accept_lbl)


# ── Cursor & counter ──────────────────────────────────────────────────────────

func _update_cursor() -> void:
	if _selectable.is_empty():
		return
	var sel: Dictionary = _selectable[_selected_idx]
	for bounty: Dictionary in _selectable:
		var bid    : String  = bounty.get("id", "")
		var row    : Control = _row_map.get(bid, null)
		if not row or row.get_child_count() < 2:
			continue
		var text_col: Control = row.get_child(1)
		if text_col.get_child_count() < 1:
			continue
		var name_lbl: Label = text_col.get_child(0) as Label
		if not (name_lbl is Label):
			continue
		var is_sel : bool   = (bounty == sel)
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


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _get_texture(monster_type: String) -> Texture2D:
	match monster_type:
		"slime1": return _tex_slime1
		"slime2": return _tex_slime2
		"slime3": return _tex_slime3
	return null


func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _hsep() -> HSeparator:
	var s     := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color              = Color(_C_BORDER.r, _C_BORDER.g, _C_BORDER.b, 0.40)
	style.content_margin_top    = 1.0
	style.content_margin_bottom = 1.0
	s.add_theme_stylebox_override("separator", style)
	return s


func _vsep() -> VSeparator:
	var s     := VSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color               = Color(_C_BORDER.r, _C_BORDER.g, _C_BORDER.b, 0.45)
	style.content_margin_left    = 1.0
	style.content_margin_right   = 1.0
	s.add_theme_stylebox_override("separator", style)
	return s


func _zone_gap() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	return spacer


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _C_BG
	sb.set_border_width_all(2)
	sb.border_color = _C_BORDER
	sb.set_corner_radius_all(6)
	return sb


# ── Player Control ────────────────────────────────────────────────────────────

func _set_player_active(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node.has_method("set_gameplay_active"):
			node.set_gameplay_active(enabled)
