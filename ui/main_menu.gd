extends Node

## Main menu — the startup scene for BARD / Erimentha.
##
## Scene structure (build in editor):
##   MainMenu  (Node, script = main_menu.gd)
##   └── (all UI built in code)
##
## Set this scene as the startup scene in Project Settings > Application > Run.

const _FONT_PATH   := "res://fonts/almendra.regular.ttf"
const _FONT_BOLD   := "res://fonts/almendra.bold.ttf"
const _C_BG        := Color(0.04, 0.03, 0.02, 1.0)
const _C_PANEL     := Color(0.07, 0.05, 0.03, 1.0)
const _C_BORDER    := Color(0.50, 0.40, 0.20, 0.90)
const _C_GOLD      := Color(0.95, 0.85, 0.45, 1.0)
const _C_DIM       := Color(0.60, 0.55, 0.45, 1.0)
const _C_DISABLED  := Color(0.35, 0.32, 0.28, 1.0)

const PYTHON_EXE   := "python3"

var _font      : Font
var _font_bold : Font
var _canvas    : CanvasLayer
var _buttons   : Array[Label] = []
var _selection : int = 0
var _busy      : bool = false

var _overlay_label  : Label     = null
var _gen_step_label : Label     = null
var _gen_bar        : ColorRect = null
var _load_picker    : Control   = null

const _BAR_WIDTH  : float = 400.0
const _BAR_HEIGHT : float = 14.0

var _picker_rows    : Array[Label]    = []
var _picker_actions : Array[Callable] = []
var _picker_sel     : int             = 0


func _ready() -> void:
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	if ResourceLoader.exists(_FONT_BOLD):
		_font_bold = load(_FONT_BOLD)

	_canvas       = CanvasLayer.new()
	_canvas.layer = 10
	add_child(_canvas)
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(root)

	var bg := ColorRect.new()
	bg.color = _C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical   = Control.GROW_DIRECTION_BOTH
	center.add_theme_constant_override("separation", 22)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(center)

	var title := Label.new()
	title.text = "Erimentha"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", _C_GOLD)
	if _font_bold:
		title.add_theme_font_override("font", _font_bold)
	elif _font:
		title.add_theme_font_override("font", _font)
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A Hunter's Chronicle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", _C_DIM)
	if _font:
		subtitle.add_theme_font_override("font", _font)
	center.add_child(subtitle)

	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(320.0, 0.0)
	sep.add_theme_color_override("color", Color(0.50, 0.40, 0.20, 0.50))
	center.add_child(sep)

	var has_save : bool = SceneManager.has_save(0)
	var options  : Array[String] = ["New Game", "Continue", "Load"]
	for i in options.size():
		var lbl := Label.new()
		lbl.text = options[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 32)
		var disabled : bool = (options[i] == "Continue" and not has_save)
		lbl.add_theme_color_override("font_color", _C_DISABLED if disabled else _C_DIM)
		if _font:
			lbl.add_theme_font_override("font", _font)
		center.add_child(lbl)
		_buttons.append(lbl)

	_highlight(_selection)


func _highlight(idx: int) -> void:
	var has_save : bool = SceneManager.has_save(0)
	for i in _buttons.size():
		var disabled : bool = (i == 1 and not has_save)
		if disabled:
			_buttons[i].add_theme_color_override("font_color", _C_DISABLED)
		else:
			_buttons[i].add_theme_color_override(
				"font_color", _C_GOLD if i == idx else _C_DIM
			)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if _load_picker != null:
		if event.is_action_pressed(PlayerInput.MENU_UP):
			_picker_sel = (_picker_sel - 1 + _picker_rows.size()) % _picker_rows.size()
			_highlight_picker()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.MENU_DOWN):
			_picker_sel = (_picker_sel + 1) % _picker_rows.size()
			_highlight_picker()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.INTERACT):
			_picker_actions[_picker_sel].call()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.MENU_CANCEL):
			_close_picker()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(PlayerInput.MENU_UP):
		_selection = _step(_selection, -1)
		_highlight(_selection)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.MENU_DOWN):
		_selection = _step(_selection, 1)
		_highlight(_selection)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.INTERACT):
		_confirm_selection()
		get_viewport().set_input_as_handled()


func _step(from: int, dir: int) -> int:
	var has_save: bool = SceneManager.has_save(0)
	var next: int = (from + dir + _buttons.size()) % _buttons.size()
	if next == 1 and not has_save:
		next = (next + dir + _buttons.size()) % _buttons.size()
	return next


func _close_picker() -> void:
	if _load_picker:
		_load_picker.queue_free()
		_load_picker = null
	_picker_rows.clear()
	_picker_actions.clear()
	_picker_sel = 0


func _highlight_picker() -> void:
	for i in _picker_rows.size():
		_picker_rows[i].add_theme_color_override(
			"font_color", _C_GOLD if i == _picker_sel else _C_DIM
		)


func _confirm_selection() -> void:
	match _selection:
		0: _start_new_game()
		1:
			if SceneManager.has_save(0):
				SceneManager.load_game(0)
		2: _show_load_picker()


func _show_load_picker() -> void:
	_picker_rows.clear()
	_picker_actions.clear()
	_picker_sel = 0
	var picker := _build_slot_picker(
		"Load Game",
		func(slot: int) -> void:
			_load_picker = null
			SceneManager.load_game(slot)
	)
	_canvas.add_child(picker)
	_load_picker = picker
	_highlight_picker()


func _build_slot_picker(title_text: String, on_select: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color     = _C_PANEL
	style.border_color = _C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(300.0, 0.0)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", _C_GOLD)
	if _font:
		title.add_theme_font_override("font", _font)
	vbox.add_child(title)

	for slot in range(3):
		var lbl  := Label.new()
		var has  : bool = SceneManager.has_save(slot)
		lbl.text = "Slot %d  %s" % [slot + 1, ("— empty —" if not has else "")]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", _C_DISABLED if not has else _C_DIM)
		if _font:
			lbl.add_theme_font_override("font", _font)
		vbox.add_child(lbl)

		if has:
			var s := slot
			_picker_rows.append(lbl)
			_picker_actions.append(func() -> void:
				on_select.call(s)
				_close_picker()
			)
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
					on_select.call(s)
					_close_picker()
			)

	var cancel := Label.new()
	cancel.text = "[ Cancel ]"
	cancel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel.add_theme_font_size_override("font_size", 20)
	cancel.add_theme_color_override("font_color", _C_DIM)
	if _font:
		cancel.add_theme_font_override("font", _font)
	cancel.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close_picker()
	)
	vbox.add_child(cancel)

	_picker_rows.append(cancel)
	_picker_actions.append(_close_picker)

	return root


# ── New Game ──────────────────────────────────────────────────────────────────

func _start_new_game() -> void:
	_busy = true
	_show_gen_overlay("Generating world")
	await get_tree().process_frame

	var project_path : String = ProjectSettings.globalize_path("res://")
	var progress_path := project_path + "worldgen_progress.json"
	if FileAccess.file_exists(progress_path):
		DirAccess.remove_absolute(progress_path)
	var script       : String = project_path + "pipeline/world_gen.py"
	var pid          : int    = OS.create_process(PYTHON_EXE, [script])

	# Poll for world_registry.json + pipeline_ready.flag (world_gen writes both)
	var elapsed : float = 0.0
	var timeout : float = 600.0
	while elapsed < timeout:
		await get_tree().create_timer(3.0).timeout
		elapsed += 3.0
		_update_gen_overlay(elapsed)
		var reg_path  := project_path + "world_registry.json"
		var flag_path := project_path + "pipeline_ready.flag"
		if FileAccess.file_exists(reg_path) and FileAccess.file_exists(flag_path):
			break

	_hide_gen_overlay()
	_busy = false
	SceneManager.go_to_town()


func _show_gen_overlay(text: String) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.name = "GenOverlay"
	_canvas.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical   = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(vbox)

	_overlay_label = Label.new()
	_overlay_label.text = text
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.add_theme_font_size_override("font_size", 44)
	_overlay_label.add_theme_color_override("font_color", _C_GOLD)
	if _font:
		_overlay_label.add_theme_font_override("font", _font)
	vbox.add_child(_overlay_label)

	_gen_step_label = Label.new()
	_gen_step_label.text = "This may take a minute or two."
	_gen_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gen_step_label.add_theme_font_size_override("font_size", 24)
	_gen_step_label.add_theme_color_override("font_color", _C_DIM)
	if _font:
		_gen_step_label.add_theme_font_override("font", _font)
	vbox.add_child(_gen_step_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.12, 0.10, 0.07, 1.0)
	bar_bg.custom_minimum_size = Vector2(_BAR_WIDTH, _BAR_HEIGHT)
	vbox.add_child(bar_bg)

	_gen_bar = ColorRect.new()
	_gen_bar.color = Color(0.55, 0.45, 0.20, 1.0)
	_gen_bar.size  = Vector2(0.0, _BAR_HEIGHT)
	bar_bg.add_child(_gen_bar)


func _update_gen_overlay(elapsed: float) -> void:
	if _overlay_label:
		var dots : String = ".".repeat(int(elapsed / 1.5) % 4)
		_overlay_label.text = "Generating world" + dots

	var project_path : String = ProjectSettings.globalize_path("res://")
	var path := project_path + "worldgen_progress.json"
	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	var data    : Dictionary = parser.get_data()
	var step    : int        = int(data.get("step",    0))
	var total   : int        = int(data.get("total",   0))
	var message : String     = str(data.get("message", ""))

	if _gen_step_label and message != "":
		_gen_step_label.text = message

	if _gen_bar and total > 0:
		var target_w : float = _BAR_WIDTH * float(step) / float(total)
		var tw := create_tween()
		tw.tween_property(_gen_bar, "size:x", target_w, 0.4)


func _hide_gen_overlay() -> void:
	var bg := _canvas.get_node_or_null("GenOverlay")
	if bg:
		bg.queue_free()
	_overlay_label  = null
	_gen_step_label = null
	_gen_bar        = null
