extends Node3D

signal mode_changed(mode: String)
signal camera_mode_changed(mode: String)
signal message_requested(text: String)
signal level_completed
signal coin_collected
signal checkpoint_activated
signal player_hurt
signal health_changed(health: int)

const Hero3D := preload("res://scripts/hero_3d.gd")
const PuzzleCourse := preload("res://scripts/puzzle_course.gd")
const TREE := preload("res://assets/quaternius_platformer/Tree.gltf")
const FRUIT_TREE := preload("res://assets/quaternius_platformer/Tree_Fruit.gltf")
const GRASS := preload("res://assets/quaternius_platformer/Grass_1.gltf")
const GRASS_2 := preload("res://assets/quaternius_platformer/Grass_2.gltf")
const GRASS_3 := preload("res://assets/quaternius_platformer/Grass_3.gltf")
const BUSH := preload("res://assets/quaternius_platformer/Bush.gltf")
const FRUIT_BUSH := preload("res://assets/quaternius_platformer/Bush_Fruit.gltf")
const ROCK := preload("res://assets/quaternius_platformer/Rock_1.gltf")
const SMALL_ROCK := preload("res://assets/quaternius_platformer/Rock_2.gltf")
const CLOUD_1 := preload("res://assets/quaternius_platformer/Cloud_1.gltf")
const CLOUD_2 := preload("res://assets/quaternius_platformer/Cloud_2.gltf")
const CLOUD_3 := preload("res://assets/quaternius_platformer/Cloud_3.gltf")
const FENCE := preload("res://assets/quaternius_platformer/Fence_Middle.gltf")
const TOWER := preload("res://assets/quaternius_platformer/Tower.gltf")
const CHEST := preload("res://assets/quaternius_platformer/Chest.gltf")
const CRATE := preload("res://assets/quaternius_platformer/Cube_Crate.gltf")
const PLATFORM_VISUAL := preload("res://assets/quaternius_platformer/Cube_Grass_Single.gltf")
const COIN_VISUAL := preload("res://assets/quaternius_platformer/Coin.gltf")
const SAW_VISUAL := preload("res://assets/quaternius_platformer/Hazard_Saw.gltf")
const GOAL_FLAG := preload("res://assets/quaternius_platformer/Goal_Flag.gltf")
const STAR_VISUAL := preload("res://assets/quaternius_platformer/Star.gltf")
const ARROW_VISUAL := preload("res://assets/quaternius_platformer/Arrow.gltf")

const ISLANDS: Array[Vector2] = [
	Vector2(0, 28), Vector2(31, 54), Vector2(57, 84),
	Vector2(87, 111), Vector2(114, 141), Vector2(144, 153), Vector2(165, 168),
	Vector2(171, 199), Vector2(202, 228), Vector2(231, 258),
	Vector2(261, 286), Vector2(289, 315)
]
const CHECKPOINTS := [39.0, 73.0, 99.0, 149.0, 166.0, 187.0, 205.0, 245.0, 299.0]
const HAZARDS := [Vector3(47, 0.65, 0), Vector3(63, 0.65, 0), Vector3(129, 0.65, -1.7), Vector3(179, 0.65, 1.8), Vector3(211, 0.65, -1.5), Vector3(271, 0.65, 0)]

var player: CharacterBody3D
var camera: Camera3D
var mode := "2D"
var is_fps := false
var camera_blend := 0.0
var fps_blend := 0.0
var orbit_yaw := 0.0
var orbit_pitch := 0.0
var checkpoint := Vector3(5, 0.1, 0)
var rng := RandomNumberGenerator.new()
var world_time := 0.0
var swayers: Array[Node3D] = []
var sway_phases: Array[float] = []
var clouds: Array[Node3D] = []
var coins: Array[Area3D] = []
var coin_heights: Array[float] = []
var is_finished := false
var health := 3
var max_health := 3
var collected_coins := 0
var run_time := 0.0
var invulnerability := 0.0
var hazards: Array[Node3D] = []
var course: Node3D
var checkpoint_mode := "2D"
var deaths := 0
var gates_used: Array[float] = []
var world_environment: WorldEnvironment
var sun: DirectionalLight3D


func _ready() -> void:
	rng.seed = 37129
	_build_sky_and_light()
	_build_landscape()
	_build_islands()
	_build_clouds()
	_build_gates()
	_build_checkpoints()
	_build_hazards()
	_build_bonus_platforms()
	player = Hero3D.new()
	player.position = checkpoint
	player.fell.connect(_on_player_fell)
	add_child(player)
	camera = Camera3D.new()
	camera.fov = 48.0
	add_child(camera)
	camera.global_position = _side_camera_position()
	camera.look_at(_side_camera_target(), Vector3.UP)
	camera.current = true
	course = PuzzleCourse.new()
	course.world = self
	add_child(course)
	apply_graphics()


func _process(delta: float) -> void:
	world_time += delta
	run_time += delta
	invulnerability = maxf(0.0, invulnerability - delta)
	for index in range(swayers.size()):
		var node := swayers[index]
		if is_instance_valid(node):
			node.rotation.z = sin(world_time * 1.7 + sway_phases[index]) * 0.055
	for cloud in clouds:
		cloud.position.x += delta * 0.46
		if cloud.position.x > 339.0:
			cloud.position.x = -15.0
	for index in range(coins.size()):
		var coin := coins[index]
		if is_instance_valid(coin) and not coin.is_queued_for_deletion():
			coin.rotation.y += delta * 2.0
			if not coin.get_meta("magnet_active", false):
				coin.position.y = coin_heights[index] + sin(world_time * 2.1 + index) * 0.18
	for index in range(hazards.size()):
		hazards[index].rotation.y += delta * (1.3 + index % 3 * 0.3)
	_update_camera(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dimension_toggle") and not event.is_echo():
		course.toggle_dimension()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		course.interact()
		get_viewport().set_input_as_handled()
		return
	if mode != "3D":
		return
	if event.is_action_pressed("camera_toggle") and not event.is_echo():
		toggle_camera()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x * 0.43 and not (event.position.x > get_viewport().get_visible_rect().size.x - 340 and event.position.y > get_viewport().get_visible_rect().size.y - 340):
		_apply_look(event.relative, 0.004 * float(GameState.settings.sensitivity))
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, 0.0025 * float(GameState.settings.sensitivity))
	elif event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func toggle_camera() -> void:
	if mode != "3D":
		return
	is_fps = not is_fps
	player.set_first_person(is_fps)
	camera_mode_changed.emit("FPS" if is_fps else "TPS")


func transition_to_3d() -> void:
	if mode == "3D":
		return
	mode = "3D"
	player.set_mode(mode)
	mode_changed.emit(mode)
	camera_mode_changed.emit("TPS")
	message_requested.emit("3D AÇILDI • YUKARI İLERİ, SAĞ/SOL YAN HAREKET")
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func transition_to_2d() -> void:
	if mode == "2D":
		return
	mode = "2D"
	is_fps = false
	player.set_first_person(false)
	player.set_mode(mode)
	mode_changed.emit(mode)
	message_requested.emit("KAMERA ÖNE DÖNDÜ • YOL AYNI YOL")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _apply_look(relative: Vector2, sensitivity: float) -> void:
	orbit_yaw -= relative.x * sensitivity
	orbit_pitch = clampf(orbit_pitch + relative.y * sensitivity, -0.6, 0.7)


func _side_camera_position() -> Vector3:
	return player.global_position + Vector3(3.0, 3.1, 22.0)


func _side_camera_target() -> Vector3:
	return player.global_position + Vector3(3.0, 1.55, 0.0)


func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):
		return
	camera_blend = move_toward(camera_blend, 1.0 if mode == "3D" else 0.0, delta / 1.15)
	fps_blend = move_toward(fps_blend, 1.0 if is_fps else 0.0, delta / 0.28)
	var side_pos := _side_camera_position()
	var side_target := _side_camera_target()
	var orbit := Basis(Vector3.UP, orbit_yaw) * Vector3(-7.3, 3.7 + orbit_pitch * 2.5, 2.1)
	var third_pos := player.global_position + orbit
	var third_target := player.global_position + Vector3(3.1, 1.55, 0.0)
	var desired_pos := side_pos.lerp(third_pos, camera_blend)
	var desired_target := side_target.lerp(third_target, camera_blend)
	var first_pos := player.global_position + Vector3(0.4, 1.62, 0)
	var first_forward := Basis(Vector3.UP, orbit_yaw) * Vector3(5.0, -orbit_pitch * 3.0, 0.0)
	desired_pos = desired_pos.lerp(first_pos, fps_blend)
	desired_target = desired_target.lerp(first_pos + first_forward, fps_blend)
	if camera_blend > 0.55 and fps_blend < 0.95:
		desired_pos = _camera_clear_position(desired_pos)
	var easing := 1.0 - exp(-5.0 * delta)
	camera.global_position = camera.global_position.lerp(desired_pos, easing)
	if camera_blend > 0.55 and fps_blend < 0.95:
		camera.global_position = _camera_clear_position(camera.global_position)
	var look_target := camera.global_position + (desired_target - camera.global_position).normalized() * 5.0
	camera.look_at(look_target, Vector3.UP)
	camera.fov = lerpf(46.0, 72.0, camera_blend) + fps_blend * 5.0


func _camera_clear_position(candidate: Vector3) -> Vector3:
	var anchor := player.global_position + Vector3(0, 1.4, 0)
	var ray := PhysicsRayQueryParameters3D.create(anchor, candidate, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return candidate if hit.is_empty() else hit.position + hit.normal * 0.28


func _build_sky_and_light() -> void:
	world_environment = WorldEnvironment.new()
	var environment := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("4faeda")
	sky_material.sky_horizon_color = Color("b9f0e5")
	sky_material.ground_bottom_color = Color("2f7890")
	sky_material.ground_horizon_color = Color("9dd8c3")
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9ecdf")
	environment.ambient_light_energy = 0.44
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("b6e4dc")
	environment.fog_light_energy = 0.65
	environment.fog_density = 0.0025
	environment.fog_sky_affect = 0.22
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_color = Color("fff5df")
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	add_child(sun)


func _build_landscape() -> void:
	_add_box(self, Vector3(159, -8.5, 0), Vector3(350, 0.2, 65), Color("358eaf"))
	for index in range(12):
		var hill := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		hill.mesh = mesh
		hill.scale = Vector3(15 + index % 3 * 4, 5 + index % 2 * 2, 4)
		hill.position = Vector3(index * 30 - 9, -3.7, -19)
		hill.material_override = _material(Color("4c8375") if index % 2 == 0 else Color("6d9b80"))
		add_child(hill)
	for x in range(5, 315, 11):
		var back_tree := _place_model(TREE if x % 3 else FRUIT_TREE, Vector3(x + rng.randf_range(-2.0, 2.0), -1.5, -11.5), rng.randf_range(0.54, 0.7))
		_register_sway(back_tree)
	for x in [72.0, 160.0, 282.0]:
		_place_model(TOWER, Vector3(x, -0.6, -13.5), 0.47)


func _build_islands() -> void:
	for island_index in range(ISLANDS.size()):
		var island := ISLANDS[island_index]
		var center_x := (island.x + island.y) * 0.5
		var width := island.y - island.x
		var ground := StaticBody3D.new()
		ground.position = Vector3(center_x, -0.65, 0)
		ground.collision_layer = 2
		ground.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(width, 1.3, 9.0)
		collision.shape = shape
		ground.add_child(collision)
		var dirt_color := Color("6d4d36") if island_index < 3 else (Color("5b5360") if island_index < 8 else Color("805437"))
		var grass_color := Color("429247") if island_index < 3 else (Color("398d72") if island_index < 8 else Color("8b9d43"))
		_add_box(ground, Vector3.ZERO, shape.size, dirt_color)
		_add_box(ground, Vector3(0, 0.66, 0), Vector3(width, 0.11, 9.05), grass_color)
		var stripe_color := Color("b18b60") if island_index < 3 else (Color("8a7792") if island_index < 8 else Color("c99a5b"))
		for band in range(3):
			_add_box(ground, Vector3(0, -0.44 + band * 0.36, 4.53), Vector3(width, 0.09, 0.07), stripe_color)
		_add_box(ground, Vector3(0, 0.63, 4.54), Vector3(width, 0.11, 0.16), Color("a5cf62") if island_index < 3 else grass_color.lightened(0.2))
		add_child(ground)
		_decorate_island(island)
		_add_island_coins(island)


func _decorate_island(island: Vector2) -> void:
	for x in range(int(island.x) + 2, int(island.y) - 1, 2):
		var x_pos := float(x) + rng.randf_range(-0.45, 0.45)
		var grass_scene: PackedScene = [GRASS, GRASS_2, GRASS_3][x % 3]
		var grass := _place_model(grass_scene, Vector3(x_pos, 0, -2.6 if x % 4 < 2 else 3.6), rng.randf_range(0.24, 0.36))
		_register_sway(grass)
		if rng.randf() < 0.34:
			var bush_scene: PackedScene = BUSH if rng.randf() < 0.7 else FRUIT_BUSH
			var bush := _place_model(bush_scene, Vector3(x_pos + 0.75, 0, -3.35 if rng.randf() < 0.7 else 3.65), rng.randf_range(0.31, 0.44))
			_register_sway(bush)
		if rng.randf() < 0.24:
			_place_model(ROCK if rng.randf() < 0.55 else SMALL_ROCK, Vector3(x_pos - 0.7, 0, -3.0 if x % 3 else 3.1), rng.randf_range(0.26, 0.43))
	for x in range(int(island.x) + 6, int(island.y) - 2, 8):
		var tree_scene: PackedScene = TREE if x % 3 else FRUIT_TREE
		var tree := _place_model(tree_scene, Vector3(float(x) + rng.randf_range(-1.0, 1.0), 0, -3.65), rng.randf_range(0.44, 0.59))
		_register_sway(tree)
	for x in range(int(island.x) + 9, int(island.y) - 2, 13):
		for segment in range(3):
			_place_model(FENCE, Vector3(x + segment * 0.9, 0, -4.0), 0.45, 0.0)
	if island.y - island.x > 26.0:
		_place_model(CHEST if int(island.x) % 2 else CRATE, Vector3(island.y - 4.2, 0, -3.5), 0.45)


func _place_model(scene: PackedScene, location: Vector3, size: float, yaw: float = INF) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.position = location + Vector3(0, size, 0)
	instance.scale = Vector3.ONE * size
	instance.rotation.y = rng.randf_range(-PI, PI) if is_inf(yaw) else yaw
	add_child(instance)
	return instance


func _register_sway(node: Node3D) -> void:
	swayers.append(node)
	sway_phases.append(rng.randf_range(0, TAU))


func _add_island_coins(island: Vector2) -> void:
	for x in range(int(island.x) + 5, int(island.y) - 1, 5):
		var z := 0.0
		if x > 84 and x < 228:
			z = [-2.0, 0.0, 2.0][x % 3]
		_add_coin(Vector3(x, 1.3, z))


func _add_coin(location: Vector3) -> void:
	var area := Area3D.new()
	area.position = location
	area.collision_layer = 4
	area.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.56
	collision.shape = shape
	area.add_child(collision)
	var visual := COIN_VISUAL.instantiate() as Node3D
	visual.scale = Vector3.ONE * 0.43
	area.add_child(visual)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body == player:
			GameState.add_coin()
			collected_coins += 1
			coin_collected.emit()
			area.queue_free()
	)
	add_child(area)
	coins.append(area)
	coin_heights.append(location.y)


func _build_clouds() -> void:
	for index in range(18):
		var cloud_scene: PackedScene = [CLOUD_1, CLOUD_2, CLOUD_3][index % 3]
		var cloud := cloud_scene.instantiate() as Node3D
		cloud.position = Vector3(index * 20 - 10, 12 + index % 4 * 1.2, -22 + index % 3 * 4)
		cloud.scale = Vector3.ONE * rng.randf_range(1.1, 1.55)
		add_child(cloud)
		clouds.append(cloud)


func _build_gates() -> void:
	_add_gate(81.8, Color("9368ff"), true)
	_add_gate(225.8, Color("ffad55"), false)
	var finish := Area3D.new()
	finish.position = Vector3(311, 1.8, 0)
	finish.collision_layer = 4
	finish.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.5, 24.0, 8.0)
	collision.shape = shape
	finish.add_child(collision)
	_add_box(finish, Vector3(-1.4, 0, 0), Vector3(0.35, 3.8, 0.35), Color("ffe267"), true)
	_add_box(finish, Vector3(1.4, 0, 0), Vector3(0.35, 3.8, 0.35), Color("ffe267"), true)
	_add_box(finish, Vector3(0, 1.92, 0), Vector3(3.15, 0.32, 0.4), Color("fff3b0"), true)
	var finish_title := Label3D.new()
	finish_title.text = "BİTİŞ"
	finish_title.font_size = 72
	finish_title.pixel_size = 0.006
	finish_title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	finish_title.position = Vector3(0, 2.55, 0)
	finish.add_child(finish_title)
	_place_model(GOAL_FLAG, Vector3(308.2, 0, -3.2), 0.83, 0.0)
	finish.body_entered.connect(func(body: Node3D) -> void:
		if body == player and not is_finished:
			if not course.all_puzzles_solved():
				message_requested.emit("Bitiş için duvar, köprü ve enerji kilidini çöz.")
				return
			is_finished = true
			GameState.add_coin(15)
			level_completed.emit()
	)
	add_child(finish)


func _build_checkpoints() -> void:
	for x in CHECKPOINTS:
		var flag := Node3D.new()
		flag.position = Vector3(x, 0, -3.65)
		var flag_visual := GOAL_FLAG.instantiate() as Node3D
		flag_visual.position.y = 0.58
		flag_visual.scale = Vector3.ONE * 0.58
		flag_visual.rotation.y = 0.0
		flag.add_child(flag_visual)
		var beacon := OmniLight3D.new()
		beacon.position = Vector3(0, 2.4, 0)
		beacon.light_color = Color("67e7ed")
		beacon.light_energy = 0.0
		beacon.omni_range = 4.5
		flag.add_child(beacon)
		add_child(flag)
		var area := Area3D.new()
		area.position = Vector3(x, 1.2, 0)
		area.collision_layer = 4
		area.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.4, 2.4, 8.5)
		collision.shape = shape
		area.add_child(collision)
		area.body_entered.connect(func(body: Node3D) -> void:
			if body != player or x <= checkpoint.x:
				return
			checkpoint = Vector3(x + 1.5, 0.1, 0)
			checkpoint_mode = mode
			beacon.light_color = Color("ffe28c")
			beacon.light_energy = 1.4
			checkpoint_activated.emit()
			message_requested.emit("KONTROL NOKTASI • %d%%" % int(x / 311.0 * 100.0))
		)
		add_child(area)


func _build_hazards() -> void:
	for position in HAZARDS:
		var spinner := Node3D.new()
		spinner.position = position
		var area := Area3D.new()
		area.collision_layer = 4
		area.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.68
		collision.shape = shape
		area.add_child(collision)
		var core := SAW_VISUAL.instantiate() as Node3D
		core.scale = Vector3.ONE * 0.44
		area.add_child(core)
		area.body_entered.connect(func(body: Node3D) -> void:
			if body == player:
				_take_hit(false)
		)
		spinner.add_child(area)
		add_child(spinner)
		hazards.append(spinner)


func _build_bonus_platforms() -> void:
	for x in [19.0, 69.0, 136.0, 193.0, 275.0]:
		var platform := StaticBody3D.new()
		platform.position = Vector3(x, 1.05, 0)
		platform.collision_layer = 2
		platform.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(3.8, 0.35, 2.8)
		collision.shape = shape
		platform.add_child(collision)
		var visual := PLATFORM_VISUAL.instantiate() as Node3D
		visual.scale = Vector3(1.7, 0.175, 1.3)
		platform.add_child(visual)
		add_child(platform)
		_add_coin(Vector3(x, 2.7, 0))


func _add_gate(x: float, color: Color, to_3d: bool) -> void:
	var gate := Area3D.new()
	gate.position = Vector3(x, 1.8, 0)
	gate.collision_layer = 4
	gate.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.3, 24.0, 8.2)
	collision.shape = shape
	gate.add_child(collision)
	_add_box(gate, Vector3(-0.9, 0, 0), Vector3(0.24, 3.6, 0.28), color, true)
	_add_box(gate, Vector3(0.9, 0, 0), Vector3(0.24, 3.6, 0.28), color, true)
	_add_box(gate, Vector3(0, 1.75, 0), Vector3(2.05, 0.28, 0.28), color, true)
	var emblem_scene: PackedScene = STAR_VISUAL if to_3d else ARROW_VISUAL
	var emblem := emblem_scene.instantiate() as Node3D
	emblem.position = Vector3(0, 2.75, 0)
	emblem.scale = Vector3.ONE * (0.48 if to_3d else 0.38)
	emblem.rotation.y = PI * 0.5
	gate.add_child(emblem)
	gate.body_entered.connect(func(body: Node3D) -> void:
		if body != player or gates_used.has(x):
			return
		gates_used.append(x)
		if to_3d:
			course.unlocked = true
			transition_to_3d()
			checkpoint = Vector3(78, 0.1, 0)
			checkpoint_mode = "3D"
		else:
			transition_to_2d()
			checkpoint = Vector3(223, 0.1, 0)
			checkpoint_mode = "2D"
	)
	add_child(gate)


func _add_box(parent: Node3D, location: Vector3, size: Vector3, color: Color, glowing: bool = false) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = location
	visual.material_override = _material(color, glowing)
	parent.add_child(visual)


func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.8
	return material


func _on_player_fell() -> void:
	_take_hit(true)


func _take_hit(fell: bool) -> void:
	if invulnerability > 0.0 or is_finished:
		if fell and not is_finished:
			deaths += 1
			_respawn()
		return
	if not fell and course.shield_charges > 0:
		course.shield_charges -= 1
		invulnerability = 1.3
		message_requested.emit("KALKAN HASARI ENGELLEDİ")
		return
	invulnerability = 1.3
	health -= 1
	player_hurt.emit()
	if health <= 0:
		deaths += 1
		health = max_health
		_respawn()
		message_requested.emit("YENİDEN DENE • KONTROL NOKTASINDAN DEVAM")
	elif fell:
		deaths += 1
		_respawn()
		message_requested.emit("DÜŞTÜN • KONTROL NOKTASINDAN DEVAM")
	else:
		player.velocity = Vector3(-3.0, 4.5, 0)
		message_requested.emit("DİKKAT • TEHLİKEYE DOKUNDUN")
	health_changed.emit(health)


func _respawn() -> void:
	player.reset_at(checkpoint)
	if checkpoint_mode == "3D":
		transition_to_3d()
	else:
		transition_to_2d()
	player.set_first_person(is_fps)


func apply_graphics() -> void:
	var quality := int(GameState.settings.graphics)
	sun.shadow_enabled = quality > 0
	get_viewport().msaa_3d = Viewport.MSAA_2X if quality == 2 else Viewport.MSAA_DISABLED
	camera.far = 160.0 if quality == 0 else 240.0
