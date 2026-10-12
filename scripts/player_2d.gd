extends CharacterBody2D

const SPEED := 310.0
const BASE_JUMP := 590.0
const GRAVITY := 1550.0

var spawn_position := Vector2.ZERO


func _ready() -> void:
	spawn_position = position
	_build_visual()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		velocity.x = move_toward(velocity.x, axis * SPEED, 1100.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1450.0 * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -(BASE_JUMP + GameState.jump_level * 55.0)

	move_and_slide()
	if position.y > 900.0:
		position = spawn_position
		velocity = Vector2.ZERO


func _build_visual() -> void:
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 18.0
	shape.height = 58.0
	collision.shape = shape
	add_child(collision)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-18, -17), Vector2(-13, -27), Vector2(0, -31),
		Vector2(13, -27), Vector2(18, -17), Vector2(18, 24),
		Vector2(9, 31), Vector2(-9, 31), Vector2(-18, 24)
	])
	body.color = Color("54e1ff")
	add_child(body)

	var visor := Polygon2D.new()
	visor.polygon = PackedVector2Array([Vector2(-12, -17), Vector2(14, -17), Vector2(14, -7), Vector2(-12, -7)])
	visor.color = Color("15213d")
	add_child(visor)

	var glow := PointLight2D.new()
	glow.energy = 0.55
	glow.texture_scale = 0.6
	add_child(glow)

	var camera := Camera2D.new()
	camera.position = Vector2(180, -80)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_right = 4100
	camera.limit_top = -100
	camera.limit_bottom = 720
	add_child(camera)
