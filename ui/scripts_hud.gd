extends CanvasLayer

## Scripts currency HUD — top-left corner, below health bar. Rebuilds on scripts_updated / inventory_updated signals.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG     := Color(0.06, 0.04, 0.03, 0.80)
const _C_BORDER := Color(0.40, 0.30, 0.14, 0.65)
const _C_TEXT   := Color(0.95, 0.85, 0.45, 1.0)
const _C_GOOP   := Color(0.70, 0.50, 0.90, 1.0)

var _font        : Font
var _scripts_lbl : Label
var _goop_lbl    : Label


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.scripts_updated.connect(_update)
	SceneManager.inventory_updated.connect(_update)
	_update()


# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	var panel := PanelContainer.new()
	panel.anchor_left    = 0.0
	panel.anchor_top     = 0.0
	panel.anchor_right   = 0.0
	panel.anchor_bottom  = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical   = Control.GROW_DIRECTION_END
	panel.offset_left  = 10.0
	panel.offset_top   = 90.0

	var style := StyleBoxFlat.new()
	style.bg_color     = _C_BG
	style.border_color = _C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	ref.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	_scripts_lbl = Label.new()
	_scripts_lbl.add_theme_color_override("font_color", _C_TEXT)
	_scripts_lbl.add_theme_font_size_override("font_size", 27)
	if _font:
		_scripts_lbl.add_theme_font_override("font", _font)
	vbox.add_child(_scripts_lbl)

	_goop_lbl = Label.new()
	_goop_lbl.add_theme_color_override("font_color", _C_GOOP)
	_goop_lbl.add_theme_font_size_override("font_size", 20)
	if _font:
		_goop_lbl.add_theme_font_override("font", _font)
	_goop_lbl.hide()
	vbox.add_child(_goop_lbl)


func _update() -> void:
	if _scripts_lbl:
		_scripts_lbl.text = "Scripts: %d" % SceneManager.scripts
	if _goop_lbl:
		var goop: int = SceneManager.slime_goop
		if goop > 0:
			_goop_lbl.text = "Slime Goop: %d" % goop
			_goop_lbl.show()
		else:
			_goop_lbl.hide()
