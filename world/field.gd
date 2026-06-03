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
var _playable_rect    : Rect2      = Rect2(Vector2.ZERO, Vector2(3840.0, 2160.0))
var _slimes_killed    : int  = 0
var _boss_spawned     : bool = false
var _boss_threshold   : int  = 0

@onready var _player        = $Player
@onready var _entrance      : Area2D    = $TownEntrance
@onready var _mob_container : Node2D    = $MobContainer
@onready var _terrain_nw    : ColorRect = $TerrainNW
@onready var _terrain_ne    : ColorRect = $TerrainNE
@onready var _terrain_se    : ColorRect = $TerrainSE

var _pause_menu : CanvasLayer = null


func _ready() -> void:
	# Half-viewport in world px at 1.5× zoom — player is clamped to this inset so the
	# camera (which follows the player freely) never shows void beyond the world edge.
	var hv := Vector2(1920.0 / 1.5, 1080.0 / 1.5) * 0.5
	_player.set_world_bounds(Rect2(hv, world_size - 2.0 * hv))
	_player.start(Vector2(world_size.x * 0.5, world_size.y * 0.35), true)

	var cam: Camera2D = _player.get_node("Camera2D")
	cam.zoom = Vector2(1.5, 1.5)

	_entrance.area_entered.connect(_on_entrance_entered)

	_zone_rects = {
		"zone_a": Rect2(_terrain_nw.position, _terrain_nw.size),
		"zone_b": Rect2(_terrain_ne.position, _terrain_ne.size),
		"zone_c": Rect2(_terrain_se.position, _terrain_se.size),
	}

	_compute_playable_rect()
	_boss_threshold = randi_range(_BOSS_THRESHOLD_MIN, _BOSS_THRESHOLD_MAX)

	var pm_script : GDScript = load("res://ui/pause_menu.gd")
	_pause_menu = CanvasLayer.new()
	_pause_menu.set_script(pm_script)
	add_child(_pause_menu)

	_start_bounty_spawning()
	SceneManager.bounties_updated.connect(_on_bounties_updated)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PlayerInput.PAUSE):
		if _pause_menu != null:
			(_pause_menu as Object).call("open", SceneManager.FIELD_SCENE)
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
	var all_bounties: Array = []
	all_bounties.append_array(SceneManager.available_bounties)
	all_bounties.append_array(SceneManager.active_bounties)
	for bounty in all_bounties:
		_start_bounty_zone(bounty)


func _start_bounty_zone(bounty: Dictionary) -> void:
	var zone         : String = bounty.get("zone", "")
	var monster_type : String = bounty.get("monster_type", "")

	if zone in _bounty_timers or zone not in _zone_rects:
		return
	if _get_mob_scene(monster_type) == null:
		return

	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot  = false
	add_child(timer)
	_bounty_timers[zone] = timer

	_spawn_bounty_mob(monster_type, zone)
	timer.start()

	timer.timeout.connect(func() -> void:
		_spawn_bounty_mob(monster_type, zone)
	)


const MAX_MOBS_PER_ZONE: int = 10


func _count_zone_mobs(zone: String) -> int:
	var count: int = 0
	for mob in _mob_container.get_children():
		if mob.get_meta("bounty_zone", "") == zone:
			count += 1
	return count


func _spawn_bounty_mob(monster_type: String, zone: String) -> void:
	if _count_zone_mobs(zone) >= MAX_MOBS_PER_ZONE:
		return

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
	if mob.has_method("set_playable_rect"):
		mob.set_playable_rect(_playable_rect)
	elif mob.has_method("set_world_size"):
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
	var boss_scene: PackedScene = load("res://mob/slime3.tscn")
	if boss_scene == null:
		push_error("Field: could not load slime3.tscn")
		return
	var boss = boss_scene.instantiate()
	boss.position = world_size * 0.5
	if boss.has_method("set_playable_rect"):
		boss.set_playable_rect(_playable_rect)
	elif boss.has_method("set_world_size"):
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
		# Elites count as their base type for bounty purposes
		var bounty_type: String = "slime1" if monster_type == "slime1_elite" else monster_type
		SceneManager.record_bounty_kill(bounty_type, zone)

	# All mob kills count toward the boss trigger
	_slimes_killed += 1
	_check_boss_trigger()


func _on_entrance_entered(area: Area2D) -> void:
	if _is_player(area):
		SceneManager.go_to_town()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _is_player(area: Area2D) -> bool:
	return area.is_in_group("player") or area.get_parent().is_in_group("player")
