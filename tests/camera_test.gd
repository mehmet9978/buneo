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
	var state: Node = root.get_node("GameState")
	state.save_path = "user://camera_test_save.cfg"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._start_game()
	var world: Node3D = main.current_world
	var camera: Camera3D = world.camera
	await create_timer(0.1).timeout
	_check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL and camera.global_basis.is_equal_approx(Basis.IDENTITY), "2D kamera eğimsiz ve tam ortografik")
	# Opposite cube faces must overlap on screen: no visible top or side face.
	for corner in [Vector3(8, 0, 0), Vector3(10, 0, 0), Vector3(8, 2, 0), Vector3(10, 2, 0)]:
		var front := camera.unproject_position(corner + Vector3(0, 0, 4))
		var back := camera.unproject_position(corner - Vector3(0, 0, 4))
		_check(front.distance_to(back) < 0.01, "Blok köşesi derinliğe göre kaymıyor: %s" % corner)
	world.course.unlocked = true
	var player_id: int = world.player.get_instance_id()
	var previous_position: Vector3 = world.player.position
	world.course.toggle_dimension()
	_check(world.is_fps and world.player.position.is_equal_approx(previous_position), "Boyut değişimi karakteri taşımadan doğrudan FPS modunu açıyor")
	await create_timer(0.95).timeout
	_check(camera.global_position.distance_to(world.player.position + Vector3(0.4, 1.62, 0)) < 0.01 and not world.player.visual.visible, "FPS kamera göz konumuna geliyor; üçüncü kişi modu bulunmuyor")
	_check(not InputMap.has_action("camera_toggle") and not world.has_method("toggle_camera"), "TPS seçimi ve kamera değiştirme eylemi kaldırıldı")
	world._apply_look(Vector2(-PI / (2.0 * 0.0025), 0), 0.0025)
	var before: Vector3 = world.player.position
	Input.action_press("move_forward")
	await create_timer(0.3).timeout
	Input.action_release("move_forward")
	_check(world.player.position.z < before.z - 0.4, "FPS'de ileri hareket bakış yönünü takip ediyor")
	world.course.toggle_dimension()
	await create_timer(0.95).timeout
	_check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL and camera.global_basis.is_equal_approx(Basis.IDENTITY), "FPS'den dönüş tam düz 2D projeksiyonuna ulaşıyor")
	_check(world.player.get_instance_id() == player_id and world.player.visual.visible, "Geçişlerde aynı karakter ve harita korunuyor")
	if failures == 0:
		print("BUNEO_CAMERA_TEST_OK")
	quit(failures)
