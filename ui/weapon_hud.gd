extends CanvasLayer

## Weapon slot HUD — bottom-center.
## Shows sword and axe slots; highlights the active weapon,
## dims locked (unowned) weapons.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"

const _C_BG            := Color(0.06, 0.04, 0.03, 0.80)
const _C_BORDER        := Color(0.40, 0.30, 0.14, 0.65)
const _C_ACTIVE_BORDER := Color(0.95, 0.85, 0.45, 0.90)
const _C_ACTIVE_TEXT   := Color(0.95, 0.85, 0.45, 1.0)
const _C_LOCKED_TEXT   := Color(0.40, 0.38, 0.32, 0.70)

const WEAPONS_ORDER  := ["sword", "axe"]
const WEAPON_LABELS  := {"sword": "Sword", "axe": "Axe"}

var _font        : Font          = null
var _slot_panels : Dictionary    = {}
var _slot_labels : Dictionary    = {}
var _player_ref  : Node          = null


func _ready() -> void:
	layer = 6
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	SceneManager.inventory_updated.connect(_rebuild)
	call_deferred("_connect_player")


func _connect_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
		if _player_ref.has_signal("weapon_changed"):
			_player_ref.weapon_changed.connect(_on_weapon_changed)
	_rebuild()


func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	var hbox := HBoxContainer.new()
	hbox.anchor_left    = 0.5
	hbox.anchor_top     = 1.0
	hbox.anchor_right   = 0.5
	hbox.anchor_bottom  = 1.0
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	hbox.offset_bottom   = -16.0
	hbox.add_theme_constant_override("separation", 8)
	ref.add_child(hbox)

	for weapon_id in WEAPONS_ORDER:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(88, 54)

		var style := _make_style(_C_BORDER, 2)
		panel.add_theme_stylebox_override("panel", style)
		hbox.add_child(panel)

		var lbl := Label.new()
		lbl.text                 = WEAPON_LABELS.get(weapon_id, weapon_id)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", _C_LOCKED_TEXT)
		if _font:
			lbl.add_theme_font_override("font", _font)
		panel.add_child(lbl)

		_slot_panels[weapon_id] = panel
		_slot_labels[weapon_id] = lbl


func _make_style(border_color: Color, border_width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = _C_BG
	s.border_color = border_color
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(6)
	return s


func _rebuild() -> void:
	var active := "sword"
	if _player_ref != null and "active_weapon" in _player_ref:
		active = _player_ref.active_weapon
	var owned := SceneManager.owned_weapons

	for weapon_id in WEAPONS_ORDER:
		var lbl   := _slot_labels.get(weapon_id) as Label
		var panel := _slot_panels.get(weapon_id) as PanelContainer
		if lbl == null or panel == null:
			continue

		var is_owned  := weapon_id in owned
		var is_active := is_owned and (weapon_id == active)

		if is_active:
			panel.add_theme_stylebox_override("panel", _make_style(_C_ACTIVE_BORDER, 3))
			lbl.add_theme_color_override("font_color", _C_ACTIVE_TEXT)
			lbl.text = WEAPON_LABELS.get(weapon_id, weapon_id)
		elif is_owned:
			panel.add_theme_stylebox_override("panel", _make_style(_C_BORDER, 2))
			lbl.add_theme_color_override("font_color", _C_ACTIVE_TEXT)
			lbl.text = WEAPON_LABELS.get(weapon_id, weapon_id)
		else:
			panel.add_theme_stylebox_override("panel", _make_style(_C_BORDER, 1))
			lbl.add_theme_color_override("font_color", _C_LOCKED_TEXT)
			lbl.text = WEAPON_LABELS.get(weapon_id, weapon_id) + " [lock]"


func _on_weapon_changed(_weapon_name: String) -> void:
	_rebuild()
