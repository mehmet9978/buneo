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
const TREE := preload("res://assets/kenney_3d/nature/tree_default.glb")
const OAK := preload("res://assets/kenney_3d/nature/tree_oak.glb")
const PINE := preload("res://assets/kenney_3d/nature/tree_pineRoundA.glb")
const GRASS := preload("res://assets/kenney_3d/nature/grass_large.glb")
const BUSH := preload("res://assets/kenney_3d/nature/plant_bush.glb")
const RED_FLOWER := preload("res://assets/kenney_3d/nature/flower_redA.glb")
const YELLOW_FLOWER := preload("res://assets/kenney_3d/nature/flower_yellowA.glb")
const ROCK := preload("res://assets/kenney_3d/nature/rock_largeA.glb")
const SMALL_ROCK := preload("res://assets/kenney_3d/nature/rock_smallA.glb")
const MUSHROOM := preload("res://assets/kenney_3d/nature/mushroom_red.glb")
const LOG := preload("res://assets/kenney_3d/nature/log.glb")

const ISLANDS: Array[Vector2] = [
	Vector2(0, 28), Vector2(31, 54), Vector2(57, 84),
	Vector2(87, 111), Vector2(114, 141), Vector2(144, 168),
	Vector2(171, 199), Vector2(202, 228), Vector2(231, 258),
	Vector2(261, 286), Vector2(289, 315)
]
const CHECKPOINTS := [39.0, 73.0, 99.0, 153.0, 187.0, 245.0, 299.0]
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


func _process(delta: float) -> void:
	world_time += delta
	run_time += delta
	invulnerability = maxf(0.0, invulnerability - delta)
	if player.global_position.x >= 81.8 and player.global_position.x < 225.8 and mode == "2D":
		transition_to_3d()
	elif player.global_position.x >= 225.8 and mode == "3D":
		transition_to_2d()
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
			coin.position.y = coin_heights[index] + sin(world_time * 2.1 + index) * 0.18
	for index in range(hazards.size()):
		hazards[index].rotation.y += delta * (1.3 + index % 3 * 0.3)
	_update_camera(delta)


func _unhandled_input(event: InputEvent) -> void:
	if mode != "3D":
		return
	if event.is_action_pressed("camera_toggle") and not event.is_echo():
		toggle_camera()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x * 0.43:
		_apply_look(event.relative, 0.004)
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, 0.0025)
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
	checkpoint = Vector3(89, 0.1, 0)
	mode_changed.emit(mode)
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
	checkpoint = Vector3(233, 0.1, 0)
	mode_changed.emit(mode)
	message_requested.emit("KAMERA ÖNE DÖNDÜ • YOL AYNI YOL")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _apply_look(relative: Vector2, sensitivity: float) -> void:
	orbit_yaw = clampf(orbit_yaw - relative.x * sensitivity, -1.0, 1.0)
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
	var easing := 1.0 - exp(-5.0 * delta)
	camera.global_position = camera.global_position.lerp(desired_pos, easing)
	var look_target := camera.global_position + (desired_target - camera.global_position).normalized() * 5.0
	camera.look_at(look_target, Vector3.UP)
	camera.fov = lerpf(46.0, 72.0, camera_blend) + fps_blend * 5.0


func _build_sky_and_light() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("8bd7e9")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9ecdf")
	environment.ambient_light_energy = 0.36
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
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
		add_child(ground)
		_decorate_island(island)
		_add_island_coins(island)


func _decorate_island(island: Vector2) -> void:
	for x in range(int(island.x) + 3, int(island.y) - 2, 3):
		var x_pos := float(x) + rng.randf_range(-0.7, 0.7)
		var grass := _place_model(GRASS, Vector3(x_pos, 0, -2.65), rng.randf_range(0.9, 1.35))
		_register_sway(grass)
		if rng.randf() < 0.55:
			var flower_scene: PackedScene = RED_FLOWER if rng.randf() < 0.5 else YELLOW_FLOWER
			var flower := _place_model(flower_scene, Vector3(x_pos + 1.0, 0, 2.9), rng.randf_range(1.0, 1.4))
			_register_sway(flower)
		if x % 9 < 3:
			var tree_scene: PackedScene = TREE if x % 3 == 0 else (OAK if x % 2 == 0 else PINE)
			var tree := _place_model(tree_scene, Vector3(x_pos, 0, -3.8), rng.randf_range(1.55, 2.1))
			_register_sway(tree)
		if rng.randf() < 0.25:
			_place_model(BUSH, Vector3(x_pos + 0.4, 0, 3.25), rng.randf_range(1.2, 1.7))
		if rng.randf() < 0.14:
			var small_scene: PackedScene = SMALL_ROCK if rng.randf() < 0.65 else MUSHROOM
			_place_model(small_scene, Vector3(x_pos - 1.0, 0, -1.8), 1.25)
	if int(island.x) % 2 == 0:
		_place_model(ROCK, Vector3(island.x + 1.8, 0, -3.2), 0.75)
	else:
		_place_model(LOG, Vector3(island.x + 2.3, 0, 3.15), 0.8)


func _place_model(scene: PackedScene, location: Vector3, size: float) -> Node3D:
	var instance := scene.instantiate() as Node3D
	instance.position = location
	instance.scale = Vector3.ONE * size
	instance.rotation.y = rng.randf_range(-PI, PI)
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
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.44
	mesh.bottom_radius = 0.44
	mesh.height = 0.1
	mesh.radial_segments = 16
	visual.mesh = mesh
	visual.rotation.x = PI * 0.5
	visual.material_override = _material(Color("ffd54d"), true)
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
	var cloud_material := _material(Color("fffdf0"))
	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 1.0
	puff_mesh.height = 2.0
	for index in range(18):
		var cloud := Node3D.new()
		cloud.position = Vector3(index * 20 - 10, 12 + index % 4 * 1.2, -22 + index % 3 * 4)
		for part in range(3):
			var puff := MeshInstance3D.new()
			puff.mesh = puff_mesh
			puff.material_override = cloud_material
			puff.position = Vector3((part - 1) * 1.45, (part % 2) * 0.3, 0)
			puff.scale = Vector3(1.3 + part % 2 * 0.45, 0.58 + part % 2 * 0.18, 0.8)
			cloud.add_child(puff)
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
	finish.body_entered.connect(func(body: Node3D) -> void:
		if body == player and not is_finished:
			is_finished = true
			GameState.add_coin(15)
			level_completed.emit()
	)
	add_child(finish)


func _build_checkpoints() -> void:
	for x in CHECKPOINTS:
		var flag := Node3D.new()
		flag.position = Vector3(x, 0, -3.65)
		_add_box(flag, Vector3(0, 1.15, 0), Vector3(0.12, 2.3, 0.12), Color("dde8ea"))
		_add_box(flag, Vector3(0.46, 1.88, 0), Vector3(0.88, 0.52, 0.08), Color("65d9d2"), true)
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
			(flag.get_child(1) as MeshInstance3D).material_override = _material(Color("ffe28c"), true)
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
		var core := MeshInstance3D.new()
		var core_mesh := SphereMesh.new()
		core_mesh.radius = 0.55
		core_mesh.height = 1.1
		core.mesh = core_mesh
		core.material_override = _material(Color("ee4d61"), true)
		area.add_child(core)
		for direction in [-1.0, 1.0]:
			_add_box(area, Vector3(direction * 0.48, 0, 0), Vector3(0.75, 0.16, 0.16), Color("631e45"))
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
		_add_box(platform, Vector3.ZERO, shape.size, Color("67607a"))
		_add_box(platform, Vector3(0, 0.19, 0), Vector3(3.9, 0.12, 2.9), Color("bd9d67"))
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
	gate.body_entered.connect(func(body: Node3D) -> void:
		if body != player:
			return
		if to_3d:
			transition_to_3d()
		else:
			transition_to_2d()
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
			player.reset_at(checkpoint)
		return
	invulnerability = 1.3
	health -= 1
	player_hurt.emit()
	if health <= 0:
		health = max_health
		player.reset_at(checkpoint)
		message_requested.emit("YENİDEN DENE • KONTROL NOKTASINDAN DEVAM")
	elif fell:
		player.reset_at(checkpoint)
		message_requested.emit("DÜŞTÜN • KONTROL NOKTASINDAN DEVAM")
	else:
		player.velocity = Vector3(-3.0, 4.5, 0)
		message_requested.emit("DİKKAT • TEHLİKEYE DOKUNDUN")
	health_changed.emit(health)
