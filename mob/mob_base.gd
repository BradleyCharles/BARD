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

var health         : int    = 1
var ai_state       : int    = AIState.WANDER_STATE
var _player_ref    : Node2D = null
var _hurt_timer    : float  = 0.0
var body_radius    : float  = 30.0
var contact_radius : float  = 44.0
var _is_aggroed    : bool   = false

var _nav_agent: NavigationAgent2D = null


func _ready() -> void:
	health = max_health
	add_to_group("ground_mobs")
	collision_layer = 8
	collision_mask  = 1
	_find_player()
	_compute_body_radius()
	_nav_agent = NavigationAgent2D.new()
	_nav_agent.path_desired_distance   = 8.0
	_nav_agent.target_desired_distance = 16.0
	add_child(_nav_agent)


func _compute_body_radius() -> void:
	for child in get_children():
		var cs: CollisionShape2D = child as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			body_radius    = (cs.shape as CircleShape2D).radius * scale.x
			contact_radius = body_radius + 8.0
			return


func _apply_hitbox(r: float) -> void:
	for child in get_children():
		var cs: CollisionShape2D = child as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			(cs.shape as CircleShape2D).radius = r
			body_radius    = r * scale.x
			contact_radius = body_radius + 8.0
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
		_disable_for_death()
		_on_died()


func _disable_for_death() -> void:
	collision_layer = 0
	collision_mask  = 0
	remove_from_group("ground_mobs")


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


# Returns a velocity vector toward the player that navigates around obstacles
# when a NavigationRegion2D is present in the scene.  Falls back to the noise
# direction when no nav map has been baked.
func _nav_move(speed: float) -> Vector2:
	if _nav_agent == null or _player_ref == null or not is_instance_valid(_player_ref):
		return _direction_to_player_with_noise(speed)
	_nav_agent.target_position = _player_ref.global_position
	if _nav_agent.is_navigation_finished():
		return _direction_to_player_with_noise(speed)
	var next_pos: Vector2  = _nav_agent.get_next_path_position()
	var base_dir: Vector2  = (next_pos - global_position).normalized()
	if base_dir == Vector2.ZERO:
		return _direction_to_player_with_noise(speed)
	var noise_angle: float = sin(Time.get_ticks_msec() * 0.003) * deg_to_rad(15.0)
	return base_dir.rotated(noise_angle) * speed
