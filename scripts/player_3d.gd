extends CharacterBody3D

signal camera_mode_changed(mode: String)

const SPEED := 7.5
const ACCELERATION := 28.0
const BASE_JUMP := 8.5
const GRAVITY := 22.0

var camera_pivot: Node3D
var pitch_pivot: Node3D
var tps_camera: Camera3D
var fps_camera: Camera3D
var is_fps := false
var spawn_position := Vector3.ZERO


func _ready() -> void:
	spawn_position = position
	_build_body()
	_build_cameras()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, 0.0025)
	if event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
		_apply_look(event.relative, 0.0045)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_look(relative: Vector2, sensitivity: float) -> void:
	rotate_y(-relative.x * sensitivity)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x - relative.y * sensitivity, -1.15, 0.85)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("camera_toggle"):
		toggle_camera()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = BASE_JUMP + GameState.jump_level * 0.75

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, ACCELERATION * delta)
	move_and_slide()

	if position.y < -12.0:
		position = spawn_position
		velocity = Vector3.ZERO


func toggle_camera() -> void:
	is_fps = not is_fps
	fps_camera.current = is_fps
	tps_camera.current = not is_fps
	camera_mode_changed.emit("FPS" if is_fps else "TPS")


func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.42
	mesh.height = 1.8
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("54e1ff")
	material.metallic = 0.35
	material.roughness = 0.25
	material.emission_enabled = true
	material.emission = Color("164a6b")
	mesh_instance.material_override = material
	add_child(mesh_instance)


func _build_cameras() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.45
	add_child(camera_pivot)
	pitch_pivot = Node3D.new()
	camera_pivot.add_child(pitch_pivot)

	tps_camera = Camera3D.new()
	tps_camera.position = Vector3(0, 1.8, 5.6)
	tps_camera.rotation.x = -0.20
	tps_camera.fov = 72.0
	tps_camera.current = true
	pitch_pivot.add_child(tps_camera)

	fps_camera = Camera3D.new()
	fps_camera.position = Vector3(0, 0.2, -0.18)
	fps_camera.fov = 78.0
	fps_camera.current = false
	pitch_pivot.add_child(fps_camera)
