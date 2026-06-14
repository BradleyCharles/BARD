extends "res://mob/mob_base.gd"

# ── Constants ─────────────────────────────────────────────────────────────────

const ASSET_BASE             : String = "res://assets/mobs/Orc3/"
const MOB_RADIUS             : float  = 40.0
const BOSS_SPEED             : float  = 70.0
const CHARGE_SPEED           : float  = 500.0
const CHARGE_DURATION        : float  = 1.0
const TELEGRAPH_DURATION     : float  = 1.5
const RECOVER_DURATION       : float  = 1.0
const ATTACK_COOLDOWN        : float  = 5.0
const CHARGE_TRIGGER_RADIUS  : float  = 350.0

# ── AI phase ──────────────────────────────────────────────────────────────────

enum OrcBossPhase { NORMAL, TELEGRAPH, CHARGE, RECOVER }

# ── Exports ───────────────────────────────────────────────────────────────────

@export var world_size: Vector2 = Vector2(3840.0, 2160.0)

# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── State ─────────────────────────────────────────────────────────────────────

var viewport_rect      : Rect2
var facing             : String       = "down"
var _is_dying          : bool         = false
var _is_hurt           : bool         = false
var _is_attacking      : bool         = false
var _boss_phase        : OrcBossPhase = OrcBossPhase.NORMAL
var _charge_dir        : Vector2      = Vector2.ZERO
var _phase_timer       : float        = 0.0
var _attack_cooldown   : float        = 0.0


func _ready() -> void:
	max_health      = 60
	personality     = Personality.BOSS
	damage          = 6
	knockback_force = 600.0

	super._ready()

	set_meta("monster_type", "orc3_boss")
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
	for anim: String in ["Idle", "Walk", "Run_attack", "Hurt", "Death"]:
		for dir: String in ["front", "back", "left", "right"]:
			var anim_name := anim.to_lower() + "_" + dir
			var path := "%sOrc3_%s/orc3_%s_%s.aseprite" % [ASSET_BASE, anim.to_lower(), dir, anim.to_lower()]
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


func _play_run()        -> void: _play_anim("walk")
func _play_idle()       -> void: _play_anim("idle")
func _play_run_attack() -> void: _play_anim("run_attack")


# ── Damage / Death overrides ──────────────────────────────────────────────────

func take_damage(amount: int, knockback_vec: Vector2) -> void:
	super.take_damage(amount, knockback_vec)
	if health <= 0:
		return
	if _boss_phase == OrcBossPhase.CHARGE or _boss_phase == OrcBossPhase.TELEGRAPH:
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
	queue_redraw()
	SceneManager.earn_slime_goop(15)
	_sprite.flip_h = false
	match facing:
		"down":  _sprite.play("death_front")
		"up":    _sprite.play("death_back")
		"right": _sprite.play("death_right")
		"left":  _sprite.play("death_left")


# ── Telegraph draw ────────────────────────────────────────────────────────────

func _draw() -> void:
	if _boss_phase != OrcBossPhase.TELEGRAPH:
		return
	var alpha := _phase_timer / TELEGRAPH_DURATION
	var length := CHARGE_SPEED * CHARGE_DURATION
	var half_w := 20.0
	var angle  := _charge_dir.angle()
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	draw_rect(Rect2(0.0, -half_w, length, half_w * 2.0), Color(1.0, 0.5, 0.0, 0.35 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ── AI / Physics ──────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _is_dying:
		return
	super._physics_process(delta)

	_attack_cooldown = max(0.0, _attack_cooldown - delta)

	match _boss_phase:
		OrcBossPhase.NORMAL:
			if _player_ref != null and is_instance_valid(_player_ref):
				linear_velocity = _direction_to_player_with_noise(BOSS_SPEED)
				_update_facing(linear_velocity)
				_play_run()
			if _attack_cooldown <= 0.0 \
					and _distance_to_player() < CHARGE_TRIGGER_RADIUS \
					and _player_ref != null:
				_charge_dir  = global_position.direction_to(_player_ref.global_position)
				_update_facing(_charge_dir)
				_boss_phase  = OrcBossPhase.TELEGRAPH
				_phase_timer = 0.0
				linear_velocity = Vector2.ZERO
				_play_idle()

		OrcBossPhase.TELEGRAPH:
			_phase_timer += delta
			linear_velocity = Vector2.ZERO
			queue_redraw()
			if _phase_timer >= TELEGRAPH_DURATION:
				_boss_phase   = OrcBossPhase.CHARGE
				_phase_timer  = 0.0
				_is_attacking = true
				queue_redraw()

		OrcBossPhase.CHARGE:
			_phase_timer    += delta
			linear_velocity  = _charge_dir * CHARGE_SPEED
			_update_facing(_charge_dir)
			_play_run_attack()
			if _phase_timer >= CHARGE_DURATION:
				_boss_phase   = OrcBossPhase.RECOVER
				_phase_timer  = 0.0
				_is_attacking = false
				linear_velocity = Vector2.ZERO
				_play_idle()

		OrcBossPhase.RECOVER:
			_phase_timer    += delta
			linear_velocity  = Vector2.ZERO
			if _phase_timer >= RECOVER_DURATION:
				_boss_phase      = OrcBossPhase.NORMAL
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
		_play_run()
