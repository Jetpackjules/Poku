extends CanvasLayer

const OPTION_FONT = preload("res://fonts/Menu_Fonts/Option_font.tres")
const TITLE_FONT = preload("res://fonts/Menu_Fonts/Title_Font.tres")
const BODY_FONT = preload("res://fonts/kirifont/KiriFont.otf")

var overlay: Control
var title_label: Label
var mode_context_label: Label
var controls_label: Label
var p1_controls_label: Label
var p2_controls_label: Label
var experiment_help_label: Label
var resume_button: Button
var reset_button: Button
var main_menu_button: Button
var controls_tab: Button
var lab_tab: Button
var controls_page: Control
var lab_page: Control
var experiment_buttons := {}
var experiment_definitions := {}
var focus_tweens := {}
var _opened_from_main_menu := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if overlay.visible:
			close()
		elif not _is_main_menu():
			open_pause()
		get_viewport().set_input_as_handled()
	elif overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open_pause() -> void:
	_open(false)


func open_options() -> void:
	_open(true)


func close() -> void:
	if not overlay.visible:
		return
	overlay.visible = false
	get_tree().paused = false
	if _opened_from_main_menu and _is_main_menu():
		var menu_root = SceneSwitcher.current_map.get_node_or_null("MenuRoot")
		if menu_root and menu_root.has_method("_focus_current_menu"):
			menu_root.call_deferred("_focus_current_menu")


func is_open() -> bool:
	return is_instance_valid(overlay) and overlay.visible


func _open(from_main_menu: bool) -> void:
	_opened_from_main_menu = from_main_menu
	title_label.text = "OPTIONS" if from_main_menu else "PAUSED"
	resume_button.text = "BACK" if from_main_menu else "RESUME"
	main_menu_button.visible = not from_main_menu
	_update_context()
	_sync_experiment_buttons()
	_show_page(&"controls")
	overlay.visible = true
	get_tree().paused = true
	controls_tab.call_deferred("grab_focus")


func _build_ui() -> void:
	overlay = Control.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.15, 0.17, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "PausePanel"
	panel.anchor_left = 0.01
	panel.anchor_top = 0.01
	panel.anchor_right = 0.99
	panel.anchor_bottom = 0.99
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.615686, 0.901961, 0.921569, 0.985)
	panel_style.set_corner_radius_all(30)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 64)
	outer_margin.add_theme_constant_override("margin_right", 64)
	outer_margin.add_theme_constant_override("margin_top", 24)
	outer_margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(outer_margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 9)
	outer_margin.add_child(layout)

	title_label = Label.new()
	title_label.custom_minimum_size.y = 82.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", TITLE_FONT)
	title_label.add_theme_font_size_override("font_size", 76)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.66, 0.70))
	title_label.add_theme_color_override("font_shadow_color", Color(0.31, 0.52, 0.54, 0.82))
	title_label.add_theme_constant_override("shadow_offset_x", 8)
	title_label.add_theme_constant_override("shadow_offset_y", 8)
	layout.add_child(title_label)

	mode_context_label = Label.new()
	mode_context_label.name = "ModeContext"
	mode_context_label.custom_minimum_size.y = 44.0
	mode_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_context_label.add_theme_font_override("font", OPTION_FONT)
	mode_context_label.add_theme_font_size_override("font_size", 22)
	mode_context_label.add_theme_color_override("font_color", Color(0.10, 0.29, 0.30))
	layout.add_child(mode_context_label)

	var tabs := HBoxContainer.new()
	tabs.name = "SectionTabs"
	tabs.custom_minimum_size.y = 72.0
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 80)
	layout.add_child(tabs)

	controls_tab = Button.new()
	controls_tab.name = "ControlsTab"
	controls_tab.text = "CONTROLS"
	controls_tab.pressed.connect(_show_page.bind(&"controls"))
	_style_tab(controls_tab, Color(0.20, 0.72, 0.32))
	tabs.add_child(controls_tab)

	lab_tab = Button.new()
	lab_tab.name = "PhysicsLabTab"
	lab_tab.text = "PHYSICS LAB"
	lab_tab.pressed.connect(_show_page.bind(&"lab"))
	_style_tab(lab_tab, Color(0.60, 0.34, 0.92))
	tabs.add_child(lab_tab)

	var page_stack := Control.new()
	page_stack.name = "PageStack"
	page_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_stack.clip_contents = true
	layout.add_child(page_stack)

	controls_page = _build_controls_page()
	controls_page.name = "ControlsPage"
	controls_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_stack.add_child(controls_page)

	lab_page = _build_lab_page()
	lab_page.name = "PhysicsLabPage"
	lab_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_stack.add_child(lab_page)

	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.custom_minimum_size.y = 76.0
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 54)
	layout.add_child(actions)

	resume_button = Button.new()
	resume_button.name = "Resume"
	resume_button.text = "RESUME"
	resume_button.pressed.connect(close)
	_style_action_button(resume_button, Color(0.18, 0.74, 0.30))
	actions.add_child(resume_button)

	reset_button = Button.new()
	reset_button.name = "ResetExperiments"
	reset_button.text = "RESET LAB"
	reset_button.pressed.connect(_on_reset_pressed)
	_style_action_button(reset_button, Color(0.90, 0.62, 0.06))
	actions.add_child(reset_button)

	main_menu_button = Button.new()
	main_menu_button.name = "MainMenu"
	main_menu_button.text = "MAIN MENU"
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_style_action_button(main_menu_button, Color(0.92, 0.27, 0.51))
	actions.add_child(main_menu_button)


func _build_controls_page() -> PanelContainer:
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", _soft_page_style(Color(0.91, 0.97, 0.90, 0.82)))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	page.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var player_cards := HBoxContainer.new()
	player_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_cards.add_theme_constant_override("separation", 30)
	content.add_child(player_cards)

	var p1_card := _control_card("PLAYER 1", Color(0.28, 0.80, 0.17), Color(0.92, 1.0, 0.86, 0.94))
	p1_controls_label = p1_card.get_node("Margin/Content/Details")
	player_cards.add_child(p1_card)

	var p2_card := _control_card("PLAYER 2", Color(0.92, 0.18, 0.61), Color(1.0, 0.88, 0.96, 0.94))
	p2_controls_label = p2_card.get_node("Margin/Content/Details")
	player_cards.add_child(p2_card)

	controls_label = Label.new()
	controls_label.name = "Controls"
	controls_label.custom_minimum_size.y = 52.0
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_override("font", OPTION_FONT)
	controls_label.add_theme_font_size_override("font_size", 25)
	controls_label.add_theme_color_override("font_color", Color(0.10, 0.34, 0.36))
	controls_label.text = "PAUSE  ·  ESCAPE ON KEYBOARD  ·  START ON EITHER CONTROLLER"
	content.add_child(controls_label)
	return page


func _control_card(title: String, title_color: Color, background: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _soft_page_style(background))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", OPTION_FONT)
	heading.add_theme_font_size_override("font_size", 42)
	heading.add_theme_color_override("font_color", title_color)
	heading.add_theme_color_override("font_shadow_color", Color(0.12, 0.24, 0.25, 0.25))
	heading.add_theme_constant_override("shadow_offset_x", 4)
	heading.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(heading)
	var details := Label.new()
	details.name = "Details"
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	details.add_theme_font_override("font", BODY_FONT)
	details.add_theme_font_size_override("font_size", 32)
	details.add_theme_color_override("font_color", Color(0.08, 0.22, 0.23))
	content.add_child(details)
	return card


func _build_lab_page() -> PanelContainer:
	var page := PanelContainer.new()
	page.add_theme_stylebox_override("panel", _soft_page_style(Color(1.0, 0.90, 0.91, 0.88)))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	page.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var protected_note := Label.new()
	protected_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	protected_note.text = "TEMPORARY · DEFAULT OFF · CLASSIC LEGS, ARM SPIN, AND PICKUP SNAP STAY PROTECTED"
	protected_note.add_theme_font_override("font", OPTION_FONT)
	protected_note.add_theme_font_size_override("font_size", 21)
	protected_note.add_theme_color_override("font_color", Color(0.56, 0.16, 0.30))
	content.add_child(protected_note)

	var grid := GridContainer.new()
	grid.name = "ExperimentGrid"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)

	for definition in GameSettings.definitions():
		var toggle := Button.new()
		var experiment: StringName = definition["id"]
		experiment_definitions[experiment] = definition
		toggle.name = String(experiment)
		toggle.toggle_mode = true
		toggle.custom_minimum_size = Vector2(0.0, 68.0)
		toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		toggle.add_theme_font_override("font", OPTION_FONT)
		toggle.add_theme_font_size_override("font_size", 25)
		toggle.add_theme_color_override("font_color", Color(0.13, 0.20, 0.22))
		toggle.add_theme_color_override("font_hover_color", Color(0.10, 0.17, 0.19))
		toggle.add_theme_color_override("font_pressed_color", Color(0.04, 0.28, 0.13))
		toggle.toggled.connect(_on_experiment_toggled.bind(experiment))
		toggle.mouse_entered.connect(_show_experiment_help.bind(experiment))
		toggle.focus_entered.connect(_show_experiment_help.bind(experiment))
		toggle.focus_entered.connect(_animate_focus.bind(toggle, true))
		toggle.focus_exited.connect(_animate_focus.bind(toggle, false))
		_style_experiment_toggle(toggle)
		grid.add_child(toggle)
		experiment_buttons[experiment] = toggle

	experiment_help_label = Label.new()
	experiment_help_label.custom_minimum_size.y = 40.0
	experiment_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	experiment_help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	experiment_help_label.add_theme_font_override("font", OPTION_FONT)
	experiment_help_label.add_theme_font_size_override("font_size", 21)
	experiment_help_label.add_theme_color_override("font_color", Color(0.48, 0.12, 0.29))
	experiment_help_label.text = "Select an experiment to see what it changes."
	content.add_child(experiment_help_label)
	return page


func _soft_page_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.18, 0.38, 0.40, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(4, 5)
	return style


func _style_tab(button: Button, color: Color) -> void:
	button.custom_minimum_size = Vector2(430.0, 66.0)
	button.flat = true
	button.add_theme_font_override("font", OPTION_FONT)
	button.add_theme_font_size_override("font_size", 42)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.12))
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.focus_entered.connect(_animate_focus.bind(button, true))
	button.focus_exited.connect(_animate_focus.bind(button, false))


func _set_tab_active(button: Button, color: Color, active: bool) -> void:
	if active:
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(color.r, color.g, color.b, 0.12)
		active_style.border_color = Color(color.r, color.g, color.b, 0.72)
		active_style.border_width_bottom = 6
		active_style.set_corner_radius_all(18)
		button.add_theme_stylebox_override("normal", active_style)
	else:
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())


func _style_experiment_toggle(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _toggle_style(Color(1.0, 1.0, 1.0, 0.58), Color(0.90, 0.55, 0.66, 0.32)))
	button.add_theme_stylebox_override("hover", _toggle_style(Color(1.0, 0.94, 0.62, 0.80), Color(0.90, 0.65, 0.15, 0.50)))
	button.add_theme_stylebox_override("pressed", _toggle_style(Color(0.63, 0.95, 0.66, 0.90), Color(0.25, 0.68, 0.30, 0.55)))
	button.add_theme_stylebox_override("focus", _toggle_style(Color(1.0, 0.94, 0.62, 0.82), Color(0.90, 0.65, 0.15, 0.55)))


func _toggle_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24.0
	style.content_margin_right = 20.0
	return style


func _style_action_button(button: Button, color: Color) -> void:
	button.custom_minimum_size = Vector2(300.0, 70.0)
	button.flat = true
	button.add_theme_font_override("font", OPTION_FONT)
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.12))
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_shadow_color", Color(0.18, 0.38, 0.40, 0.30))
	button.add_theme_constant_override("shadow_offset_x", 4)
	button.add_theme_constant_override("shadow_offset_y", 5)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.focus_entered.connect(_animate_focus.bind(button, true))
	button.focus_exited.connect(_animate_focus.bind(button, false))


func _animate_focus(button: BaseButton, focused: bool) -> void:
	button.pivot_offset = button.size * 0.5
	if focus_tweens.has(button) and focus_tweens[button].is_valid():
		focus_tweens[button].kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK if focused else Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.025, 1.025) if focused else Vector2.ONE, 0.13)
	focus_tweens[button] = tween


func _show_page(page: StringName) -> void:
	var show_controls := page == &"controls"
	controls_page.visible = show_controls
	lab_page.visible = not show_controls
	reset_button.visible = not show_controls
	_set_tab_active(controls_tab, Color(0.20, 0.72, 0.32), show_controls)
	_set_tab_active(lab_tab, Color(0.60, 0.34, 0.92), not show_controls)


func _update_context() -> void:
	if _opened_from_main_menu or not is_instance_valid(SceneSwitcher.current_map):
		mode_context_label.text = "CONTROLS AND OPTIONAL PHYSICS EXPERIMENTS"
		_set_poku_controls()
		return
	var mode_title := str(SceneSwitcher.current_map.get("mode_title"))
	var objective := str(SceneSwitcher.current_map.get("objective"))
	if mode_title == "<null>":
		mode_title = SceneSwitcher.current_map.name
	if objective == "<null>":
		objective = ""
	mode_context_label.text = "%s  —  %s" % [mode_title, objective]
	var uses_poku_players = SceneSwitcher.current_map.get("uses_poku_players")
	if uses_poku_players == false:
		p1_controls_label.text = "KEYBOARD  ·  WASD OR ARROWS\nJUMP  ·  UP     CROUCH  ·  DOWN"
		p2_controls_label.text = "CONTROLLER  ·  EITHER PAD\nMOVE  ·  LEFT STICK\nJUMP  ·  A     CROUCH  ·  B"
	else:
		_set_poku_controls()


func _set_poku_controls() -> void:
	p1_controls_label.text = "KEYBOARD  ·  WASD\nJUMP  ·  W     CROUCH  ·  S\nSPIN / THROW  ·  SPACE\n\nCONTROLLER 1  ·  LEFT STICK\nJUMP  ·  A     CROUCH  ·  B\nSPIN / THROW  ·  RT / X / RB"
	p2_controls_label.text = "KEYBOARD  ·  ARROW KEYS\nJUMP  ·  UP     CROUCH  ·  DOWN\nSPIN / THROW  ·  RIGHT SHIFT\n\nCONTROLLER 2  ·  LEFT STICK\nJUMP  ·  A     CROUCH  ·  B\nSPIN / THROW  ·  RT / X / RB"


func _sync_experiment_buttons() -> void:
	for experiment in experiment_buttons:
		var enabled := GameSettings.is_enabled(experiment)
		experiment_buttons[experiment].set_pressed_no_signal(enabled)
		_update_experiment_button_text(experiment, enabled)


func _update_experiment_button_text(experiment: StringName, enabled: bool) -> void:
	var definition: Dictionary = experiment_definitions[experiment]
	experiment_buttons[experiment].text = "%s  %s" % ["✓" if enabled else "○", definition["label"]]


func _show_experiment_help(experiment: StringName) -> void:
	if experiment_definitions.has(experiment):
		experiment_help_label.text = experiment_definitions[experiment]["detail"]


func _on_experiment_toggled(enabled: bool, experiment: StringName) -> void:
	GameSettings.set_enabled(experiment, enabled)
	_update_experiment_button_text(experiment, enabled)
	_show_experiment_help(experiment)


func _on_reset_pressed() -> void:
	GameSettings.reset_experiments()
	_sync_experiment_buttons()
	experiment_help_label.text = "All experiments reset. Classic behavior is active."


func _on_main_menu_pressed() -> void:
	close()
	SceneSwitcher.change_map("Main_Menu")


func _is_main_menu() -> bool:
	return is_instance_valid(SceneSwitcher.current_map) and SceneSwitcher.current_map.name == "Main_Menu"
