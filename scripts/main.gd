extends Node

const ContinuousWorld := preload("res://scripts/continuous_world.gd")
const HUDScene := preload("res://scripts/hud.gd")
const SFX_COIN := preload("res://assets/kenney_audio/pluck_001.ogg")
const SFX_JUMP := preload("res://assets/kenney_audio/select_001.ogg")
const SFX_HURT := preload("res://assets/kenney_audio/glitch_001.ogg")
const SFX_CHECKPOINT := preload("res://assets/kenney_audio/confirmation_001.ogg")
const SFX_GATE := preload("res://assets/kenney_audio/open_001.ogg")
const SFX_FINISH := preload("res://assets/kenney_audio/bong_001.ogg")
const SFX_CLICK := preload("res://assets/kenney_audio/click_001.ogg")

var current_world: Node3D
var hud: CanvasLayer
var current_mode := "2D"
var is_paused := false
var has_started := false


func _ready() -> void:
	current_world = ContinuousWorld.new()
	add_child(current_world)
	current_world.mode_changed.connect(_on_mode_changed)
	current_world.camera_mode_changed.connect(_on_camera_mode_changed)
	current_world.message_requested.connect(_on_message_requested)
	current_world.level_completed.connect(_on_level_completed)
	current_world.coin_collected.connect(func() -> void: _play_sound(SFX_COIN))
	current_world.checkpoint_activated.connect(func() -> void: _play_sound(SFX_CHECKPOINT))
	current_world.player_hurt.connect(_on_player_hurt)
	current_world.health_changed.connect(_on_health_changed)
	current_world.player.jumped.connect(func() -> void: _play_sound(SFX_JUMP))

	hud = HUDScene.new()
	add_child(hud)
	hud.start_requested.connect(_start_game)
	hud.upgrade_requested.connect(_on_upgrade_requested)
	hud.camera_requested.connect(_on_camera_requested)
	hud.pause_requested.connect(_toggle_pause)
	hud.restart_requested.connect(_restart)
	GameState.message_requested.connect(hud.show_message)
	GameState.coins_changed.connect(hud.set_coins)
	GameState.upgrade_changed.connect(hud.set_upgrade)
	hud.set_coins(GameState.coins)
	hud.set_upgrade(GameState.jump_level)
	hud.set_mode_2d()
	hud.set_health(current_world.health)
	current_world.process_mode = Node.PROCESS_MODE_DISABLED
	hud.show_main_menu()


func _process(_delta: float) -> void:
	if is_instance_valid(hud) and is_instance_valid(current_world):
		hud.set_progress(current_world.player.global_position.x / 311.0)


func _start_game() -> void:
	if has_started:
		return
	has_started = true
	current_world.process_mode = Node.PROCESS_MODE_INHERIT
	hud.begin_gameplay()
	_play_sound(SFX_CLICK)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _on_health_changed(value: int) -> void:
	if is_instance_valid(hud):
		hud.set_health(value)


func _on_player_hurt() -> void:
	_play_sound(SFX_HURT)
	if is_instance_valid(hud):
		hud.flash_damage()


func _on_mode_changed(mode: String) -> void:
	current_mode = mode
	_play_sound(SFX_GATE)
	if mode == "3D":
		hud.set_mode_3d()
	else:
		hud.set_mode_2d()


func _on_camera_mode_changed(mode: String) -> void:
	hud.set_camera_mode(mode)


func _on_message_requested(message: String) -> void:
	hud.show_message(message)


func _on_level_completed() -> void:
	_play_sound(SFX_FINISH)
	current_world.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_completion(current_world.run_time, current_world.collected_coins)


func _on_upgrade_requested() -> void:
	if GameState.buy_jump_upgrade():
		_play_sound(SFX_CLICK)


func _on_camera_requested() -> void:
	if current_mode == "3D":
		current_world.toggle_camera()
		_play_sound(SFX_CLICK)


func _toggle_pause() -> void:
	if current_world.is_finished or not has_started:
		return
	is_paused = not is_paused
	current_world.process_mode = Node.PROCESS_MODE_DISABLED if is_paused else Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_paused(is_paused)
	_play_sound(SFX_CLICK)


func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()


func _play_sound(stream: AudioStream) -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = -8.0
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
