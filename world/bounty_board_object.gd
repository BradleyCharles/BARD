extends StaticBody2D

@export var detection_radius: float = 60.0
@export var prompt_offset: Vector2 = Vector2(0.0, -60.0)

const _BOARD_SCENE := "res://ui/bounty_board.tscn"
const _FONT_PATH   := "res://fonts/almendra.regular.ttf"

var _player_in_range: bool = false
var _board_instance: Node = null
var _prompt_lbl: Label


func _ready() -> void:
	add_to_group("bounty_board")

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = detection_radius
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

	_prompt_lbl = Label.new()
	_prompt_lbl.text = "[A] Bounty Board"
	_prompt_lbl.position = prompt_offset
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.visible = false
	if ResourceLoader.exists(_FONT_PATH):
		_prompt_lbl.add_theme_font_override("font", load(_FONT_PATH))
	_prompt_lbl.add_theme_font_size_override("font_size", 16)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.73, 0.38, 1.0))
	add_child(_prompt_lbl)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _board_instance != null:
		return
	if event.is_action_pressed(PlayerInput.INTERACT):
		get_viewport().set_input_as_handled()
		_open_board()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_prompt_lbl.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_prompt_lbl.visible = false


func _open_board() -> void:
	var packed := load(_BOARD_SCENE) as PackedScene
	if packed == null:
		push_error("BountyBoard: could not load %s" % _BOARD_SCENE)
		return
	_board_instance = packed.instantiate()
	get_tree().root.add_child(_board_instance)
	_board_instance.board_closed.connect(_on_board_closed)
	_board_instance.open()


func _on_board_closed() -> void:
	if _board_instance:
		_board_instance.queue_free()
		_board_instance = null
