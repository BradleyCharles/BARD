extends CanvasLayer

## Top-center HUD that shows the name of the nearest interactable (NPC or bounty board)
## when the player enters its detection range. Added by town.gd at startup.
## NPCs and interactable objects call show_interactable / hide_interactable via group lookup.

const _FONT_PATH  := "res://fonts/almendra.regular.ttf"
const _C_BG       := Color(0.07, 0.05, 0.03, 0.88)
const _C_BORDER   := Color(0.50, 0.40, 0.20, 0.80)
const _C_GOLD     := Color(0.95, 0.85, 0.45, 1.0)
const _C_DIM      := Color(0.75, 0.65, 0.40, 0.85)

var _panel          : PanelContainer
var _name_lbl       : Label
var _title_lbl      : Label
var _current_source : Node = null


func _ready() -> void:
	layer = 30
	add_to_group("interaction_indicator")
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	var font : Font = null
	if ResourceLoader.exists(_FONT_PATH):
		font = load(_FONT_PATH)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.custom_minimum_size = Vector2(0.0, 80.0)
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical   = Control.GROW_DIRECTION_END
	_panel.position.y      = 14.0

	var style := StyleBoxFlat.new()
	style.bg_color     = _C_BG
	style.border_color = _C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12.0)
	style.content_margin_left  = 24.0
	style.content_margin_right = 24.0
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.add_theme_font_size_override("font_size", 30)
	_name_lbl.add_theme_color_override("font_color", _C_GOLD)
	if font:
		_name_lbl.add_theme_font_override("font", font)
	vbox.add_child(_name_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 22)
	_title_lbl.add_theme_color_override("font_color", _C_DIM)
	if font:
		_title_lbl.add_theme_font_override("font", font)
	_title_lbl.visible = false
	vbox.add_child(_title_lbl)


func show_interactable(label_text: String, source: Node, title: String = "") -> void:
	_current_source    = source
	_name_lbl.text     = label_text
	_title_lbl.text    = title
	_title_lbl.visible = title != ""
	_panel.visible     = true


func hide_interactable(source: Node) -> void:
	if source == _current_source:
		_current_source = null
		_panel.visible  = false
