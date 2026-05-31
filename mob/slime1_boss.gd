extends "res://mob/mob_base.gd"

const ASSET_BASE  := "res://assets/Slime1/Without_shadow/"
const IDLE_FRAMES := 6
const IDLE_FPS    := 8.0
const BOSS_SPEED  : float = 40.0
const MOB_RADIUS  : float = 400.0

@export var world_size: Vector2 = Vector2(3840.0, 2160.0)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var viewport_rect: Rect2


func _ready() -> void:
	max_health      = 10
	personality     = Personality.BOSS
	damage          = 5
	knockback_force = 600.0

	super._ready()

	set_meta("monster_type", "slime1_boss")
	viewport_rect = Rect2(Vector2.ZERO, world_size)
	modulate      = Color(1.0, 0.2, 0.2, 1.0)
	scale         = Vector2(10, 10)

	_build_sprite_frames()


func set_world_size(size: Vector2) -> void:
	world_size    = size
	viewport_rect = Rect2(Vector2.ZERO, world_size)


func set_playable_rect(rect: Rect2) -> void:
	viewport_rect = rect


func _build_sprite_frames() -> void:
	var sf       := SpriteFrames.new()
	sf.remove_animation("default")
	var idle_dir := ASSET_BASE + "slime1_idle/"
	_add_anim(sf, "idle_down",  idle_dir, "idle_down",  IDLE_FRAMES, IDLE_FPS, true)
	_add_anim(sf, "idle_up",    idle_dir, "idle_up",    IDLE_FRAMES, IDLE_FPS, true)
	_add_anim(sf, "idle_right", idle_dir, "idle_right", IDLE_FRAMES, IDLE_FPS, true)
	_sprite.sprite_frames = sf
	_sprite.play("idle_down")


func _add_anim(sf: SpriteFrames, anim_name: String, folder: String,
			   prefix: String, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, loop)
	sf.set_animation_speed(anim_name, fps)
	for i in count:
		var tex := load(folder + prefix + str(i) + ".png") as Texture2D
		sf.add_frame(anim_name, tex)


func _reset_modulate() -> void:
	modulate = Color(1.0, 0.2, 0.2, 1.0)


func _on_died() -> void:
	SceneManager.earn_slime_goop(5)
	super._on_died()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# BOSS always chases
	if _player_ref != null and is_instance_valid(_player_ref):
		linear_velocity = _direction_to_player_with_noise(BOSS_SPEED)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var pos      := state.transform.origin
	var hit_wall := false
	var x_min    := viewport_rect.position.x + MOB_RADIUS
	var x_max    := viewport_rect.end.x - MOB_RADIUS
	var y_min    := viewport_rect.position.y + MOB_RADIUS
	var y_max    := viewport_rect.end.y - MOB_RADIUS

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
