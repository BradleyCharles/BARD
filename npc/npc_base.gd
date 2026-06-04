extends Node2D

## Base script for all NPCs — named characters and background wanderers.
##
## Scene structure for npc_base.tscn (build once, reuse for every NPC):
##   NPC  (Node2D, script = npc_base.gd)
##   ├── AnimatedSprite2D
##   ├── DetectionArea  (Area2D)
##   │     collision_layer = 0  (doesn't push anything)
##   │     collision_mask  = 2  (scans player layer — set player to layer 2)
##   │     Connect: area_entered → _on_area_entered
##   │     Connect: area_exited  → _on_area_exited
##   │   └── CollisionShape2D  (CircleShape2D — radius driven by detection_radius export)
##   └── NameLabel  (Label)
##         offset = Vector2(0, -60) so it floats above the sprite
##         horizontal_alignment = CENTER
##         visible = false by default
##
## Dialogue architecture:
##   Each named NPC has a hardcoded root menu (role-specific options) which merges
##   with LLM-generated dialogue loaded from a JSON file. The "Talk" option in the
##   root menu links to the generated "greeting" node. If no generated file exists
##   the "Talk" option is hidden and the NPC still functions via hardcoded options.


# ── Exports ───────────────────────────────────────────────────────────────────

@export var npc_role        : String = ""
@export var npc_id          : String = ""
@export var npc_name        : String = "Villager"
@export_file("*.json") var dialogue_file: String = ""
@export var detection_radius: float  = 40.0
## True for anonymous background NPCs that wander but carry no dialogue.
@export var is_wanderer     : bool   = false


# ── Hardcoded root nodes per NPC role ─────────────────────────────────────────
##
## These are always present regardless of whether generated dialogue exists.
## "Talk" links to the generated "greeting" node. If no generated dialogue
## is available that response is removed at merge time.
## Node keys here must not collide with generated node names (greeting, farewell, etc.)

const ROLE_ROOT_NODES : Dictionary = {
	"innkeeper": {
		"root": {
			"text": "What can I do for you?",
			"responses": [
				{"key": 1, "text": "I'd like to sleep for the night.", "next": "sleep_confirm"},
				{"key": 2, "text": "Do you have anything to buy?",    "next": "out_of_stock"},
				{"key": 3, "text": "I wanted to talk.",               "next": "greeting"},
				{"key": 4, "text": "Nothing, goodbye.",               "next": "root_farewell"},
			]
		},
		"sleep_confirm": {
			"text": "Of course. Rest well, hunter.",
			"responses": [
				{"key": 1, "text": "Good night.", "next": null, "action": "end_day"}
			]
		},
		"out_of_stock": {
			"text": "Sorry, I'm fresh out of supplies right now.",
			"responses": [
				{"key": 1, "text": "No worries.", "next": "root"}
			]
		},
		"root_farewell": {
			"text": "Safe travels, hunter.",
			"responses": [
				{"key": 1, "text": "Goodbye.", "next": null}
			]
		}
	},
	"blacksmith": {
		"root": {
			"text": "Need something?",
			"responses": [
				{"key": 1, "text": "Can I browse your wares?",  "next": "out_of_stock"},
				{"key": 2, "text": "Upgrade my weapons.",       "next": "upgrade_menu"},
				{"key": 3, "text": "I wanted to talk.",         "next": "greeting"},
				{"key": 4, "text": "Nothing, goodbye.",         "next": "root_farewell"},
			]
		},
		"out_of_stock": {
			"text": "Nothing available right now, I'm afraid.",
			"responses": [
				{"key": 1, "text": "Understood.", "next": "root"}
			]
		},
		"upgrade_menu": {
			"text": "What would you like?",
			"responses": [
				{"key": 1, "text": "Buy Axe (50 Scripts)",
					"next": "buy_axe_confirm"},
				{"key": 2, "text": "Upgrade Sword (100 Scripts + 5 Goop)",
					"next": "upgrade_sword_confirm"},
				{"key": 3, "text": "Upgrade Axe (150 Scripts + 10 Goop)",
					"next": "upgrade_axe_confirm"},
				{"key": 4, "text": "Never mind.",                          "next": "root"},
			]
		},
		"buy_axe_confirm": {
			"text": "An axe — solid choice. That'll be 50 Scripts.",
			"responses": [
				{"key": 1, "text": "Yes, I'll take it.", "next": null, "action": "buy_axe"},
				{"key": 2, "text": "Not yet.",           "next": "upgrade_menu"},
			]
		},
		"upgrade_sword_confirm": {
			"text": "A sharper edge. 100 Scripts and 5 Slime Goop.",
			"responses": [
				{"key": 1, "text": "Do it.",   "next": null, "action": "upgrade_sword"},
				{"key": 2, "text": "Not yet.", "next": "upgrade_menu"},
			]
		},
		"upgrade_axe_confirm": {
			"text": "Heavier head, longer haft. 150 Scripts and 10 Slime Goop.",
			"responses": [
				{"key": 1, "text": "Do it.",   "next": null, "action": "upgrade_axe"},
				{"key": 2, "text": "Not yet.", "next": "upgrade_menu"},
			]
		},
		"root_farewell": {
			"text": "Right then.",
			"responses": [
				{"key": 1, "text": "Goodbye.", "next": null}
			]
		}
	},
	"guild_commander": {
		"root": {
			"text": "Hunter. What do you need?",
			"responses": [
				{"key": 1, "text": "I want to check the bounty board.", "next": "bounty_stub"},
				{"key": 2, "text": "I wanted to talk.",                 "next": "greeting"},
				{"key": 3, "text": "Nothing. Carry on.",                "next": "root_farewell"},
			]
		},
		"bounty_stub": {
			"text": "The board is posted behind you. Help yourself.",
			"responses": [
				{"key": 1, "text": "Right.", "next": "root"}
			]
		},
		"turnin_confirm": {
			"text": "Let me see what you have.",
			"responses": [
				{"key": 1, "text": "Here.", "next": null, "action": "open_turn_in"}
			]
		},
		"root_farewell": {
			"text": "Dismissed.",
			"responses": [
				{"key": 1, "text": "Goodbye.", "next": null}
			]
		}
	}
}


# ── Node refs ─────────────────────────────────────────────────────────────────

@onready var _sprite    : AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection : Area2D           = $DetectionArea
@onready var _name_lbl  : Label            = $NameLabel

var _prompt_lbl : Label


# ── State ─────────────────────────────────────────────────────────────────────

var _dialogue_nodes  : Dictionary = {}
var _dialogue_box    : Node       = null
var _player_in_range : bool       = false

# Wander (background NPCs only)
var _wander_dir   : Vector2 = Vector2.ZERO
var _wander_timer : float   = 0.0
var _world_bounds : Rect2   = Rect2(Vector2.ZERO, Vector2(99999.0, 99999.0))
const WANDER_SPEED : float  = 38.0

# Chat (wanderers only)
var _chat_cooldown   : float = 0.0
var _is_chatting     : bool  = false
const CHAT_RADIUS    : float = 60.0
const CHAT_COOLDOWN  : float = 30.0
const CHAT_DURATION  : float = 4.0


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_sprite_frames()
	_detection.area_entered.connect(_on_area_entered)
	_detection.area_exited.connect(_on_area_exited)
	_add_physics_body()

	var shape := _detection.get_node("CollisionShape2D")
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = detection_radius

	_name_lbl.text    = npc_name
	_name_lbl.visible = true

	if not is_wanderer:
		_prompt_lbl = Label.new()
		_prompt_lbl.text = "[A] Talk"
		_prompt_lbl.position = _name_lbl.position + Vector2(0.0, 20.0)
		_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_prompt_lbl.add_theme_font_size_override("font_size", 13)
		_prompt_lbl.add_theme_color_override(
			"font_color", Color(0.88, 0.73, 0.38, 1.0))
		_prompt_lbl.visible = false
		add_child(_prompt_lbl)

	_load_dialogue()

	if is_wanderer:
		add_to_group("wanderer")
		_init_world_bounds()
		_pick_wander_direction()
	else:
		_try_play("idle_down")


func _process(delta: float) -> void:
	if not is_wanderer:
		return

	if _chat_cooldown > 0.0:
		_chat_cooldown -= delta

	if _is_chatting:
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander_direction()
	position += _wander_dir * WANDER_SPEED * delta
	var clamped := position.clamp(_world_bounds.position, _world_bounds.end)
	if clamped != position:
		position = clamped
		_pick_wander_direction()

	if _chat_cooldown <= 0.0:
		_check_nearby_chat()


# ── Dialogue loading ──────────────────────────────────────────────────────────

func _load_dialogue() -> void:
	var generated : Dictionary = {}

	if dialogue_file != "":
		var file := FileAccess.open(dialogue_file, FileAccess.READ)
		if file == null:
			push_warning("NPC '%s': dialogue file not found -- %s" % [npc_name, dialogue_file])
		else:
			var json := JSON.new()
			var err  := json.parse(file.get_as_text())
			file.close()
			if err != OK:
				push_warning("NPC '%s': failed to parse dialogue JSON (line %d)" \
					% [npc_name, json.get_error_line()])
			else:
				var data := json.get_data() as Dictionary
				generated = data.get("nodes", {})
				if data.has("npc_name"):
					npc_name       = data["npc_name"]
					_name_lbl.text = npc_name

	_dialogue_nodes = _build_merged_dialogue(generated)


func _build_merged_dialogue(generated: Dictionary) -> Dictionary:
	## Merge hardcoded role root nodes with generated dialogue.
	## If no role is set (wanderers) return generated as-is.
	## If no generated dialogue is available, remove the "Talk" option.
	if npc_role == "" or not ROLE_ROOT_NODES.has(npc_role):
		return generated

	var merged : Dictionary = ROLE_ROOT_NODES[npc_role].duplicate(true)

	if generated.is_empty():
		# No generated dialogue -- remove the "Talk" / "greeting" response from root
		var root_responses : Array = merged["root"]["responses"]
		merged["root"]["responses"] = root_responses.filter(
			func(r: Dictionary) -> bool: return r.get("next") != "greeting"
		)
	else:
		# Merge generated nodes in -- hardcoded keys take precedence on collision
		for key in generated:
			if not merged.has(key):
				merged[key] = generated[key]

	return merged


## Reload dialogue at the start of each new day without re-instantiating the NPC.
func reload_dialogue() -> void:
	_dialogue_nodes = {}
	if npc_id == "":
		return
	var day_path := "res://dialogue/%s_day%d.json" \
		% [npc_id.to_lower(), SceneManager.day]
	if FileAccess.file_exists(day_path):
		dialogue_file = day_path
	_load_dialogue()


# ── Proximity detection ───────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if is_wanderer or not _player_in_range:
		return
	if _dialogue_box != null and _dialogue_box.is_open():
		return
	if event.is_action_pressed(PlayerInput.INTERACT):
		get_viewport().set_input_as_handled()
		_open_dialogue()


func _on_area_entered(area: Area2D) -> void:
	if not _is_player_area(area):
		return
	_player_in_range = true
	if _prompt_lbl:
		_prompt_lbl.visible = true
	if npc_id != "" and not SceneManager.get_flag("met_" + npc_id.to_lower()):
		SceneManager.set_flag("met_" + npc_id.to_lower(), true)


func _on_area_exited(area: Area2D) -> void:
	if not _is_player_area(area):
		return
	_player_in_range = false
	if _prompt_lbl:
		_prompt_lbl.visible = false
	_close_dialogue()


func _is_player_area(area: Area2D) -> bool:
	return area.is_in_group("player") or area.get_parent().is_in_group("player")


# ── Dialogue ──────────────────────────────────────────────────────────────────

func _open_dialogue() -> void:
	if _dialogue_nodes.is_empty() or is_wanderer:
		return
	_dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if _dialogue_box == null:
		push_warning(
			"NPC '%s': no node in group 'dialogue_box' found." % npc_name)
		return
	if npc_role == "guild_commander":
		_patch_guild_commander_root()
	elif npc_role == "blacksmith":
		_patch_blacksmith_root()
	if _prompt_lbl:
		_prompt_lbl.visible = false
	if not _dialogue_box.closed.is_connected(_on_dialogue_closed):
		_dialogue_box.closed.connect(_on_dialogue_closed)
	var start_node := "root" if ROLE_ROOT_NODES.has(npc_role) else "greeting"
	_dialogue_box.open(_dialogue_nodes, start_node, npc_name)


func _patch_guild_commander_root() -> void:
	var has_complete := SceneManager.active_bounties.any(
		func(b: Dictionary) -> bool: return b.get("status") == "complete"
	)
	var responses : Array = _dialogue_nodes["root"]["responses"]
	for i in responses.size():
		if responses[i].get("key") == 1:
			if has_complete:
				responses[i] = {
					"key": 1, "text": "I have completed a bounty.",
					"next": "turnin_confirm"
				}
			else:
				responses[i] = {
					"key": 1, "text": "I want to check the bounty board.",
					"next": "bounty_stub"
				}
			break


func _patch_blacksmith_root() -> void:
	if not _dialogue_nodes.has("upgrade_menu"):
		return
	var owned   := SceneManager.owned_weapons
	var responses: Array = []
	if "axe" not in owned:
		responses.append({"text": "Buy Axe (50 Scripts)", "next": "buy_axe_confirm"})
	else:
		responses.append({
			"text": "Upgrade Sword (100 Scripts + 5 Goop)",
			"next": "upgrade_sword_confirm"
		})
		responses.append({
			"text": "Upgrade Axe (150 Scripts + 10 Goop)",
			"next": "upgrade_axe_confirm"
		})
	responses.append({"text": "Never mind.", "next": "root"})
	for i in responses.size():
		responses[i]["key"] = i + 1
	_dialogue_nodes["upgrade_menu"]["responses"] = responses


func _on_dialogue_closed() -> void:
	if _prompt_lbl and _player_in_range:
		_prompt_lbl.visible = true
	_dialogue_box = null


func _close_dialogue() -> void:
	if _dialogue_box != null and _dialogue_box.is_open():
		_dialogue_box.close()
	_dialogue_box = null


# ── Wander ────────────────────────────────────────────────────────────────────

func _check_nearby_chat() -> void:
	for node in get_tree().get_nodes_in_group("wanderer"):
		var other := node as Node2D
		if other == null or other == self:
			continue
		var other_npc := node as Object
		if other_npc.get("_is_chatting") == true or other_npc.get("_chat_cooldown") > 0.0:
			continue
		if global_position.distance_to(other.global_position) <= CHAT_RADIUS:
			var exchange : Dictionary = _pick_exchange()
			if not exchange.is_empty():
				_start_chat(exchange.get("line_a", "…"), other, exchange.get("line_b", "…"))
			return


func _pick_exchange() -> Dictionary:
	var day_path := "res://dialogue/villager_ambient_day%d.json" % SceneManager.day
	if not FileAccess.file_exists(day_path):
		return {}
	var file := FileAccess.open(day_path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	var data    := parser.get_data() as Dictionary
	var pool    : Array = data.get("exchanges", [])
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()] as Dictionary


func _start_chat(my_line: String, other: Node2D, their_line: String) -> void:
	_is_chatting = true
	var other_npc := other as Object
	if other_npc != null:
		other_npc.set("_is_chatting", true)

	var bubble_script : GDScript = load("res://ui/speech_bubble.gd")

	var my_bubble := Node2D.new()
	my_bubble.set_script(bubble_script)
	add_child(my_bubble)
	(my_bubble as Object).call("show_text", my_line)

	var their_bubble := Node2D.new()
	their_bubble.set_script(bubble_script)
	other.add_child(their_bubble)
	(their_bubble as Object).call("show_text", their_line)

	await get_tree().create_timer(CHAT_DURATION).timeout

	_is_chatting     = false
	_chat_cooldown   = CHAT_COOLDOWN
	_pick_wander_direction()

	if other_npc != null:
		other_npc.set("_is_chatting",   false)
		other_npc.set("_chat_cooldown", CHAT_COOLDOWN)
		if other_npc.has_method("_pick_wander_direction"):
			other_npc.call("_pick_wander_direction")


func _init_world_bounds() -> void:
	var left   := get_parent().get_node_or_null("BoundaryLeft")   as Control
	var right  := get_parent().get_node_or_null("BoundaryRight")  as Control
	var top    := get_parent().get_node_or_null("BoundaryTop")    as Control
	var bottom := get_parent().get_node_or_null("BoundaryBottom") as Control
	if left and right and top and bottom:
		var x_min : float = left.position.x + left.size.x
		var x_max : float = right.position.x
		var y_min : float = top.position.y + top.size.y
		var y_max : float = bottom.position.y
		_world_bounds = Rect2(x_min, y_min, x_max - x_min, y_max - y_min)


func _pick_wander_direction() -> void:
	_wander_timer = randf_range(2.5, 6.0)
	if randf() < 0.30:
		_wander_dir = Vector2.ZERO
		_try_play("idle_down")
		return
	var angle   := randf() * TAU
	_wander_dir  = Vector2(cos(angle), sin(angle))
	_sprite.flip_h = _wander_dir.x < 0.0
	if abs(_wander_dir.y) > abs(_wander_dir.x):
		_try_play("idle_up" if _wander_dir.y < 0.0 else "idle_down")
	else:
		_try_play("idle_right")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _add_physics_body() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8
	body.collision_mask  = 0
	var shape_node := CollisionShape2D.new()
	var circle     := CircleShape2D.new()
	circle.radius  = 12.0
	shape_node.shape = circle
	body.add_child(shape_node)
	add_child(body)


func _try_play(anim: String) -> void:
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)


# ── Sprite setup ──────────────────────────────────────────────────────────────

const FRAME_SIZE := 64
const ROW_DOWN   := 0
const ROW_RIGHT  := 2
const ROW_UP     := 3

func _build_sprite_frames() -> void:
	var base     := "res://assets/Swordsman_lvl1/Without_shadow/"
	var idle_tex : Texture2D = load(base + "Swordsman_lvl1_Idle_without_shadow.png")

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	_add_anim(sf, "idle_down",  idle_tex, ROW_DOWN,  12, 8.0, true)
	_add_anim(sf, "idle_right", idle_tex, ROW_RIGHT, 12, 8.0, true)
	_add_anim(sf, "idle_up",    idle_tex, ROW_UP,     4, 8.0, true)

	_sprite.sprite_frames = sf


func _add_anim(sf: SpriteFrames, anim: String, sheet: Texture2D,
			   row: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(anim)
	sf.set_animation_loop(anim, loop)
	sf.set_animation_speed(anim, fps)
	for i in count:
		var a := AtlasTexture.new()
		a.atlas  = sheet
		a.region = Rect2(i * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
		sf.add_frame(anim, a)
