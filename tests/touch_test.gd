extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _touch(finger: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.position = position
	event.pressed = pressed
	root.push_input(event, true)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://touch_test_save.cfg"
	state.settings.controls_size = 1.0
	state.settings.controls_alpha = 0.84
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main._start_game()
	await process_frame
	var right: TouchScreenButton = main.hud.touch_buttons[1]
	var left: TouchScreenButton = main.hud.touch_buttons[0]
	var jump: TouchScreenButton = main.hud.touch_buttons[4]
	var right_center: Vector2 = right.position + Vector2(64, 64)
	var left_center: Vector2 = left.position + Vector2(64, 64)
	var jump_center: Vector2 = jump.position + Vector2(64, 64)
	_touch(0, right_center, true)
	_touch(1, jump_center, true)
	await process_frame
	if not Input.is_action_pressed("move_right") or not Input.is_action_pressed("jump"):
		push_error("Hareket ve zıplama eşzamanlı dokunmada etkinleşmedi")
		quit(1)
		return
	_touch(0, right_center, false)
	await process_frame
	if Input.is_action_pressed("move_right") or not Input.is_action_pressed("jump"):
		push_error("Bir parmak kalkınca diğerinin eylemi bozuldu")
		quit(1)
		return
	_touch(1, jump_center, false)
	await process_frame
	if Input.is_action_pressed("jump"):
		push_error("Zıplama parmak kalkınca bırakılmadı")
		quit(1)
		return
	_touch(0, left_center, true)
	_touch(1, right_center, true)
	await process_frame
	if not Input.is_action_pressed("move_left") or not Input.is_action_pressed("move_right"):
		push_error("Sol ve sağ düğmeler ayrı parmakları algılamadı")
		quit(1)
		return
	_touch(1, right_center, false)
	await process_frame
	if not Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		push_error("Sağ parmak kalkınca sol yön bozuldu")
		quit(1)
		return
	_touch(0, left_center, false)
	await process_frame
	main.current_world.course.unlocked = true
	var dimension: TouchScreenButton = main.hud.dimension_button
	var interact: TouchScreenButton = main.hud.interact_button
	var dimension_center: Vector2 = dimension.position + Vector2(64, 64)
	var interact_center: Vector2 = interact.position + Vector2(64, 64)
	_touch(0, right_center, true)
	_touch(1, jump_center, true)
	_touch(2, dimension_center, true)
	await process_frame
	if not Input.is_action_pressed("move_right") or not Input.is_action_pressed("jump") or main.current_mode != "3D":
		push_error("Üç parmakla hareket + zıplama + boyut değiştirme çalışmadı")
		quit(1)
		return
	_touch(2, dimension_center, false)
	_touch(1, jump_center, false)
	_touch(0, right_center, false)
	_touch(3, interact_center, true)
	await process_frame
	if not Input.is_action_pressed("interact"):
		push_error("Etkileşim dokunmatik düğmesi etkinleşmedi")
		quit(1)
		return
	main._toggle_pause()
	if Input.is_action_pressed("interact") or main.hud.dimension_button.visible:
		push_error("Duraklatma dokunmatik eylemleri temizlemedi")
		quit(1)
		return
	_touch(3, interact_center, false)
	main._toggle_pause()
	print("BUNEO_MULTI_TOUCH_OK")
	await create_timer(0.25).timeout
	main.queue_free()
	await process_frame
	quit()
