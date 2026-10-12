extends CharacterBody3D

signal fell
signal jumped

const HERO_SCENE := preload("res://assets/kenney_3d/hero.glb")
const SPEED := 6.7
const GRAVITY := 23.0
const BASE_JUMP := 8.8

var mode := "2D"
var visual: Node3D
var animator: AnimationPlayer
var current_animation := ""


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.94
	add_child(collision)

	visual = HERO_SCENE.instantiate()
	visual.scale = Vector3.ONE * 0.5
	visual.rotation.y = PI * 0.25
	add_child(visual)
	animator = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for name in ["Idle", "Run"]:
		animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	_play_animation("Idle")


func _physics_process(delta: float) -> void:
	var horizontal := Input.get_axis("move_left", "move_right")
	var depth := 0.0
	if mode == "3D":
		depth = horizontal
		horizontal = Input.get_axis("move_back", "move_forward")
	var direction := Vector2(horizontal, depth).normalized()
	velocity.x = move_toward(velocity.x, direction.x * SPEED, 28.0 * delta)
	velocity.z = move_toward(velocity.z, direction.y * SPEED, 28.0 * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = BASE_JUMP + GameState.jump_level * 0.72
		jumped.emit()
	move_and_slide()

	if mode == "2D":
		position.z = move_toward(position.z, 0.0, 7.0 * delta)
		velocity.z = 0.0
	else:
		position.z = clampf(position.z, -3.15, 3.15)

	if absf(velocity.x) > 0.15:
		var facing_angle := PI * (0.25 if mode == "2D" else 0.5)
		var target_yaw := facing_angle if velocity.x > 0.0 else -facing_angle
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, minf(delta * 11.0, 1.0))
	elif mode == "3D" and absf(velocity.z) > 0.15:
		var target_yaw := 0.0 if velocity.z > 0.0 else PI
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, minf(delta * 11.0, 1.0))
	elif mode == "3D":
		visual.rotation.y = lerp_angle(visual.rotation.y, PI * 0.5, minf(delta * 5.0, 1.0))

	if not is_on_floor():
		_play_animation("Jump")
	elif direction.length_squared() > 0.04:
		_play_animation("Run")
	else:
		_play_animation("Idle")

	if global_position.y < -11.0:
		fell.emit()


func set_mode(next_mode: String) -> void:
	mode = next_mode


func reset_at(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO
	visual.visible = true


func set_first_person(enabled: bool) -> void:
	visual.visible = not enabled


func _play_animation(name: String) -> void:
	if current_animation == name:
		return
	current_animation = name
	animator.play(name, 0.15)
