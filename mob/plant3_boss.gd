extends "res://mob/mob_base.gd"

# ── Constants ─────────────────────────────────────────────────────────────────

const ASSET_BASE             : String = "res://assets/mobs/Plant3/"
const MOB_RADIUS             : float  = 40.0
const BOSS_CREEP_SPEED       : float  = 30.0
const BEAM_REACH             : float  = 400.0
const BEAM_HALF_WIDTH        : float  = 20.0
const BEAM_HALF_WIDTH_RADIANS: float  = 0.35
const AOE_DAMAGE             : int    = 7
const AOE_KNOCKBACK          : float  = 500.0
const ATTACK_COOLDOWN        : float  = 6.0
const TELEGRAPH_DURATION     : float  = 2.0
const ATTACK_TRIGGER_RADIUS  : float  = 400.0

# ── AI phase ──────────────────────────────────────────────────────────────────

enum PlantBossPhase { CREEP, TELEGRAPH, FIRE }

# ── Exports ───────────────────────────────────────────────────────────────────

@export var world_size: Vector2 = Vector2(3840.0, 2160.0)

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── State ─────────────────────────────────────────────────────────────────────

var viewport_rect      : Rect2
var facing             : String        = "down"
var _is_dying          : bool          = false
var _is_hurt           : bool          = false
var _boss_phase        : PlantBossPhase = PlantBossPhase.CREEP
var _telegraph_timer   : float         = 0.0
var _beam_start_angle  : float         = 0.0
var _attack_cooldown   : float         = 0.0


func _ready() -> void:
	max_health      = 50
	personality     = Personality.BOSS
	damage          = 7
	knockback_force = 500.0

	super._ready()

	set_meta("monster_type", "plant3_boss")
	viewport_rect = Rect2(Vector2.ZERO, world_size)

	_build_sprite_frames()
	_sprite.animation_finished.connect(_on_animation_finished)


func set_world_size(size: Vector2) -> void:
	world_size    = size
	viewport_rect = Rect2(Vector2.ZERO, size)


func set_playable_rect(rect: Rect2) -> void:
	viewport_rect = rect


func _reset_modulate() -> void:
	modulate = Color.WHITE


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["Idle", "Walk", "Walk_attack", "Hurt", "Death"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path := "%s%s/Plant3_%s_%s.aseprite" % [ASSET_BASE, anim, anim, dir]
			_merge_anim(sf, anim_name, path)
	_sprite.sprite_frames = sf


func _merge_anim(sf: SpriteFrames, anim_name: String, path: String) -> void:
	var src: SpriteFrames = load(path) as SpriteFrames
	var one_shot: bool = anim_name.begins_with("hurt") or anim_name.begins_with("death") \
		or anim_name.begins_with("walk_attack")
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


func _play_walk()        -> void: _play_anim("walk")
func _play_idle()        -> void: _play_anim("idle")
func _play_walk_attack() -> void: _play_anim("walk_attack")


# ── Damage / Death overrides ──────────────────────────────────────────────────

func take_damage(amount: int, knockback_vec: Vector2) -> void:
	super.take_damage(amount, knockback_vec)
	if health <= 0:
		return
	if _boss_phase != PlantBossPhase.CREEP:
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
	queue_redraw()
	SceneManager.earn_slime_goop(15)
	_sprite.flip_h = false
	match facing:
		"down":  _sprite.play("death_front")
		"up":    _sprite.play("death_back")
		"right": _sprite.play("death_right")
		"left":  _sprite.play("death_left")


# ── Starburst telegraph draw ──────────────────────────────────────────────────

func _draw() -> void:
	if _boss_phase != PlantBossPhase.TELEGRAPH:
		return
	var alpha := _telegraph_timer / TELEGRAPH_DURATION
	for i: int in 5:
		var angle := _beam_start_angle + i * (TAU / 5.0)
		draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
		draw_rect(
			Rect2(0.0, -BEAM_HALF_WIDTH, BEAM_REACH, BEAM_HALF_WIDTH * 2.0),
			Color(1.0, 0.5, 0.0, 0.35 * alpha)
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ── Starburst hit check ───────────────────────────────────────────────────────

func _check_starburst_hit() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	if _distance_to_player() > BEAM_REACH:
		return
	var angle_to_player := \
		(global_position.direction_to(_player_ref.global_position)).angle()
	for i: int in 5:
		var beam_center := _beam_start_angle + i * (TAU / 5.0)
		var diff := absf(wrapf(angle_to_player - beam_center, -PI, PI))
		if diff <= BEAM_HALF_WIDTH_RADIANS:
			var kb_dir := (_player_ref.global_position - global_position).normalized()
			_player_ref.call_deferred("take_damage", AOE_DAMAGE, kb_dir * AOE_KNOCKBACK)
			return


# ── AI / Physics ──────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	super._physics_process(delta)

	_attack_cooldown = max(0.0, _attack_cooldown - delta)

	match _boss_phase:
		PlantBossPhase.CREEP:
			if _player_ref != null and is_instance_valid(_player_ref):
				linear_velocity = _direction_to_player_with_noise(BOSS_CREEP_SPEED)
				_update_facing(linear_velocity)
				_play_walk()
			if _attack_cooldown <= 0.0 and _distance_to_player() < ATTACK_TRIGGER_RADIUS:
				_boss_phase       = PlantBossPhase.TELEGRAPH
				_telegraph_timer  = 0.0
				_beam_start_angle = randf() * TAU
				linear_velocity   = Vector2.ZERO
				_play_idle()

		PlantBossPhase.TELEGRAPH:
			linear_velocity   = Vector2.ZERO
			_telegraph_timer += delta
			queue_redraw()
			if _telegraph_timer >= TELEGRAPH_DURATION:
				_boss_phase = PlantBossPhase.FIRE

		PlantBossPhase.FIRE:
			linear_velocity = Vector2.ZERO
			_check_starburst_hit()
			queue_redraw()
			_play_walk_attack()
			_boss_phase      = PlantBossPhase.CREEP
			_attack_cooldown = ATTACK_COOLDOWN


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

	if _player_ref != null and is_instance_valid(_player_ref):
		var to_player : Vector2 = _player_ref.global_position - pos
		var min_sep   : float   = MOB_RADIUS + 30.0
		if to_player.length() < min_sep and to_player.length() > 0.0:
			pos -= to_player.normalized() * (min_sep - to_player.length())
			hit_wall = true

	var x_min := viewport_rect.position.x + MOB_RADIUS
	var x_max := viewport_rect.end.x - MOB_RADIUS
	var y_min := viewport_rect.position.y + MOB_RADIUS
	var y_max := viewport_rect.end.y - MOB_RADIUS
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
		_play_walk()
