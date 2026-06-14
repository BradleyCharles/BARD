extends CharacterBody2D

signal hit
signal fly_caught
signal weapon_changed(weapon_name: String)
signal attack_connected(weapon_id: String, hit_point: Vector2, attack_dir: Vector2)

enum PlayerState { IDLE, MOVE, ATTACK, HURT, DODGE, DEAD }

@export var speed: float = PlayerStats.BASE_SPEED
@export var sprite_scale: float = 1.0:
	set(v):
		sprite_scale = v
		scale = Vector2.ONE * v

@onready var _sprite     : AnimatedSprite2D  = $AnimatedSprite2D
@onready var _body_shape : CollisionShape2D  = $CollisionShape2D
@onready var _sword      : Area2D            = $SwordHitbox
@onready var _hurt_area  : Area2D            = $HurtArea

var facing        : Vector2 = Vector2.RIGHT
var is_attacking  : bool    = false   # kept for external compat; driven by _state
var is_dying      : bool    = false
var _death_signal : String  = ""

var health         : int   = PlayerStats.MAX_HEALTH
var _iframes       : float = 0.0
var _is_hurt       : bool  = false    # kept for external compat; driven by _state
var combat_enabled : bool  = false

var _state: PlayerState = PlayerState.IDLE

# ── Attack buffer ──────────────────────────────────────────────────────────────

const _ATTACK_BUFFER_WINDOW: float = 0.15
var _attack_buffer: float = 0.0

# ── Dodge ──────────────────────────────────────────────────────────────────────

var is_dodging      : bool    = false   # driven by _state
var _dodge_timer    : float   = 0.0
var _cooldown_timer : float   = 0.0
var _last_move_dir  : Vector2 = Vector2.RIGHT

# ── Knockback ──────────────────────────────────────────────────────────────────

var _knockback_vel  : Vector2 = Vector2.ZERO
var _knockback_time : float   = 0.0

# ── Weapon system ──────────────────────────────────────────────────────────────

var _weapon_stats   : Dictionary       = {}
var active_weapon   : String           = SwordData.ID
var _weapon_sprite  : AnimatedSprite2D = null

var _player_radius      : float = 0.0
var _post_unpause_grace : float = 0.0
var _hitstop_active     : bool  = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		_post_unpause_grace = 0.15


# Synchronises the convenience booleans with the authoritative _state.
func _set_state(new_state: PlayerState) -> void:
	_state       = new_state
	is_attacking = new_state == PlayerState.ATTACK
	_is_hurt     = new_state == PlayerState.HURT
	is_dodging   = new_state == PlayerState.DODGE


func _ready() -> void:
	_weapon_stats = {
		SwordData.ID: {
			"damage":          SwordData.DAMAGE,
			"swing_fps":       SwordData.SWING_FPS,
			"knockback":       SwordData.KNOCKBACK,
			"hitbox":          SwordData.hitbox,
			"sprite_size":     SwordData.sprite_size,
			"sprite_path":     SwordData.SPRITE_PATH,
			"frame_count":     SwordData.FRAME_COUNT,
			"native_size":     SwordData.NATIVE_SIZE,
			"hit_frame_start": SwordData.HIT_FRAME_START,
			"hit_frame_end":   SwordData.HIT_FRAME_END,
			"hitbox_offset":   SwordData.HITBOX_OFFSET,
			"move_modifier":   SwordData.MOVE_MODIFIER,
			"hitstop":         SwordData.HITSTOP,
		},
		AxeData.ID: {
			"damage":          AxeData.DAMAGE,
			"swing_fps":       AxeData.SWING_FPS,
			"knockback":       AxeData.KNOCKBACK,
			"hitbox":          AxeData.hitbox,
			"sprite_size":     AxeData.sprite_size,
			"sprite_path":     AxeData.SPRITE_PATH,
			"frame_count":     AxeData.FRAME_COUNT,
			"native_size":     AxeData.NATIVE_SIZE,
			"hit_frame_start": AxeData.HIT_FRAME_START,
			"hit_frame_end":   AxeData.HIT_FRAME_END,
			"hitbox_offset":   AxeData.HITBOX_OFFSET,
			"move_modifier":   AxeData.MOVE_MODIFIER,
			"hitstop":         AxeData.HITSTOP,
		},
	}
	add_to_group("player")
	collision_mask = 1
	_player_radius = (_body_shape.shape as CapsuleShape2D).radius
	_build_sprite_frames()
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.animation_finished.connect(_on_animation_finished)
	_sword.body_entered.connect(_on_sword_hit)
	_sword.collision_mask     = 8
	_hurt_area.collision_mask = 8
	_weapon_sprite = AnimatedSprite2D.new()
	_weapon_sprite.z_index = 1
	_weapon_sprite.visible = false
	add_child(_weapon_sprite)
	_build_weapon_frames()
	_weapon_sprite.animation_finished.connect(_on_weapon_anim_finished)
	hide()


# ── Sprite setup ───────────────────────────────────────────────────────────────

func _build_sprite_frames() -> void:
	const B := "res://assets/Swordsman_lvl3/Swordsman_lvl3_"
	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	_copy_anim(sf, "idle",        B + "Idle/Swordsman_lvl3_Idle_side_right.aseprite",   8.0, true)
	_copy_anim(sf, "idle_up",     B + "Idle/Swordsman_lvl3_Idle_back.aseprite",          8.0, true)
	_copy_anim(sf, "idle_down",   B + "Idle/Swordsman_lvl3_Idle_front.aseprite",         8.0, true)

	_copy_anim(sf, "walk",        B + "Walk/Swordsman_lvl3_Walk_side_right.aseprite",   8.0, true)
	_copy_anim(sf, "walk_up",     B + "Walk/Swordsman_lvl3_Walk_back.aseprite",          8.0, true)
	_copy_anim(sf, "walk_down",   B + "Walk/Swordsman_lvl3_Walk_front.aseprite",         8.0, true)

	_copy_anim(sf, "run",         B + "Run/Swordsman_lvl3_Run_side_right.aseprite",    12.0, true)
	_copy_anim(sf, "run_up",      B + "Run/Swordsman_lvl3_Run_back.aseprite",           12.0, true)
	_copy_anim(sf, "run_down",    B + "Run/Swordsman_lvl3_Run_front.aseprite",          12.0, true)

	var B_atk := B + "Attack/Swordsman_lvl3_attack_"
	_copy_anim(sf, "attack",      B_atk + "side_right.aseprite", 20.0, false)
	_copy_anim(sf, "attack_up",   B_atk + "back.aseprite",       20.0, false)
	_copy_anim(sf, "attack_down", B_atk + "front.aseprite",      20.0, false)

	_copy_anim(sf, "hurt",  B + "Hurt/Swordsman_lvl3_Hurt_side_right.aseprite",  12.0, false)
	_copy_anim(sf, "death", B + "Death/Swordsman_lvl3_Death_side_right.aseprite", 10.0, false)

	_sprite.sprite_frames = sf
	_sprite.play("idle")


func _copy_anim(sf: SpriteFrames, anim: String, path: String, fps: float, loop: bool) -> void:
	var src: SpriteFrames = load(path)
	var src_anim: String = src.get_animation_names()[0]
	sf.add_animation(anim)
	sf.set_animation_loop(anim, loop)
	sf.set_animation_speed(anim, fps)
	for i: int in src.get_frame_count(src_anim):
		sf.add_frame(anim, src.get_frame_texture(src_anim, i))


func _build_weapon_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	for weapon_id: String in _weapon_stats:
		var ws: Dictionary = _weapon_stats[weapon_id]
		sf.add_animation(weapon_id)
		sf.set_animation_loop(weapon_id, false)
		sf.set_animation_speed(weapon_id, ws["swing_fps"])
		for i: int in range(1, int(ws["frame_count"]) + 1):
			sf.add_frame(weapon_id, load(ws["sprite_path"] + "%d.png" % i))

	_weapon_sprite.sprite_frames = sf


func _on_weapon_anim_finished() -> void:
	if not is_attacking:
		_weapon_sprite.visible = false


# ── Game loop ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if is_dying:
		return
	if _iframes > 0.0:
		_iframes -= delta
		if _iframes <= 0.0:
			_iframes = 0.0
			_apply_contact_damage()
	if _post_unpause_grace > 0.0:
		_post_unpause_grace -= delta
	if _attack_buffer > 0.0:
		_attack_buffer -= delta

	# Dodge timers
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			if _state == PlayerState.DODGE:
				_set_state(PlayerState.IDLE)
			modulate = Color.WHITE
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

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

	var is_running: bool = Input.is_action_pressed(PlayerInput.RUN) \
			and _state not in [PlayerState.ATTACK, PlayerState.DODGE, PlayerState.HURT]

	var move_vel: Vector2

	match _state:
		PlayerState.ATTACK:
			var stats: Dictionary = _weapon_stats.get(active_weapon, _weapon_stats[SwordData.ID])
			var modifier: float   = float(stats.get("move_modifier", 0.0))
			if modifier > 0.0 and move_input.length() > 0:
				move_vel = move_input.normalized() * speed * modifier
			else:
				move_vel = Vector2.ZERO
		PlayerState.DODGE:
			move_vel = facing.normalized() * PlayerStats.DODGE_SPEED
		PlayerState.HURT:
			move_vel = _knockback_vel if _knockback_time > 0.0 else Vector2.ZERO
		_:  # IDLE or MOVE — state driven below
			if _knockback_time > 0.0:
				move_vel = _knockback_vel
			elif move_input.length() > 0:
				var spd_mult: float = PlayerStats.RUN_SPEED_MULTIPLIER if is_running else 1.0
				var current_speed: float = speed * spd_mult
				move_vel = facing * current_speed
				_state = PlayerState.MOVE
			else:
				move_vel = Vector2.ZERO
				_state = PlayerState.IDLE

	if combat_enabled:
		if Input.is_action_just_pressed(PlayerInput.ATTACK):
			if _state not in [PlayerState.ATTACK, PlayerState.DODGE, PlayerState.HURT] \
					and not is_dying:
				_start_attack()
			elif _state == PlayerState.ATTACK:
				_attack_buffer = _ATTACK_BUFFER_WINDOW

		if Input.is_action_just_pressed(PlayerInput.DODGE) \
				and _state not in [PlayerState.ATTACK, PlayerState.HURT] \
				and not is_dying and _cooldown_timer <= 0.0 \
				and _state != PlayerState.DODGE \
				and _post_unpause_grace <= 0.0:
			_start_dodge()
			move_vel = facing.normalized() * PlayerStats.DODGE_SPEED

	var can_swap: bool = _state not in [PlayerState.ATTACK, PlayerState.DODGE]
	if Input.is_action_just_pressed(PlayerInput.WEAPON_SWAP) and can_swap:
		_cycle_weapon()

	velocity = _block_mob_movement(move_vel)
	move_and_slide()

	if _state not in [PlayerState.ATTACK, PlayerState.HURT, PlayerState.DODGE] and not is_dying:
		_update_animation(move_vel)


func _update_animation(move_dir: Vector2) -> void:
	var anim: String
	var flip := false
	var running: bool = Input.is_action_pressed(PlayerInput.RUN) and move_dir.length() > 0

	if move_dir.length() == 0:
		if abs(facing.y) > abs(facing.x):
			anim = "idle_up" if facing.y < 0 else "idle_down"
		else:
			anim = "idle"
			flip = facing.x < 0
	else:
		if abs(move_dir.y) > abs(move_dir.x):
			anim = ("run_up" if move_dir.y < 0 else "run_down") if running \
					else ("walk_up" if move_dir.y < 0 else "walk_down")
		else:
			anim = "run" if running else "walk"
			flip = move_dir.x < 0

	_sprite.flip_h = flip
	if _sprite.animation != anim:
		_sprite.play(anim)
	elif not _sprite.is_playing():
		_sprite.play()


# ── Dodge ──────────────────────────────────────────────────────────────────────

func _start_dodge() -> void:
	_set_state(PlayerState.DODGE)
	_iframes        = PlayerStats.IFRAME_TIME
	_dodge_timer    = PlayerStats.DODGE_DURATION
	_cooldown_timer = PlayerStats.DODGE_COOLDOWN
	modulate        = Color(1.0, 1.0, 1.0, 0.5)


# ── Weapon system ──────────────────────────────────────────────────────────────

func _cycle_weapon() -> void:
	var owned := SceneManager.owned_weapons
	if owned.size() <= 1:
		return
	var idx      := owned.find(active_weapon)
	active_weapon = owned[(idx + 1) % owned.size()]
	weapon_changed.emit(active_weapon)


# ── Attack ─────────────────────────────────────────────────────────────────────

func _start_attack() -> void:
	_sword.monitoring = false
	_set_state(PlayerState.ATTACK)

	var stats: Dictionary = _weapon_stats.get(active_weapon, _weapon_stats[SwordData.ID])

	# Snap facing to nearest of 8 directions (every 45°)
	var snapped_angle: float = round(facing.angle() / (PI / 4.0)) * (PI / 4.0)
	var attack_dir: Vector2  = Vector2.from_angle(snapped_angle)

	# Place and orient hitbox — rotation replaces the old x/y size swap
	_sword.position  = attack_dir * float(stats["hitbox_offset"])
	_sword.rotation  = snapped_angle
	_sword.scale.x   = 1.0
	var shape_node := _sword.get_node("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is RectangleShape2D:
		(shape_node.shape as RectangleShape2D).size = stats["hitbox"]

	# Player character animation: up/down by dominant y, flip for left half
	var anim: String
	if attack_dir.y < -0.5:
		anim = "attack_up"
	elif attack_dir.y > 0.5:
		anim = "attack_down"
	else:
		anim = "attack"
	_sprite.flip_h = attack_dir.x < 0.0

	for a: String in ["attack", "attack_up", "attack_down"]:
		_sprite.sprite_frames.set_animation_speed(a, stats["swing_fps"])
	_sprite.play(anim)

	# Weapon overlay: explicit per-direction rotation and flip.
	_weapon_sprite.flip_h = false
	_weapon_sprite.flip_v = false
	if is_equal_approx(snapped_angle, 0.0):                # E
		_weapon_sprite.rotation = 0.0
	elif is_equal_approx(snapped_angle, -PI / 4.0):        # NE
		_weapon_sprite.rotation = PI / 4.0 - PI / 2.0
	elif is_equal_approx(snapped_angle, -PI / 2.0):        # N
		_weapon_sprite.flip_v = true
		_weapon_sprite.rotation = -PI / 2.0
	elif is_equal_approx(snapped_angle, -3.0 * PI / 4.0): # NW
		_weapon_sprite.flip_h = true
		_weapon_sprite.rotation = -PI / 4.0 + PI / 2.0
	elif is_equal_approx(absf(snapped_angle), PI):         # W
		_weapon_sprite.flip_h = true
		_weapon_sprite.rotation = 0.0
	elif is_equal_approx(snapped_angle, 3.0 * PI / 4.0):  # SW
		_weapon_sprite.flip_h = true
		_weapon_sprite.rotation = PI / 4.0 - PI / 2.0
	elif is_equal_approx(snapped_angle, PI / 2.0):         # S
		_weapon_sprite.flip_v = true
		_weapon_sprite.rotation = PI / 2.0
	elif is_equal_approx(snapped_angle, PI / 4.0):         # SE
		_weapon_sprite.rotation = -PI / 4.0 + PI / 2.0

	_weapon_sprite.scale    = (stats["sprite_size"] as Vector2) / float(stats["native_size"])
	_weapon_sprite.position = _sword.position
	var player_frames: int  = _sprite.sprite_frames.get_frame_count(anim)
	var weapon_fps: float   = \
			float(stats["frame_count"]) * float(stats["swing_fps"]) / float(player_frames)
	_weapon_sprite.sprite_frames.set_animation_speed(active_weapon, weapon_fps)
	_weapon_sprite.play(active_weapon)
	_weapon_sprite.visible = true


func _on_frame_changed() -> void:
	if not is_attacking:
		return
	var stats: Dictionary = _weapon_stats.get(active_weapon, _weapon_stats[SwordData.ID])
	var f: int = _sprite.frame
	_sword.monitoring = f >= int(stats["hit_frame_start"]) and f <= int(stats["hit_frame_end"])


func _on_animation_finished() -> void:
	var anim := _sprite.animation
	if anim in ["attack", "attack_up", "attack_down"]:
		_sword.monitoring      = false
		_weapon_sprite.visible = false

		# Consume buffered attack first; otherwise fall through to movement
		if _attack_buffer > 0.0 and combat_enabled:
			_attack_buffer = 0.0
			_start_attack()
			return

		_set_state(PlayerState.IDLE)
		var move_input := Vector2.ZERO
		if Input.is_action_pressed(PlayerInput.MOVE_RIGHT): move_input.x += 1
		if Input.is_action_pressed(PlayerInput.MOVE_LEFT):  move_input.x -= 1
		if Input.is_action_pressed(PlayerInput.MOVE_DOWN):  move_input.y += 1
		if Input.is_action_pressed(PlayerInput.MOVE_UP):    move_input.y -= 1
		_update_animation(move_input.normalized() if move_input.length() > 0 else Vector2.ZERO)

	elif anim == "hurt":
		_set_state(PlayerState.IDLE)
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


# ── Hit stop ───────────────────────────────────────────────────────────────────

func _apply_hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active  = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true)
	Engine.time_scale = 1.0
	_hitstop_active  = false


# ── Impact particles ───────────────────────────────────────────────────────────

func _spawn_hit_particles(hit_pos: Vector2, dir: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.one_shot              = true
	p.explosiveness         = 0.95
	p.amount                = 10
	p.lifetime              = 0.35
	p.initial_velocity_min  = 60.0
	p.initial_velocity_max  = 160.0
	p.spread                = 55.0
	p.direction             = dir
	p.gravity               = Vector2.ZERO
	p.scale_amount_min      = 1.5
	p.scale_amount_max      = 3.0
	p.color                 = Color(1.0, 0.85, 0.3, 1.0)
	p.emitting              = false
	get_parent().add_child(p)
	p.global_position = hit_pos
	p.emitting        = true
	p.finished.connect(p.queue_free)


# ── Mob blocking (script-level, keeps player out of mob bodies without recovery push) ──

func _block_mob_movement(vel: Vector2) -> Vector2:
	if vel.length_squared() < 1.0:
		return vel
	var blockers: Array = []
	blockers.append_array(get_tree().get_nodes_in_group("ground_mobs"))
	blockers.append_array(get_tree().get_nodes_in_group("npc_blocker"))
	for blocker in blockers:
		if not is_instance_valid(blocker):
			continue
		var blocker_node: Node2D = blocker as Node2D
		if blocker_node == null:
			continue
		var to_blocker: Vector2 = blocker_node.global_position - global_position
		var dist: float = to_blocker.length()
		if dist < 1.0:
			continue
		var raw_radius: Variant = (blocker as Object).get("body_radius")
		var blocker_radius: float = float(raw_radius) if raw_radius != null else 30.0
		var block_dist: float = blocker_radius + _player_radius
		if dist < block_dist:
			var push_dir: Vector2 = to_blocker.normalized()
			var dot: float = vel.dot(push_dir)
			if dot > 0.0:
				vel -= push_dir * dot
	return vel


# ── Collision ──────────────────────────────────────────────────────────────────

func _apply_contact_damage() -> void:
	if is_dying:
		return
	for body in _hurt_area.get_overlapping_bodies():
		var b: Node2D = body as Node2D
		if b == null:
			continue
		if not (b.is_in_group("ground_mobs") or b.is_in_group("flying_mobs")):
			continue
		var mob_attacking: Variant = b.get("_is_attacking")
		if mob_attacking != null and mob_attacking == false:
			continue
		var mob_damage: int = 1
		var mob_kb_force: float = 150.0
		if "damage" in b:
			mob_damage = b.damage
		if "knockback_force" in b:
			mob_kb_force = b.knockback_force
		var kb_dir: Vector2 = (global_position - b.global_position).normalized()
		take_damage(mob_damage, kb_dir * mob_kb_force)
		return


func _on_body_entered(body: Node2D) -> void:
	if is_dying:
		return
	if body.is_in_group("flying_mobs") or body.is_in_group("ground_mobs"):
		var mob_attacking: Variant = body.get("_is_attacking")
		if mob_attacking != null and mob_attacking == false:
			return
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
	_iframes          = PlayerStats.IFRAME_TIME
	_sword.monitoring = false
	_weapon_sprite.visible = false
	if knockback.length_squared() > 0.0:
		_knockback_vel  = knockback
		_knockback_time = PlayerStats.KNOCKBACK_DURATION
	if health <= 0:
		_start_dying("hit")
	else:
		_set_state(PlayerState.HURT)
		_sprite.play("hurt")


func _start_dying(signal_name: String) -> void:
	if is_dying:
		return
	is_dying               = true
	_death_signal          = signal_name
	_set_state(PlayerState.DEAD)
	_sword.monitoring      = false
	_weapon_sprite.visible = false
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

			var hit_point: Vector2  = (global_position + body.global_position) * 0.5
			var attack_dir: Vector2 = (body.global_position - global_position).normalized()
			_spawn_hit_particles(hit_point, attack_dir)
			attack_connected.emit(active_weapon, hit_point, attack_dir)
			_apply_hitstop(float(stats.get("hitstop", 0.05)))


# ── Public API ─────────────────────────────────────────────────────────────────

func set_gameplay_active(enabled: bool) -> void:
	set_process(enabled)
	set_process_input(enabled)


func start(pos: Vector2, combat: bool = false) -> void:
	is_dying       = false
	_set_state(PlayerState.IDLE)
	_death_signal  = ""
	_dodge_timer   = 0.0
	_cooldown_timer = 0.0
	_knockback_vel  = Vector2.ZERO
	_knockback_time = 0.0
	_attack_buffer  = 0.0
	facing          = Vector2.RIGHT
	_last_move_dir  = Vector2.RIGHT
	_body_shape.disabled   = false
	_sword.monitoring      = false
	_weapon_sprite.visible = false
	_sprite.flip_h         = false
	_iframes        = 0.0
	health          = PlayerStats.MAX_HEALTH
	modulate        = Color.WHITE
	combat_enabled  = combat
	SceneManager.set_player_health(health)
	_sprite.play("idle")
	position = pos
	show()
