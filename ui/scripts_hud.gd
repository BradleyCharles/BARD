extends CanvasLayer

## Scripts currency HUD — top-right corner. Rebuilds on scripts_updated signal.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG     := Color(0.06, 0.04, 0.03, 0.80)
const _C_BORDER := Color(0.40, 0.30, 0.14, 0.65)
const _C_TEXT   := Color(0.95, 0.85, 0.45, 1.0)

var _font  : Font
var _label : Label


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.scripts_updated.connect(_update)
	_update()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	var panel := PanelContainer.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 0.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical   = Control.GROW_DIRECTION_END
	panel.offset_left  = -10.0
	panel.offset_top   = 10.0

	var style := StyleBoxFlat.new()
	style.bg_color     = _C_BG
	style.border_color = _C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	ref.add_child(panel)

	_label = Label.new()
	_label.add_theme_color_override("font_color", _C_TEXT)
	_label.add_theme_font_size_override("font_size", 22)
	if _font:
		_label.add_theme_font_override("font", _font)
	panel.add_child(_label)


func _update() -> void:
	if _label:
		_label.text = "Scripts: %d" % SceneManager.scripts
