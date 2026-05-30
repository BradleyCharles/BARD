extends Node

## The Ashfield — monster hunting area.
## This script drives the field scene (world/field.tscn).
## It replaces the old main/main.gd for the RPG build.
##
## Scene structure (build in editor):
##   Field  (Node, script = field.gd)
##   ├── Background      (ColorRect, anchors=full, color=dark green placeholder)
##   │
##   │   ── Terrain placeholders (implied treeline / irregular edges) ──────────
##   ├── TerrainNW       (ColorRect, dark olive, top-left corner block)
##   ├── TerrainNE       (ColorRect, dark olive, top-right corner block)
##   ├── TerrainSE       (ColorRect, dark olive, bottom-right corner block)
##   │       These give the clearing its irregular shape visually.
##   │       Replace with TileMap art in a later phase.
##   │
##   ├── TownEntrance    (Area2D)  ← area_entered connected to _on_entrance_entered
##   │   │   Placed near the south edge of the world, clearly visible.
##   │   ├── CollisionShape2D  (RectangleShape2D, ~200×60)
##   │   └── EntryMarker  (ColorRect, bright gold/yellow, same size as shape)
##   │         Label child: "⟵ Thornwall" or similar
##   │
##   ├── MobContainer    (Node2D — mobs are spawned as children here)
##   │
##   ├── Player          (instance of Player/player.tscn)
##   │   └── Camera2D
##   │         enabled = true
##   │         (no limits — free follow as designed)
##   │
##   └── DayLabel        (Label, top-left anchor, font_size=32)


@export var slime1_scene : PackedScene
## Logical size of the playable field world in pixels.
@export var world_size   : Vector2 = Vector2(3840.0, 2160.0)

const SPAWN_MARGIN : float = 40.0   # inset from terrain edge when placing mobs

var _bounty_timers  : Dictionary = {}   # zone -> Timer
var _zone_rects     : Dictionary = {}   # zone -> Rect2 (populated in _ready)

@onready var _player        = $Player
@onready var _entrance      : Area2D   = $TownEntrance
@onready var _mob_container : Node2D   = $MobContainer
@onready var _day_label     : Label    = $DayLabel
@onready var _terrain_nw    : ColorRect = $TerrainNW
@onready var _terrain_ne    : ColorRect = $TerrainNE
@onready var _terrain_se    : ColorRect = $TerrainSE


func _ready() -> void:
	# Give the player the world bounds so it clamps within the field
	_player.set_world_bounds(Rect2(Vector2.ZERO, world_size))
	# Spawn in the upper-center of the field (away from the south entrance)
	_player.start(Vector2(world_size.x * 0.5, world_size.y * 0.35))

	_player.mob_killed.connect(_on_mob_killed)
	_entrance.area_entered.connect(_on_entrance_entered)

	_zone_rects = {
		"zone_a": Rect2(_terrain_nw.position, _terrain_nw.size),
		"zone_b": Rect2(_terrain_ne.position, _terrain_ne.size),
		"zone_c": Rect2(_terrain_se.position, _terrain_se.size),
	}

	_day_label.text = "Day  %d" % SceneManager.day

	_start_bounty_spawning()
	SceneManager.bounties_updated.connect(_on_bounties_updated)


# ── Bounty Spawning ───────────────────────────────────────────────────────────

func _start_bounty_spawning() -> void:
	var all_bounties : Array = []
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
	var scene := _get_mob_scene(monster_type)
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


func _get_mob_scene(monster_type: String) -> PackedScene:
	match monster_type:
		"slime1": return slime1_scene
	push_error("Field: no scene registered for monster_type '%s'" % monster_type)
	return null


func _on_bounties_updated() -> void:
	_start_bounty_spawning()


# ── Events ────────────────────────────────────────────────────────────────────

func _on_mob_killed(mob_body: Node) -> void:
	var monster_type : String = mob_body.get_meta("monster_type", "unknown")
	SceneManager.record_kill(monster_type)

	if mob_body.has_meta("bounty_zone"):
		var zone : String = mob_body.get_meta("bounty_zone")
		SceneManager.record_bounty_kill(monster_type, zone)
	mob_body.queue_free()


func _on_entrance_entered(area: Area2D) -> void:
	if _is_player(area):
		SceneManager.go_to_town()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _is_player(area: Area2D) -> bool:
	return area.is_in_group("player") or area.get_parent().is_in_group("player")
