extends "res://mob/mob_base.gd"

# ── Constants ─────────────────────────────────────────────────────────────────

const ASSET_BASE       : String = "res://assets/mobs/Orc1/"
const MOB_RADIUS       : float  = 30.0
const CHARGE_SPEED     : float  = 280.0
const CHARGE_DURATION  : float  = 1.2
const RECOVER_DURATION : float  = 0.8

# ── AI phase ──────────────────────────────────────────────────────────────────

enum OrcPhase { WANDER, CHARGE, RECOVER }

# ── Exports ───────────────────────────────────────────────────────────────────

@export var wander_min_speed : float = 40.0
@export var wander_max_speed : float = 40.0

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── State ─────────────────────────────────────────────────────────────────────

var wander_speed  : float    = 0.0
var wander_timer  : Timer
var is_moving     : bool     = false
var _home_zone    : Rect2
var facing        : String   = "down"
var _is_dying     : bool     = false
var _is_hurt      : bool     = false
var _is_attacking : bool     = false
var _orc_phase    : OrcPhase = OrcPhase.WANDER
var _charge_dir   : Vector2  = Vector2.ZERO
var _phase_timer  : float    = 0.0


func _ready() -> void:
	max_health      = 8
	personality     = Personality.WANDER
	aggro_radius    = 250.0
	damage          = 2
	knockback_force = 250.0

	super._ready()

	set_meta("monster_type", "orc1")
	_home_zone   = Rect2(Vector2.ZERO, Vector2(3840.0, 2160.0))
	wander_speed = randf_range(wander_min_speed, wander_max_speed)

	_build_sprite_frames()
	_sprite.animation_finished.connect(_on_animation_finished)

	wander_timer          = Timer.new()
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timeout)
	add_child(wander_timer)

	_begin_move()


func set_playable_rect(rect: Rect2) -> void:
	_home_zone = rect


func set_world_size(size: Vector2) -> void:
	_home_zone = Rect2(Vector2.ZERO, size)


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["Idle", "Walk", "Run_attack", "Hurt", "Death"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path := "%s%s/Orc1_%s_%s.aseprite" % [ASSET_BASE, anim, anim, dir]
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
func _play_walk()       -> void: _play_anim("walk")
func _play_run_attack() -> void: _play_anim("run_attack")


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

	match _orc_phase:
		OrcPhase.WANDER:
			if _distance_to_player() < aggro_radius and _player_ref != null:
				_charge_dir  = global_position.direction_to(_player_ref.global_position)
				_update_facing(_charge_dir)
				_orc_phase   = OrcPhase.CHARGE
				_phase_timer = 0.0
				wander_timer.stop()
			else:
				pass  # movement driven by wander_timer callbacks
		OrcPhase.CHARGE:
			_phase_timer    += delta
			_is_attacking    = true
			linear_velocity  = _charge_dir * CHARGE_SPEED
			_update_facing(_charge_dir)
			_play_run_attack()
			if _phase_timer >= CHARGE_DURATION:
				_orc_phase    = OrcPhase.RECOVER
				_phase_timer  = 0.0
				_is_attacking = false
				linear_velocity = Vector2.ZERO
				_play_idle()
		OrcPhase.RECOVER:
			_phase_timer    += delta
			linear_velocity  = Vector2.ZERO
			if _phase_timer >= RECOVER_DURATION:
				_orc_phase = OrcPhase.WANDER
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
	var vel   := Vector2(cos(angle), sin(angle)) * wander_speed
	linear_velocity = vel
	_update_facing(vel)
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
	if _orc_phase != OrcPhase.WANDER:
		return
	if is_moving:
		_begin_pause()
	else:
		_begin_move()


# ── Boundary enforcement ──────────────────────────────────────────────────────

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _is_dying:
		return
	if _orc_phase != OrcPhase.WANDER:
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
		if is_moving:
			call_deferred("_begin_pause")


# ── Animation callbacks ───────────────────────────────────────────────────────

func _on_animation_finished() -> void:
	if _is_dying:
		queue_free()
		return
	if _is_hurt:
		_is_hurt = false
		match _orc_phase:
			OrcPhase.CHARGE:   _play_run_attack()
			OrcPhase.RECOVER:  _play_idle()
			_:                 _play_idle()
