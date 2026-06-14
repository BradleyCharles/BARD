extends "res://mob/mob_base.gd"

# ── Constants ────────────────────────────────────────────────────────────────

const ASSET_BASE          := "res://assets/mobs/Slime1/"
const MOB_RADIUS          : float = 30.0
## contact_radius is computed in mob_base._ready() as body_radius + 20.0 (player radius)
const PACK_TRIGGER_RADIUS : float = 200.0
const PACK_COUNT_NEEDED   : int   = 2
const LINK_SCAN_INTERVAL  : float = 0.5

# ── Exports ───────────────────────────────────────────────────────────────────

@export var min_speed : float   = 40.0
@export var max_speed : float   = 70.0
@export var world_size: Vector2 = Vector2(3840.0, 2160.0)

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── State ─────────────────────────────────────────────────────────────────────

var wander_speed     : float  = 0.0
var wander_timer     : Timer
var is_moving        : bool   = false
var _home_zone    : Rect2
var facing           : String = "down"
var _is_dying        : bool   = false
var _is_hurt         : bool   = false
var _link_scan_timer  : float  = 0.0
var _returning_to_zone: bool   = false


func _ready() -> void:
	max_health      = 3
	personality     = Personality.PACK_MENTALITY
	aggro_radius    = 200.0
	damage          = 1
	knockback_force = 100.0

	super._ready()
	_apply_hitbox(HITBOX_SLIME1)

	set_meta("monster_type", "slime1")
	_home_zone = Rect2(Vector2.ZERO, world_size)
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
	_home_zone = Rect2(Vector2.ZERO, world_size)


func set_playable_rect(rect: Rect2) -> void:
	_home_zone = rect


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["Idle", "Walk", "Run", "Hurt", "Death"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path := "%s%s/Slime1_%s_%s.aseprite" % [ASSET_BASE, anim, anim, dir]
			_merge_anim(sf, anim_name, path)
	_sprite.sprite_frames = sf


func _merge_anim(sf: SpriteFrames, anim_name: String, path: String) -> void:
	var src: SpriteFrames = load(path) as SpriteFrames
	var one_shot := anim_name.begins_with("hurt") or anim_name.begins_with("death")
	var loop: bool = not one_shot
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


# ── Link / Pack system ────────────────────────────────────────────────────────

## Called externally (or by _link_pack cascade) to permanently aggro this slime.
func trigger_aggro() -> void:
	if _is_aggroed or _is_dying:
		return
	if _count_nearby_mobs() < PACK_COUNT_NEEDED:
		return
	if _distance_to_player() >= aggro_radius:
		return
	_is_aggroed = true
	_link_pack()


func _link_pack() -> void:
	for mob in get_tree().get_nodes_in_group("ground_mobs"):
		if mob == self:
			continue
		if mob.get_meta("monster_type", "") == "slime1":
			if global_position.distance_to(mob.global_position) <= PACK_TRIGGER_RADIUS:
				mob.call("trigger_aggro")


func _count_nearby_mobs() -> int:
	var count: int = 0
	for mob in get_tree().get_nodes_in_group("ground_mobs"):
		if mob == self:
			continue
		if global_position.distance_to(mob.global_position) <= PACK_TRIGGER_RADIUS:
			count += 1
	return count


# ── AI / Physics ──────────────────────────────────────────────────────────────

func _is_outside_leash() -> bool:
	return not _home_zone.grow(30.0).has_point(global_position)


func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	super._physics_process(delta)

	if _is_hurt:
		return

	if _returning_to_zone:
		if _home_zone.has_point(global_position):
			_returning_to_zone = false
			_begin_move()
		else:
			var target := _home_zone.get_center()
			linear_velocity = (target - global_position).normalized() * wander_speed
			_update_facing(linear_velocity)
			_play_walk()
		linear_velocity += _calc_separation()
		return

	var dist     := _distance_to_player()
	var in_aggro := dist < aggro_radius

	if _is_aggroed:
		# Already linked — chase player and periodically spread the link.
		if ai_state != AIState.CHASE_STATE:
			ai_state = AIState.CHASE_STATE
			wander_timer.stop()
		if _is_outside_leash():
			_is_aggroed = false
			_returning_to_zone = true
			ai_state = AIState.WANDER_STATE
		else:
			if _player_ref != null and is_instance_valid(_player_ref):
				if dist > contact_radius:
					linear_velocity = _nav_move(max_speed)
					_update_facing(linear_velocity)
					_play_run()
				else:
					linear_velocity = Vector2.ZERO
					_play_idle()
			_link_scan_timer -= delta
			if _link_scan_timer <= 0.0:
				_link_pack()
				_link_scan_timer = LINK_SCAN_INTERVAL
	elif in_aggro:
		# Not yet linked — check if pack condition is met to trigger.
		if _count_nearby_mobs() >= PACK_COUNT_NEEDED:
			trigger_aggro()
		else:
			if ai_state != AIState.FLEE_STATE:
				ai_state = AIState.FLEE_STATE
				wander_timer.stop()
			if _player_ref != null and is_instance_valid(_player_ref):
				var away: Vector2 = \
					(global_position - _player_ref.global_position).normalized()
				linear_velocity = away * max_speed
				_update_facing(linear_velocity)
				_play_run()
	else:
		if ai_state in [AIState.CHASE_STATE, AIState.FLEE_STATE]:
			ai_state = AIState.WANDER_STATE
			_begin_move()

	linear_velocity += _calc_separation()


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
	if ai_state != AIState.WANDER_STATE:
		return

	var pos      := state.transform.origin
	var hit_wall := false

	var x_min := _home_zone.position.x + MOB_RADIUS
	var x_max := _home_zone.end.x - MOB_RADIUS
	var y_min := _home_zone.position.y + MOB_RADIUS
	var y_max := _home_zone.end.y - MOB_RADIUS

	if pos.x < x_min:
		pos.x = x_min
		state.linear_velocity.x = 0.0
		hit_wall = true
	elif pos.x > x_max:
		pos.x = x_max
		state.linear_velocity.x = 0.0
		hit_wall = true

	if pos.y < y_min:
		pos.y = y_min
		state.linear_velocity.y = 0.0
		hit_wall = true
	elif pos.y > y_max:
		pos.y = y_max
		state.linear_velocity.y = 0.0
		hit_wall = true

	if hit_wall:
		var t := state.transform
		t.origin = pos
		state.transform = t
		if is_moving:
			call_deferred("_begin_pause")


# ── Animation callbacks ───────────────────────────────────────────────────────

func _on_animation_finished() -> void:
	if _is_dying:
		queue_free()
		return
	if _is_hurt:
		_is_hurt = false
		if _is_aggroed or ai_state == AIState.CHASE_STATE or ai_state == AIState.FLEE_STATE:
			_play_run()
		elif is_moving:
			_play_walk()
		else:
			_play_idle()
