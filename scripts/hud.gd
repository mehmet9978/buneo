extends CanvasLayer

signal start_requested
signal upgrade_requested
signal camera_requested
signal pause_requested
signal restart_requested

const TOUCH_TEXTURE := preload("res://assets/touch_button.svg")
const DISPLAY_FONT := preload("res://assets/fonts/Bungee-Regular.ttf")
const UI_FONT := preload("res://assets/fonts/NunitoSans.ttf")
const INK := Color("071522")
const CYAN := Color("52e3ff")
const GOLD := Color("ffc94a")
const MINT := Color("79e7a8")
const CORAL := Color("ff6f76")

var coins_label: Label
var menu_coins_label: Label
var mode_label: Label
var camera_button: Button
var upgrade_button: Button
var menu_upgrade_button: Button
var message_label: Label
var transition_panel: ColorRect
var transition_label: Label
var up_button: TouchScreenButton
var down_button: TouchScreenButton
var touch_buttons: Array[TouchScreenButton] = []
var health_label: Label
var progress_fill: ColorRect
var progress_label: Label
var pause_panel: Control
var finish_panel: Control
var finish_stats: Label
var main_menu: Control
var game_hud: Control
var is_3d := false
var gameplay_active := false
var message_tween: Tween
var damage_flash: ColorRect


func _ready() -> void:
	layer = 20
	_build_hud()
	get_viewport().size_changed.connect(_layout_touch_controls)
	_layout_touch_controls()


func show_main_menu() -> void:
	gameplay_active = false
	main_menu.visible = true
	game_hud.visible = false
	_refresh_touch_controls()


func begin_gameplay() -> void:
	gameplay_active = true
	main_menu.visible = false
	game_hud.visible = true
	_refresh_touch_controls()
	show_message("MOR KAPIYA ULAŞ • KAMERA AYNI DÜNYADA ARKANA DÖNECEK")


func set_coins(total: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "%03d" % total
	if is_instance_valid(menu_coins_label):
		menu_coins_label.text = "◆  %03d" % total
	_update_upgrade_button()


func set_upgrade(level: int) -> void:
	var cost := GameState.get_upgrade_cost()
	if is_instance_valid(upgrade_button):
		upgrade_button.text = "ZIPLAMA  LV.%d   •   %d◆" % [level, cost]
	if is_instance_valid(menu_upgrade_button):
		menu_upgrade_button.text = "ZIPLAMAYI GELİŞTİR   LV.%d   •   %d◆" % [level, cost]
	_update_upgrade_button()


func set_mode_2d() -> void:
	is_3d = false
	if is_instance_valid(mode_label):
		mode_label.text = "◉  2D YAN BAKIŞ"
	if is_instance_valid(camera_button):
		camera_button.visible = false
	_refresh_touch_controls()


func set_mode_3d() -> void:
	is_3d = true
	mode_label.text = "◉  3D • TPS"
	camera_button.visible = true
	_refresh_touch_controls()


func set_camera_mode(mode: String) -> void:
	mode_label.text = "◉  3D • " + mode
	camera_button.text = "KAMERA  " + mode


func show_message(text: String) -> void:
	if not is_instance_valid(message_label):
		return
	if is_instance_valid(message_tween):
		message_tween.kill()
	message_label.text = text
	message_label.modulate.a = 1.0
	message_tween = create_tween()
	message_tween.tween_interval(2.5)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.42)


func set_health(value: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "♥".repeat(value) + "♡".repeat(3 - value)


func flash_damage() -> void:
	damage_flash.modulate.a = 1.0
	create_tween().tween_property(damage_flash, "modulate:a", 0.0, 0.4)


func set_progress(value: float) -> void:
	if not is_instance_valid(progress_fill):
		return
	var percent := clampf(value, 0.0, 1.0)
	progress_fill.size.x = 300.0 * percent
	progress_label.text = "%02d%%" % int(percent * 100.0)


func set_paused(value: bool) -> void:
	pause_panel.visible = value
	_refresh_touch_controls()


func show_completion(time_seconds: float, found_coins: int) -> void:
	var minutes := int(time_seconds) / 60
	var seconds := int(time_seconds) % 60
	finish_stats.text = "SÜRE   %02d:%02d\nTOPLANAN   %02d ◆\nBİTİRME ÖDÜLÜ   +15 ◆" % [minutes, seconds, found_coins]
	finish_panel.visible = true
	_refresh_touch_controls()


func play_transition(text: String) -> void:
	transition_label.text = text
	transition_panel.visible = true
	transition_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(transition_panel, "modulate:a", 1.0, 0.24)
	tween.tween_interval(0.34)
	tween.tween_property(transition_panel, "modulate:a", 0.0, 0.38)
	tween.tween_callback(func() -> void: transition_panel.visible = false)


func _build_hud() -> void:
	game_hud = Control.new()
	game_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game_hud)
	_build_top_cards()
	_build_touch_controls()
	message_label = _make_label("", 19, Color.WHITE, UI_FONT)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-390, 104)
	message_label.size = Vector2(780, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_outline_color", INK)
	message_label.add_theme_constant_override("outline_size", 7)
	game_hud.add_child(message_label)
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.08, 0.16, 0.24)
	damage_flash.modulate.a = 0.0
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)
	_build_main_menu()
	_build_transition()
	_build_overlay_panels()
	show_main_menu()


func _build_top_cards() -> void:
	var health_card := _make_card(Vector2(22, 18), Vector2(164, 56), Color(0.03, 0.09, 0.14, 0.88), Color(0.24, 0.54, 0.64, 0.45))
	game_hud.add_child(health_card)
	var heart_icon := _make_label("CAN", 14, Color("98bcca"), UI_FONT)
	heart_icon.position = Vector2(16, 8)
	health_card.add_child(heart_icon)
	health_label = _make_label("♥♥♥", 24, CORAL, UI_FONT)
	health_label.position = Vector2(54, 18)
	health_card.add_child(health_label)
	var progress_card := _make_card(Vector2.ZERO, Vector2(414, 56), Color(0.03, 0.09, 0.14, 0.88), Color(0.24, 0.54, 0.64, 0.45))
	progress_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress_card.position = Vector2(-207, 18)
	game_hud.add_child(progress_card)
	var stage := _make_label("BOYUT YOLU", 13, Color("a7cbd5"), UI_FONT)
	stage.position = Vector2(18, 8)
	progress_card.add_child(stage)
	var track := ColorRect.new()
	track.position = Vector2(18, 34)
	track.size = Vector2(300, 8)
	track.color = Color("1e4150")
	progress_card.add_child(track)
	progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0, 8)
	progress_fill.color = MINT
	track.add_child(progress_fill)
	progress_label = _make_label("00%", 17, Color.WHITE, UI_FONT)
	progress_label.position = Vector2(336, 24)
	progress_card.add_child(progress_label)
	var pause_button := _make_button("Ⅱ", Vector2.ZERO, Vector2(52, 52), "dark")
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-238, 20)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	game_hud.add_child(pause_button)
	var coin_card := _make_card(Vector2.ZERO, Vector2(158, 56), Color(0.03, 0.09, 0.14, 0.9), Color(0.93, 0.65, 0.2, 0.55))
	coin_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	coin_card.position = Vector2(-174, 18)
	game_hud.add_child(coin_card)
	var diamond := _make_label("◆", 24, GOLD, UI_FONT)
	diamond.position = Vector2(17, 14)
	coin_card.add_child(diamond)
	coins_label = _make_label("000", 25, Color.WHITE, UI_FONT)
	coins_label.position = Vector2(54, 12)
	coins_label.size = Vector2(84, 35)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_card.add_child(coins_label)
	mode_label = _make_label("◉  2D YAN BAKIŞ", 15, Color("c9f5ff"), UI_FONT)
	mode_label.position = Vector2(24, 86)
	mode_label.add_theme_color_override("font_outline_color", INK)
	mode_label.add_theme_constant_override("outline_size", 5)
	game_hud.add_child(mode_label)
	upgrade_button = _make_button("ZIPLAMA", Vector2(24, 118), Vector2(228, 44), "glass")
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	game_hud.add_child(upgrade_button)
	camera_button = _make_button("KAMERA  TPS", Vector2(266, 118), Vector2(166, 44), "glass")
	camera_button.pressed.connect(func() -> void: camera_requested.emit())
	game_hud.add_child(camera_button)


func _build_main_menu() -> void:
	main_menu = Control.new()
	main_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_menu)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.045, 0.07, 0.62)
	main_menu.add_child(shade)
	var left_shade := ColorRect.new()
	left_shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_shade.offset_right = 610
	left_shade.color = Color(0.015, 0.04, 0.065, 0.84)
	main_menu.add_child(left_shade)
	var accent := ColorRect.new()
	accent.position = Vector2(72, 76)
	accent.size = Vector2(84, 6)
	accent.color = GOLD
	main_menu.add_child(accent)
	var eyebrow := _make_label("BİR DÜNYA  •  İKİ BAKIŞ", 16, Color("a8ced6"), UI_FONT)
	eyebrow.position = Vector2(72, 98)
	main_menu.add_child(eyebrow)
	var logo := _make_label("BUNEO", 70, Color.WHITE, DISPLAY_FONT)
	logo.position = Vector2(66, 124)
	logo.add_theme_color_override("font_outline_color", Color("18586c"))
	logo.add_theme_constant_override("outline_size", 9)
	main_menu.add_child(logo)
	var subtitle := _make_label("BOYUT KAPISI", 27, CYAN, DISPLAY_FONT)
	subtitle.position = Vector2(74, 217)
	main_menu.add_child(subtitle)
	var description := _make_label("Koş. Altınları topla. Kamera dönerken\naynı dünyanın içine gir.", 20, Color("d7e8e9"), UI_FONT)
	description.position = Vector2(74, 273)
	description.add_theme_constant_override("line_spacing", 7)
	main_menu.add_child(description)
	var play := _make_button("OYNA  ▶", Vector2(72, 368), Vector2(386, 72), "primary")
	play.add_theme_font_override("font", DISPLAY_FONT)
	play.add_theme_font_size_override("font_size", 24)
	play.pressed.connect(func() -> void: start_requested.emit())
	main_menu.add_child(play)
	menu_upgrade_button = _make_button("ZIPLAMAYI GELİŞTİR", Vector2(72, 454), Vector2(386, 56), "glass")
	menu_upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	main_menu.add_child(menu_upgrade_button)
	var hint_card := _make_card(Vector2(72, 530), Vector2(386, 82), Color(0.03, 0.11, 0.16, 0.88), Color(0.18, 0.55, 0.62, 0.55))
	main_menu.add_child(hint_card)
	var hint_title := _make_label("2D  →  TPS  →  FPS", 19, MINT, UI_FONT)
	hint_title.position = Vector2(18, 11)
	hint_card.add_child(hint_title)
	var hint_copy := _make_label("Harita değişmez; sadece bakışın değişir.", 15, Color("c5dfe2"), UI_FONT)
	hint_copy.position = Vector2(18, 44)
	hint_card.add_child(hint_copy)
	var profile_card := _make_card(Vector2.ZERO, Vector2(180, 54), Color(0.025, 0.08, 0.12, 0.88), Color(0.93, 0.65, 0.2, 0.5))
	profile_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	profile_card.position = Vector2(-208, 28)
	main_menu.add_child(profile_card)
	menu_coins_label = _make_label("◆  000", 23, GOLD, UI_FONT)
	menu_coins_label.position = Vector2(20, 11)
	profile_card.add_child(menu_coins_label)
	var version := _make_label("ALPHA 0.4  •  ANDROID", 13, Color("90b5be"), UI_FONT)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-244, -42)
	main_menu.add_child(version)


func _build_touch_controls() -> void:
	var left := _make_action_button("‹", "move_left")
	game_hud.add_child(left)
	var right := _make_action_button("›", "move_right")
	game_hud.add_child(right)
	up_button = _make_action_button("⌃", "move_forward")
	game_hud.add_child(up_button)
	down_button = _make_action_button("⌄", "move_back")
	game_hud.add_child(down_button)
	var jump := _make_action_button("ZIPLA", "jump")
	game_hud.add_child(jump)
	touch_buttons = [left, right, up_button, down_button, jump]


func _layout_touch_controls() -> void:
	if touch_buttons.size() != 5:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var centers := [Vector2(78, viewport_size.y - 122), Vector2(206, viewport_size.y - 122), Vector2(142, viewport_size.y - 186), Vector2(142, viewport_size.y - 58), Vector2(viewport_size.x - 94, viewport_size.y - 105)]
	for index in range(touch_buttons.size()):
		touch_buttons[index].position = centers[index] - Vector2(64, 64)


func _build_transition() -> void:
	transition_panel = ColorRect.new()
	transition_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_panel.color = Color(0.02, 0.04, 0.08, 0.93)
	transition_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_panel.visible = false
	add_child(transition_panel)
	transition_label = _make_label("", 38, CYAN, DISPLAY_FONT)
	transition_label.set_anchors_preset(Control.PRESET_CENTER)
	transition_label.position = Vector2(-430, -55)
	transition_label.size = Vector2(860, 110)
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.add_theme_color_override("font_outline_color", Color("1d4260"))
	transition_label.add_theme_constant_override("outline_size", 8)
	transition_panel.add_child(transition_label)


func _build_overlay_panels() -> void:
	pause_panel = _make_overlay()
	var pause_stack := _make_overlay_stack(pause_panel)
	pause_stack.add_child(_make_overlay_title("OYUN DURDU"))
	pause_stack.add_child(_make_overlay_caption("Aynı dünyadasın. Hazır olduğunda devam et."))
	var resume := _make_overlay_button("DEVAM ET", true)
	resume.pressed.connect(func() -> void: pause_requested.emit())
	pause_stack.add_child(resume)
	var restart := _make_overlay_button("BAŞTAN OYNA")
	restart.pressed.connect(func() -> void: restart_requested.emit())
	pause_stack.add_child(restart)
	finish_panel = _make_overlay()
	var finish_stack := _make_overlay_stack(finish_panel)
	finish_stack.add_child(_make_overlay_title("PARKUR TAMAMLANDI!"))
	var stars := _make_overlay_title("★  ★  ★")
	stars.add_theme_color_override("font_color", GOLD)
	finish_stack.add_child(stars)
	finish_stats = _make_overlay_caption("")
	finish_stack.add_child(finish_stats)
	var again := _make_overlay_button("TEKRAR OYNA", true)
	again.pressed.connect(func() -> void: restart_requested.emit())
	finish_stack.add_child(again)


func _make_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.03, 0.055, 0.82)
	overlay.add_child(shade)
	return overlay


func _make_overlay_stack(panel: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 0)
	var style := _panel_style(Color("102b3b"), Color("4dd7e8"), 3, 24)
	style.content_margin_left = 44
	style.content_margin_right = 44
	style.content_margin_top = 36
	style.content_margin_bottom = 36
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	card.add_child(stack)
	return stack


func _make_overlay_title(value: String) -> Label:
	var label := _make_label(value, 34, CYAN, DISPLAY_FONT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_overlay_caption(value: String) -> Label:
	var label := _make_label(value, 19, Color("e4f1f2"), UI_FONT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _make_overlay_button(value: String, primary: bool = false) -> Button:
	var button := _make_button(value, Vector2.ZERO, Vector2(420, 60), "primary" if primary else "glass")
	button.custom_minimum_size = Vector2(420, 60)
	return button


func _refresh_touch_controls() -> void:
	if touch_buttons.size() != 5:
		return
	var overlays_open := (pause_panel.visible if is_instance_valid(pause_panel) else false) or (finish_panel.visible if is_instance_valid(finish_panel) else false)
	var active := gameplay_active and not overlays_open
	touch_buttons[0].visible = active
	touch_buttons[1].visible = active
	up_button.visible = active and is_3d
	down_button.visible = active and is_3d
	touch_buttons[4].visible = active


func _update_upgrade_button() -> void:
	var affordable := GameState.coins >= GameState.get_upgrade_cost()
	if is_instance_valid(upgrade_button):
		upgrade_button.modulate = Color.WHITE if affordable else Color(0.72, 0.78, 0.8)
	if is_instance_valid(menu_upgrade_button):
		menu_upgrade_button.modulate = Color.WHITE if affordable else Color(0.72, 0.78, 0.8)


func _make_button(text: String, pos: Vector2, button_size: Vector2, kind: String) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE if kind != "primary" else INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE if kind != "primary" else INK)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if kind != "primary" else INK)
	var bg := GOLD if kind == "primary" else Color(0.035, 0.13, 0.19, 0.9)
	var border := Color("ffe18a") if kind == "primary" else Color(0.25, 0.7, 0.78, 0.58)
	var normal := _panel_style(bg, border, 2, 14)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.10)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.12)
	button.add_theme_stylebox_override("pressed", pressed)
	return button


func _make_card(pos: Vector2, card_size: Vector2, color: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = card_size
	panel.add_theme_stylebox_override("panel", _panel_style(color, border, 2, 15))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _panel_style(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 6
	return style


func _make_label(text: String, size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_action_button(text: String, action: String) -> TouchScreenButton:
	var button := TouchScreenButton.new()
	button.texture_normal = TOUCH_TEXTURE
	button.texture_pressed = TOUCH_TEXTURE
	button.action = action
	button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	button.passby_press = true
	button.modulate = Color(1, 1, 1, 0.84)
	var hit_area := CircleShape2D.new()
	hit_area.radius = 52.0
	button.shape = hit_area
	button.shape_centered = true
	var label := _make_label(text, 33 if text != "ZIPLA" else 17, Color.WHITE, UI_FONT)
	label.position = Vector2.ZERO
	label.size = Vector2(128, 128)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("123147"))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return button
