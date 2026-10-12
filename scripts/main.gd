extends Node

const World2DScene := preload("res://scripts/world_2d.gd")
const World3DScene := preload("res://scripts/world_3d.gd")
const HUDScene := preload("res://scripts/hud.gd")

var current_world: Node
var hud: CanvasLayer
var current_mode := "2D"
var transition_busy := false


func _ready() -> void:
	hud = HUDScene.new()
	add_child(hud)
	hud.upgrade_requested.connect(_on_upgrade_requested)
	hud.camera_requested.connect(_on_camera_requested)
	GameState.message_requested.connect(hud.show_message)
	GameState.coins_changed.connect(hud.set_coins)
	GameState.upgrade_changed.connect(hud.set_upgrade)
	hud.set_coins(GameState.coins)
	hud.set_upgrade(GameState.jump_level)
	show_2d_world()


func show_2d_world() -> void:
	current_mode = "2D"
	_clear_world()
	current_world = World2DScene.new()
	add_child(current_world)
	move_child(current_world, 0)
	current_world.request_3d.connect(_on_request_3d)
	hud.set_mode_2d()
	hud.show_message("ALTINLARI TOPLA • BOYUT KAPISINA ULAŞ")


func show_3d_world() -> void:
	current_mode = "3D"
	_clear_world()
	current_world = World3DScene.new()
	add_child(current_world)
	move_child(current_world, 0)
	current_world.request_2d.connect(_on_request_2d)
	current_world.camera_mode_changed.connect(hud.set_camera_mode)
	hud.set_mode_3d()
	hud.show_message("3D BÖLGE: KIRMIZI ÇIKIŞ KAPISINI BUL")


func _clear_world() -> void:
	if is_instance_valid(current_world):
		current_world.queue_free()
		remove_child(current_world)
	current_world = null


func _on_request_3d() -> void:
	if transition_busy:
		return
	transition_busy = true
	hud.play_transition("BOYUT DEĞİŞİYOR: 2D → 3D")
	await get_tree().create_timer(0.55).timeout
	show_3d_world()
	transition_busy = false


func _on_request_2d() -> void:
	if transition_busy:
		return
	transition_busy = true
	hud.play_transition("BÖLÜM TAMAMLANDI!")
	await get_tree().create_timer(0.7).timeout
	show_2d_world()
	transition_busy = false


func _on_upgrade_requested() -> void:
	GameState.buy_jump_upgrade()


func _on_camera_requested() -> void:
	if current_mode == "3D" and is_instance_valid(current_world):
		current_world.toggle_camera()
