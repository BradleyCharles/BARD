extends StaticBody2D

@export var door_offset: Vector2 = Vector2(0.0, 40.0)

var _player_nearby: bool = false

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


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false


func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	if event.is_action_pressed(PlayerInput.INTERACT):
		SceneManager.go_to_guildhall_interior()
