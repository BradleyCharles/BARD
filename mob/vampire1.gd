extends "res://mob/mob_base.gd"

# ── Constants ─────────────────────────────────────────────────────────────────

const ASSET_BASE         : String = "res://assets/mobs/Vampires1/"
const MOB_RADIUS         : float  = 30.0
const ORBIT_RADIUS      : float = MobStats.VAMPIRE1_ORBIT_RADIUS
const ORBIT_SPEED       : float = MobStats.VAMPIRE1_ORBIT_SPEED
const DASH_SPEED        : float = MobStats.VAMPIRE1_DASH_SPEED
const DASH_DURATION     : float = MobStats.VAMPIRE1_DASH_DURATION
const RECOVER_DURATION  : float = MobStats.VAMPIRE1_RECOVER_DURATION
const DASH_INTERVAL_MIN : float = MobStats.VAMPIRE1_DASH_INTERVAL_MIN
const DASH_INTERVAL_MAX : float = MobStats.VAMPIRE1_DASH_INTERVAL_MAX

# ── AI phase ──────────────────────────────────────────────────────────────────

enum VampirePhase { ORBIT, DASH, RECOVER }

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── State ─────────────────────────────────────────────────────────────────────

var _home_zone       : Rect2
var facing           : String       = "down"
var _is_dying        : bool         = false
var _is_hurt         : bool         = false
var _is_attacking    : bool         = false
var _phase           : VampirePhase = VampirePhase.ORBIT
var _dash_dir        : Vector2      = Vector2.ZERO
var _phase_timer     : float        = 0.0
var _dash_cooldown   : float        = 0.0


func _ready() -> void:
	max_health      = MobStats.VAMPIRE1_MAX_HEALTH
	personality     = Personality.WANDER
	aggro_radius    = MobStats.VAMPIRE1_AGGRO_RADIUS
	damage          = MobStats.VAMPIRE1_DAMAGE
	knockback_force = MobStats.VAMPIRE1_KNOCKBACK

	super._ready()
	collision_mask = 0
	_apply_hitbox(MobStats.VAMPIRE1_HITBOX_RADIUS)
	z_index = 4

	set_meta("monster_type", "vampire1")
	_home_zone    = Rect2(Vector2.ZERO, Vector2(3840.0, 2160.0))
	_dash_cooldown = randf_range(DASH_INTERVAL_MIN, DASH_INTERVAL_MAX)

	_build_sprite_frames()
	_sprite.animation_finished.connect(_on_animation_finished)


func set_playable_rect(rect: Rect2) -> void:
	_home_zone = rect


func set_world_size(size: Vector2) -> void:
	_home_zone = Rect2(Vector2.ZERO, size)


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["Idle", "Run", "Attack", "Hurt", "Death"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path := "%s%s/Vampires1_%s_%s.aseprite" % [ASSET_BASE, anim, anim, dir]
			_merge_anim(sf, anim_name, path)
	_sprite.sprite_frames = sf


func _merge_anim(sf: SpriteFrames, anim_name: String, path: String) -> void:
	var src: SpriteFrames = load(path) as SpriteFrames
	var one_shot: bool = anim_name.begins_with("hurt") or anim_name.begins_with("death")
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, not one_shot)
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


func _play_idle()       -> void: _play_anim("idle")
func _play_run()        -> void: _play_anim("run")
func _play_attack() -> void: _play_anim("attack")


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
	_is_dying     = true
	_is_hurt      = false
	_is_attacking = false
	died.emit(self)
	linear_velocity = Vector2.ZERO
	_sprite.flip_h  = false
	match facing:
		"down":  _sprite.play("death_front")
		"up":    _sprite.play("death_back")
		"right": _sprite.play("death_right")
		"left":  _sprite.play("death_left")


# ── AI / Physics ──────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	super._physics_process(delta)
	if _is_hurt:
		return

	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	match _phase:
		VampirePhase.ORBIT:
			var to_player  := _player_ref.global_position - global_position
			var dist       := to_player.length()
			if not _is_aggroed:
				if dist <= aggro_radius:
					_is_aggroed = true
				else:
					linear_velocity = Vector2.ZERO
					_play_idle()
			if _is_aggroed:
				_dash_cooldown -= delta
				var tangent    := Vector2(-to_player.y, to_player.x).normalized()
				var radial     := to_player.normalized() * (dist - ORBIT_RADIUS) * 0.05
				linear_velocity = (tangent * ORBIT_SPEED) + radial
				_update_facing(linear_velocity)
				_play_run()
				if _dash_cooldown <= 0.0:
					_dash_dir    = to_player.normalized()
					_phase       = VampirePhase.DASH
					_phase_timer = 0.0
					_is_attacking = true

		VampirePhase.DASH:
			_phase_timer    += delta
			linear_velocity  = _dash_dir * DASH_SPEED
			_update_facing(_dash_dir)
			_play_attack()
			if _phase_timer >= DASH_DURATION:
				_phase        = VampirePhase.RECOVER
				_phase_timer  = 0.0
				_is_attacking = false
				linear_velocity = Vector2.ZERO
				_play_idle()

		VampirePhase.RECOVER:
			_phase_timer    += delta
			linear_velocity  = Vector2.ZERO
			if _phase_timer >= RECOVER_DURATION:
				_phase         = VampirePhase.ORBIT
				_dash_cooldown = randf_range(DASH_INTERVAL_MIN, DASH_INTERVAL_MAX)

	linear_velocity += _calc_separation()


func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 1.0:
		return
	if abs(vel.x) >= abs(vel.y):
		facing = "right" if vel.x >= 0.0 else "left"
	else:
		facing = "down" if vel.y >= 0.0 else "up"


# ── Boundary enforcement ──────────────────────────────────────────────────────

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _is_dying:
		return
	var pos      := state.transform.origin
	var hit_wall := false
	var x_min    := _home_zone.position.x + MOB_RADIUS
	var x_max    := _home_zone.end.x - MOB_RADIUS
	var y_min    := _home_zone.position.y + MOB_RADIUS
	var y_max    := _home_zone.end.y - MOB_RADIUS
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


# ── Animation callbacks ───────────────────────────────────────────────────────

func _on_animation_finished() -> void:
	if _is_dying:
		queue_free()
		return
	if _is_hurt:
		_is_hurt = false
		match _phase:
			VampirePhase.ORBIT: _play_run()
			VampirePhase.DASH:  _play_attack()
			_:                  _play_idle()
