extends CanvasLayer

## Day counter HUD — sits below the health bar in the top-left corner.
## Reacts to SceneManager.day_updated. Added to the scene tree by SceneManager
## on startup so it persists across scene transitions.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

var _label       : Label
var _panel_style : StyleBoxFlat


func _ready() -> void:
	layer = 5
	var font: Font = null
	if ResourceLoader.exists(_FONT_PATH):
		font = load(_FONT_PATH)
	_build_ui(font)
	SceneManager.day_updated.connect(_update)
	SceneManager.theme_changed.connect(_apply_theme)
	_update()


func _build_ui(font: Font) -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.0
	panel.anchor_top    = 0.0
	panel.anchor_right  = 0.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical   = Control.GROW_DIRECTION_END
	panel.offset_left = 10.0
	panel.offset_top  = 170.0

	_panel_style = StyleBoxFlat.new()
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(4)
	_panel_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", _panel_style)
	ref.add_child(panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 23)
	if font:
		_label.add_theme_font_override("font", font)
	panel.add_child(_label)

	_apply_theme()


func _apply_theme() -> void:
	if _panel_style:
		_panel_style.bg_color     = UITheme.bg(0.80)
		_panel_style.border_color = UITheme.border_dim()
	if _label:
		_label.add_theme_color_override("font_color", UITheme.gold())


func _update() -> void:
	if _label == null:
		return
	_label.text = "Day  %d" % SceneManager.day
