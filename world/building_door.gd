extends StaticBody2D

@export var target_scene: String = ""
@export var door_offset: Vector2 = Vector2(0.0, 40.0)
@export var prompt_offset: Vector2 = Vector2(0.0, 20.0)

var _player_nearby: bool = false
var _prompt_lbl: Label

func _ready() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	shape.position = door_offset
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

	_prompt_lbl = Label.new()
	_prompt_lbl.text = "[A] Enter"
	_prompt_lbl.position = door_offset + prompt_offset
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.73, 0.38, 1.0))
	_prompt_lbl.visible = false
	add_child(_prompt_lbl)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		_prompt_lbl.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		_prompt_lbl.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or target_scene.is_empty():
		return
	if event.is_action_pressed(PlayerInput.INTERACT):
		_prompt_lbl.visible = false
		SceneManager.go_to_building(target_scene)
