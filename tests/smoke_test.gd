extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_check(main.current_mode == "2D", "Oyun 2D modda başlıyor")
	_check(main.current_world != null, "2D dünya oluşturuluyor")

	main._on_request_3d()
	await create_timer(0.7).timeout
	_check(main.current_mode == "3D", "Kapı 3D moda geçiriyor")
	_check(main.current_world.player != null, "3D oyuncu oluşturuluyor")

	main._on_camera_requested()
	_check(main.current_world.player.is_fps, "TPS/FPS kamera değişiyor")

	var game_state: Node = root.get_node_or_null("GameState")
	_check(game_state != null, "Kayıt ve ekonomi sistemi yükleniyor")
	if game_state != null:
		game_state.coins = game_state.get_upgrade_cost()
		var previous_level: int = game_state.jump_level
		_check(game_state.buy_jump_upgrade(), "Altınla özellik satın alınıyor")
		_check(game_state.jump_level == previous_level + 1, "Zıplama seviyesi artıyor")

	main._on_request_2d()
	await create_timer(0.9).timeout
	_check(main.current_mode == "2D", "3D çıkışı 2D moda döndürüyor")

	if failures == 0:
		print("BUNEO_SMOKE_TEST_OK")
	quit(failures)
