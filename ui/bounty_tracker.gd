extends CanvasLayer

## Passive HUD overlay — top-right corner — showing the player's active bounties.
## Built entirely in code; attach this script to a CanvasLayer node (layer = 15
## sits above the game world but below dialogue and the bounty board).
##
## Lifecycle: always present in the scene, hides its panel when there is nothing
## to show. Rebuilds instantly whenever SceneManager emits bounties_updated.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

# Semantic status colours — same in both themes.
const _C_COMPLETE := Color(0.48, 0.74, 0.42, 0.85)

var _font        : Font
var _panel       : PanelContainer
var _panel_style : StyleBoxFlat
var _header_lbl  : Label
var _sep_style   : StyleBoxFlat
var _list        : VBoxContainer


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.bounties_updated.connect(_rebuild)
	SceneManager.theme_changed.connect(_on_theme_changed)
	_rebuild()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	_panel = PanelContainer.new()
	_panel.anchor_left   = 1.0
	_panel.anchor_top    = 0.0
	_panel.anchor_right  = 1.0
	_panel.anchor_bottom = 0.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical   = Control.GROW_DIRECTION_END
	_panel.offset_right    = -16.0
	_panel.offset_top      = 16.0
	_panel.custom_minimum_size = Vector2(264.0, 0.0)

	_panel_style = StyleBoxFlat.new()
	_panel_style.set_border_width_all(1)
	_panel_style.corner_radius_top_left     = 3
	_panel_style.corner_radius_top_right    = 3
	_panel_style.corner_radius_bottom_left  = 3
	_panel_style.corner_radius_bottom_right = 3
	_panel.add_theme_stylebox_override("panel", _panel_style)
	ref.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  8)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	_header_lbl = Label.new()
	_header_lbl.text = "BOUNTIES"
	if _font:
		_header_lbl.add_theme_font_override("font", _font)
	_header_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_header_lbl)

	var sep := HSeparator.new()
	_sep_style = StyleBoxFlat.new()
	_sep_style.content_margin_top    = 1.0
	_sep_style.content_margin_bottom = 1.0
	sep.add_theme_stylebox_override("separator", _sep_style)
	vbox.add_child(sep)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_list)

	_apply_theme()


func _apply_theme() -> void:
	if _panel_style:
		_panel_style.bg_color     = UITheme.bg(0.80)
		_panel_style.border_color = UITheme.border_dim()
	if _sep_style:
		var bc: Color = UITheme.border_dim()
		_sep_style.bg_color = Color(bc.r, bc.g, bc.b, 0.5)
	if _header_lbl:
		_header_lbl.add_theme_color_override("font_color", UITheme.section())


func _on_theme_changed() -> void:
	_apply_theme()
	_rebuild()


# ── Rebuild ───────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	_clear()

	var entries: Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool:
			var s: String = b.get("status", "")
			return s == "active" or s == "complete"
	)

	if entries.is_empty():
		_panel.hide()
		return

	_panel.show()
	for bounty in entries:
		_list.add_child(_make_entry(bounty))


func _make_entry(bounty: Dictionary) -> Control:
	var zone_labels: Dictionary = {
		"zone_a": "Zone A", "zone_b": "Zone B", "zone_c": "Zone C"
	}
	var zone        : String = zone_labels.get(bounty.get("zone", ""), bounty.get("zone", ""))
	var quantity    : int    = bounty.get("quantity", 0)
	var killed      : int    = bounty.get("killed", 0)
	var status      : String = bounty.get("status", "active")
	var monster_type: String = bounty.get("monster_type", "")
	var short_text  : String = "%s — %d / %d %s" % [zone, killed, quantity, monster_type]

	var lbl := Label.new()
	lbl.text = short_text
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override(
		"font_color", _C_COMPLETE if status == "complete" else UITheme.text()
	)
	return lbl


# ── Internals ─────────────────────────────────────────────────────────────────

func _clear() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
