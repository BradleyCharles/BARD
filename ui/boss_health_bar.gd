extends CanvasLayer

const _FONT_PATH := "res://fonts/almendra.regular.ttf"
const BAR_WIDTH  : float = 600.0
const BAR_HEIGHT : float = 22.0

const _C_BG       := Color(0.06, 0.04, 0.03, 0.92)
const _C_BORDER   := Color(0.60, 0.20, 0.20, 0.85)
const _C_BAR_BG   := Color(0.20, 0.08, 0.08, 1.0)
const _C_BAR_FILL := Color(0.90, 0.15, 0.15, 1.0)
const _C_TEXT     := Color(1.00, 0.80, 0.80, 1.0)

var _font     : Font      = null
var _fill_rect: ColorRect = null
var _label    : Label     = null
var _boss_ref : Node      = null


func _ready() -> void:
	layer = 20
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	hide()


func init(boss: Node) -> void:
	_boss_ref = boss
	boss.died.connect(_on_boss_died)
	show()
	_update()


func _process(_delta: float) -> void:
	if _boss_ref != null and is_instance_valid(_boss_ref):
		_update()


func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	var panel := PanelContainer.new()
	panel.anchor_left    = 0.5
	panel.anchor_top     = 0.0
	panel.anchor_right   = 0.5
	panel.anchor_bottom  = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_top     = 14.0

	var style := StyleBoxFlat.new()
	style.bg_color   = _C_BG
	style.border_color = _C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	ref.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	_label = Label.new()
	_label.text                 = "BOSS"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", _C_TEXT)
	if _font:
		_label.add_theme_font_override("font", _font)
	vbox.add_child(_label)

	var bar_bg := ColorRect.new()
	bar_bg.color              = _C_BAR_BG
	bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	vbox.add_child(bar_bg)

	_fill_rect = ColorRect.new()
	_fill_rect.color = _C_BAR_FILL
	_fill_rect.size  = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_fill_rect.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_bg.add_child(_fill_rect)


func _update() -> void:
	if _boss_ref == null or not is_instance_valid(_boss_ref):
		return
	var hp     : int = _boss_ref.health
	var max_hp : int = _boss_ref.max_health
	_label.text = "BOSS  %d / %d" % [hp, max_hp]
	var pct := float(hp) / float(max_hp) if max_hp > 0 else 0.0
	_fill_rect.size = Vector2(BAR_WIDTH * pct, BAR_HEIGHT)


func _on_boss_died(_mob: Node) -> void:
	_boss_ref = null
	hide()
	queue_free()
