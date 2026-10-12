extends CharacterBody3D

signal fell
signal jumped

const HERO_SCENE := preload("res://assets/quaternius_platformer/hero.glb")
const SPEED := 6.7
const GRAVITY := 23.0
const BASE_JUMP := 8.8

var mode := "2D"
var visual: Node3D
var animator: AnimationPlayer
var current_animation := ""
var plane_z := 0.0
var depth_limits := Vector2(-3.95, 3.95)
var coyote_time := 0.0
var jump_buffer := 0.0


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
	visual.scale = Vector3.ONE * 0.42
	visual.position.y = 0.42
	visual.rotation.y = PI * 0.25
	add_child(visual)
	animator = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for name in ["Idle", "Run", "Jump_Idle"]:
		animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	_play_animation("Idle")


func _physics_process(delta: float) -> void:
	var horizontal := Input.get_axis("move_left", "move_right")
	var depth := 0.0
	if mode == "3D":
		depth = horizontal
		horizontal = Input.get_axis("move_back", "move_forward")
	var direction := Vector2(horizontal, depth).normalized()
	var acceleration := 28.0 if is_on_floor() else (24.0 if GameState.get_upgrade_level("air") > 0 else 14.0)
	velocity.x = move_toward(velocity.x, direction.x * SPEED, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.y * SPEED, acceleration * delta)
	coyote_time = 0.12 if is_on_floor() else maxf(0.0, coyote_time - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if jump_buffer > 0.0 and coyote_time > 0.0:
		velocity.y = BASE_JUMP + mini(GameState.jump_level, GameState.MAX_JUMP_LEVEL) * 0.72
		jump_buffer = 0.0
		coyote_time = 0.0
		jumped.emit()
	move_and_slide()

	if mode == "2D":
		position.z = plane_z
		velocity.z = 0.0
	else:
		position.z = clampf(position.z, depth_limits.x, depth_limits.y)

	if mode == "3D" and Vector2(velocity.x, velocity.z).length() > 0.15:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(velocity.x, velocity.z), minf(delta * 11.0, 1.0))
	elif absf(velocity.x) > 0.15:
		var facing_angle := PI * (0.25 if mode == "2D" else 0.5)
		var target_yaw := facing_angle if velocity.x > 0.0 else -facing_angle
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, minf(delta * 11.0, 1.0))
	elif mode == "3D" and absf(velocity.z) > 0.15:
		var target_yaw := 0.0 if velocity.z > 0.0 else PI
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, minf(delta * 11.0, 1.0))
	elif mode == "3D":
		visual.rotation.y = lerp_angle(visual.rotation.y, PI * 0.5, minf(delta * 5.0, 1.0))

	if not is_on_floor():
		_play_animation("Jump" if velocity.y > 2.0 else "Jump_Idle")
	elif direction.length_squared() > 0.04:
		_play_animation("Run")
	else:
		_play_animation("Idle")
	animator.speed_scale = 1.35 if current_animation == "Run" else 1.0

	if global_position.y < -11.0:
		fell.emit()


func set_mode(next_mode: String) -> void:
	mode = next_mode
	if mode == "2D":
		plane_z = position.z
		velocity.z = 0.0


func reset_at(point: Vector3) -> void:
	global_position = point
	plane_z = point.z
	velocity = Vector3.ZERO
	coyote_time = 0.0
	jump_buffer = 0.0
	visual.visible = true


func set_first_person(enabled: bool) -> void:
	visual.visible = not enabled


func _play_animation(name: String) -> void:
	if current_animation == name:
		return
	current_animation = name
	animator.play(name, 0.15)
