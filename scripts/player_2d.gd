extends CharacterBody2D

const SPEED := 310.0
const BASE_JUMP := 590.0
const GRAVITY := 1550.0
const STAND_TEXTURE := preload("res://assets/kenney/p1_stand.png")
const JUMP_TEXTURE := preload("res://assets/kenney/p1_jump.png")
const WALK_TEXTURES := [
	preload("res://assets/kenney/p1_walk01.png"),
	preload("res://assets/kenney/p1_walk02.png"),
	preload("res://assets/kenney/p1_walk03.png"),
	preload("res://assets/kenney/p1_walk04.png"),
	preload("res://assets/kenney/p1_walk05.png")
]

var spawn_position := Vector2.ZERO
var sprite: Sprite2D
var walk_time := 0.0


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
	_update_visual(delta)
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

	sprite = Sprite2D.new()
	sprite.texture = STAND_TEXTURE
	sprite.scale = Vector2(0.7, 0.7)
	add_child(sprite)

	var camera := Camera2D.new()
	camera.position = Vector2(180, -80)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_right = 4100
	camera.limit_top = -100
	camera.limit_bottom = 720
	add_child(camera)


func _update_visual(delta: float) -> void:
	if absf(velocity.x) > 10.0:
		sprite.flip_h = velocity.x < 0.0
	if not is_on_floor():
		sprite.texture = JUMP_TEXTURE
	elif absf(velocity.x) > 20.0:
		walk_time += delta
		sprite.texture = WALK_TEXTURES[int(walk_time * 11.0) % WALK_TEXTURES.size()]
	else:
		walk_time = 0.0
		sprite.texture = STAND_TEXTURE
