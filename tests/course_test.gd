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


func _walk_to(world: Node3D, x: float, seconds: float = 2.0) -> void:
	var action: String = "move_right" if world.mode == "2D" else "move_forward"
	Input.action_press(action)
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while world.player.position.x < x - maxf(0.25, world.player.velocity.x * world.player.velocity.x / (56.0 if world.player.is_on_floor() else 28.0)) and Time.get_ticks_msec() < deadline:
		await physics_frame
	Input.action_release(action)
	await create_timer(0.3).timeout


func _hop(world: Node3D, x: float, switch_mode: bool) -> void:
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	if switch_mode:
		world.course.toggle_dimension()
	await _walk_to(world, x)
	await create_timer(0.55).timeout


func _walk_depth_to(world: Node3D, z: float) -> void:
	var action := "move_left" if z < world.player.position.z else "move_right"
	Input.action_press(action)
	var deadline := Time.get_ticks_msec() + 2500
	while absf(world.player.position.z - z) > maxf(0.25, world.player.velocity.z * world.player.velocity.z / 56.0) and Time.get_ticks_msec() < deadline:
		await physics_frame
	Input.action_release(action)
	await create_timer(0.4).timeout


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.save_path = "user://course_test_save.cfg"
	state.reset_progress()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._start_game()
	var world: Node3D = main.current_world
	var course: Node3D = world.course
	var player: CharacterBody3D = world.player
	_check(course.platforms.size() == 11 and course.traps.size() == 5, "Platform ve yeni tuzak türleri parkurda oluşturuldu")
	player.reset_at(Vector3(12.5, 0.1, 0))
	await create_timer(0.15).timeout
	var before: int = state.coins
	course.interact()
	await process_frame
	_check(state.coins == before + 3 and course.crates[0].collision_layer == 0, "Sandık etkileşimle kırılıyor ve 3 altın veriyor")
	course.interact()
	_check(state.coins == before + 3, "Aynı sandık ikinci kez ödül vermiyor")

	var moving: AnimatableBody3D = course.platforms[0]
	player.reset_at(moving.position + Vector3(0, 0.2, 0))
	await create_timer(0.3).timeout
	var previous_y: float = player.position.y
	await create_timer(0.35).timeout
	_check(player.is_on_floor() and absf(player.position.y - previous_y) > 0.08, "Hareketli platform üstündeki karakteri taşıyor")
	player.reset_at(Vector3(42, 0.1, 0))
	var initial_health: int = world.health
	world.invulnerability = 0.0
	await create_timer(4.2).timeout
	_check(world.health < initial_health, "Zamanlı lazerin etkin fazı fiziksel temasla hasar veriyor")
	player.reset_at(Vector3(50, 0.1, 0))
	world.health = 3
	world.invulnerability = 0.0
	var crumble: AnimatableBody3D = course.platforms[1]
	player.reset_at(crumble.position + Vector3(0, 0.2, 0))
	await create_timer(0.95).timeout
	_check(not crumble.enabled and crumble.collision_layer == 0, "Üstüne basılan platform çöküp çarpışmasını kapatıyor")
	player.reset_at(Vector3(78, 0.1, 0))
	await _walk_to(world, 82.5)
	await create_timer(1.3).timeout
	_check(course.unlocked and world.mode == "3D", "Mor kapı boyut gücünü açıyor")

	player.reset_at(Vector3(100.8, 0.1, 0))
	await create_timer(0.2).timeout
	await _walk_to(world, 106.0, 0.9)
	_check(player.position.x < 102.1, "Merkez yolundaki duvar fiziksel olarak oyuncuyu durduruyor")
	player.reset_at(Vector3(101, 0.1, -3.5))
	await _walk_to(world, 106.1)
	course.interact()
	_check(course.wall_open and course.wall_door.collision_layer == 0, "TPS'de duvarın yanından dolaşıp düğmeyle çıkış açılıyor")

	player.reset_at(Vector3(148, 0.1, 0))
	await create_timer(0.2).timeout
	course.toggle_dimension()
	await _walk_to(world, 151.5)
	await _hop(world, 155.0, false)
	_check(player.is_on_floor() and absf(player.position.x - 155) < 0.7, "İlk mavi köprü basamağı 2D'de fiziksel olarak erişilebilir")
	await _hop(world, 159.0, true)
	_check(world.mode == "3D" and player.is_on_floor() and absf(player.position.x - 159) < 0.7, "Havada boyut değiştirerek mor 3D basamağına geçiliyor")
	await _hop(world, 163.0, true)
	_check(world.mode == "2D" and player.is_on_floor() and absf(player.position.x - 163) < 0.7, "Son mavi basamakta 2D'ye dönülüyor")
	await _hop(world, 167.0, false)
	_check(course.bridge_completed, "Her iki mod kullanılarak perspektif köprüsü tamamlandı")

	player.reset_at(Vector3(184, 0.05, 0))
	await create_timer(0.2).timeout
	_check(player.velocity.y > 10.0, "Zıplama pedi karakteri yüksek rotaya fırlatıyor")
	await create_timer(0.2).timeout
	world.transition_to_3d()
	player.reset_at(Vector3(208, 0.1, 0))
	world.toggle_camera()
	await create_timer(0.7).timeout
	world.camera.look_at(course.targets[1].global_position, Vector3.UP)
	_check(not course.activate_target(1) and course.target_step == 0, "FPS kilidi yanlış sırayı reddediyor")
	for index in range(3):
		world.camera.look_at(course.targets[index].global_position, Vector3.UP)
		_check(course.activate_target(index), "Nişan alınan FPS hedefi %d etkinleşiyor" % (index + 1))
	_check(course.energy_door.collision_layer == 0, "Üç hedef enerji kapısının fiziksel kilidini açıyor")

	world.toggle_camera()
	player.reset_at(Vector3(96, 0.1, 0))
	world.camera.look_at(course.targets[0].global_position, Vector3.UP)
	_check(not course.activate_target(0), "Enerji hedefleri TPS modunda etkinleştirilemiyor")
	await create_timer(0.15).timeout
	await _walk_depth_to(world, -8.5)
	_check(course.secrets_found.has(0), "Yan mağaraya TPS hareketiyle girilip kristal alınıyor")
	await create_timer(0.6).timeout
	var camera_ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 1.4, 0), world.camera.global_position, 2)
	_check(world.get_world_3d().direct_space_state.intersect_ray(camera_ray).is_empty(), "TPS kamera mağarada duvar arkasında kalmıyor")
	player.reset_at(Vector3(184, 0.05, 0))
	await create_timer(0.1).timeout
	await _walk_to(world, 188.0)
	await create_timer(0.7).timeout
	_check(course.secrets_found.has(1), "Zıplama pediyle yüksek kristale gerçekten ulaşılıyor")
	player.reset_at(Vector3(221.5, 0.1, 0))
	await create_timer(0.15).timeout
	await _walk_depth_to(world, 8.5)
	_check(course.secrets_found.has(2), "Enerji kilidinin arkasındaki hazineye TPS'de giriliyor")
	_check(course.secrets_found.size() == 3 and state.collected_secrets.size() == 3, "Üç gizli alanın kristalleri temasla toplanıp kalıcı kaydediliyor")
	state.coins = 100
	_check(state.buy_upgrade("shield"), "Kalkan satın alınabiliyor")
	course.start_run()
	world.invulnerability = 0.0
	var previous_health: int = world.health
	world._take_hit(false)
	_check(world.health == previous_health and course.shield_charges == 0, "Tur başı kalkanı bir hasarı engelleyip tüketiliyor")
	world.invulnerability = 0.0
	world._take_hit(false)
	_check(world.health < previous_health, "Tüketilen kalkan sonraki hasarı engellemiyor")
	before = state.coins
	course.collect_secret(0)
	_check(state.coins == before, "Toplanan kristal aynı turda tekrar ödül vermiyor")
	world.deaths = 0
	player.reset_at(Vector3(311, 0.1, 0))
	await create_timer(0.2).timeout
	_check(world.is_finished and main.hud.finish_panel.visible, "Bulmacalar çözülünce parkur tamamlanıyor")
	_check(state.best_stars == 3 and state.best_time > 0.0, "Tamamlanan turdan gerçek yıldız ve rekor kaydı oluşuyor")
	_check(state.evaluate_run(200.0, 0, 0) == 1 and state.evaluate_run(100.0, 4, 3) == 2, "Yıldızlar süre, düşüş ve keşfe göre değişiyor")

	state.coins = 100
	_check(state.buy_upgrade("magnet") and state.get_upgrade_level("magnet") == 1, "Altın mıknatısı satın alınıyor")
	_check(not state.buy_upgrade("shield") and state.buy_upgrade("air"), "Kalkan sınırı korunuyor ve hava kontrolü satın alınıyor")
	state.save_game()
	var restored: Node = load("res://scripts/game_state.gd").new()
	restored.save_path = state.save_path
	restored.load_game()
	_check(restored.best_stars == 3 and restored.collected_secrets.size() == 3 and restored.get_upgrade_level("shield") == 1, "İlerleme, kristaller, rekor ve yükseltmeler kayıttan geri yükleniyor")
	restored.free()
	main.queue_free()
	await process_frame
	if failures == 0:
		print("BUNEO_COURSE_TEST_OK")
	quit(failures)
