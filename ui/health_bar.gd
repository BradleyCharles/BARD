extends CanvasLayer

## Health bar HUD — top-left corner. Reacts to SceneManager.player_health_changed.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG       := Color(0.06, 0.04, 0.03, 0.80)
const _C_BORDER   := Color(0.40, 0.30, 0.14, 0.65)
const _C_BAR_BG   := Color(0.20, 0.08, 0.08, 1.0)
const _C_BAR_FILL := Color(0.78, 0.20, 0.20, 1.0)
const _C_BAR_LOW  := Color(0.90, 0.55, 0.10, 1.0)
const _C_TEXT     := Color(0.95, 0.85, 0.45, 1.0)

const BAR_WIDTH  : float = 180.0
const BAR_HEIGHT : float = 14.0

var _font      : Font
var _fill_rect : ColorRect
var _label     : Label


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.player_health_changed.connect(_update)
	_update()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
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
	panel.offset_top  = 10.0

	var style := StyleBoxFlat.new()
	style.bg_color     = _C_BG
	style.border_color = _C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	ref.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_label = Label.new()
	_label.add_theme_color_override("font_color", _C_TEXT)
	_label.add_theme_font_size_override("font_size", 23)
	if _font:
		_label.add_theme_font_override("font", _font)
	vbox.add_child(_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = _C_BAR_BG
	bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	vbox.add_child(bar_bg)

	_fill_rect = ColorRect.new()
	_fill_rect.color = _C_BAR_FILL
	_fill_rect.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_bg.add_child(_fill_rect)


func _update() -> void:
	if _label == null:
		return
	var hp  : int = SceneManager.player_health
	var max_hp : int = SceneManager.player_max_health
	_label.text = "HP  %d / %d" % [hp, max_hp]

	var pct := float(hp) / float(max_hp) if max_hp > 0 else 0.0
	_fill_rect.size = Vector2(BAR_WIDTH * pct, BAR_HEIGHT)
	_fill_rect.color = _C_BAR_LOW if pct <= 0.3 else _C_BAR_FILL
