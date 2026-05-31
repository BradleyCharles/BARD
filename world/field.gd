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


@export var slime1_scene      : PackedScene
@export var slime1_elite_scene: PackedScene
@export var slime2_scene      : PackedScene
## Logical size of the playable field world in pixels.
@export var world_size        : Vector2 = Vector2(3840.0, 2160.0)

const SPAWN_MARGIN            : float = 40.0
const _BOSS_THRESHOLD_MIN     : int   = 19
const _BOSS_THRESHOLD_MAX     : int   = 20

var _bounty_timers    : Dictionary = {}
var _zone_rects       : Dictionary = {}
var _slimes_killed    : int  = 0
var _boss_spawned     : bool = false
var _boss_threshold   : int  = 0

@onready var _player        = $Player
@onready var _entrance      : Area2D    = $TownEntrance
@onready var _mob_container : Node2D    = $MobContainer
@onready var _day_label     : Label     = $DayLabel
@onready var _terrain_nw    : ColorRect = $TerrainNW
@onready var _terrain_ne    : ColorRect = $TerrainNE
@onready var _terrain_se    : ColorRect = $TerrainSE


func _ready() -> void:
	_player.set_world_bounds(Rect2(Vector2.ZERO, world_size))
	_player.start(Vector2(world_size.x * 0.5, world_size.y * 0.35))

	# Camera: 1.5× zoom with world-edge limits
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.zoom = Vector2(1.5, 1.5)
	cam.limit_enabled = true
	var hv := Vector2(1920.0 / 1.5, 1080.0 / 1.5) * 0.5   # Vector2(640, 360)
	cam.limit_left   = int(hv.x)
	cam.limit_top    = int(hv.y)
	cam.limit_right  = int(world_size.x - hv.x)
	cam.limit_bottom = int(world_size.y - hv.y)

	_entrance.area_entered.connect(_on_entrance_entered)

	_zone_rects = {
		"zone_a": Rect2(_terrain_nw.position, _terrain_nw.size),
		"zone_b": Rect2(_terrain_ne.position, _terrain_ne.size),
		"zone_c": Rect2(_terrain_se.position, _terrain_se.size),
	}

	_day_label.text = "Day  %d" % SceneManager.day

	_boss_threshold = randi_range(_BOSS_THRESHOLD_MIN, _BOSS_THRESHOLD_MAX)

	_start_bounty_spawning()
	SceneManager.bounties_updated.connect(_on_bounties_updated)


# ── Bounty Spawning ───────────────────────────────────────────────────────────

func _start_bounty_spawning() -> void:
	var all_bounties: Array = []
	all_bounties.append_array(SceneManager.available_bounties)
	all_bounties.append_array(SceneManager.active_bounties)
	for bounty in all_bounties:
		_start_bounty_zone(bounty)


func _start_bounty_zone(bounty: Dictionary) -> void:
	var zone         : String = bounty.get("zone", "")
	var monster_type : String = bounty.get("monster_type", "")
	var quantity     : int    = bounty.get("quantity", 0)
	var killed       : int    = bounty.get("killed", 0)
	var to_spawn     : int    = max(0, quantity - killed)

	if zone in _bounty_timers or to_spawn <= 0 or zone not in _zone_rects:
		return
	if _get_mob_scene(monster_type) == null:
		return

	var spawned := [0]
	var timer   := Timer.new()
	timer.wait_time = 8.0
	timer.one_shot  = false
	add_child(timer)
	_bounty_timers[zone] = timer

	timer.timeout.connect(func() -> void:
		if spawned[0] >= to_spawn:
			timer.stop()
			timer.queue_free()
			_bounty_timers.erase(zone)
			return
		_spawn_bounty_mob(monster_type, zone)
		spawned[0] += 1
	)

	_spawn_bounty_mob(monster_type, zone)
	spawned[0] = 1
	if to_spawn > 1:
		timer.start()


func _spawn_bounty_mob(monster_type: String, zone: String) -> void:
	var scene: PackedScene
	# 10% chance to spawn elite when type is slime1
	if monster_type == "slime1" and randf() < 0.1 and slime1_elite_scene != null:
		scene = slime1_elite_scene
	else:
		scene = _get_mob_scene(monster_type)
	if scene == null:
		return

	var zone_rect : Rect2 = _zone_rects[zone]
	var mob               = scene.instantiate()
	mob.set_meta("bounty_zone", zone)
	if mob.has_method("set_world_size"):
		mob.set_world_size(world_size)
	mob.position = Vector2(
		randf_range(zone_rect.position.x + SPAWN_MARGIN, zone_rect.end.x - SPAWN_MARGIN),
		randf_range(zone_rect.position.y + SPAWN_MARGIN, zone_rect.end.y - SPAWN_MARGIN)
	)
	_mob_container.add_child(mob)

	if mob.has_signal("died"):
		mob.died.connect(_on_mob_died)


func _get_mob_scene(monster_type: String) -> PackedScene:
	match monster_type:
		"slime1": return slime1_scene
		"slime2": return slime2_scene
	push_error("Field: no scene registered for monster_type '%s'" % monster_type)
	return null


func _on_bounties_updated() -> void:
	_start_bounty_spawning()


# ── Boss trigger ──────────────────────────────────────────────────────────────

func _check_boss_trigger() -> void:
	if _boss_spawned:
		return
	if _slimes_killed >= _boss_threshold:
		_spawn_boss()


func _spawn_boss() -> void:
	_boss_spawned = true
	var boss_scene: PackedScene = load("res://mob/slime1_boss.tscn")
	if boss_scene == null:
		push_error("Field: could not load slime1_boss.tscn")
		return
	var boss = boss_scene.instantiate()
	boss.position = world_size * 0.5
	if boss.has_method("set_world_size"):
		boss.set_world_size(world_size)
	_mob_container.add_child(boss)
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

	if mob_body.has_meta("bounty_zone"):
		var zone: String = mob_body.get_meta("bounty_zone")
		SceneManager.record_bounty_kill(monster_type, zone)

	# Count kills for boss trigger (all slime variants count)
	if monster_type in ["slime1", "slime1_elite"]:
		_slimes_killed += 1
		_check_boss_trigger()


func _on_entrance_entered(area: Area2D) -> void:
	if _is_player(area):
		SceneManager.go_to_town()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _is_player(area: Area2D) -> bool:
	return area.is_in_group("player") or area.get_parent().is_in_group("player")
