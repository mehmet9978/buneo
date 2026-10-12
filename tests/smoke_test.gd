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
	var world: Node3D = main.current_world
	var player: CharacterBody3D = world.player
	var camera: Camera3D = world.camera
	_check(world != null and player != null, "Tek 3D dünya ve karakter oluşturuluyor")
	_check(player.animator.get_animation_list().has("Idle") and player.animator.get_animation_list().has("Run") and player.animator.get_animation_list().has("Jump"), "Kenney karakter animasyonları yüklendi")

	player.global_position = Vector3(81.8, 0.15, 0.0)
	await physics_frame
	await physics_frame
	var gate_position := player.global_position
	await create_timer(1.3).timeout
	_check(main.current_mode == "3D", "Mor kapı 3D hareketi açıyor")
	_check(main.current_world == world and world.player == player, "Geçişte dünya ve oyuncu değişmiyor")
	_check(player.global_position.distance_to(gate_position) < 0.6, "Oyuncu başka haritaya taşınmıyor")
	_check(world.camera_blend > 0.95, "Tek kamera karakterin arkasına kayıyor")

	main._on_camera_requested()
	_check(world.is_fps, "TPS/FPS kamera değişiyor")

	var game_state: Node = root.get_node_or_null("GameState")
	_check(game_state != null, "Kayıt ve ekonomi sistemi yükleniyor")
	if game_state != null:
		game_state.coins = game_state.get_upgrade_cost()
		var previous_level: int = game_state.jump_level
		_check(game_state.buy_jump_upgrade(), "Altınla özellik satın alınıyor")
		_check(game_state.jump_level == previous_level + 1, "Zıplama seviyesi artıyor")

	player.global_position = Vector3(225.8, 0.15, 0.0)
	await physics_frame
	await physics_frame
	await create_timer(1.3).timeout
	_check(main.current_mode == "2D", "Turuncu kapı kamerayı aynı sahnede karşıdan bakışa döndürüyor")
	_check(main.current_world == world and world.player == player, "Geri dönüşte dünya ve oyuncu korunuyor")

	if failures == 0:
		print("BUNEO_SMOKE_TEST_OK")
	quit(failures)
