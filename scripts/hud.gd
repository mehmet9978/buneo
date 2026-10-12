extends CanvasLayer

signal start_requested
signal upgrade_requested
signal pause_requested
signal restart_requested
signal dimension_requested
signal interact_requested
signal settings_changed
signal shop_requested(id: String)

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
var objective_label: Label
var run_label: Label
var prompt_label: Label
var crosshair: Label
var finish_stars: Label
var menu_record: Label
var settings_panel: Control
var shop_panel: Control
var shop_buttons: Dictionary = {}
var dimension_button: TouchScreenButton
var interact_button: TouchScreenButton
var shop_note: Label
var menu_feedback: Label


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
	show_message("MOR KAPIYA ULAŞ • AYNI DÜNYADA KARAKTERİN GÖZÜNDEN DEVAM ET")


func set_coins(total: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "%03d" % total
	if is_instance_valid(menu_coins_label):
		menu_coins_label.text = "◆  %03d" % total
	_update_upgrade_button()
	_refresh_shop()


func set_upgrade(level: int) -> void:
	if is_instance_valid(upgrade_button):
		upgrade_button.text = "ÖZELLİKLER  •  ZIPLAMA %d/3" % level
	if is_instance_valid(menu_upgrade_button):
		menu_upgrade_button.text = "ÖZELLİKLERİ GELİŞTİR   •   %d◆" % GameState.coins
	_update_upgrade_button()
	_refresh_shop()


func set_mode_2d() -> void:
	is_3d = false
	if is_instance_valid(mode_label):
		mode_label.text = "◉  2D YAN BAKIŞ"
	if is_instance_valid(crosshair):
		crosshair.visible = false
	_refresh_touch_controls()


func set_mode_3d() -> void:
	is_3d = true
	mode_label.text = "◉  3D • FPS"
	crosshair.visible = true
	_refresh_touch_controls()


func show_message(text: String) -> void:
	if not is_instance_valid(message_label):
		return
	if is_instance_valid(message_tween):
		message_tween.kill()
	message_label.text = text
	if is_instance_valid(shop_panel) and shop_panel.visible:
		shop_note.text = text
	if not gameplay_active and is_instance_valid(menu_feedback):
		menu_feedback.text = text
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


func show_completion(time_seconds: float, found_coins: int, deaths: int, secrets: int, result: Dictionary) -> void:
	var minutes := int(time_seconds) / 60
	var seconds := int(time_seconds) % 60
	finish_stars.text = "★  ".repeat(result.stars) + "☆  ".repeat(3 - result.stars)
	finish_stats.text = "SÜRE  %02d:%02d   •   ALTIN  %02d ◆\nDÜŞÜŞ / YENİDEN DOĞMA  %d   •   KRİSTAL  %d/3\n%s   •   EN İYİ  %02d:%02d\n+15 ◆ BİTİRME ÖDÜLÜ" % [minutes, seconds, found_coins, deaths, secrets, "YENİ REKOR!" if result.new_record else "PARKUR TAMAMLANDI", int(result.best_time) / 60, int(result.best_time) % 60]
	finish_panel.visible = true
	_refresh_touch_controls()


func set_run_info(course: Node3D, elapsed: float, deaths: int) -> void:
	objective_label.text = course.objective
	run_label.text = "KRİSTAL %d/3   •   %02d:%02d   •   DÜŞÜŞ %d   •   KALKAN %d" % [course.secrets_found.size(), int(elapsed) / 60, int(elapsed) % 60, deaths, course.shield_charges]
	prompt_label.text = course.prompt
	dimension_button.modulate.a = float(GameState.settings.controls_alpha) if course.unlocked else 0.35
	crosshair.add_theme_color_override("font_color", MINT if is_instance_valid(course.aim_target) else Color.WHITE)


func set_menu_record() -> void:
	menu_record.text = "EN İYİ  %s   •   %d/3 ★   •   %d/3 KRİSTAL" % ["—" if GameState.best_time <= 0 else "%02d:%02d" % [int(GameState.best_time) / 60, int(GameState.best_time) % 60], GameState.best_stars, GameState.collected_secrets.size()]


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
	message_label.position = Vector2(-390, 176)
	message_label.size = Vector2(780, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_outline_color", INK)
	message_label.add_theme_constant_override("outline_size", 7)
	game_hud.add_child(message_label)
	objective_label = _make_label("", 16, Color.WHITE, UI_FONT)
	objective_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_label.position = Vector2(-370, 84)
	objective_label.size = Vector2(740, 28)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_constant_override("outline_size", 5)
	objective_label.add_theme_color_override("font_outline_color", INK)
	game_hud.add_child(objective_label)
	run_label = _make_label("", 14, Color("c8f5f2"), UI_FONT)
	run_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	run_label.position = Vector2(-330, 112)
	run_label.size = Vector2(660, 26)
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_label.add_theme_constant_override("outline_size", 5)
	run_label.add_theme_color_override("font_outline_color", INK)
	game_hud.add_child(run_label)
	prompt_label = _make_label("", 21, GOLD, UI_FONT)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-300, -88)
	prompt_label.size = Vector2(600, 32)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_constant_override("outline_size", 5)
	prompt_label.add_theme_color_override("font_outline_color", INK)
	game_hud.add_child(prompt_label)
	crosshair = _make_label("+", 36, Color.WHITE, UI_FONT)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-18, -28)
	crosshair.size = Vector2(36, 56)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.visible = false
	game_hud.add_child(crosshair)
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1.0, 0.08, 0.16, 0.24)
	damage_flash.modulate.a = 0.0
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)
	_build_main_menu()
	_build_transition()
	_build_overlay_panels()
	_build_settings()
	_build_shop()
	set_menu_record()
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
	upgrade_button.pressed.connect(func() -> void: open_shop())
	game_hud.add_child(upgrade_button)


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
	menu_upgrade_button.pressed.connect(func() -> void: open_shop())
	main_menu.add_child(menu_upgrade_button)
	var hint_card := _make_card(Vector2(72, 530), Vector2(386, 82), Color(0.03, 0.11, 0.16, 0.88), Color(0.18, 0.55, 0.62, 0.55))
	main_menu.add_child(hint_card)
	var hint_title := _make_label("2D  ↔  FPS", 19, MINT, UI_FONT)
	hint_title.position = Vector2(18, 11)
	hint_card.add_child(hint_title)
	var hint_copy := _make_label("Görünmeyen yolu bul. Boyutla köprü kur.", 15, Color("c5dfe2"), UI_FONT)
	hint_copy.position = Vector2(18, 44)
	hint_card.add_child(hint_copy)
	var profile_card := _make_card(Vector2.ZERO, Vector2(180, 54), Color(0.025, 0.08, 0.12, 0.88), Color(0.93, 0.65, 0.2, 0.5))
	profile_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	profile_card.position = Vector2(-208, 28)
	main_menu.add_child(profile_card)
	menu_coins_label = _make_label("◆  000", 23, GOLD, UI_FONT)
	menu_coins_label.position = Vector2(20, 11)
	profile_card.add_child(menu_coins_label)
	var version := _make_label("ALPHA 0.6  •  2D / FPS", 13, Color("90b5be"), UI_FONT)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-244, -42)
	main_menu.add_child(version)
	menu_record = _make_label("", 14, Color("a7cfce"), UI_FONT)
	menu_record.position = Vector2(74, 634)
	main_menu.add_child(menu_record)
	menu_feedback = _make_label("", 14, GOLD, UI_FONT)
	menu_feedback.position = Vector2(74, 666)
	main_menu.add_child(menu_feedback)
	var settings_button := _make_button("AYARLAR", Vector2.ZERO, Vector2(180, 48), "glass")
	settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	settings_button.position = Vector2(-208, 94)
	settings_button.pressed.connect(func() -> void: open_settings())
	main_menu.add_child(settings_button)


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
	dimension_button = _make_action_button("BOYUT", "dimension_toggle")
	game_hud.add_child(dimension_button)
	interact_button = _make_action_button("ETKİLEŞ", "interact")
	game_hud.add_child(interact_button)
	touch_buttons.append(dimension_button)
	touch_buttons.append(interact_button)


func _layout_touch_controls() -> void:
	if touch_buttons.size() < 7:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := float(GameState.settings.controls_size)
	var margin := 24.0
	if OS.has_feature("mobile"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var safe := DisplayServer.get_display_safe_area()
		if safe.size.x > 0 and screen_size.x > 0:
			margin = maxf(24, maxf(safe.position.x, screen_size.x - safe.end.x) * viewport_size.x / screen_size.x + 12)
	var inset := maxf(0.0, margin - 24.0)
	game_hud.offset_left = inset
	game_hud.offset_right = -inset
	if is_instance_valid(main_menu):
		main_menu.offset_left = inset
		main_menu.offset_right = -inset
	viewport_size.x -= inset * 2.0
	margin = 24.0
	var left_x := margin + 64 * scale_factor
	var right_x := left_x + 128 * scale_factor
	var center_x := (left_x + right_x) * 0.5
	var bottom := viewport_size.y - 68 * scale_factor - 10
	var centers := [Vector2(left_x, bottom - 70 * scale_factor), Vector2(right_x, bottom - 70 * scale_factor), Vector2(center_x, bottom - 144 * scale_factor), Vector2(center_x, bottom), Vector2(viewport_size.x - margin - 64 * scale_factor, bottom - 30 * scale_factor), Vector2(viewport_size.x - margin - 208 * scale_factor, bottom - 30 * scale_factor), Vector2(viewport_size.x - margin - 64 * scale_factor, bottom - 176 * scale_factor)]
	for index in range(touch_buttons.size()):
		touch_buttons[index].scale = Vector2.ONE * scale_factor
		touch_buttons[index].modulate.a = float(GameState.settings.controls_alpha)
		touch_buttons[index].position = centers[index] - Vector2.ONE * 64 * scale_factor


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
	var settings_button := _make_overlay_button("AYARLAR")
	settings_button.pressed.connect(func() -> void: open_settings())
	pause_stack.add_child(settings_button)
	finish_panel = _make_overlay()
	var finish_stack := _make_overlay_stack(finish_panel)
	finish_stack.add_child(_make_overlay_title("PARKUR TAMAMLANDI!"))
	finish_stars = _make_overlay_title("☆  ☆  ☆")
	finish_stars.add_theme_color_override("font_color", GOLD)
	finish_stack.add_child(finish_stars)
	finish_stats = _make_overlay_caption("")
	finish_stack.add_child(finish_stats)
	var criteria := _make_overlay_caption("★ Bitiş  •  ★ ≤3:00 ve ≤3 düşüş  •  ★ 3 kristal")
	criteria.add_theme_font_size_override("font_size", 15)
	finish_stack.add_child(criteria)
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


func open_shop() -> void:
	if gameplay_active and not pause_panel.visible:
		pause_requested.emit()
	shop_panel.visible = true
	shop_note.text = "Altınlarını kalıcı özellikler için kullan."
	_refresh_shop()
	_refresh_touch_controls()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func open_settings() -> void:
	if gameplay_active and not pause_panel.visible:
		pause_requested.emit()
	settings_panel.visible = true
	_refresh_touch_controls()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_modal() -> bool:
	if settings_panel.visible:
		settings_panel.visible = false
	elif shop_panel.visible:
		shop_panel.visible = false
	else:
		return false
	_refresh_touch_controls()
	return true


func _build_shop() -> void:
	shop_panel = _make_overlay()
	var stack := _make_overlay_stack(shop_panel)
	stack.add_child(_make_overlay_title("ÖZELLİKLER"))
	for id in ["jump", "magnet", "shield", "air"]:
		var button := _make_overlay_button("")
		button.custom_minimum_size.y = 70
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(func() -> void: shop_requested.emit(id))
		stack.add_child(button)
		shop_buttons[id] = button
	shop_note = _make_overlay_caption("Altınlarını kalıcı özellikler için kullan.")
	shop_note.add_theme_font_size_override("font_size", 16)
	stack.add_child(shop_note)
	var back := _make_overlay_button("GERİ", true)
	back.pressed.connect(func() -> void: close_modal())
	stack.add_child(back)
	_refresh_shop()


func _refresh_shop() -> void:
	var names := {"jump": "ZIPLAMA GÜCÜ", "magnet": "ALTIN MIKNATISI", "shield": "KALKAN", "air": "HAVA KONTROLÜ"}
	var descriptions := {"jump": "Daha yükseğe zıpla", "magnet": "Yakındaki altınları çek", "shield": "Her turda bir hasarı engelle", "air": "Havada daha hızlı yön değiştir"}
	for id in shop_buttons:
		var button: Button = shop_buttons[id]
		var level := GameState.get_upgrade_level(id)
		var maximum: int = GameState.UPGRADE_LIMITS[id]
		var cost := GameState.upgrade_cost(id)
		button.text = "%s   %d/%d   •   %s\n%s" % [names[id], level, maximum, "TAMAM" if level >= maximum else "%d◆" % cost, descriptions[id]]
		button.disabled = level >= maximum
		button.modulate = Color.WHITE if GameState.coins >= cost or level >= maximum else Color(0.75, 0.85, 0.87)


func _build_settings() -> void:
	settings_panel = _make_overlay()
	var stack := _make_overlay_stack(settings_panel)
	stack.add_child(_make_overlay_title("AYARLAR"))
	_add_slider(stack, "Efekt sesi", "effects", 0.0, 1.0, 0.05)
	_add_slider(stack, "Kamera hassasiyeti", "sensitivity", 0.4, 2.0, 0.1)
	_add_slider(stack, "Düğme boyutu", "controls_size", 0.8, 1.2, 0.05)
	_add_slider(stack, "Düğme görünürlüğü", "controls_alpha", 0.3, 1.0, 0.05)
	var quality := OptionButton.new()
	quality.add_theme_font_override("font", UI_FONT)
	quality.add_theme_font_size_override("font_size", 19)
	quality.custom_minimum_size.y = 46
	for value in ["GRAFİK: DÜŞÜK", "GRAFİK: ORTA", "GRAFİK: YÜKSEK"]:
		quality.add_item(value)
	quality.selected = int(GameState.settings.graphics)
	quality.item_selected.connect(func(index: int) -> void:
		GameState.update_setting("graphics", index)
		settings_changed.emit()
	)
	stack.add_child(quality)
	var vibration := CheckButton.new()
	vibration.text = "TİTREŞİM"
	vibration.add_theme_font_override("font", UI_FONT)
	vibration.add_theme_font_size_override("font_size", 18)
	vibration.button_pressed = bool(GameState.settings.vibration)
	vibration.toggled.connect(func(value: bool) -> void: GameState.update_setting("vibration", value))
	stack.add_child(vibration)
	var keys := _make_overlay_caption("BOYUT: Q   •   ETKİLEŞ: E\n3D'ye geçince doğrudan FPS • Bakış: sağda sürükle")
	keys.add_theme_font_size_override("font_size", 15)
	stack.add_child(keys)
	var back := _make_overlay_button("GERİ", true)
	back.pressed.connect(func() -> void: close_modal())
	stack.add_child(back)


func _add_slider(stack: VBoxContainer, title: String, key: String, minimum: float, maximum: float, step_value: float) -> void:
	var row := HBoxContainer.new()
	var label := _make_label(title, 17, Color("d6eeee"), UI_FONT)
	label.custom_minimum_size.x = 210
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step_value
	slider.value = float(GameState.settings[key])
	slider.custom_minimum_size = Vector2(230, 28)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		GameState.update_setting(key, value)
		_layout_touch_controls()
		settings_changed.emit()
	)
	row.add_child(slider)
	stack.add_child(row)


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
	if touch_buttons.size() < 7:
		return
	var overlays_open := (pause_panel.visible if is_instance_valid(pause_panel) else false) or (finish_panel.visible if is_instance_valid(finish_panel) else false)
	var active := gameplay_active and not overlays_open and not (shop_panel.visible if is_instance_valid(shop_panel) else false) and not (settings_panel.visible if is_instance_valid(settings_panel) else false)
	touch_buttons[0].visible = active
	touch_buttons[1].visible = active
	up_button.visible = active and is_3d
	down_button.visible = active and is_3d
	touch_buttons[4].visible = active
	dimension_button.visible = active
	interact_button.visible = active


func _update_upgrade_button() -> void:
	if is_instance_valid(menu_upgrade_button):
		menu_upgrade_button.text = "ÖZELLİKLERİ GELİŞTİR   •   %d◆" % GameState.coins


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
	var label := _make_label(text, 33 if text.length() == 1 else 17, Color.WHITE, UI_FONT)
	label.position = Vector2.ZERO
	label.size = Vector2(128, 128)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("123147"))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return button
