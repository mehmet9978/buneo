extends Node3D

signal request_2d
signal camera_mode_changed(mode: String)

const Player3D := preload("res://scripts/player_3d.gd")

var player: CharacterBody3D


func _ready() -> void:
	_build_environment()
	_build_arena()
	player = Player3D.new()
	player.position = Vector3(0, 0.1, 13)
	player.collision_layer = 1
	player.collision_mask = 2
	player.camera_mode_changed.connect(func(mode: String) -> void: camera_mode_changed.emit(mode))
	add_child(player)


func toggle_camera() -> void:
	if is_instance_valid(player):
		player.toggle_camera()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("081128")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("6d8ac4")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("c1dcff")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)


func _build_arena() -> void:
	_add_box(Vector3(0, -0.5, -10), Vector3(24, 1, 52), Color("182a54"), true)
	_add_box(Vector3(-9.5, 1.2, 5), Vector3(2.5, 2.4, 6), Color("284681"), true)
	_add_box(Vector3(8.5, 1.6, -2), Vector3(3, 3.2, 5), Color("284681"), true)
	_add_box(Vector3(-6.5, 1.0, -11), Vector3(4, 2, 3), Color("284681"), true)
	_add_box(Vector3(5.5, 1.3, -19), Vector3(3, 2.6, 5), Color("284681"), true)

	for x in [-11.5, 11.5]:
		for z in range(-32, 17, 8):
			_add_neon_pillar(Vector3(x, 1.5, float(z)))

	var coin_positions := [
		Vector3(0, 1.0, 8), Vector3(-5, 1.0, 3), Vector3(4, 1.0, -3),
		Vector3(-3, 1.0, -9), Vector3(5, 1.0, -14), Vector3(-4, 1.0, -20),
		Vector3(3, 1.0, -26), Vector3(0, 1.0, -31)
	]
	for coin_pos in coin_positions:
		_add_coin(coin_pos)
	_add_exit(Vector3(0, 2.0, -35))


func _add_box(pos: Vector3, size: Vector3, color: Color, collision_enabled: bool) -> void:
	var root: Node3D
	if collision_enabled:
		var body := StaticBody3D.new()
		body.collision_layer = 2
		body.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		root = body
	else:
		root = Node3D.new()
	root.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.25
	material.roughness = 0.55
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	add_child(root)


func _add_neon_pillar(pos: Vector3) -> void:
	var pillar := MeshInstance3D.new()
	pillar.position = pos
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.18, 3.0, 0.18)
	pillar.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("864dff")
	material.emission_enabled = true
	material.emission = Color("7c34d4")
	material.emission_energy_multiplier = 2.5
	pillar.material_override = material
	add_child(pillar)


func _add_coin(pos: Vector3) -> void:
	var coin := Area3D.new()
	coin.position = pos
	coin.collision_layer = 4
	coin.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	collision.shape = shape
	coin.add_child(collision)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.48
	mesh.bottom_radius = 0.48
	mesh.height = 0.14
	mesh.radial_segments = 24
	mesh_instance.mesh = mesh
	mesh_instance.rotation_degrees.x = 90
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffd447")
	material.metallic = 0.75
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = Color("9b5b00")
	mesh_instance.material_override = material
	coin.add_child(mesh_instance)
	coin.body_entered.connect(func(body: Node) -> void:
		if body == player:
			GameState.add_coin()
			coin.queue_free()
	)
	add_child(coin)
	var tween := create_tween().set_loops()
	tween.tween_property(coin, "rotation:y", TAU, 1.4).from(0.0)


func _add_exit(pos: Vector3) -> void:
	var gate := Area3D.new()
	gate.position = pos
	gate.collision_layer = 4
	gate.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.5, 4.2, 1.0)
	collision.shape = shape
	gate.add_child(collision)

	for x in [-2.2, 2.2]:
		var side := MeshInstance3D.new()
		side.position = Vector3(x, 0, 0)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.35, 4.2, 0.5)
		side.mesh = mesh
		side.material_override = _emissive_material(Color("ff425f"))
		gate.add_child(side)
	var top := MeshInstance3D.new()
	top.position.y = 2.0
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(4.75, 0.35, 0.5)
	top.mesh = top_mesh
	top.material_override = _emissive_material(Color("ff425f"))
	gate.add_child(top)
	gate.body_entered.connect(func(body: Node) -> void:
		if body == player:
			request_2d.emit()
	)
	add_child(gate)


func _emissive_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	return material
