extends CanvasLayer

## Scripts currency HUD — top-left corner, below health bar. Rebuilds on scripts_updated / inventory_updated signals.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_GOOP := Color(0.70, 0.50, 0.90, 1.0)

var _font        : Font
var _scripts_lbl : Label
var _goop_lbl    : Label
var _panel_style : StyleBoxFlat


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.scripts_updated.connect(_update)
	SceneManager.inventory_updated.connect(_update)
	SceneManager.theme_changed.connect(_apply_theme)
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

	_panel_style = StyleBoxFlat.new()
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(4)
	_panel_style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", _panel_style)
	ref.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	_scripts_lbl = Label.new()
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

	_apply_theme()


func _apply_theme() -> void:
	if _panel_style:
		_panel_style.bg_color     = UITheme.bg(0.80)
		_panel_style.border_color = UITheme.border_dim()
	if _scripts_lbl:
		_scripts_lbl.add_theme_color_override("font_color", UITheme.gold())


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
