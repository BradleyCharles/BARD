extends Node

## The Ashfield — monster hunting area.
## This script drives the field scene (world/field.tscn).
##
## Scene structure (build in editor):
##   Field  (Node, script = field.gd)
##   ├── Background      (ColorRect, anchors=full, color=dark green placeholder)
##   │
##   │   ── Terrain placeholders (implied treeline / irregular edges) ──────────
##   ├── TerrainNW       (ColorRect, dark olive, top-left corner block)
##   ├── TerrainNE       (ColorRect, dark olive, top-right corner block)
##   ├── TerrainSE       (ColorRect, dark olive, bottom-right corner block)
##   │
##   ├── TownEntrance    (Area2D)  ← area_entered connected to _on_entrance_entered
##   │   ├── CollisionShape2D  (RectangleShape2D, ~200×60)
##   │   └── EntryMarker  (ColorRect)
##   │
##   ├── MobContainer    (Node2D — mobs are spawned as children here)
##   │
##   ├── Player          (instance of Player/player.tscn)
##   │   └── Camera2D
##   │
##   └── DayLabel        (Label, top-left anchor, font_size=32)


# ── Mob scenes — assign in Godot editor inspector ─────────────────────────────

@export var slime1_scene  : PackedScene
@export var slime2_scene  : PackedScene
@export var slime3_scene  : PackedScene
@export var slime3_boss_scene : PackedScene

# Zone A
@export var orc1_scene        : PackedScene
@export var orc2_scene        : PackedScene
@export var orc3_scene        : PackedScene
@export var orc3_boss_scene   : PackedScene
@export var plant1_scene      : PackedScene
@export var plant2_scene      : PackedScene
@export var plant3_scene      : PackedScene
@export var plant3_boss_scene : PackedScene

# Zone B
@export var vampire1_scene      : PackedScene
@export var vampire2_scene      : PackedScene
@export var vampire3_scene      : PackedScene
@export var vampire3_boss_scene : PackedScene

## Logical size of the playable field world in pixels.
@export var world_size : Vector2 = Vector2(3840.0, 2160.0)

# ── Constants ─────────────────────────────────────────────────────────────────

const SPAWN_MARGIN         : float = 40.0
const BOSS_KILL_THRESHOLD  : int   = 20
const MAX_MOBS_PER_ZONE    : int   = 5
const MAX_TESTING_MOBS     : int   = 10

# ── Kill counters & boss flags ────────────────────────────────────────────────

# Zone C — combined slime kill counter
var _zone_c_slime_killed   : int  = 0
var _slime3_boss_spawned   : bool = false

# Zone A — independent orc and plant counters
var _zone_a_orc_killed     : int  = 0
var _zone_a_plant_killed   : int  = 0
var _orc3_boss_spawned     : bool = false
var _plant3_boss_spawned   : bool = false

# Zone B — combined vampire kill counter
var _zone_b_vampire_killed : int  = 0
var _vampire3_boss_spawned : bool = false

# ── Spawn state ───────────────────────────────────────────────────────────────

var _bounty_timers : Dictionary = {}
var _zone_rects    : Dictionary = {}
var _playable_rect : Rect2      = Rect2(Vector2.ZERO, Vector2(3840.0, 2160.0))
var _testing_timer : Timer      = null

@onready var _player        = $Player
@onready var _entrance      : Area2D    = $TownEntrance
@onready var _mob_container : Node2D    = $MobContainer
@onready var _terrain_nw    : ColorRect = $ZoneA
@onready var _terrain_ne    : ColorRect = $ZoneB
@onready var _terrain_se    : ColorRect = $ZoneC

var _pause_menu    : CanvasLayer = null
var _minimap       : CanvasLayer = null
var _teleport_menu : CanvasLayer = null
var _boss_tracker  : CanvasLayer = null


func _ready() -> void:
	_player.start(Vector2(800.0, 1500.0), true)

	var cam: Camera2D = _player.get_node("Camera2D")
	cam.zoom = Vector2(3.5, 3.5)

	_entrance.area_entered.connect(_on_entrance_entered)

	_zone_rects = {
		"zone_a": Rect2(_terrain_nw.position, _terrain_nw.size),
		"zone_b": Rect2(_terrain_ne.position, _terrain_ne.size),
		"zone_c": Rect2(_terrain_se.position, _terrain_se.size),
	}

	_compute_playable_rect()

	var pm_script : GDScript = load("res://ui/pause_menu.gd")
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(pm_script)
	add_child(_pause_menu)

	var mm_script : GDScript = load("res://ui/minimap.gd")
	_minimap = CanvasLayer.new()
	_minimap.set_script(mm_script)
	add_child(_minimap)
	(_minimap as Object).call("init", _playable_rect, _zone_rects, _build_minimap_tile_layers())

	var bt_script : GDScript = load("res://ui/boss_tracker.gd")
	_boss_tracker = CanvasLayer.new()
	_boss_tracker.set_script(bt_script)
	add_child(_boss_tracker)
	(_boss_tracker as Object).call("init", BOSS_KILL_THRESHOLD)

	_player.hit.connect(_on_player_died)

	_start_bounty_spawning()
	SceneManager.bounties_updated.connect(_on_bounties_updated)
	SceneManager.testing_mode_changed.connect(_on_testing_mode_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PlayerInput.PAUSE):
		if _pause_menu != null:
			(_pause_menu as Object).call("open", SceneManager.FIELD_SCENE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.SELECT) and SceneManager.testing_mode:
		if _teleport_menu == null:
			_open_teleport_menu()
		get_viewport().set_input_as_handled()


# ── Playable rect ─────────────────────────────────────────────────────────────

func _compute_playable_rect() -> void:
	var left   := get_node_or_null("BoundaryLeft")   as Control
	var right  := get_node_or_null("BoundaryRight")  as Control
	var top    := get_node_or_null("BoundaryTop")    as Control
	var bottom := get_node_or_null("BoundaryBottom") as Control
	if left and right and top and bottom:
		var x_min : float = left.position.x + left.size.x
		var x_max : float = right.position.x
		var y_min : float = top.position.y + top.size.y
		var y_max : float = bottom.position.y
		_playable_rect = Rect2(x_min, y_min, x_max - x_min, y_max - y_min)


# ── Bounty Spawning ───────────────────────────────────────────────────────────

func _start_bounty_spawning() -> void:
	for bounty in SceneManager.active_bounties:
		_start_bounty_zone(bounty)


func _start_bounty_zone(bounty: Dictionary) -> void:
	var zone         : String = bounty.get("zone", "")
	var monster_type : String = bounty.get("monster_type", "")

	if zone in _bounty_timers or zone not in _zone_rects:
		return
	if _get_mob_scene(monster_type) == null:
		return

	var timer := Timer.new()
	timer.wait_time = 3.5
	timer.one_shot  = false
	add_child(timer)
	_bounty_timers[zone] = timer

	_spawn_bounty_mob(monster_type, zone)
	timer.start()

	timer.timeout.connect(func() -> void:
		_spawn_bounty_mob(monster_type, zone)
	)


func _count_zone_mobs(zone: String) -> int:
	var count: int = 0
	for mob in _mob_container.get_children():
		if mob.get_meta("bounty_zone", "") == zone:
			count += 1
	return count


func _spawn_bounty_mob(monster_type: String, zone: String) -> void:
	if _count_zone_mobs(zone) >= MAX_MOBS_PER_ZONE:
		return

	var scene: PackedScene = _get_mob_scene(monster_type)
	if scene == null:
		return

	var zone_rect : Rect2 = _zone_rects[zone]
	var mob               = scene.instantiate()
	mob.set_meta("bounty_zone", zone)
	mob.position = Vector2(
		randf_range(zone_rect.position.x + SPAWN_MARGIN, zone_rect.end.x - SPAWN_MARGIN),
		randf_range(zone_rect.position.y + SPAWN_MARGIN, zone_rect.end.y - SPAWN_MARGIN)
	)
	_mob_container.add_child(mob)
	if mob.has_method("set_playable_rect"):
		mob.set_playable_rect(zone_rect)
	elif mob.has_method("set_world_size"):
		mob.set_world_size(world_size)

	if mob.has_signal("died"):
		mob.died.connect(_on_mob_died)


func _get_mob_scene(monster_type: String) -> PackedScene:
	match monster_type:
		"slime1":   return slime1_scene
		"slime2":   return slime2_scene
		"slime3":   return slime3_scene
		"orc1":     return orc1_scene
		"orc2":     return orc2_scene
		"orc3":     return orc3_scene
		"plant1":   return plant1_scene
		"plant2":   return plant2_scene
		"plant3":   return plant3_scene
		"vampire1": return vampire1_scene
		"vampire2": return vampire2_scene
		"vampire3": return vampire3_scene
	push_error("Field: no scene registered for monster_type '%s'" % monster_type)
	return null


func _on_bounties_updated() -> void:
	_start_bounty_spawning()


# ── Testing mode spawning ─────────────────────────────────────────────────────

func _on_testing_mode_changed(enabled: bool) -> void:
	if enabled:
		_start_testing_spawning()
	else:
		_stop_testing_spawning()


func _start_testing_spawning() -> void:
	for zone in _zone_rects:
		_fill_testing_zone(zone)

	_testing_timer = Timer.new()
	_testing_timer.wait_time = 4.0
	_testing_timer.one_shot  = false
	_testing_timer.timeout.connect(_on_testing_timer)
	add_child(_testing_timer)
	_testing_timer.start()


func _stop_testing_spawning() -> void:
	if _testing_timer != null:
		_testing_timer.queue_free()
		_testing_timer = null
	for mob in _mob_container.get_children():
		if mob.get_meta("is_testing_mob", false):
			mob.queue_free()


func _on_testing_timer() -> void:
	for zone in _zone_rects:
		_fill_testing_zone(zone)


func _fill_testing_zone(zone: String) -> void:
	var count: int = _count_testing_mobs(zone)
	while count < MAX_TESTING_MOBS:
		_spawn_testing_mob(zone)
		count += 1


func _count_testing_mobs(zone: String) -> int:
	var count: int = 0
	for mob in _mob_container.get_children():
		if mob.get_meta("is_testing_mob", false) \
				and mob.get_meta("testing_zone", "") == zone:
			count += 1
	return count


func _spawn_testing_mob(zone: String) -> void:
	var monster_type := _testing_random_mob(zone)
	var scene: PackedScene = _get_mob_scene(monster_type)
	if scene == null:
		return
	var zone_rect : Rect2 = _zone_rects[zone]
	var mob               = scene.instantiate()
	mob.set_meta("is_testing_mob", true)
	mob.set_meta("testing_zone", zone)
	mob.position = Vector2(
		randf_range(zone_rect.position.x + SPAWN_MARGIN, zone_rect.end.x - SPAWN_MARGIN),
		randf_range(zone_rect.position.y + SPAWN_MARGIN, zone_rect.end.y - SPAWN_MARGIN)
	)
	_mob_container.add_child(mob)
	if mob.has_method("set_playable_rect"):
		mob.set_playable_rect(zone_rect)
	elif mob.has_method("set_world_size"):
		mob.set_world_size(world_size)
	if mob.has_signal("died"):
		mob.died.connect(_on_mob_died)


func _testing_random_mob(zone: String) -> String:
	var roll := randf()
	match zone:
		"zone_a":
			# Orcs and plants: tiers weighted 50/30/20, then coin-flip orc vs plant
			var tier: String
			if roll < 0.5:   tier = "1"
			elif roll < 0.8: tier = "2"
			else:             tier = "3"
			return ("orc" if randf() < 0.5 else "plant") + tier
		"zone_b":
			if roll < 0.5:   return "vampire1"
			elif roll < 0.8: return "vampire2"
			else:             return "vampire3"
		"zone_c":
			if roll < 0.5:   return "slime1"
			elif roll < 0.8: return "slime2"
			else:             return "slime3"
	return "slime1"


# ── Teleport menu ─────────────────────────────────────────────────────────────

func _open_teleport_menu() -> void:
	var script: GDScript = load("res://ui/teleport_menu.gd")
	_teleport_menu = CanvasLayer.new()
	_teleport_menu.set_script(script)
	add_child(_teleport_menu)
	(_teleport_menu as Object).call(
		"init", _zone_rects, _player
	)
	(_teleport_menu as Object).connect("menu_closed", _on_teleport_closed)


func _on_teleport_closed() -> void:
	if _teleport_menu:
		_teleport_menu.queue_free()
		_teleport_menu = null


# ── Boss triggers ─────────────────────────────────────────────────────────────

func _check_boss_triggers() -> void:
	if not _slime3_boss_spawned and _zone_c_slime_killed >= BOSS_KILL_THRESHOLD:
		_slime3_boss_spawned = true
		call_deferred("_spawn_boss", slime3_boss_scene)

	if not _orc3_boss_spawned and _zone_a_orc_killed >= BOSS_KILL_THRESHOLD:
		_orc3_boss_spawned = true
		call_deferred("_spawn_boss", orc3_boss_scene)

	if not _plant3_boss_spawned and _zone_a_plant_killed >= BOSS_KILL_THRESHOLD:
		_plant3_boss_spawned = true
		call_deferred("_spawn_boss", plant3_boss_scene)

	if not _vampire3_boss_spawned and _zone_b_vampire_killed >= BOSS_KILL_THRESHOLD:
		_vampire3_boss_spawned = true
		call_deferred("_spawn_boss", vampire3_boss_scene)


func _spawn_boss(scene: PackedScene) -> void:
	if scene == null:
		push_error("Field: _spawn_boss called with null scene")
		return

	var boss = scene.instantiate()
	boss.position = world_size * 0.5
	_mob_container.add_child(boss)
	if boss.has_method("set_playable_rect"):
		boss.set_playable_rect(_playable_rect)
	elif boss.has_method("set_world_size"):
		boss.set_world_size(world_size)
	if boss.has_signal("died"):
		boss.died.connect(_on_mob_died)

	var bar_scene: PackedScene = load("res://ui/boss_health_bar.tscn")
	if bar_scene:
		var bar = bar_scene.instantiate()
		get_tree().root.add_child(bar)
		bar.init(boss)


# ── Events ────────────────────────────────────────────────────────────────────

func _on_mob_died(mob_body: Node) -> void:
	var monster_type: String = mob_body.get_meta("monster_type", "unknown")
	SceneManager.record_kill(monster_type)

	var is_testing: bool = mob_body.get_meta("is_testing_mob", false)

	if not is_testing and mob_body.has_meta("bounty_zone"):
		var zone: String = mob_body.get_meta("bounty_zone")
		SceneManager.record_bounty_kill(monster_type, zone)

	match monster_type:
		"slime1", "slime2", "slime3":
			_zone_c_slime_killed += 1
		"orc1", "orc2", "orc3":
			_zone_a_orc_killed += 1
		"plant1", "plant2", "plant3":
			_zone_a_plant_killed += 1
		"vampire1", "vampire2", "vampire3":
			_zone_b_vampire_killed += 1
	_check_boss_triggers()
	_update_boss_tracker()


func _on_player_died() -> void:
	var go_script: GDScript = load("res://ui/game_over_screen.gd")
	var go_layer := CanvasLayer.new()
	go_layer.set_script(go_script)
	add_child(go_layer)


func _on_entrance_entered(area: Area2D) -> void:
	if _is_player(area):
		SceneManager.go_to_town()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _is_player(area: Area2D) -> bool:
	return area.is_in_group("player") or area.get_parent().is_in_group("player")


func _build_minimap_tile_layers() -> Array:
	var layers : Array = []
	var overpass : TileMapLayer = get_node_or_null("FieldTileMap/OverPass") as TileMapLayer
	if overpass:
		layers.append({"node": overpass, "color": Color(0.28, 0.52, 0.20, 1.0)})
	var barrier_color := Color(0.42, 0.30, 0.18, 1.0)
	for bname in ["Barrier0", "Barrier1", "Barrier2"]:
		var b : TileMapLayer = get_node_or_null("FieldBarrier/" + bname) as TileMapLayer
		if b:
			layers.append({"node": b, "color": barrier_color})
	var exit_color := Color(0.75, 0.65, 0.30, 1.0)
	for ename in ["ExitPath", "ExitPillars"]:
		var e : TileMapLayer = get_node_or_null("FieldExit/" + ename) as TileMapLayer
		if e:
			layers.append({"node": e, "color": exit_color})
	return layers


func get_zone_rects() -> Dictionary:
	return _zone_rects


func _update_boss_tracker() -> void:
	if _boss_tracker == null:
		return
	(_boss_tracker as Object).call("set_family", "slime",   _zone_c_slime_killed,   _slime3_boss_spawned)
	(_boss_tracker as Object).call("set_family", "orc",     _zone_a_orc_killed,     _orc3_boss_spawned)
	(_boss_tracker as Object).call("set_family", "plant",   _zone_a_plant_killed,   _plant3_boss_spawned)
	(_boss_tracker as Object).call("set_family", "vampire", _zone_b_vampire_killed, _vampire3_boss_spawned)
