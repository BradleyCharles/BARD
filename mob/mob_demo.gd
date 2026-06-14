extends Node2D

## Stationary display-only mob used in testing mode.
## No AI, no collision, no physics — just idle sprite and hitbox visualisation.
##
## _hitbox_radius is always stored in WORLD pixels (shape_radius × mob_scale).
## The node stays at scale=(1,1) so _draw() radius = world radius with no multipliers.
## Bosses have mob_scale=3; their sprite child is scaled independently.

const _CONFIGS: Dictionary = {
	"slime1": {
		"path": "res://assets/mobs/Slime1/Idle/Slime1_Idle_front.aseprite",
		"shape_radius": 18.0, "mob_scale": 1.0},
	"slime2": {
		"path": "res://assets/mobs/Slime2/Idle/Slime2_Idle_front.aseprite",
		"shape_radius": 18.0, "mob_scale": 1.0},
	"slime3": {
		"path": "res://assets/mobs/Slime3/Idle/Slime3_Idle_front.aseprite",
		"shape_radius": 20.0, "mob_scale": 1.0},
	"slime3_boss": {
		"path": "res://assets/mobs/Slime3/Idle/Slime3_Idle_front.aseprite",
		"shape_radius": 40.0, "mob_scale": 3.0},
	"orc1": {
		"path": "res://assets/mobs/Orc1/Orc1_idle/orc1_front_idle.aseprite",
		"shape_radius": 18.0, "mob_scale": 1.0},
	"orc2": {
		"path": "res://assets/mobs/Orc2/Orc2_idle/orc2_front_idle.aseprite",
		"shape_radius": 20.0, "mob_scale": 1.0},
	"orc3": {
		"path": "res://assets/mobs/Orc3/Orc3_idle/orc3_front_idle.aseprite",
		"shape_radius": 22.0, "mob_scale": 1.0},
	"orc3_boss": {
		"path": "res://assets/mobs/Orc3/Orc3_idle/orc3_front_idle.aseprite",
		"shape_radius": 22.0, "mob_scale": 3.0},
	"plant1": {
		"path": "res://assets/mobs/Plant1/Idle/Plant1_Idle_front.aseprite",
		"shape_radius": 16.0, "mob_scale": 1.0},
	"plant2": {
		"path": "res://assets/mobs/Plant2/Idle/Plant2_Idle_front.aseprite",
		"shape_radius": 18.0, "mob_scale": 1.0},
	"plant3": {
		"path": "res://assets/mobs/Plant3/Idle/Plant3_Idle_front.aseprite",
		"shape_radius": 20.0, "mob_scale": 1.0},
	"plant3_boss": {
		"path": "res://assets/mobs/Plant3/Idle/Plant3_Idle_front.aseprite",
		"shape_radius": 20.0, "mob_scale": 3.0},
	"vampire1": {
		"path": "res://assets/mobs/Vampires1/Idle/Vampires1_Idle_front.aseprite",
		"shape_radius": 14.0, "mob_scale": 1.0},
	"vampire2": {
		"path": "res://assets/mobs/Vampires2/Idle/Vampires2_Idle_front.aseprite",
		"shape_radius": 16.0, "mob_scale": 1.0},
	"vampire3": {
		"path": "res://assets/mobs/Vampires3/Idle/Vampires3_Idle_front.aseprite",
		"shape_radius": 18.0, "mob_scale": 1.0},
	"vampire3_boss": {
		"path": "res://assets/mobs/Vampires3/Idle/Vampires3_Idle_front.aseprite",
		"shape_radius": 18.0, "mob_scale": 3.0},
}

var _hitbox_radius : float             = 18.0
var _sprite        : AnimatedSprite2D  = null


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	add_child(_sprite)


func init(mob_type: String) -> void:
	var cfg: Dictionary = _CONFIGS.get(mob_type, {})
	if cfg.is_empty():
		return
	var mob_scale: float = float(cfg.get("mob_scale", 1.0))
	_hitbox_radius = float(cfg.get("shape_radius", 18.0)) * mob_scale
	_sprite.scale = Vector2(mob_scale, mob_scale)
	var path: String = str(cfg.get("path", ""))
	var src: SpriteFrames = load(path) as SpriteFrames
	if src == null:
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", src.get_animation_speed("default"))
	for i: int in src.get_frame_count("default"):
		sf.add_frame("idle", src.get_frame_texture("default", i))
	_sprite.sprite_frames = sf
	_sprite.play("idle")
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, _hitbox_radius, Color(1.0, 1.0, 0.0, 0.25))
	draw_arc(Vector2.ZERO, _hitbox_radius, 0.0, TAU, 32, Color(1.0, 1.0, 0.0, 1.0), 2.0)
