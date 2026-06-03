extends CanvasLayer

## In-game pause menu. Opened by PlayerInput.PAUSE (Escape / Start button).
## Pauses the scene tree while open; this node runs with PROCESS_MODE_ALWAYS.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"
const _C_BG      := Color(0.0,  0.0,  0.0,  0.88)
const _C_PANEL   := Color(0.07, 0.05, 0.03, 1.0)
const _C_BORDER  := Color(0.50, 0.40, 0.20, 0.90)
const _C_GOLD    := Color(0.95, 0.85, 0.45, 1.0)
const _C_DIM     := Color(0.60, 0.55, 0.45, 1.0)

var _font              : Font
var _buttons           : Array[Label] = []
var _fullscreen_label  : Label = null
var _selection         : int = 0
var _is_open           : bool = false
var _scene_path        : String = ""

var _load_picker : Control = null


func _ready() -> void:
	layer             = 250
	process_mode      = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	visible = false


func _build_ui() -> void:
	var ref := Control.new()
	ref.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ref)

	var bg := ColorRect.new()
	bg.color = _C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ref.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var style := StyleBoxFlat.new()
	style.bg_color     = _C_PANEL
	style.border_color = _C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	ref.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", _C_GOLD)
	if _font:
		title.add_theme_font_override("font", _font)
	vbox.add_child(title)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.50, 0.40, 0.20, 0.60))
	vbox.add_child(sep)

	for option in ["Resume", "Save", "Load"]:
		var lbl := Label.new()
		lbl.text = option
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.add_theme_color_override("font_color", _C_DIM)
		if _font:
			lbl.add_theme_font_override("font", _font)
		vbox.add_child(lbl)
		_buttons.append(lbl)

	var fs_lbl := Label.new()
	fs_lbl.text = _fullscreen_label_text()
	fs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fs_lbl.add_theme_font_size_override("font_size", 28)
	fs_lbl.add_theme_color_override("font_color", _C_DIM)
	if _font:
		fs_lbl.add_theme_font_override("font", _font)
	vbox.add_child(fs_lbl)
	_buttons.append(fs_lbl)
	_fullscreen_label = fs_lbl

	_highlight(_selection)


func _fullscreen_label_text() -> String:
	var is_fs: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	return "Fullscreen  [%s]" % ("ON" if is_fs else "OFF")


func _highlight(idx: int) -> void:
	for i in _buttons.size():
		_buttons[i].add_theme_color_override(
			"font_color", _C_GOLD if i == idx else _C_DIM
		)


func open(current_scene_path: String) -> void:
	_scene_path = current_scene_path
	_selection  = 0
	_highlight(_selection)
	_fullscreen_label.text = _fullscreen_label_text()
	visible = true
	_is_open = true
	get_tree().paused = true


func close() -> void:
	visible  = false
	_is_open = false
	get_tree().paused = false
	if _load_picker:
		_load_picker.queue_free()
		_load_picker = null


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or _load_picker != null:
		return
	if event.is_action_pressed(PlayerInput.MENU_UP):
		_selection = (_selection - 1 + _buttons.size()) % _buttons.size()
		_highlight(_selection)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.MENU_DOWN):
		_selection = (_selection + 1) % _buttons.size()
		_highlight(_selection)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.INTERACT):
		_confirm_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(PlayerInput.PAUSE) \
			or event.is_action_pressed(PlayerInput.MENU_CANCEL):
		close()
		get_viewport().set_input_as_handled()


func _confirm_selection() -> void:
	match _selection:
		0: close()
		1:
			SceneManager.save_game(0, _scene_path)
			close()
		2:
			_show_load_picker()
		3:
			var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_fullscreen_label.text = _fullscreen_label_text()


func _show_load_picker() -> void:
	var picker := _build_slot_picker(
		"Load Game",
		func(slot: int) -> void:
			close()
			SceneManager.load_game(slot)
	)
	add_child(picker)
	_load_picker = picker


func _build_slot_picker(title_text: String, on_select: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.70)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var style := StyleBoxFlat.new()
	style.bg_color     = _C_PANEL
	style.border_color = _C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(300.0, 0.0)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", _C_GOLD)
	if _font:
		title.add_theme_font_override("font", _font)
	vbox.add_child(title)

	for slot in range(3):
		var lbl := Label.new()
		var has : bool = SceneManager.has_save(slot)
		lbl.text = "Slot %d  %s" % [slot + 1, ("— empty —" if not has else "")]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", _C_DIM if not has else _C_GOLD)
		if _font:
			lbl.add_theme_font_override("font", _font)
		vbox.add_child(lbl)

		if has:
			var s := slot
			var btn := lbl
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
					on_select.call(s)
					root.queue_free()
					_load_picker = null
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
			root.queue_free()
			_load_picker = null
	)
	vbox.add_child(cancel)

	return root
