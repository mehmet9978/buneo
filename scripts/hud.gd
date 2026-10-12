extends CanvasLayer

signal upgrade_requested
signal camera_requested

var coins_label: Label
var mode_label: Label
var camera_button: Button
var upgrade_button: Button
var message_label: Label
var transition_panel: ColorRect
var transition_label: Label
var up_button: Button
var down_button: Button


func _ready() -> void:
	layer = 20
	_build_hud()


func set_coins(total: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "◆ %03d" % total
	_update_upgrade_button()


func set_upgrade(level: int) -> void:
	if is_instance_valid(upgrade_button):
		upgrade_button.text = "ZIPLAMA +  Lv.%d  (%d◆)" % [level, GameState.get_upgrade_cost()]
	_update_upgrade_button()


func set_mode_2d() -> void:
	mode_label.text = "2D PLATFORM"
	camera_button.visible = false
	up_button.visible = false
	down_button.visible = false


func set_mode_3d() -> void:
	mode_label.text = "3D • TPS"
	camera_button.visible = true
	up_button.visible = true
	down_button.visible = true


func set_camera_mode(mode: String) -> void:
	mode_label.text = "3D • " + mode
	camera_button.text = "KAMERA: " + mode


func show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.3)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.45)


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
	mode_label.text = "2D PLATFORM"
	mode_label.position = Vector2(200, 23)
	mode_label.add_theme_font_size_override("font_size", 17)
	mode_label.add_theme_color_override("font_color", Color("a8bce8"))
	top_bar.add_child(mode_label)

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
	message_label.position = Vector2(-340, 86)
	message_label.size = Vector2(680, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", Color("ffffff"))
	add_child(message_label)

	_build_touch_controls()
	_build_transition()


func _build_touch_controls() -> void:
	var left := _make_action_button("◀", "move_left")
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left.position = Vector2(26, -118)
	add_child(left)

	var right := _make_action_button("▶", "move_right")
	right.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	right.position = Vector2(212, -118)
	add_child(right)

	up_button = _make_action_button("▲", "move_forward")
	up_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	up_button.position = Vector2(119, -205)
	add_child(up_button)

	down_button = _make_action_button("▼", "move_back")
	down_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	down_button.position = Vector2(119, -75)
	add_child(down_button)

	var jump := _make_action_button("ZIPLA", "jump")
	jump.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump.position = Vector2(-155, -135)
	jump.size = Vector2(125, 105)
	add_child(jump)


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


func _make_button(text: String, pos: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 16)
	return button


func _make_action_button(text: String, action: String) -> Button:
	var button := Button.new()
	button.text = text
	button.size = Vector2(82, 82)
	button.modulate = Color(1, 1, 1, 0.78)
	button.add_theme_font_size_override("font_size", 22)
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	return button


func _update_upgrade_button() -> void:
	if not is_instance_valid(upgrade_button):
		return
	upgrade_button.text = "ZIPLAMA +  Lv.%d  (%d◆)" % [GameState.jump_level, GameState.get_upgrade_cost()]
	upgrade_button.modulate = Color.WHITE if GameState.coins >= GameState.get_upgrade_cost() else Color(0.7, 0.7, 0.75, 0.82)
