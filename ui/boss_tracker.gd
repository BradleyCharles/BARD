extends CanvasLayer

const _FONT_PATH  := "res://fonts/almendra.regular.ttf"
const BAR_WIDTH   : float = 150.0
const BAR_HEIGHT  : float = 20.0
const MARGIN      : float = 16.0

# Semantic family colours and bar-bg — same in both themes.
const _C_BAR_BG  := Color(0.18, 0.14, 0.06, 1.0)
const _C_SLIME   := Color(0.20, 0.75, 0.45, 1.0)
const _C_ORC     := Color(0.80, 0.45, 0.15, 1.0)
const _C_PLANT   := Color(0.35, 0.70, 0.20, 1.0)
const _C_VAMPIRE := Color(0.65, 0.15, 0.75, 1.0)

var _font         : Font           = null
var _panel        : PanelContainer = null
var _panel_style  : StyleBoxFlat   = null
var _heading_lbl  : Label          = null
var _threshold    : int            = 20
var _family_rows  : Array          = []


func _ready() -> void:
	layer = 5
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	SceneManager.theme_changed.connect(_apply_theme)


func init(threshold: int) -> void:
	_threshold = threshold
	_build_ui()


## Called by field.gd on every non-testing mob kill for that family.
## family: "slime" | "orc" | "plant" | "vampire"
func set_family(family: String, count: int, spawned: bool) -> void:
	for entry in _family_rows:
		if entry["key"] == family:
			entry["count"]   = count
			entry["spawned"] = spawned
			_refresh_row(entry)
			_sync_panel_visibility()
			return


func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	_panel = PanelContainer.new()
	_panel.anchor_left    = 0.0
	_panel.anchor_top     = 1.0
	_panel.anchor_right   = 0.0
	_panel.anchor_bottom  = 1.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left     = MARGIN
	_panel.offset_bottom   = -MARGIN

	_panel_style = StyleBoxFlat.new()
	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(4)
	_panel_style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", _panel_style)
	ref.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_panel.add_child(vbox)

	_heading_lbl = Label.new()
	_heading_lbl.text = "BOSS SUMMONS"
	_heading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading_lbl.add_theme_font_size_override("font_size", 23)
	if _font:
		_heading_lbl.add_theme_font_override("font", _font)
	vbox.add_child(_heading_lbl)

	_family_rows = [
		_build_row(vbox, "slime",   "Slime",   _C_SLIME),
		_build_row(vbox, "orc",     "Orc",     _C_ORC),
		_build_row(vbox, "plant",   "Plant",   _C_PLANT),
		_build_row(vbox, "vampire", "Vampire", _C_VAMPIRE),
	]

	_panel.hide()
	_apply_theme()


func _build_row(
		parent: VBoxContainer, key: String, label_text: String, fill_color: Color
) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.hide()
	parent.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.custom_minimum_size = Vector2(72.0, 0.0)
	name_lbl.add_theme_font_size_override("font_size", 20)
	if _font:
		name_lbl.add_theme_font_override("font", _font)
	row.add_child(name_lbl)

	var bar_bg := ColorRect.new()
	bar_bg.color = _C_BAR_BG
	bar_bg.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	row.add_child(bar_bg)

	var fill := ColorRect.new()
	fill.color = fill_color
	fill.size  = Vector2(0.0, BAR_HEIGHT)
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_bg.add_child(fill)

	var count_lbl := Label.new()
	count_lbl.text = "0/%d" % _threshold
	count_lbl.custom_minimum_size = Vector2(52.0, 0.0)
	count_lbl.add_theme_font_size_override("font_size", 20)
	if _font:
		count_lbl.add_theme_font_override("font", _font)
	row.add_child(count_lbl)

	return {
		"key":         key,
		"row":         row,
		"fill":        fill,
		"name_lbl":    name_lbl,
		"count_label": count_lbl,
		"count":       0,
		"spawned":     false,
	}


func _apply_theme() -> void:
	if _panel_style:
		_panel_style.bg_color     = UITheme.bg(0.90)
		_panel_style.border_color = UITheme.border_dim()
	if _heading_lbl:
		_heading_lbl.add_theme_color_override("font_color", UITheme.text())
	for entry in _family_rows:
		var name_lbl  : Label = entry.get("name_lbl")  as Label
		var count_lbl : Label = entry.get("count_label") as Label
		if name_lbl:
			name_lbl.add_theme_color_override("font_color", UITheme.text())
		if count_lbl:
			count_lbl.add_theme_color_override("font_color", UITheme.text())


func _refresh_row(entry: Dictionary) -> void:
	var count  : int         = entry["count"]
	var spawned: bool        = entry["spawned"]
	var row    : HBoxContainer = entry["row"] as HBoxContainer
	row.visible = count > 0 and not spawned

	if row.visible:
		var fill      : ColorRect = entry["fill"] as ColorRect
		var count_lbl : Label     = entry["count_label"] as Label
		fill.size      = Vector2(BAR_WIDTH * float(count) / float(_threshold), BAR_HEIGHT)
		count_lbl.text = "%d/%d" % [count, _threshold]


func _sync_panel_visibility() -> void:
	var any_visible: bool = false
	for entry in _family_rows:
		var row: HBoxContainer = entry["row"] as HBoxContainer
		if row.visible:
			any_visible = true
			break
	_panel.visible = any_visible
