extends CanvasLayer

## Top-center HUD that shows the name of the nearest interactable (NPC or bounty board)
## when the player enters its detection range. Added by town.gd at startup.
## NPCs and interactable objects call show_interactable / hide_interactable via group lookup.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

var _panel          : PanelContainer
var _panel_style    : StyleBoxFlat
var _name_lbl       : Label
var _title_lbl      : Label
var _current_source : Node = null


func _ready() -> void:
	layer = 30
	add_to_group("interaction_indicator")
	_build_ui()
	_panel.visible = false
	SceneManager.theme_changed.connect(_apply_theme)


func _build_ui() -> void:
	var font: Font = null
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

	_panel_style = StyleBoxFlat.new()
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(4)
	_panel_style.set_content_margin_all(12.0)
	_panel_style.content_margin_left  = 24.0
	_panel_style.content_margin_right = 24.0
	_panel.add_theme_stylebox_override("panel", _panel_style)
	root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.add_theme_font_size_override("font_size", 30)
	if font:
		_name_lbl.add_theme_font_override("font", font)
	vbox.add_child(_name_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 22)
	if font:
		_title_lbl.add_theme_font_override("font", font)
	_title_lbl.visible = false
	vbox.add_child(_title_lbl)

	_apply_theme()


func _apply_theme() -> void:
	if _panel_style:
		_panel_style.bg_color     = UITheme.bg(0.88)
		_panel_style.border_color = UITheme.border()
	if _name_lbl:
		_name_lbl.add_theme_color_override("font_color", UITheme.gold())
	if _title_lbl:
		_title_lbl.add_theme_color_override("font_color", UITheme.dim(0.85))


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
