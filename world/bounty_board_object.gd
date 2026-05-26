extends Node2D

## Physical bounty board object placed in the world (town, guild hall, etc.).
##
## Scene structure to build in the editor:
##   BountyBoardObject  (Node2D, script = bounty_board_object.gd)
##                       Add to group "bounty_board" (done in _ready).
##   ├── Sprite2D        (optional visual — board art or placeholder ColorRect)
##   ├── DetectionArea   (Area2D)
##   │     collision_layer = 0
##   │     collision_mask  = 2   (player layer)
##   │     Connect: area_entered → _on_area_entered
##   │     Connect: area_exited  → _on_area_exited
##   │   └── CollisionShape2D  (CircleShape2D — radius set from detection_radius export)
##   └── PromptLabel     (Label)
##         position = Vector2(0, -80) or above the board sprite
##         horizontal_alignment = CENTER
##         visible = false by default


@export var detection_radius : float = 140.0

const _BOARD_SCENE := "res://ui/bounty_board.tscn"
const _FONT_PATH   := "res://fonts/almendra.regular.ttf"

@onready var _detection  : Area2D = $DetectionArea
@onready var _prompt_lbl : Label  = $PromptLabel

var _player_in_range : bool = false
var _board_instance  : Node = null


func _ready() -> void:
	add_to_group("bounty_board")

	_detection.area_entered.connect(_on_area_entered)
	_detection.area_exited.connect(_on_area_exited)

	var shape := _detection.get_node("CollisionShape2D")
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = detection_radius

	_prompt_lbl.text                = "Press E to view bounties"
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.visible             = false
	if ResourceLoader.exists(_FONT_PATH):
		_prompt_lbl.add_theme_font_override("font", load(_FONT_PATH))
	_prompt_lbl.add_theme_font_size_override("font_size", 16)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.88, 0.73, 0.38, 1.0))


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or _board_instance != null:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_E:
		get_viewport().set_input_as_handled()
		_open_board()


# ── Proximity detection ───────────────────────────────────────────────────────

func _on_area_entered(area: Area2D) -> void:
	if not _is_player_area(area):
		return
	_player_in_range    = true
	_prompt_lbl.visible = true


func _on_area_exited(area: Area2D) -> void:
	if not _is_player_area(area):
		return
	_player_in_range    = false
	_prompt_lbl.visible = false


func _is_player_area(area: Area2D) -> bool:
	return area.is_in_group("player") or area.get_parent().is_in_group("player")


# ── Board lifecycle ───────────────────────────────────────────────────────────

func _open_board() -> void:
	var packed := load(_BOARD_SCENE) as PackedScene
	if packed == null:
		push_error("BountyBoardObject: could not load %s" % _BOARD_SCENE)
		return
	_board_instance = packed.instantiate()
	get_tree().root.add_child(_board_instance)
	_board_instance.board_closed.connect(_on_board_closed)
	_board_instance.open()


func _on_board_closed() -> void:
	if _board_instance:
		_board_instance.queue_free()
		_board_instance = null
