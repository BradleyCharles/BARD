extends "res://mob/mob_base.gd"

## Slime2 — pack mentality mob.
## Flees when alone near the player; attacks when 3+ slime2s are nearby.
## Sprites: Slime2_Idle_without_shadow.png (384×256, 6 frames × 4 rows)
##          Slime2_Walk_without_shadow.png (512×256, 8 frames × 4 rows)
## Row order: 0=Down, 1=Left, 2=Right, 3=Up

const ASSET_BASE  := "res://assets/Slime2/Without_shadow/"
const FRAME_SIZE  := 64
const IDLE_COLS   := 6
const IDLE_FPS    := 8.0
const MOB_RADIUS  : float = 30.0

@export var min_speed : float   = 50.0
@export var max_speed : float   = 100.0
@export var world_size: Vector2 = Vector2(3840.0, 2160.0)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var wander_speed : float  = 0.0
var wander_timer : Timer
var is_moving    : bool   = false
var viewport_rect: Rect2
var facing       : String = "down"


func _ready() -> void:
	max_health     = 2
	personality    = Personality.PACK_MENTALITY
	aggro_radius   = 150.0
	pack_radius    = 200.0
	pack_threshold = 3

	super._ready()

	set_meta("monster_type", "slime2")
	viewport_rect = Rect2(Vector2.ZERO, world_size)
	wander_speed  = randf_range(min_speed, max_speed)

	_build_sprite_frames()

	wander_timer          = Timer.new()
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timeout)
	add_child(wander_timer)

	_begin_move()


func set_world_size(size: Vector2) -> void:
	world_size    = size
	viewport_rect = Rect2(Vector2.ZERO, world_size)


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _make_atlas(sheet: Texture2D, col: int, row: int) -> AtlasTexture:
	var a    := AtlasTexture.new()
	a.atlas   = sheet
	a.region  = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	return a


func _build_sprite_frames() -> void:
	var idle_tex: Texture2D = load(ASSET_BASE + "Slime2_Idle_without_shadow.png")
	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	# Row 0=Down, Row 3=Up, Row 2=Right (flip for Left)
	var row_map := [["idle_down", 0], ["idle_up", 3], ["idle_right", 2]]
	for entry in row_map:
		sf.add_animation(entry[0])
		sf.set_animation_loop(entry[0], true)
		sf.set_animation_speed(entry[0], IDLE_FPS)
		for col in IDLE_COLS:
			sf.add_frame(entry[0], _make_atlas(idle_tex, col, entry[1]))

	_sprite.sprite_frames = sf
	_sprite.play("idle_down")


# ── Animation helpers ─────────────────────────────────────────────────────────

func _play_idle() -> void:
	match facing:
		"down":
			_sprite.flip_h = false
			_sprite.play("idle_down")
		"up":
			_sprite.flip_h = false
			_sprite.play("idle_up")
		"right":
			_sprite.flip_h = false
			_sprite.play("idle_right")
		"left":
			_sprite.flip_h = true
			_sprite.play("idle_right")


func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 1.0:
		return
	if abs(vel.x) >= abs(vel.y):
		facing = "right" if vel.x >= 0.0 else "left"
	else:
		facing = "down" if vel.y >= 0.0 else "up"


# ── Pack counting ─────────────────────────────────────────────────────────────

func _count_nearby_pack() -> int:
	var count := 0
	for mob in get_tree().get_nodes_in_group("ground_mobs"):
		if mob == self:
			continue
		if mob.get_meta("monster_type", "") == "slime2":
			if global_position.distance_to(mob.global_position) <= pack_radius:
				count += 1
	return count


# ── AI / Physics ──────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	var dist       := _distance_to_player()
	var pack_count := _count_nearby_pack()
	var in_aggro   := dist < aggro_radius
	var has_pack   := pack_count >= pack_threshold

	if in_aggro and has_pack:
		if ai_state != AIState.CHASE_STATE:
			ai_state = AIState.CHASE_STATE
			wander_timer.stop()
		linear_velocity = _direction_to_player_with_noise(max_speed)
		_update_facing(linear_velocity)
		_play_idle()
	elif in_aggro and not has_pack:
		if ai_state != AIState.FLEE_STATE:
			ai_state = AIState.FLEE_STATE
			wander_timer.stop()
		if _player_ref != null and is_instance_valid(_player_ref):
			var away := (global_position - _player_ref.global_position).normalized()
			linear_velocity = away * max_speed
			_update_facing(linear_velocity)
			_play_idle()
	else:
		if ai_state in [AIState.CHASE_STATE, AIState.FLEE_STATE]:
			ai_state = AIState.WANDER_STATE
			_begin_move()


# ── Wander ────────────────────────────────────────────────────────────────────

func _begin_pause() -> void:
	is_moving       = false
	linear_velocity = Vector2.ZERO
	_play_idle()
	wander_timer.wait_time = randf_range(1.0, 4.0)
	wander_timer.start()


func _begin_move() -> void:
	is_moving = true
	var angle := randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * wander_speed
	_update_facing(linear_velocity)
	wander_timer.wait_time = randf_range(1.0, 3.0)
	wander_timer.start()
	_play_idle()


func _on_wander_timeout() -> void:
	if ai_state != AIState.WANDER_STATE:
		return
	if is_moving:
		_begin_pause()
	else:
		_begin_move()


# ── Boundary enforcement ──────────────────────────────────────────────────────

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var pos      := state.transform.origin
	var hit_wall := false

	if pos.x < MOB_RADIUS:
		pos.x = MOB_RADIUS
		state.linear_velocity.x = 0.0
		hit_wall = true
	elif pos.x > viewport_rect.size.x - MOB_RADIUS:
		pos.x = viewport_rect.size.x - MOB_RADIUS
		state.linear_velocity.x = 0.0
		hit_wall = true

	if pos.y < MOB_RADIUS:
		pos.y = MOB_RADIUS
		state.linear_velocity.y = 0.0
		hit_wall = true
	elif pos.y > viewport_rect.size.y - MOB_RADIUS:
		pos.y = viewport_rect.size.y - MOB_RADIUS
		state.linear_velocity.y = 0.0
		hit_wall = true

	if hit_wall:
		var t := state.transform
		t.origin = pos
		state.transform = t
		if is_moving and ai_state == AIState.WANDER_STATE:
			call_deferred("_begin_pause")
