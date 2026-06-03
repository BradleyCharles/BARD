extends CanvasLayer

## In-game pause menu. Opened by PlayerInput.PAUSE (Escape / Start button).
## Pauses the scene tree while open; this node runs with PROCESS_MODE_ALWAYS.

const _FONT_PATH := "res://fonts/almendra.regular.ttf"
const _C_BG      := Color(0.0,  0.0,  0.0,  0.88)
const _C_PANEL   := Color(0.07, 0.05, 0.03, 1.0)
const _C_BORDER  := Color(0.50, 0.40, 0.20, 0.90)
const _C_GOLD    := Color(0.95, 0.85, 0.45, 1.0)
const _C_DIM     := Color(0.60, 0.55, 0.45, 1.0)

var _font             : Font
var _buttons          : Array[Label] = []
var _fullscreen_label : Label        = null
var _selection        : int          = 0
var _is_open          : bool         = false
var _scene_path       : String       = ""

var _load_picker    : Control          = null
var _picker_rows    : Array[Label]    = []
var _picker_actions : Array[Callable] = []
var _picker_sel     : int             = 0

var _confirm_overlay  : Control          = null
var _confirm_rows     : Array[Label]    = []
var _confirm_actions  : Array[Callable] = []
var _confirm_sel      : int             = 0


func _ready() -> void:
	layer        = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(_FONT_PATH):
		_font = load(_FONT_PATH)
	_build_ui()
	visible = false


# ── Main menu UI ──────────────────────────────────────────────────────────────

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
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
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


# ── Open / Close ──────────────────────────────────────────────────────────────

func open(current_scene_path: String) -> void:
	_scene_path = current_scene_path
	_selection  = 0
	_highlight(_selection)
	_fullscreen_label.text = _fullscreen_label_text()
	visible  = true
	_is_open = true
	get_tree().paused = true


func close() -> void:
	visible  = false
	_is_open = false
	get_tree().paused = false
	_close_confirm()
	_close_picker()


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if _confirm_overlay != null:
		if event.is_action_pressed(PlayerInput.MENU_UP):
			_confirm_sel = (_confirm_sel - 1 + _confirm_rows.size()) % _confirm_rows.size()
			_highlight_confirm()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.MENU_DOWN):
			_confirm_sel = (_confirm_sel + 1) % _confirm_rows.size()
			_highlight_confirm()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.INTERACT):
			_confirm_actions[_confirm_sel].call()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(PlayerInput.MENU_CANCEL):
			_close_confirm()
			get_viewport().set_input_as_handled()
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
		1: _show_save_picker()
		2: _show_load_picker()
		3:
			if not OS.has_feature("editor"):
				var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
				if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_fullscreen_label.text = _fullscreen_label_text()


# ── Picker helpers ────────────────────────────────────────────────────────────

func _highlight_picker() -> void:
	for i in _picker_rows.size():
		_picker_rows[i].add_theme_color_override(
			"font_color", _C_GOLD if i == _picker_sel else _C_DIM
		)


func _close_picker() -> void:
	if _load_picker:
		_load_picker.queue_free()
		_load_picker = null
	_picker_rows.clear()
	_picker_actions.clear()
	_picker_sel = 0


func _highlight_confirm() -> void:
	for i in _confirm_rows.size():
		_confirm_rows[i].add_theme_color_override(
			"font_color", _C_GOLD if i == _confirm_sel else _C_DIM
		)


func _close_confirm() -> void:
	if _confirm_overlay:
		_confirm_overlay.queue_free()
		_confirm_overlay = null
	_confirm_rows.clear()
	_confirm_actions.clear()
	_confirm_sel = 0


# ── Save picker ───────────────────────────────────────────────────────────────

func _show_save_picker() -> void:
	_picker_rows.clear()
	_picker_actions.clear()
	_picker_sel = 0

	var root := _build_overlay_panel("Save Game")
	var vbox  : VBoxContainer = root.get_child(1).get_child(0)

	for slot in range(3):
		var has  : bool   = SceneManager.has_save(slot)
		var lbl  := Label.new()
		lbl.text = "Slot %d  %s" % [slot + 1, ("— empty —" if not has else "")]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", _C_DIM)
		if _font:
			lbl.add_theme_font_override("font", _font)
		vbox.add_child(lbl)

		var s := slot
		var h := has
		_picker_rows.append(lbl)
		_picker_actions.append(func() -> void:
			if h:
				_show_overwrite_confirm(s)
			else:
				_close_picker()
				SceneManager.save_game(s, _scene_path)
				close()
		)
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				if h:
					_show_overwrite_confirm(s)
				else:
					_close_picker()
					SceneManager.save_game(s, _scene_path)
					close()
		)

	_add_cancel_row(vbox)
	add_child(root)
	_load_picker = root
	_highlight_picker()


func _show_overwrite_confirm(slot: int) -> void:
	_confirm_rows.clear()
	_confirm_actions.clear()
	_confirm_sel = 0

	var root := _build_overlay_panel("Overwrite Slot %d?" % (slot + 1))
	var vbox  : VBoxContainer = root.get_child(1).get_child(0)

	var on_yes := func() -> void:
		_close_confirm()
		_close_picker()
		SceneManager.save_game(slot, _scene_path)
		close()
	var on_no := func() -> void:
		_close_confirm()
	var options : Array = [["Yes", on_yes], ["No", on_no]]
	for pair in options:
		var lbl := Label.new()
		lbl.text = pair[0]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", _C_DIM)
		if _font:
			lbl.add_theme_font_override("font", _font)
		vbox.add_child(lbl)
		var cb : Callable = pair[1]
		_confirm_rows.append(lbl)
		_confirm_actions.append(cb)
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				cb.call()
		)

	add_child(root)
	_confirm_overlay = root
	_highlight_confirm()


# ── Load picker ───────────────────────────────────────────────────────────────

func _show_load_picker() -> void:
	_picker_rows.clear()
	_picker_actions.clear()
	_picker_sel = 0

	var root := _build_overlay_panel("Load Game")
	var vbox  : VBoxContainer = root.get_child(1).get_child(0)

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
			_picker_rows.append(lbl)
			_picker_actions.append(func() -> void: on_select_load(s))
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton \
						and (ev as InputEventMouseButton).pressed:
					on_select_load(s)
			)

	_add_cancel_row(vbox)
	add_child(root)
	_load_picker = root
	_highlight_picker()


func on_select_load(slot: int) -> void:
	_close_picker()
	close()
	SceneManager.load_game(slot)


# ── Shared panel builder ──────────────────────────────────────────────────────

func _build_overlay_panel(title_text: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.70)
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

	return root


func _add_cancel_row(vbox: VBoxContainer) -> void:
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
