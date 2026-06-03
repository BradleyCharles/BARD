extends "res://mob/mob_base.gd"

## Slime2 — pack mentality mob.
## Flees when alone near the player; attacks when 3+ slime2s are nearby.

const ASSET_BASE  := "res://assets/Slime1/Without_shadow/Slime2/"
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
var _is_dying    : bool   = false
var _is_hurt     : bool   = false


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
	_sprite.animation_finished.connect(_on_animation_finished)

	wander_timer          = Timer.new()
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timeout)
	add_child(wander_timer)

	_begin_move()


func set_world_size(size: Vector2) -> void:
	world_size    = size
	viewport_rect = Rect2(Vector2.ZERO, world_size)


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["Idle", "Walk", "Run", "Hurt", "Death"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path      := ASSET_BASE + anim + "/Slime2_" + anim + "_" + dir + ".aseprite"
			_merge_anim(sf, anim_name, path)
	_sprite.sprite_frames = sf


func _merge_anim(sf: SpriteFrames, anim_name: String, path: String) -> void:
	var src: SpriteFrames = load(path) as SpriteFrames
	var loop: bool = not (anim_name.begins_with("hurt") or anim_name.begins_with("death"))
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, loop)
	sf.set_animation_speed(anim_name, src.get_animation_speed("default"))
	for i: int in src.get_frame_count("default"):
		sf.add_frame(anim_name, src.get_frame_texture("default", i))


# ── Animation helpers ─────────────────────────────────────────────────────────

func _play_anim(prefix: String) -> void:
	if _is_dying or _is_hurt:
		return
	_sprite.flip_h = false
	match facing:
		"down":  _sprite.play(prefix + "_front")
		"up":    _sprite.play(prefix + "_back")
		"right": _sprite.play(prefix + "_right")
		"left":  _sprite.play(prefix + "_left")


func _play_idle() -> void:
	_play_anim("idle")


func _play_walk() -> void:
	_play_anim("walk")


func _play_run() -> void:
	_play_anim("run")


# ── Damage / Death overrides ──────────────────────────────────────────────────

func take_damage(amount: int, knockback_vec: Vector2) -> void:
	super.take_damage(amount, knockback_vec)
	if health <= 0:
		return
	_is_hurt = true
	_sprite.flip_h = false
	match facing:
		"down":  _sprite.play("hurt_front")
		"up":    _sprite.play("hurt_back")
		"right": _sprite.play("hurt_right")
		"left":  _sprite.play("hurt_left")


func _on_died() -> void:
	_is_dying = true
	_is_hurt  = false
	died.emit(self)
	linear_velocity = Vector2.ZERO
	_sprite.flip_h  = false
	match facing:
		"down":  _sprite.play("death_front")
		"up":    _sprite.play("death_back")
		"right": _sprite.play("death_right")
		"left":  _sprite.play("death_left")


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
	if _is_dying:
		return
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
		_play_run()
	elif in_aggro and not has_pack:
		if ai_state != AIState.FLEE_STATE:
			ai_state = AIState.FLEE_STATE
			wander_timer.stop()
		if _player_ref != null and is_instance_valid(_player_ref):
			var away := (global_position - _player_ref.global_position).normalized()
			linear_velocity = away * max_speed
			_update_facing(linear_velocity)
			_play_run()
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
	_play_walk()


func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 1.0:
		return
	if abs(vel.x) >= abs(vel.y):
		facing = "right" if vel.x >= 0.0 else "left"
	else:
		facing = "down" if vel.y >= 0.0 else "up"


func _on_wander_timeout() -> void:
	if ai_state != AIState.WANDER_STATE:
		return
	if is_moving:
		_begin_pause()
	else:
		_begin_move()


# ── Boundary enforcement ──────────────────────────────────────────────────────

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _is_dying:
		return
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


# ── Animation callbacks ───────────────────────────────────────────────────────

func _on_animation_finished() -> void:
	if _is_dying:
		queue_free()
		return
	if _is_hurt:
		_is_hurt = false
		if ai_state == AIState.CHASE_STATE or ai_state == AIState.FLEE_STATE:
			_play_run()
		elif is_moving:
			_play_walk()
		else:
			_play_idle()
