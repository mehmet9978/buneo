extends CanvasLayer

signal upgrade_requested
signal camera_requested
signal pause_requested
signal restart_requested

var coins_label: Label
var mode_label: Label
var camera_button: Button
var upgrade_button: Button
var message_label: Label
var transition_panel: ColorRect
var transition_label: Label
var up_button: TouchScreenButton
var down_button: TouchScreenButton
var touch_buttons: Array[TouchScreenButton] = []
var health_label: Label
var progress_fill: ColorRect
var progress_label: Label
var pause_panel: ColorRect
var finish_panel: ColorRect
var finish_stats: Label
var is_3d := false
var message_tween: Tween
var damage_flash: ColorRect

const TOUCH_TEXTURE := preload("res://assets/touch_button.svg")


func _ready() -> void:
	layer = 20
	_build_hud()
	get_viewport().size_changed.connect(_layout_touch_controls)
	_layout_touch_controls()


func set_coins(total: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "◆ %03d" % total
	_update_upgrade_button()


func set_upgrade(level: int) -> void:
	if is_instance_valid(upgrade_button):
		upgrade_button.text = "ZIPLAMA +  Lv.%d  (%d◆)" % [level, GameState.get_upgrade_cost()]
	_update_upgrade_button()


func set_mode_2d() -> void:
	is_3d = false
	mode_label.text = "2D BAKIŞ • 3D DÜNYA"
	camera_button.visible = false
	_refresh_touch_controls()


func set_mode_3d() -> void:
	is_3d = true
	mode_label.text = "3D • TPS"
	camera_button.visible = true
	_refresh_touch_controls()


func set_camera_mode(mode: String) -> void:
	mode_label.text = "3D • " + mode
	camera_button.text = "KAMERA: " + mode


func show_message(text: String) -> void:
	if is_instance_valid(message_tween):
		message_tween.kill()
	message_label.text = text
	message_label.modulate.a = 1.0
	message_tween = create_tween()
	message_tween.tween_interval(2.3)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.45)


func set_health(value: int) -> void:
	health_label.text = "CAN  " + "♥".repeat(value) + "♡".repeat(3 - value)


func flash_damage() -> void:
	damage_flash.modulate.a = 1.0
	create_tween().tween_property(damage_flash, "modulate:a", 0.0, 0.4)


func set_progress(value: float) -> void:
	var percent := clampf(value, 0.0, 1.0)
	progress_fill.size.x = 182.0 * percent
	progress_label.text = "%d%%" % int(percent * 100.0)


func set_paused(value: bool) -> void:
	pause_panel.visible = value
	_refresh_touch_controls()


func show_completion(time_seconds: float, found_coins: int) -> void:
	finish_stats.text = "Süre: %02d:%02d   •   Toplanan altın: %d\nTamamlama ödülü: +15 altın" % [int(time_seconds) / 60, int(time_seconds) % 60, found_coins]
	finish_panel.visible = true
	_refresh_touch_controls()


func play_transition(text: String) -> void:
	transition_label.text = text
	transition_panel.visible = true
	transition_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(transition_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(0.25)
	tween.tween_property(transition_panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void: transition_panel.visible = false)


func _build_hud() -> void:
	var top_bar := ColorRect.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 72
	top_bar.color = Color(0.025, 0.04, 0.09, 0.90)
	add_child(top_bar)

	var title := Label.new()
	title.text = "B U N E O"
	title.position = Vector2(24, 15)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("54e1ff"))
	top_bar.add_child(title)

	mode_label = Label.new()
	mode_label.text = "2D BAKIŞ • 3D DÜNYA"
	mode_label.position = Vector2(200, 23)
	mode_label.add_theme_font_size_override("font_size", 17)
	mode_label.add_theme_color_override("font_color", Color("a8bce8"))
	top_bar.add_child(mode_label)

	health_label = Label.new()
	health_label.position = Vector2(490, 23)
	health_label.add_theme_font_size_override("font_size", 19)
	health_label.add_theme_color_override("font_color", Color("ff7183"))
	top_bar.add_child(health_label)
	set_health(3)

	var progress_track := ColorRect.new()
	progress_track.position = Vector2(710, 32)
	progress_track.size = Vector2(182, 9)
	progress_track.color = Color("274159")
	top_bar.add_child(progress_track)
	progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0, 9)
	progress_fill.color = Color("6ee3ba")
	progress_track.add_child(progress_fill)
	progress_label = Label.new()
	progress_label.position = Vector2(904, 23)
	progress_label.add_theme_font_size_override("font_size", 17)
	progress_label.add_theme_color_override("font_color", Color("d5f2e7"))
	top_bar.add_child(progress_label)
	set_progress(0.0)

	var pause_button := _make_button("II", Vector2.ZERO, Vector2(46, 42))
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-236, 15)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	top_bar.add_child(pause_button)

	coins_label = Label.new()
	coins_label.text = "◆ 000"
	coins_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	coins_label.position = Vector2(-170, 17)
	coins_label.size = Vector2(150, 40)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_size_override("font_size", 27)
	coins_label.add_theme_color_override("font_color", Color("ffd447"))
	top_bar.add_child(coins_label)

	upgrade_button = _make_button("ZIPLAMA +", Vector2(24, 88), Vector2(235, 48))
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	add_child(upgrade_button)

	camera_button = _make_button("KAMERA: TPS", Vector2(275, 88), Vector2(180, 48))
	camera_button.pressed.connect(func() -> void: camera_requested.emit())
	add_child(camera_button)

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-340, 145)
	message_label.size = Vector2(680, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", Color("ffffff"))
	message_label.add_theme_color_override("font_outline_color", Color("1c354b"))
	message_label.add_theme_constant_override("outline_size", 5)
	add_child(message_label)

	_build_touch_controls()
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.13, 0.22, 0.2)
	damage_flash.modulate.a = 0.0
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)
	_build_transition()
	_build_overlay_panels()


func _build_touch_controls() -> void:
	var left := _make_action_button("<", "move_left")
	add_child(left)

	var right := _make_action_button(">", "move_right")
	add_child(right)

	up_button = _make_action_button("^", "move_forward")
	add_child(up_button)

	down_button = _make_action_button("v", "move_back")
	add_child(down_button)

	var jump := _make_action_button("ZIPLA", "jump")
	add_child(jump)
	touch_buttons = [left, right, up_button, down_button, jump]


func _layout_touch_controls() -> void:
	if touch_buttons.size() != 5:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var bottom := viewport_size.y - 94.0
	var centers := [
		Vector2(80, bottom - 85),
		Vector2(240, bottom - 85),
		Vector2(160, bottom - 170),
		Vector2(160, bottom),
		Vector2(viewport_size.x - 92, bottom)
	]
	for index in range(touch_buttons.size()):
		touch_buttons[index].position = centers[index] - Vector2(64, 64)


func _build_transition() -> void:
	transition_panel = ColorRect.new()
	transition_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_panel.color = Color("070a18")
	transition_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_panel.visible = false
	add_child(transition_panel)
	transition_label = Label.new()
	transition_label.set_anchors_preset(Control.PRESET_CENTER)
	transition_label.position = Vector2(-400, -45)
	transition_label.size = Vector2(800, 90)
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.add_theme_font_size_override("font_size", 36)
	transition_label.add_theme_color_override("font_color", Color("b657ff"))
	transition_panel.add_child(transition_label)


func _build_overlay_panels() -> void:
	pause_panel = _make_overlay()
	var pause_stack := _make_overlay_stack(pause_panel)
	pause_stack.add_child(_make_overlay_title("DURAKLATILDI"))
	pause_stack.add_child(_make_overlay_caption("Aynı dünyada kalıyorsun. Hazır olduğunda devam et."))
	var resume := _make_overlay_button("DEVAM ET")
	resume.pressed.connect(func() -> void: pause_requested.emit())
	pause_stack.add_child(resume)
	var restart := _make_overlay_button("BAŞTAN OYNA")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	pause_stack.add_child(restart)

	finish_panel = _make_overlay()
	var finish_stack := _make_overlay_stack(finish_panel)
	finish_stack.add_child(_make_overlay_title("PARKUR TAMAMLANDI!"))
	finish_stats = _make_overlay_caption("")
	finish_stack.add_child(finish_stats)
	var again := _make_overlay_button("TEKRAR OYNA")
	again.pressed.connect(func() -> void: restart_requested.emit())
	finish_stack.add_child(again)


func _make_overlay() -> ColorRect:
	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0.015, 0.025, 0.05, 0.86)
	panel.visible = false
	add_child(panel)
	return panel


func _make_overlay_stack(panel: ColorRect) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(510, 0)
	stack.add_theme_constant_override("separation", 22)
	center.add_child(stack)
	return stack


func _make_overlay_title(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("6be2f0"))
	return label


func _make_overlay_caption(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color("e4edf4"))
	return label


func _make_overlay_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(390, 62)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color("ecfbff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("174258")
	normal.border_color = Color("4bbcc9")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("226177")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("123348")
	button.add_theme_stylebox_override("pressed", pressed)
	return button


func _refresh_touch_controls() -> void:
	if touch_buttons.size() != 5:
		return
	var active := not pause_panel.visible and not finish_panel.visible if is_instance_valid(pause_panel) and is_instance_valid(finish_panel) else true
	touch_buttons[0].visible = active
	touch_buttons[1].visible = active
	up_button.visible = active and is_3d
	down_button.visible = active and is_3d
	touch_buttons[4].visible = active


func _make_button(text: String, pos: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 16)
	return button


func _make_action_button(text: String, action: String) -> TouchScreenButton:
	var button := TouchScreenButton.new()
	button.texture_normal = TOUCH_TEXTURE
	button.action = action
	button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var hit_area := CircleShape2D.new()
	hit_area.radius = 50.0
	button.shape = hit_area
	button.shape_centered = true
	var label := Label.new()
	label.text = text
	label.position = Vector2.ZERO
	label.size = Vector2(128, 128)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26 if text != "ZIPLA" else 19)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return button


func _update_upgrade_button() -> void:
	if not is_instance_valid(upgrade_button):
		return
	upgrade_button.text = "ZIPLAMA +  Lv.%d  (%d◆)" % [GameState.jump_level, GameState.get_upgrade_cost()]
	upgrade_button.modulate = Color.WHITE if GameState.coins >= GameState.get_upgrade_cost() else Color(0.7, 0.7, 0.75, 0.82)
