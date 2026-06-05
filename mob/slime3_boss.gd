extends "res://mob/mob_base.gd"

# ── Constants ────────────────────────────────────────────────────────────────

const ASSET_BASE         := "res://assets/Slime3/"
const MOB_RADIUS         : float = 40.0
const BOSS_SPEED         : float = 60.0
const AOE_DAMAGE         : int   = 7
const AOE_KNOCKBACK      : float = 700.0
const AOE_RADIUS         : float = 150.0
const ATTACK_COOLDOWN    : float = 5.0
const TELEGRAPH_DURATION : float = 1.5

# ── Boss phase ────────────────────────────────────────────────────────────────

enum BossPhase { NORMAL, TELEGRAPH, ATTACKING }

# ── Exports ───────────────────────────────────────────────────────────────────

@export var world_size: Vector2 = Vector2(3840.0, 2160.0)

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── State ─────────────────────────────────────────────────────────────────────

var viewport_rect     : Rect2
var facing            : String    = "down"
var _is_dying         : bool      = false
var _is_hurt          : bool      = false
var _boss_phase       : BossPhase = BossPhase.NORMAL
var _aoe_cooldown     : float     = 0.0
var _telegraph_timer  : float     = 0.0
var _telegraph_radius : float     = 0.0


func _ready() -> void:
	max_health      = 30
	personality     = Personality.BOSS
	damage          = 5
	knockback_force = 600.0

	super._ready()

	set_meta("monster_type", "slime3_boss")
	viewport_rect = Rect2(Vector2.ZERO, world_size)

	_build_sprite_frames()
	_sprite.animation_finished.connect(_on_animation_finished)


func set_world_size(size: Vector2) -> void:
	world_size    = size
	viewport_rect = Rect2(Vector2.ZERO, world_size)


func set_playable_rect(rect: Rect2) -> void:
	viewport_rect = rect


func _reset_modulate() -> void:
	modulate = Color.WHITE


# ── Sprite setup ──────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim: String in ["Idle", "Walk", "Run", "Hurt", "Death", "Attack"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path := "%s%s/Slime3_%s_%s.aseprite" % [ASSET_BASE, anim, anim, dir]
			_merge_anim(sf, anim_name, path)
	_sprite.sprite_frames = sf


func _merge_anim(sf: SpriteFrames, anim_name: String, path: String) -> void:
	var src: SpriteFrames = load(path) as SpriteFrames
	var one_shot := anim_name.begins_with("hurt") or anim_name.begins_with("death") \
		or anim_name.begins_with("attack")
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


func _play_run() -> void:
	_play_anim("run")


func _play_attack() -> void:
	_sprite.flip_h = false
	match facing:
		"down":  _sprite.play("attack_front")
		"up":    _sprite.play("attack_back")
		"right": _sprite.play("attack_right")
		"left":  _sprite.play("attack_left")


# ── AOE Telegraph / Attack ────────────────────────────────────────────────────

func _start_telegraph() -> void:
	_boss_phase       = BossPhase.TELEGRAPH
	_telegraph_timer  = 0.0
	_telegraph_radius = 0.0


func _fire_aoe() -> void:
	_boss_phase       = BossPhase.ATTACKING
	_telegraph_radius = 0.0
	queue_redraw()
	_play_attack()
	if _distance_to_player() <= AOE_RADIUS \
			and _player_ref != null and is_instance_valid(_player_ref):
		var kb_dir: Vector2 = \
			(_player_ref.global_position - global_position).normalized()
		_player_ref.call_deferred("take_damage", AOE_DAMAGE, kb_dir * AOE_KNOCKBACK)


func _draw() -> void:
	if _telegraph_radius > 0.0:
		var alpha: float = _telegraph_timer / TELEGRAPH_DURATION
		var r: float = _telegraph_radius
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.0, 0.0, 0.25 * alpha))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 0.0, 0.0, 0.9), 2.0)


# ── Damage / Death overrides ──────────────────────────────────────────────────

func take_damage(amount: int, knockback_vec: Vector2) -> void:
	super.take_damage(amount, knockback_vec)
	if health <= 0:
		return
	if _boss_phase != BossPhase.NORMAL:
		return
	_is_hurt = true
	_sprite.flip_h = false
	match facing:
		"down":  _sprite.play("hurt_front")
		"up":    _sprite.play("hurt_back")
		"right": _sprite.play("hurt_right")
		"left":  _sprite.play("hurt_left")


func _on_died() -> void:
	_is_dying         = true
	_is_hurt          = false
	_boss_phase       = BossPhase.NORMAL
	_telegraph_radius = 0.0
	died.emit(self)
	linear_velocity = Vector2.ZERO
	queue_redraw()
	SceneManager.earn_slime_goop(20)
	_sprite.flip_h = false
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

	_aoe_cooldown = max(0.0, _aoe_cooldown - delta)

	match _boss_phase:
		BossPhase.NORMAL:
			if _player_ref != null and is_instance_valid(_player_ref):
				linear_velocity = _direction_to_player_with_noise(BOSS_SPEED)
				_update_facing(linear_velocity)
				_play_run()
			if _aoe_cooldown <= 0.0 and _distance_to_player() <= AOE_RADIUS:
				_start_telegraph()
		BossPhase.TELEGRAPH:
			linear_velocity   = Vector2.ZERO
			_telegraph_timer  += delta
			_telegraph_radius  = (AOE_RADIUS / scale.x) * (_telegraph_timer / TELEGRAPH_DURATION)
			queue_redraw()
			if _telegraph_timer >= TELEGRAPH_DURATION:
				_fire_aoe()
		BossPhase.ATTACKING:
			linear_velocity = Vector2.ZERO


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

	# Player separation
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
		_play_run()
		return
	if _boss_phase == BossPhase.ATTACKING:
		_boss_phase   = BossPhase.NORMAL
		_aoe_cooldown = ATTACK_COOLDOWN
		_play_run()
