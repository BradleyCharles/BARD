extends CanvasLayer

## Pause-menu sub-screen listing active bounties.
## The player can navigate and drop a bounty, which returns it to the board.

signal screen_closed

const _FONT_PATH  := "res://fonts/almendra.regular.ttf"

# Semantic colours — same in both themes.
const _C_PROGRESS := Color(0.78, 0.70, 0.38, 1.0)
const _C_COMPLETE := Color(0.48, 0.74, 0.42, 1.0)
const _C_WARNING  := Color(0.85, 0.35, 0.25, 1.0)

const _ZONE_LABELS: Dictionary = {
	"zone_a": "Zone A", "zone_b": "Zone B", "zone_c": "Zone C"
}

var _tex_slime1  : Texture2D
var _tex_slime2  : Texture2D
var _tex_slime3  : Texture2D
var _tex_orc1    : Texture2D
var _tex_orc2    : Texture2D
var _tex_orc3    : Texture2D
var _tex_plant1  : Texture2D
var _tex_plant2  : Texture2D
var _tex_plant3  : Texture2D
var _tex_vampire1: Texture2D
var _tex_vampire2: Texture2D
var _tex_vampire3: Texture2D

var _font        : Font
var _ref         : Control
var _list        : VBoxContainer
var _detail_pane : VBoxContainer
var _scroll      : ScrollContainer

var _bounties     : Array      = []
var _selected_idx : int        = 0
var _row_map      : Dictionary = {}
var _input_guard  : bool       = false

var _confirm_overlay : Control          = null
var _confirm_rows    : Array[Label]    = []
var _confirm_actions : Array[Callable] = []
var _confirm_sel     : int             = 0


func _ready() -> void:
	layer        = 260
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_tex_slime1   = _load_tex("res://assets/Bounty_Board/Slime1_bounty.png")
	_tex_slime2   = _load_tex("res://assets/Bounty_Board/Slime2_bounty.png")
	_tex_slime3   = _load_tex("res://assets/Bounty_Board/Slime3_bounty.png")
	_tex_orc1     = _load_tex("res://assets/Bounty_Board/Orc1_bounty.png")
	_tex_orc2     = _load_tex("res://assets/Bounty_Board/Orc2_bounty.png")
	_tex_orc3     = _load_tex("res://assets/Bounty_Board/Orc3_bounty.png")
	_tex_plant1   = _load_tex("res://assets/Bounty_Board/Plant1_bounty.png")
	_tex_plant2   = _load_tex("res://assets/Bounty_Board/Plant2_bounty.png")
	_tex_plant3   = _load_tex("res://assets/Bounty_Board/Plant3_bounty.png")
	_tex_vampire1 = _load_tex("res://assets/Bounty_Board/vampire1_bounty.png")
	_tex_vampire2 = _load_tex("res://assets/Bounty_Board/vampire2_bounty.png")
	_tex_vampire3 = _load_tex("res://assets/Bounty_Board/vampire3_bounty.png")
	_build_ui()
	SceneManager.theme_changed.connect(_on_theme_changed)
	_input_guard = true
	_refresh()


func _process(_delta: float) -> void:
	if _input_guard:
		_input_guard = false
		return
	if _confirm_overlay != null:
		if Input.is_action_just_pressed(PlayerInput.MENU_UP):
			_confirm_sel = (_confirm_sel - 1 + _confirm_rows.size()) % _confirm_rows.size()
			_highlight_confirm()
		elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
			_confirm_sel = (_confirm_sel + 1) % _confirm_rows.size()
			_highlight_confirm()
		return
	if Input.is_action_just_pressed(PlayerInput.MENU_UP):
		_navigate(-1)
	elif Input.is_action_just_pressed(PlayerInput.MENU_DOWN):
		_navigate(1)


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _input_guard:
		return

	if _confirm_overlay != null:
		if event.is_action_pressed(PlayerInput.INTERACT):
			_confirm_actions[_confirm_sel].call()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.MENU_CANCEL):
			_close_confirm()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(PlayerInput.INTERACT):
		_try_drop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.MENU_CANCEL) \
			or event.is_action_pressed(PlayerInput.PAUSE):
		screen_closed.emit()
		get_viewport().set_input_as_handled()


func _navigate(dir: int) -> void:
	var count: int = _bounties.size()
	if count == 0:
		return
	_selected_idx = (_selected_idx + dir + count) % count
	_update_cursor()
	_update_detail(_bounties[_selected_idx])
	var bid: String  = _bounties[_selected_idx].get("id", "")
	var row: Control = _row_map.get(bid, null)
	if _scroll and row:
		_scroll.ensure_control_visible(row)


func _try_drop() -> void:
	if _bounties.is_empty():
		return
	var bounty: Dictionary = _bounties[_selected_idx]
	if bounty.get("status") == "turned_in":
		return
	_show_drop_confirm(bounty)


# ── Theme ─────────────────────────────────────────────────────────────────────

func _on_theme_changed() -> void:
	_close_confirm()
	if _ref:
		_ref.queue_free()
	_ref         = null
	_list        = null
	_detail_pane = null
	_scroll      = null
	_row_map.clear()
	_bounties.clear()
	_build_ui()
	_input_guard = true
	_refresh()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	_ref = Control.new()
	_ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ref.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ref)

	var dim := ColorRect.new()
	dim.color = UITheme.overlay(0.60)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ref.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.04
	panel.anchor_top    = 0.04
	panel.anchor_right  = 0.96
	panel.anchor_bottom = 0.96
	panel.add_theme_stylebox_override("panel", _panel_style())
	_ref.add_child(panel)

	var outer := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(outer)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	outer.add_child(main_vbox)

	main_vbox.add_child(_lbl("Active Bounties", 30, UITheme.gold()))
	main_vbox.add_child(_hsep())

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	main_vbox.add_child(content)

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

	content.add_child(_vsep())

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

	var hint := _lbl("↑↓  Navigate     [A]  Drop Bounty     [B]  Back", 14, UITheme.hint())
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(hint)


# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_bounties.clear()
	_row_map.clear()

	var active: Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool: return b.get("status") != "turned_in"
	)

	if active.is_empty():
		_list.add_child(_lbl("  No active contracts.", 18, UITheme.dim()))
	else:
		for bounty: Dictionary in active:
			var row: HBoxContainer = _bounty_row(bounty)
			var bid: String = bounty.get("id", "")
			_list.add_child(row)
			_row_map[bid] = row
			_bounties.append(bounty)

	_selected_idx = clampi(_selected_idx, 0, max(0, _bounties.size() - 1))
	_update_cursor()
	_update_detail(_bounties[_selected_idx] if not _bounties.is_empty() else {})


# ── Row builder ───────────────────────────────────────────────────────────────

func _bounty_row(bounty: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 58)

	var thumb := TextureRect.new()
	thumb.texture             = _get_texture(bounty.get("monster_type", ""))
	thumb.custom_minimum_size = Vector2(72, 54)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.modulate            = Color(1.0, 1.0, 1.0, 0.80)
	row.add_child(thumb)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 3)
	row.add_child(text_col)

	var display: String = bounty.get("display_name", bounty.get("id", ""))
	var zone   : String = _ZONE_LABELS.get(bounty.get("zone", ""), bounty.get("zone", ""))
	var killed : int    = int(bounty.get("killed", 0))
	var total  : int    = int(bounty.get("quantity", 0))
	var status : String = bounty.get("status", "active")

	text_col.add_child(_lbl(display + "  —  " + zone, 18, UITheme.text()))

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
		var empty := _lbl("No active contracts.", 18, UITheme.dim())
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail_pane.add_child(empty)
		return

	var monster_type: String = bounty.get("monster_type", "")
	var quantity    : int    = int(bounty.get("quantity", 0))
	var killed      : int    = int(bounty.get("killed", 0))
	var zone        : String = bounty.get("zone", "")
	var flavor      : String = bounty.get("flavor", "")
	var display     : String = bounty.get("display_name", bounty.get("id", ""))
	var diff        : String = SceneManager.difficulty_label(monster_type)
	var size_s      : String = SceneManager.size_label(quantity)
	var zone_s      : String = _ZONE_LABELS.get(zone, zone)
	var status      : String = bounty.get("status", "active")
	var reward      : String = bounty.get("reward_text", "")

	var tex: Texture2D = _get_texture(monster_type)
	if tex:
		var img := TextureRect.new()
		img.texture               = tex
		img.custom_minimum_size   = Vector2(0, 170)
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_detail_pane.add_child(img)

	var name_lbl := _lbl(display, 24, UITheme.gold())
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_pane.add_child(name_lbl)

	_detail_pane.add_child(_lbl("%s  ·  %s  ·  %s" % [zone_s, diff, size_s], 15, UITheme.section()))
	_detail_pane.add_child(_hsep())

	var flavor_lbl := _lbl(flavor, 16, UITheme.text())
	flavor_lbl.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	flavor_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_pane.add_child(flavor_lbl)

	_detail_pane.add_child(_hsep())

	var prog_text : String
	var prog_color: Color
	if status == "complete":
		prog_text  = "Complete — ready to turn in"
		prog_color = _C_COMPLETE
	else:
		prog_text  = "Progress:  %d / %d" % [killed, quantity]
		prog_color = _C_PROGRESS
	_detail_pane.add_child(_lbl(prog_text, 16, prog_color))
	_detail_pane.add_child(_lbl("Reward:  %s" % reward, 16, UITheme.gold()))
	_detail_pane.add_child(_hsep())

	var drop_lbl := _lbl("[A]  Drop this contract", 15, _C_WARNING)
	drop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_pane.add_child(drop_lbl)


# ── Cursor ────────────────────────────────────────────────────────────────────

func _update_cursor() -> void:
	if _bounties.is_empty():
		return
	var sel: Dictionary = _bounties[_selected_idx]
	for bounty: Dictionary in _bounties:
		var bid     : String  = bounty.get("id", "")
		var row     : Control = _row_map.get(bid, null)
		if not row or row.get_child_count() < 2:
			continue
		var text_col: Control = row.get_child(1)
		if text_col.get_child_count() < 1:
			continue
		var name_lbl: Label = text_col.get_child(0) as Label
		if not (name_lbl is Label):
			continue
		var is_sel  : bool   = (bounty == sel)
		var display : String = bounty.get("display_name", bounty.get("id", ""))
		var zone    : String = _ZONE_LABELS.get(bounty.get("zone", ""), bounty.get("zone", ""))
		name_lbl.text = ("▶  " if is_sel else "    ") + display + "  —  " + zone
		name_lbl.add_theme_color_override("font_color", UITheme.gold() if is_sel else UITheme.text())


# ── Drop Confirm ──────────────────────────────────────────────────────────────

func _show_drop_confirm(bounty: Dictionary) -> void:
	_close_confirm()
	_confirm_rows.clear()
	_confirm_actions.clear()
	_confirm_sel = 0

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var bg := ColorRect.new()
	bg.color = UITheme.overlay(0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color     = UITheme.bg(0.97)
	style.border_color = UITheme.border()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var display: String = bounty.get("display_name", bounty.get("id", ""))
	var title := _lbl("Drop  \"%s\"?" % display, 26, UITheme.gold())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	vbox.add_child(_hsep())

	var warn := _lbl(
		"Dropping this contract will reset all kill progress\nand return it to the bounty board.",
		17, _C_WARNING)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(warn)

	var bid: String = bounty.get("id", "")
	var on_yes := func() -> void:
		_close_confirm()
		SceneManager.drop_bounty(bid)
		_selected_idx = 0
		_refresh()
	var on_no := func() -> void:
		_close_confirm()

	for pair: Array in [["Yes, drop it", on_yes], ["No, keep it", on_no]]:
		var lbl := _lbl(pair[0] as String, 22, UITheme.dim())
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cb: Callable = pair[1] as Callable
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				cb.call()
		)
		vbox.add_child(lbl)
		_confirm_rows.append(lbl)
		_confirm_actions.append(cb)

	_confirm_overlay = root
	_highlight_confirm()


func _highlight_confirm() -> void:
	for i in _confirm_rows.size():
		_confirm_rows[i].add_theme_color_override(
			"font_color", UITheme.gold() if i == _confirm_sel else UITheme.dim()
		)


func _close_confirm() -> void:
	if _confirm_overlay:
		_confirm_overlay.queue_free()
		_confirm_overlay = null
	_confirm_rows.clear()
	_confirm_actions.clear()
	_confirm_sel = 0


# ── Helpers ───────────────────────────────────────────────────────────────────

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _get_texture(monster_type: String) -> Texture2D:
	match monster_type:
		"slime1":   return _tex_slime1
		"slime2":   return _tex_slime2
		"slime3":   return _tex_slime3
		"orc1":     return _tex_orc1
		"orc2":     return _tex_orc2
		"orc3":     return _tex_orc3
		"plant1":   return _tex_plant1
		"plant2":   return _tex_plant2
		"plant3":   return _tex_plant3
		"vampire1": return _tex_vampire1
		"vampire2": return _tex_vampire2
		"vampire3": return _tex_vampire3
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
	var bc    : Color = UITheme.border()
	var style := StyleBoxFlat.new()
	style.bg_color              = Color(bc.r, bc.g, bc.b, 0.40)
	style.content_margin_top    = 1.0
	style.content_margin_bottom = 1.0
	s.add_theme_stylebox_override("separator", style)
	return s


func _vsep() -> VSeparator:
	var s     := VSeparator.new()
	var bc    : Color = UITheme.border()
	var style := StyleBoxFlat.new()
	style.bg_color               = Color(bc.r, bc.g, bc.b, 0.45)
	style.content_margin_left    = 1.0
	style.content_margin_right   = 1.0
	s.add_theme_stylebox_override("separator", style)
	return s


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.bg(0.97)
	sb.set_border_width_all(2)
	sb.border_color = UITheme.border()
	sb.set_corner_radius_all(6)
	return sb
