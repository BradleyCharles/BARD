extends Node2D

## Floating speech bubble displayed above an NPC's head.
## Created and destroyed by npc_base.gd during villager exchanges.
## Fades out automatically after the display duration.

const _FONT_PATH    := "res://fonts/almendra.regular.ttf"
const _C_BG         := Color(0.07, 0.05, 0.03, 0.92)
const _C_BORDER     := Color(0.50, 0.40, 0.20, 0.80)
const _C_TEXT       := Color(0.92, 0.84, 0.68, 1.0)
const DISPLAY_TIME  : float = 4.0
const FADE_TIME     : float = 0.6
const BUBBLE_OFFSET : float = -100.0

var _elapsed : float = 0.0
var _label   : Label = null
var _panel   : PanelContainer = null


func _ready() -> void:
	var font: Font = null
	if ResourceLoader.exists(_FONT_PATH):
		font = load(_FONT_PATH)
	_build(font)


func _build(font: Font) -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color     = _C_BG
	style.border_color = _C_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(7)
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.add_theme_color_override("font_color", _C_TEXT)
	_label.add_theme_font_size_override("font_size", 16)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(180.0, 0.0)
	if font:
		_label.add_theme_font_override("font", font)
	_panel.add_child(_label)
	add_child(_panel)


func show_text(text: String) -> void:
	if _label == null:
		return
	_label.text = text
	await get_tree().process_frame
	_panel.position = Vector2(-_panel.size.x * 0.5, BUBBLE_OFFSET - _panel.size.y)
	_elapsed = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	var remaining := DISPLAY_TIME - _elapsed
	if remaining <= FADE_TIME:
		modulate.a = maxf(0.0, remaining / FADE_TIME)
	if _elapsed >= DISPLAY_TIME:
		queue_free()
