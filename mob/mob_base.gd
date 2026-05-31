extends RigidBody2D

## Shared base for all ground mobs.
## Subclasses must call super._ready() and super._physics_process(delta).

signal died(mob: Node)

enum Personality { WANDER = 0, WEAK_AGGRESSIVE = 1, PACK_MENTALITY = 2, BOSS = 3 }
enum AIState     { WANDER_STATE = 0, CHASE_STATE = 1, FLEE_STATE = 2 }

@export var max_health    : int   = 1
@export var personality   : int   = Personality.WANDER
@export var aggro_radius  : float = 150.0
@export var pack_radius   : float = 200.0
@export var pack_threshold: int   = 3
@export var damage        : int   = 1
@export var knockback_force: float = 150.0

var health     : int    = 1
var ai_state   : int    = AIState.WANDER_STATE
var _player_ref: Node2D = null
var _hurt_timer: float  = 0.0


func _ready() -> void:
	health = max_health
	add_to_group("ground_mobs")
	_find_player()


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
