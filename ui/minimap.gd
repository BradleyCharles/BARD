extends CanvasLayer

## Minimap HUD — bottom-right corner, field scene only.
## Draws a static north-up map of the Ashfield with the player's position
## (direction-indicating arrow-circle) and enemy dots (red).
##
## Instantiated by field.gd in _ready(). field.gd calls init() after add_child()
## to supply the real world bounds, bounty zones, and TileMapLayer nodes.
##
## Tile layers are pre-rendered into an Image once at init time so _on_draw()
## only issues a single texture draw call per frame for the terrain.

const PANEL_W   : float = 375.0
const PADDING   : float = 10.0
const CAM_ZOOM  : float = 3.5   ## must match Camera2D.zoom set in field.gd
const VIEW_SCALE: float = 2.0   ## minimap shows this many times the player viewport

const _C_PANEL_BG  := Color(0.06, 0.04, 0.03, 0.88)
const _C_BORDER    := Color(0.40, 0.30, 0.14, 0.75)
const _C_MAP_BG    := Color(0.08, 0.14, 0.06, 0.95)
const _C_ZONE_A    := Color(0.25, 0.45, 0.20, 0.40)
const _C_ZONE_B    := Color(0.20, 0.35, 0.45, 0.40)
const _C_ZONE_C    := Color(0.45, 0.20, 0.20, 0.40)
const _C_ZONE_EDGE := Color(0.55, 0.55, 0.55, 0.30)
const _C_PLAYER    := Color(0.95, 0.85, 0.45, 1.0)
const _C_ENEMY     := Color(0.85, 0.15, 0.15, 1.0)
const _C_BOSS      := Color(1.0,  0.45, 0.10, 1.0)

var _world_rect  : Rect2      = Rect2(Vector2.ZERO, Vector2(3840.0, 2160.0))
var _zone_rects  : Dictionary = {}
var _panel_h     : float      = 0.0
var _map_w       : float      = 0.0
var _map_h       : float      = 0.0
var _map_origin  : Vector2

var _view_rect   : Rect2
var _canvas       : Control
var _tile_texture : ImageTexture


func _ready() -> void:
	layer = 4
	_recalc_map_dims()

	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ref)

	_canvas = Control.new()
	_canvas.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_canvas.anchor_left   = 1.0
	_canvas.anchor_top    = 1.0
	_canvas.anchor_right  = 1.0
	_canvas.anchor_bottom = 1.0
	_canvas.draw.connect(_on_draw)
	ref.add_child(_canvas)
	_apply_canvas_offsets()


## Called by field.gd after add_child.
## tile_layers: Array of {node: TileMapLayer, color: Color}
func init(world_rect: Rect2, zones: Dictionary, tile_layers: Array = []) -> void:
	_world_rect = world_rect
	_zone_rects = zones
	_recalc_map_dims()
	_apply_canvas_offsets()
	_bake_tile_texture(tile_layers)


func _recalc_map_dims() -> void:
	_map_w      = PANEL_W - PADDING * 2.0
	_map_h      = _map_w * (_world_rect.size.y / _world_rect.size.x)
	_panel_h    = _map_h + PADDING * 2.0
	_map_origin = Vector2(PADDING, PADDING)


func _apply_canvas_offsets() -> void:
	if _canvas == null:
		return
	_canvas.offset_left   = -(PANEL_W + 16.0)
	_canvas.offset_top    = -(_panel_h + 16.0)
	_canvas.offset_right  = -16.0
	_canvas.offset_bottom = -16.0


## Pre-render all tile layers into a single ImageTexture so _on_draw()
## only needs one draw_texture call per frame.
func _bake_tile_texture(layers: Array) -> void:
	if layers.is_empty():
		return

	var img_w : int = int(_map_w)
	var img_h : int = int(_map_h)
	var img := Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))

	for entry in layers:
		var layer_node : TileMapLayer = entry.get("node") as TileMapLayer
		var color      : Color        = entry.get("color", Color.WHITE)
		if layer_node == null:
			continue

		var tile_size : Vector2 = Vector2(16.0, 16.0)
		if layer_node.tile_set != null:
			tile_size = Vector2(layer_node.tile_set.tile_size)

		var tw : float = maxf(1.0, tile_size.x / _world_rect.size.x * _map_w)
		var th : float = maxf(1.0, tile_size.y / _world_rect.size.y * _map_h)
		var pw : int   = ceili(tw)
		var ph : int   = ceili(th)

		for cell in layer_node.get_used_cells():
			var local_pos : Vector2 = layer_node.map_to_local(cell)
			var world_pos : Vector2 = layer_node.to_global(local_pos)
			var nx : float = (world_pos.x - _world_rect.position.x) / _world_rect.size.x
			var ny : float = (world_pos.y - _world_rect.position.y) / _world_rect.size.y
			var px : int   = roundi(nx * _map_w - tw * 0.5)
			var py : int   = roundi(ny * _map_h - th * 0.5)

			for dy in range(ph):
				for dx in range(pw):
					var ix : int = px + dx
					var iy : int = py + dy
					if ix >= 0 and ix < img_w and iy >= 0 and iy < img_h:
						img.set_pixel(ix, iy, color)

	_tile_texture = ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	_canvas.queue_redraw()


# ── Drawing ───────────────────────────────────────────────────────────────────


func _compute_view_rect() -> void:
	var vp_size : Vector2 = get_viewport().get_visible_rect().size
	var half_w  : float   = vp_size.x / CAM_ZOOM * VIEW_SCALE * 0.5
	var half_h  : float   = vp_size.y / CAM_ZOOM * VIEW_SCALE * 0.5
	var players := get_tree().get_nodes_in_group("player")
	var center  : Vector2 = _world_rect.get_center()
	if players.size() > 0 and players[0] is Node2D:
		center = (players[0] as Node2D).global_position
	var x : float = clampf(center.x - half_w,
			_world_rect.position.x, _world_rect.end.x - half_w * 2.0)
	var y : float = clampf(center.y - half_h,
			_world_rect.position.y, _world_rect.end.y - half_h * 2.0)
	_view_rect = Rect2(Vector2(x, y), Vector2(half_w * 2.0, half_h * 2.0))

func _on_draw() -> void:
	_compute_view_rect()
	var panel_size := Vector2(PANEL_W, _panel_h)

	# 1. Panel background
	_canvas.draw_rect(Rect2(Vector2.ZERO, panel_size), _C_PANEL_BG)

	# 2. Map area background
	_canvas.draw_rect(Rect2(_map_origin, Vector2(_map_w, _map_h)), _C_MAP_BG)

	# 3. Terrain texture (pre-baked from TileMapLayers)
	if _tile_texture != null:
		# Map _view_rect into texture coordinates (baked at _world_rect scale)
		var tw : float = _tile_texture.get_width()
		var th : float = _tile_texture.get_height()
		var sx : float = (_view_rect.position.x - _world_rect.position.x) / _world_rect.size.x * tw
		var sy : float = (_view_rect.position.y - _world_rect.position.y) / _world_rect.size.y * th
		var sw : float = _view_rect.size.x / _world_rect.size.x * tw
		var sh : float = _view_rect.size.y / _world_rect.size.y * th
		var src_rect := Rect2(sx, sy, sw, sh)
		_canvas.draw_texture_rect_region(
				_tile_texture, Rect2(_map_origin, Vector2(_map_w, _map_h)), src_rect)

	# 4. Zone highlights (semi-transparent, drawn over terrain)
	var zone_colors : Array = [_C_ZONE_A, _C_ZONE_B, _C_ZONE_C]
	var zi : int = 0
	for zone_key in ["zone_a", "zone_b", "zone_c"]:
		if _zone_rects.has(zone_key):
			var zr    : Rect2 = _zone_rects[zone_key]
			var zrect := Rect2(_to_map(zr.position), _to_map(zr.end) - _to_map(zr.position))
			_canvas.draw_rect(zrect, zone_colors[zi])
			_canvas.draw_rect(zrect, _C_ZONE_EDGE, false, 1.0)
		zi += 1

	# 5. Panel border
	_canvas.draw_rect(Rect2(Vector2.ZERO, panel_size), _C_BORDER, false, 1.5)

	if not is_inside_tree():
		return

	# 6. Enemy dots
	for mob in get_tree().get_nodes_in_group("ground_mobs"):
		if not mob is Node2D:
			continue
		var mp := _to_map((mob as Node2D).global_position)
		if not _in_map_bounds(mp):
			continue
		var is_boss : bool = mob.get_meta("monster_type", "").ends_with("_boss")
		_canvas.draw_circle(mp, 3.5, _C_BOSS if is_boss else _C_ENEMY)

	# 7. Player indicator
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player : Node = players[0]
	if not player is Node2D:
		return
	var pp     : Vector2 = _to_map((player as Node2D).global_position)
	var facing : Vector2 = Vector2.DOWN
	if "facing" in player:
		facing = player.facing
	_draw_player_arrow(pp, facing)


func _draw_player_arrow(center: Vector2, facing: Vector2) -> void:
	_canvas.draw_circle(center, 5.5, _C_PLAYER)
	var dir  := facing.normalized() if facing.length() > 0.01 else Vector2.DOWN
	var tip  := center + dir * 12.0
	var perp := Vector2(-dir.y, dir.x) * 5.0
	_canvas.draw_colored_polygon(
		PackedVector2Array([tip, center + perp, center - perp]),
		_C_PLAYER
	)


# ── Coordinate helpers ────────────────────────────────────────────────────────

func _to_map(world_pos: Vector2) -> Vector2:
	var nx := (world_pos.x - _view_rect.position.x) / _view_rect.size.x
	var ny := (world_pos.y - _view_rect.position.y) / _view_rect.size.y
	return Vector2(_map_origin.x + nx * _map_w, _map_origin.y + ny * _map_h)


func _in_map_bounds(map_pos: Vector2) -> bool:
	return map_pos.x >= _map_origin.x and map_pos.x <= _map_origin.x + _map_w \
		and map_pos.y >= _map_origin.y and map_pos.y <= _map_origin.y + _map_h
