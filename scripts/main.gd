extends Node

const ContinuousWorld := preload("res://scripts/continuous_world.gd")
const HUDScene := preload("res://scripts/hud.gd")

var current_world: Node3D
var hud: CanvasLayer
var current_mode := "2D"


func _ready() -> void:
	current_world = ContinuousWorld.new()
	add_child(current_world)
	current_world.mode_changed.connect(_on_mode_changed)
	current_world.camera_mode_changed.connect(_on_camera_mode_changed)
	current_world.message_requested.connect(_on_message_requested)
	current_world.level_completed.connect(_on_level_completed)

	hud = HUDScene.new()
	add_child(hud)
	hud.upgrade_requested.connect(_on_upgrade_requested)
	hud.camera_requested.connect(_on_camera_requested)
	GameState.message_requested.connect(hud.show_message)
	GameState.coins_changed.connect(hud.set_coins)
	GameState.upgrade_changed.connect(hud.set_upgrade)
	hud.set_coins(GameState.coins)
	hud.set_upgrade(GameState.jump_level)
	hud.set_mode_2d()
	hud.show_message("TEK DÜNYA • MOR KAPIDA KAMERA KARAKTERİN ARKASINA DÖNER")


func _on_mode_changed(mode: String) -> void:
	current_mode = mode
	if mode == "3D":
		hud.set_mode_3d()
	else:
		hud.set_mode_2d()


func _on_camera_mode_changed(mode: String) -> void:
	hud.set_camera_mode(mode)


func _on_message_requested(message: String) -> void:
	hud.show_message(message)


func _on_level_completed() -> void:
	hud.play_transition("BÖLÜM TAMAMLANDI • +15 ALTIN")
	await get_tree().create_timer(1.4).timeout
	get_tree().reload_current_scene()


func _on_upgrade_requested() -> void:
	GameState.buy_jump_upgrade()


func _on_camera_requested() -> void:
	if current_mode == "3D":
		current_world.toggle_camera()
