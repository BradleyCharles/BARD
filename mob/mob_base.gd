extends RigidBody2D

## Shared base for all ground mobs.
## Subclasses must call super._ready() and super._physics_process(delta).

signal died(mob: Node)

enum Personality { WANDER = 0, WEAK_AGGRESSIVE = 1, PACK_MENTALITY = 2, BOSS = 3 }
enum AIState     { WANDER_STATE = 0, CHASE_STATE = 1, FLEE_STATE = 2 }

## ── Hitbox radii ─────────────────────────────────────────────────────────────
## Tune these to tighten or loosen per-mob collision detection.
## Call _apply_hitbox(HITBOX_X) in the subclass _ready() after super._ready().
const HITBOX_SLIME1   : float = 18.0
const HITBOX_SLIME2   : float = 18.0
const HITBOX_SLIME3   : float = 20.0
const HITBOX_ORC1     : float = 18.0
const HITBOX_ORC2     : float = 20.0
const HITBOX_ORC3     : float = 22.0
const HITBOX_PLANT1   : float = 16.0
const HITBOX_PLANT2   : float = 18.0
const HITBOX_PLANT3   : float = 20.0
const HITBOX_VAMPIRE1 : float = 14.0
const HITBOX_VAMPIRE2 : float = 16.0
const HITBOX_VAMPIRE3 : float = 18.0

@export var max_health    : int   = 1
@export var personality   : int   = Personality.WANDER
@export var aggro_radius  : float = 150.0
@export var pack_radius   : float = 200.0
@export var pack_threshold: int   = 3
@export var damage        : int   = 1
@export var knockback_force: float = 150.0

var health         : int    = 1
var ai_state       : int    = AIState.WANDER_STATE
var _player_ref    : Node2D = null
var _hurt_timer    : float  = 0.0
var body_radius    : float  = 30.0
var contact_radius : float  = 44.0
var _is_aggroed    : bool   = false
var _demo_mode     : bool   = false


func _ready() -> void:
	health = max_health
	add_to_group("ground_mobs")
	collision_layer = 8
	collision_mask  = 1
	_find_player()
	_compute_body_radius()


func _compute_body_radius() -> void:
	for child in get_children():
		var cs: CollisionShape2D = child as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			body_radius    = (cs.shape as CircleShape2D).radius * scale.x
			contact_radius = body_radius + 20.0
			return


func _apply_hitbox(r: float) -> void:
	for child in get_children():
		var cs: CollisionShape2D = child as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			(cs.shape as CircleShape2D).radius = r
			body_radius    = r * scale.x
			contact_radius = body_radius + 20.0
			return


func _find_player() -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		_player_ref = nodes[0] as Node2D


func take_damage(amount: int, knockback_vec: Vector2) -> void:
	if health <= 0:
		return
	health -= amount
	apply_central_impulse(knockback_vec)
	_hurt_timer = 0.15
	modulate = Color(1.0, 0.4, 0.4, 1.0)
	if health <= 0:
		_on_died()


func _on_died() -> void:
	died.emit(self)
	queue_free()


func _reset_modulate() -> void:
	modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			_reset_modulate()

	if _player_ref == null or not is_instance_valid(_player_ref):
		_find_player()


func _direction_to_player_with_noise(speed: float) -> Vector2:
	if _player_ref == null:
		return Vector2.ZERO
	var base_dir := (_player_ref.global_position - global_position).normalized()
	var noise_angle := sin(Time.get_ticks_msec() * 0.003) * deg_to_rad(15.0)
	return base_dir.rotated(noise_angle) * speed


func _distance_to_player() -> float:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return INF
	return global_position.distance_to(_player_ref.global_position)


func _player_is_invincible() -> bool:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return false
	var iframes: Variant = _player_ref.get("_iframes")
	return iframes != null and float(iframes) > 0.0


func enable_demo_mode() -> void:
	_demo_mode = true
	freeze = true
	collision_layer = 0
	collision_mask  = 0
	linear_velocity = Vector2.ZERO
	remove_from_group("ground_mobs")
	set_physics_process(false)
	set_process(false)
	for child in get_children():
		var t: Timer = child as Timer
		if t != null:
			t.stop()
	call_deferred("_apply_demo_idle")


func _apply_demo_idle() -> void:
	var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle_front"):
		sprite.play("idle_front")
	queue_redraw()


func _draw() -> void:
	if not _demo_mode:
		return
	for child in get_children():
		var cs: CollisionShape2D = child as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			var r: float = (cs.shape as CircleShape2D).radius
			draw_circle(cs.position, r, Color(1.0, 1.0, 0.0, 0.25))
			draw_arc(cs.position, r, 0.0, TAU, 32, Color(1.0, 1.0, 0.0, 1.0), 2.0)
			return


func _calc_separation() -> Vector2:
	var sep := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("ground_mobs"):
		if other == self or not is_instance_valid(other):
			continue
		var other_node: Node2D = other as Node2D
		if other_node == null:
			continue
		var to_self: Vector2 = global_position - other_node.global_position
		var dist: float = to_self.length()
		if dist < 0.1:
			continue
		var raw: Variant = (other as Object).get("body_radius")
		var other_radius: float = float(raw) if raw != null else 30.0
		var min_dist: float = body_radius + other_radius
		if dist < min_dist:
			sep += to_self.normalized() * (min_dist - dist) * 3.0
	return sep
