extends Node

signal coins_changed(total: int)
signal upgrade_changed(level: int)
signal message_requested(text: String)

const SAVE_PATH := "user://buneo_save.cfg"
const BASE_UPGRADE_COST := 10
const MAX_JUMP_LEVEL := 3
const UPGRADE_LIMITS := {"jump": 3, "magnet": 2, "shield": 1, "air": 1}
const UPGRADE_PRICES := {"jump": 10, "magnet": 20, "shield": 30, "air": 25}
const TIME_TARGET := 180.0

var coins: int = 0
var jump_level: int = 0
var upgrades := {"magnet": 0, "shield": 0, "air": 0}
var best_time := 0.0
var best_stars := 0
var collected_secrets: Array[int] = []
var settings := {"effects": 0.8, "sensitivity": 1.0, "controls_size": 1.0, "controls_alpha": 0.84, "graphics": 1, "vibration": true}
var save_path := SAVE_PATH
var save_delay := -1.0
var loaded_from_backup := false


func _ready() -> void:
	load_game()


func add_coin(amount: int = 1) -> void:
	coins = maxi(0, coins + amount)
	coins_changed.emit(coins)
	save_delay = 0.5


func _process(delta: float) -> void:
	if save_delay >= 0.0:
		save_delay -= delta
		if save_delay <= 0.0:
			save_game()


func get_upgrade_cost() -> int:
	return BASE_UPGRADE_COST + jump_level * 5


func buy_jump_upgrade() -> bool:
	return buy_upgrade("jump")


func get_upgrade_level(id: String) -> int:
	return jump_level if id == "jump" else int(upgrades.get(id, 0))


func upgrade_cost(id: String) -> int:
	return int(UPGRADE_PRICES.get(id, 0)) + get_upgrade_level(id) * 5


func buy_upgrade(id: String) -> bool:
	if not UPGRADE_LIMITS.has(id):
		return false
	if get_upgrade_level(id) >= int(UPGRADE_LIMITS[id]):
		message_requested.emit("Bu özellik en yüksek seviyede.")
		return false
	var cost := upgrade_cost(id)
	if coins < cost:
		message_requested.emit("Yükseltme için %d altın daha gerekli!" % (cost - coins))
		return false
	coins -= cost
	if id == "jump":
		jump_level += 1
	else:
		upgrades[id] = get_upgrade_level(id) + 1
	coins_changed.emit(coins)
	upgrade_changed.emit(jump_level)
	message_requested.emit("Özellik geliştirildi • Seviye %d" % get_upgrade_level(id))
	save_game()
	return true


func evaluate_run(time_seconds: float, deaths: int, secrets: int) -> int:
	return 1 + int(time_seconds <= TIME_TARGET and deaths <= 3) + int(secrets == 3)


func record_run(time_seconds: float, deaths: int, secrets: int) -> Dictionary:
	var stars := evaluate_run(time_seconds, deaths, secrets)
	var new_record := best_time <= 0.0 or time_seconds < best_time
	if new_record:
		best_time = time_seconds
	best_stars = maxi(best_stars, stars)
	save_game()
	return {"stars": stars, "new_record": new_record, "best_time": best_time}


func discover_secret(id: int) -> void:
	if id >= 0 and id < 3 and not collected_secrets.has(id):
		collected_secrets.append(id)
		save_game()


func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	_validate_settings()
	save_game()


func _validate_settings() -> void:
	settings.effects = clampf(float(settings.effects), 0.0, 1.0)
	settings.sensitivity = clampf(float(settings.sensitivity), 0.4, 2.0)
	settings.controls_size = clampf(float(settings.controls_size), 0.8, 1.2)
	settings.controls_alpha = clampf(float(settings.controls_alpha), 0.3, 1.0)
	settings.graphics = clampi(int(settings.graphics), 0, 2)
	settings.vibration = bool(settings.vibration)


func reset_progress() -> void:
	coins = 0
	jump_level = 0
	upgrades = {"magnet": 0, "shield": 0, "air": 0}
	best_time = 0.0
	best_stars = 0
	collected_secrets.clear()
	coins_changed.emit(coins)
	upgrade_changed.emit(jump_level)
	save_game()


func save_game() -> void:
	save_delay = -1.0
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("player", "coins", coins)
	config.set_value("player", "jump_level", jump_level)
	config.set_value("player", "upgrades", upgrades)
	config.set_value("level_1", "best_time", best_time)
	config.set_value("level_1", "stars", best_stars)
	config.set_value("level_1", "secrets", collected_secrets)
	config.set_value("settings", "values", settings)
	var temporary := save_path + ".tmp"
	if config.save(temporary) != OK:
		push_warning("İlerleme kaydedilemedi.")
		return
	if FileAccess.file_exists(save_path) and not loaded_from_backup:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".bak"))
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(save_path)) == OK:
		loaded_from_backup = false


func load_game() -> void:
	var config := ConfigFile.new()
	loaded_from_backup = false
	if config.load(save_path) != OK:
		if config.load(save_path + ".bak") != OK:
			return
		loaded_from_backup = true
	coins = clampi(int(config.get_value("player", "coins", 0)), 0, 999999)
	jump_level = clampi(int(config.get_value("player", "jump_level", 0)), 0, MAX_JUMP_LEVEL)
	var saved_upgrades: Variant = config.get_value("player", "upgrades", {})
	if saved_upgrades is Dictionary:
		for key in upgrades:
			upgrades[key] = clampi(int(saved_upgrades.get(key, 0)), 0, int(UPGRADE_LIMITS[key]))
	best_time = maxf(0.0, float(config.get_value("level_1", "best_time", 0.0)))
	best_stars = clampi(int(config.get_value("level_1", "stars", 0)), 0, 3)
	collected_secrets.clear()
	var saved_secrets: Variant = config.get_value("level_1", "secrets", [])
	if saved_secrets is Array:
		for id in saved_secrets:
			if id is int and id >= 0 and id < 3 and not collected_secrets.has(id):
				collected_secrets.append(id)
	var saved_settings: Variant = config.get_value("settings", "values", {})
	if saved_settings is Dictionary:
		for key in settings:
			settings[key] = saved_settings.get(key, settings[key])
	_validate_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
