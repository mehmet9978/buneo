extends Node

signal coins_changed(total: int)
signal upgrade_changed(level: int)
signal message_requested(text: String)

const SAVE_PATH := "user://buneo_save.cfg"
const BASE_UPGRADE_COST := 10

var coins: int = 0
var jump_level: int = 0


func _ready() -> void:
	load_game()


func add_coin(amount: int = 1) -> void:
	coins += amount
	coins_changed.emit(coins)
	save_game()


func get_upgrade_cost() -> int:
	return BASE_UPGRADE_COST + jump_level * 5


func buy_jump_upgrade() -> bool:
	var cost := get_upgrade_cost()
	if coins < cost:
		message_requested.emit("Yükseltme için %d altın daha gerekli!" % (cost - coins))
		return false
	coins -= cost
	jump_level += 1
	coins_changed.emit(coins)
	upgrade_changed.emit(jump_level)
	message_requested.emit("Zıplama gücü seviye %d oldu!" % jump_level)
	save_game()
	return true


func reset_progress() -> void:
	coins = 0
	jump_level = 0
	coins_changed.emit(coins)
	upgrade_changed.emit(jump_level)
	save_game()


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "coins", coins)
	config.set_value("player", "jump_level", jump_level)
	config.save(SAVE_PATH)


func load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	coins = int(config.get_value("player", "coins", 0))
	jump_level = int(config.get_value("player", "jump_level", 0))
