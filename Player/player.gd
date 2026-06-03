extends CharacterBody2D

signal hit
signal fly_caught
signal weapon_changed(weapon_name: String)

@export var speed: float = PlayerStats.BASE_SPEED

@onready var _sprite     : AnimatedSprite2D  = $AnimatedSprite2D
@onready var _body_shape : CollisionShape2D  = $CollisionShape2D
@onready var _sword      : Area2D            = $SwordHitbox

var _world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0))

var facing       : Vector2 = Vector2.RIGHT
var is_attacking : bool    = false
var is_dying     : bool    = false
var _death_signal: String  = ""

var health          : int   = PlayerStats.MAX_HEALTH
var _iframes        : float = 0.0
var _is_hurt        : bool  = false
var combat_enabled  : bool  = false

# ── Dodge ────────────────────────────────────────────────────────────────────

var is_dodging      : bool    = false
var _dodge_timer    : float   = 0.0
var _cooldown_timer : float   = 0.0
var _last_move_dir  : Vector2 = Vector2.RIGHT

# ── Roll ──────────────────────────────────────────────────────────────────────

var is_rolling           : bool  = false
var _roll_timer          : float = 0.0
var _roll_cooldown_timer : float = 0.0

# ── Knockback ─────────────────────────────────────────────────────────────────

var _knockback_vel : Vector2 = Vector2.ZERO
var _knockback_time: float   = 0.0

# ── Weapon system ─────────────────────────────────────────────────────────────

var _weapon_stats: Dictionary = {}
var active_weapon: String     = SwordData.ID

# ── Sprite sheet rows ─────────────────────────────────────────────────────────

const ROW_DOWN  = 0
const ROW_RIGHT = 2
const ROW_UP    = 3
const FRAME_SIZE = 64


func _ready() -> void:
	_weapon_stats = {
		SwordData.ID: {
			"damage":    SwordData.DAMAGE,
			"swing_fps": SwordData.SWING_FPS,
			"knockback": SwordData.KNOCKBACK,
			"hitbox":    SwordData.hitbox,
		},
		AxeData.ID: {
			"damage":    AxeData.DAMAGE,
			"swing_fps": AxeData.SWING_FPS,
			"knockback": AxeData.KNOCKBACK,
			"hitbox":    AxeData.hitbox,
		},
	}
	add_to_group("player")
	_build_sprite_frames()
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_sword.body_entered.connect(_on_sword_hit)
	hide()


# ── World bounds ──────────────────────────────────────────────────────────────

func set_world_bounds(bounds: Rect2) -> void:
	_world_bounds = bounds


# ── Sprite sheet setup ────────────────────────────────────────────────────────

func _make_atlas(sheet: Texture2D, col: int, row: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = sheet
	a.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
	return a


func _add_anim(sf: SpriteFrames, anim: String, sheet: Texture2D,
			   row: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(anim)
	sf.set_animation_loop(anim, loop)
	sf.set_animation_speed(anim, fps)
	for i in count:
		sf.add_frame(anim, _make_atlas(sheet, i, row))


func _build_sprite_frames() -> void:
	var base := "res://assets/Swordsman_lvl1/Without_shadow/"
	var idle_tex  : Texture2D = load(base + "Swordsman_lvl1_Idle_without_shadow.png")
	var walk_tex  : Texture2D = load(base + "Swordsman_lvl1_Walk_without_shadow.png")
	var atk_tex   : Texture2D = load(base + "Swordsman_lvl1_attack_without_shadow.png")
	var hurt_tex  : Texture2D = load(base + "Swordsman_lvl1_Hurt_without_shadow.png")
	var death_tex : Texture2D = load(base + "Swordsman_lvl1_Death_without_shadow.png")

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	_add_anim(sf, "idle",         idle_tex, ROW_RIGHT, 12, 8.0,  true)
	_add_anim(sf, "idle_up",      idle_tex, ROW_UP,     4, 8.0,  true)
	_add_anim(sf, "idle_down",    idle_tex, ROW_DOWN,  12, 8.0,  true)

	_add_anim(sf, "walk",         walk_tex, ROW_RIGHT,  6, 8.0,  true)
	_add_anim(sf, "walk_up",      walk_tex, ROW_UP,     6, 8.0,  true)
	_add_anim(sf, "walk_down",    walk_tex, ROW_DOWN,   6, 8.0,  true)

	_add_anim(sf, "attack",       atk_tex, ROW_RIGHT, 8, 20.0, false)
	_add_anim(sf, "attack_up",    atk_tex, ROW_UP,    8, 20.0, false)
	_add_anim(sf, "attack_down",  atk_tex, ROW_DOWN,  8, 20.0, false)

	_add_anim(sf, "hurt",  hurt_tex,  ROW_RIGHT, 5, 12.0, false)
	_add_anim(sf, "death", death_tex, ROW_RIGHT, 7, 10.0, false)

	_sprite.sprite_frames = sf
	_sprite.play("idle")


# ── Game loop ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if is_dying:
		return
	if _iframes > 0.0:
		_iframes -= delta

	# Dodge timers
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			is_dodging = false
			modulate = Color.WHITE
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	# Roll timers
	if _roll_timer > 0.0:
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			is_rolling = false
			modulate = Color.WHITE
	if _roll_cooldown_timer > 0.0:
		_roll_cooldown_timer -= delta

	# Knockback timer
	if _knockback_time > 0.0:
		_knockback_time -= delta

	var move_input := Vector2.ZERO
	if Input.is_action_pressed(PlayerInput.MOVE_RIGHT): move_input.x += 1
	if Input.is_action_pressed(PlayerInput.MOVE_LEFT):  move_input.x -= 1
	if Input.is_action_pressed(PlayerInput.MOVE_DOWN):  move_input.y += 1
	if Input.is_action_pressed(PlayerInput.MOVE_UP):    move_input.y -= 1

	if move_input.length() > 0:
		facing = move_input.normalized()
		_last_move_dir = facing

	var move_vel: Vector2

	if is_attacking:
		move_vel = Vector2.ZERO
	elif is_dodging:
		move_vel = -facing.normalized() * PlayerStats.DODGE_SPEED
	elif is_rolling:
		move_vel = facing.normalized() * PlayerStats.ROLL_SPEED
	elif _knockback_time > 0.0:
		move_vel = _knockback_vel
	else:
		if move_input.length() > 0:
			move_vel = facing * speed
		else:
			move_vel = Vector2.ZERO

	if combat_enabled:
		if Input.is_action_just_pressed(PlayerInput.ATTACK) and not is_attacking \
				and not is_dodging and not is_rolling:
			_start_attack()

		if Input.is_action_just_pressed(PlayerInput.DODGE) and not is_attacking \
				and not is_dying and _cooldown_timer <= 0.0 and not is_dodging and not is_rolling:
			_start_dodge()
			move_vel = -facing.normalized() * PlayerStats.DODGE_SPEED

		if Input.is_action_just_pressed(PlayerInput.ROLL) \
				and not is_attacking and not is_dying \
				and _roll_cooldown_timer <= 0.0 and not is_dodging and not is_rolling:
			_start_roll()
			move_vel = facing.normalized() * PlayerStats.ROLL_SPEED

	var can_swap: bool = not is_attacking and not is_dodging and not is_rolling
	if Input.is_action_just_pressed(PlayerInput.WEAPON_SWAP) and can_swap:
		_cycle_weapon()

	velocity = move_vel
	move_and_slide()
	position = position.clamp(_world_bounds.position, _world_bounds.end)

	if not is_attacking and not _is_hurt and not is_dodging and not is_rolling:
		_update_animation(move_vel if not is_dodging else Vector2.ZERO)


func _update_animation(move_dir: Vector2) -> void:
	var anim: String
	var flip := false

	if move_dir.length() == 0:
		if abs(facing.y) > abs(facing.x):
			anim = "idle_up" if facing.y < 0 else "idle_down"
		else:
			anim = "idle"
			flip = facing.x < 0
	else:
		if abs(move_dir.y) > abs(move_dir.x):
			anim = "walk_up" if move_dir.y < 0 else "walk_down"
		else:
			anim = "walk"
			flip = move_dir.x < 0

	_sprite.flip_h = flip
	if _sprite.animation != anim:
		_sprite.play(anim)
	elif not _sprite.is_playing():
		_sprite.play()


# ── Dodge ─────────────────────────────────────────────────────────────────────

func _start_dodge() -> void:
	is_dodging      = true
	_iframes        = PlayerStats.IFRAME_TIME
	_dodge_timer    = PlayerStats.DODGE_DURATION
	_cooldown_timer = PlayerStats.DODGE_COOLDOWN
	modulate        = Color(1.0, 1.0, 1.0, 0.5)


# ── Roll ──────────────────────────────────────────────────────────────────────

func _start_roll() -> void:
	is_rolling           = true
	_roll_timer          = PlayerStats.ROLL_DURATION
	_roll_cooldown_timer = PlayerStats.ROLL_COOLDOWN
	modulate             = Color(1.0, 1.0, 1.0, 0.6)


# ── Weapon system ─────────────────────────────────────────────────────────────

func _cycle_weapon() -> void:
	var owned := SceneManager.owned_weapons
	if owned.size() <= 1:
		return
	var idx      := owned.find(active_weapon)
	active_weapon = owned[(idx + 1) % owned.size()]
	weapon_changed.emit(active_weapon)


# ── Attack ────────────────────────────────────────────────────────────────────

func _start_attack() -> void:
	is_attacking = true

	var stats: Dictionary = _weapon_stats.get(active_weapon, _weapon_stats[SwordData.ID])

	# Snap to 4 cardinal directions
	var attack_dir: Vector2
	if abs(facing.y) > abs(facing.x):
		attack_dir = Vector2(0.0, -1.0 if facing.y < 0.0 else 1.0)
	else:
		attack_dir = Vector2(-1.0 if facing.x < 0.0 else 1.0, 0.0)

	_sword.position = attack_dir * 10.0
	_sword.scale.x  = -1.0 if _sprite.flip_h else 1.0

	# Resize hitbox — swap x/y when facing up or down so the box stays weapon-relative
	var shape_node := _sword.get_node("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is RectangleShape2D:
		var base_size : Vector2 = stats["hitbox"]
		var swapped   : Vector2 = Vector2(base_size.y, base_size.x)
		var hitbox    : Vector2 = swapped if attack_dir.y != 0.0 else base_size
		(shape_node.shape as RectangleShape2D).size = hitbox

	# Set swing speed
	for anim_name in ["attack", "attack_up", "attack_down"]:
		_sprite.sprite_frames.set_animation_speed(anim_name, stats["swing_fps"])

	var anim: String
	if attack_dir.y != 0.0:
		anim = "attack_up" if attack_dir.y < 0.0 else "attack_down"
		_sprite.flip_h = false
	else:
		anim = "attack"
		_sprite.flip_h = attack_dir.x < 0.0

	_sprite.play(anim)


func _on_frame_changed() -> void:
	if not is_attacking:
		return
	var f := _sprite.frame
	_sword.monitoring = (f >= 2 and f <= 6)


func _on_animation_finished() -> void:
	var anim := _sprite.animation
	if anim in ["attack", "attack_up", "attack_down"]:
		is_attacking      = false
		_sword.monitoring = false
		_update_animation(Vector2.ZERO)
	elif anim == "hurt":
		_is_hurt = false
		_sprite.flip_h = false
		if health <= 0:
			_sprite.play("death")
		else:
			_update_animation(Vector2.ZERO)
	elif anim == "death":
		if _death_signal == "hit":
			hit.emit()
		elif _death_signal == "fly_caught":
			fly_caught.emit()
		_death_signal = ""


# ── Collision ──────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if is_dying:
		return
	if body.is_in_group("flying_mobs") or body.is_in_group("ground_mobs"):
		var mob_damage: int = 1
		var mob_kb_force: float = 150.0
		if "damage" in body:
			mob_damage = body.damage
		if "knockback_force" in body:
			mob_kb_force = body.knockback_force
		var kb_dir: Vector2 = (global_position - body.global_position).normalized()
		call_deferred("take_damage", mob_damage, kb_dir * mob_kb_force)


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dying or _iframes > 0.0:
		return
	health -= amount
	SceneManager.set_player_health(health)
	_iframes     = PlayerStats.IFRAME_TIME
	is_attacking = false
	_sword.monitoring = false
	if knockback.length_squared() > 0.0:
		_knockback_vel  = knockback
		_knockback_time = PlayerStats.KNOCKBACK_DURATION
	if health <= 0:
		_start_dying("hit")
	else:
		_is_hurt = true
		_sprite.play("hurt")


func _start_dying(signal_name: String) -> void:
	if is_dying:
		return
	is_dying      = true
	_death_signal = signal_name
	is_attacking  = false
	_sword.monitoring = false
	_body_shape.set_deferred("disabled", true)
	_sprite.flip_h = false
	_sprite.play("hurt")


func _on_sword_hit(body: Node2D) -> void:
	if is_dying:
		return
	if body.is_in_group("flying_mobs") or body.is_in_group("ground_mobs"):
		if body.has_method("take_damage"):
			var stats: Dictionary = _weapon_stats.get(active_weapon, _weapon_stats[SwordData.ID])
			var knockback: Vector2 = (body.global_position - global_position).normalized() \
							* float(stats["knockback"])
			body.take_damage(stats["damage"], knockback)


# ── Public API ────────────────────────────────────────────────────────────────

func set_gameplay_active(enabled: bool) -> void:
	set_process(enabled)
	set_process_input(enabled)


func start(pos: Vector2, combat: bool = false) -> void:
	is_dying     = false
	is_attacking = false
	is_dodging   = false
	is_rolling   = false
	combat_enabled = combat
	_death_signal        = ""
	_dodge_timer         = 0.0
	_cooldown_timer      = 0.0
	_roll_timer          = 0.0
	_roll_cooldown_timer = 0.0
	_knockback_vel       = Vector2.ZERO
	_knockback_time      = 0.0
	facing          = Vector2.RIGHT
	_last_move_dir  = Vector2.RIGHT
	_body_shape.disabled = false
	_sword.monitoring    = false
	_sprite.flip_h       = false
	_iframes  = 0.0
	_is_hurt  = false
	health    = PlayerStats.MAX_HEALTH
	modulate  = Color.WHITE
	SceneManager.set_player_health(health)
	_sprite.play("idle")
	position = pos
	show()
