extends CanvasLayer

## Passive HUD overlay — bottom-right corner — showing the player's active bounties.
## Built entirely in code; attach this script to a CanvasLayer node (layer = 15
## sits above the game world but below dialogue and the bounty board).
##
## Lifecycle: always present in the scene, hides its panel when there is nothing
## to show. Rebuilds instantly whenever SceneManager emits bounties_updated.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG       := Color(0.06, 0.04, 0.03, 0.80)
const _C_BORDER   := Color(0.40, 0.30, 0.14, 0.65)
const _C_HEADER   := Color(0.68, 0.55, 0.28, 1.0)
const _C_ACTIVE   := Color(0.82, 0.76, 0.64, 1.0)
const _C_COMPLETE := Color(0.48, 0.74, 0.42, 0.85)

var _font  : Font
var _panel : PanelContainer
var _list  : VBoxContainer


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.bounties_updated.connect(_rebuild)
	_rebuild()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Full-rect reference so child anchors resolve against the viewport
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	_panel = PanelContainer.new()
	# Anchor all four corners to the bottom-right of the viewport
	_panel.anchor_left   = 1.0
	_panel.anchor_top    = 1.0
	_panel.anchor_right  = 1.0
	_panel.anchor_bottom = 1.0
	# Grow inward (left and up) from that anchor point
	_panel.grow_horizontal        = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical          = Control.GROW_DIRECTION_BEGIN
	_panel.offset_right           = -16.0
	_panel.offset_bottom          = -16.0
	_panel.custom_minimum_size    = Vector2(264.0, 0.0)
	_panel.add_theme_stylebox_override("panel", _panel_style())
	ref.add_child(_panel)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  8)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var header := Label.new()
	header.layout_mode = 2
	header.text = "BOUNTIES"
	if _font:
		header.add_theme_font_override("font", _font)
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", _C_HEADER)
	vbox.add_child(header)

	var sep       := HSeparator.new()
	sep.layout_mode = 2
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color              = Color(_C_BORDER.r, _C_BORDER.g, _C_BORDER.b, 0.5)
	sep_style.content_margin_top    = 1.0
	sep_style.content_margin_bottom = 1.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	_list = VBoxContainer.new()
	_list.layout_mode = 2
	_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_list)


# ── Rebuild ───────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	_clear()

	var entries : Array = SceneManager.active_bounties.filter(
		func(b: Dictionary) -> bool:
			var s : String = b.get("status", "")
			return s == "active" or s == "complete"
	)

	if entries.is_empty():
		_panel.hide()
		return

	_panel.show()
	for bounty in entries:
		_list.add_child(_make_entry(bounty))


func _make_entry(bounty: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.layout_mode = 2
	container.add_theme_constant_override("separation", 2)

	var flavor : String = bounty.get("flavor", "")
	var status : String = bounty.get("status", "active")

	var flavor_lbl := RichTextLabel.new()
	flavor_lbl.layout_mode   = 2
	flavor_lbl.bbcode_enabled = true
	flavor_lbl.fit_content    = true
	flavor_lbl.scroll_active  = false
	flavor_lbl.custom_minimum_size = Vector2(244.0, 0.0)
	if _font:
		flavor_lbl.add_theme_font_override("normal_font", _font)
	flavor_lbl.add_theme_font_size_override("normal_font_size", 16)

	if status == "complete":
		flavor_lbl.text = "[s]" + flavor + "[/s]"
		flavor_lbl.add_theme_color_override("default_color", _C_COMPLETE)
	else:
		flavor_lbl.text = flavor
		flavor_lbl.add_theme_color_override("default_color", _C_ACTIVE)

	container.add_child(flavor_lbl)

	if status == "active":
		var killed   : int = bounty.get("killed",   0)
		var quantity : int = bounty.get("quantity",  0)
		var remaining : int = max(0, quantity - killed)

		var counter_lbl := Label.new()
		counter_lbl.layout_mode = 2
		counter_lbl.text = "%d / %d killed" % [killed, quantity]
		if _font:
			counter_lbl.add_theme_font_override("font", _font)
		counter_lbl.add_theme_font_size_override("font_size", 13)
		counter_lbl.add_theme_color_override("font_color",
			_C_COMPLETE if remaining == 0 else Color(0.60, 0.55, 0.42, 1.0))
		container.add_child(counter_lbl)

	return container


# ── Style ─────────────────────────────────────────────────────────────────────

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color            = _C_BG
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_color               = _C_BORDER
	sb.corner_radius_top_left     = 3
	sb.corner_radius_top_right    = 3
	sb.corner_radius_bottom_left  = 3
	sb.corner_radius_bottom_right = 3
	return sb


# ── Internals ─────────────────────────────────────────────────────────────────

func _clear() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
