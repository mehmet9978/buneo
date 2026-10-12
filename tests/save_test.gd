extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var state: Node = load("res://scripts/game_state.gd").new()
	state.save_path = "user://save_integrity_test.cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("player", "coins", 42)
	legacy.set_value("player", "jump_level", 12)
	legacy.save(state.save_path)
	state.load_game()
	_check(state.coins == 42 and state.jump_level == 3, "Eski sürüm kaydı altınları koruyup zıplama seviyesini güvenli sınıra taşıyor")
	_check(not state.buy_jump_upgrade() and state.coins == 42, "Maksimum seviyede satın alma altın düşürmüyor")
	state.coins = 150
	state.buy_upgrade("magnet")
	state.buy_upgrade("shield")
	state.update_setting("controls_size", 1.2)
	state.update_setting("effects", 0.0)
	state.discover_secret(0)
	state.discover_secret(2)
	state.record_run(175.0, 2, 2)
	state.record_run(200.0, 5, 3)
	state.save_game()
	var restored: Node = load("res://scripts/game_state.gd").new()
	restored.save_path = state.save_path
	restored.load_game()
	_check(restored.best_time == 175.0 and restored.best_stars == 2, "Yavaş sonraki tur en iyi süreyi veya yıldızı düşürmüyor")
	_check(restored.settings.effects == 0.0 and restored.settings.controls_size == 1.2, "Ses ve dokunmatik ayarları kalıcı korunuyor")
	_check(restored.get_upgrade_level("magnet") == 1 and restored.collected_secrets.size() == 2, "Yükseltmeler ve bulunan kristaller kayıttan geri geliyor")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(state.save_path), ProjectSettings.globalize_path(state.save_path + ".interrupted"))
	restored.best_time = 0.0
	restored.load_game()
	_check(restored.best_time == 175.0 and restored.get_upgrade_level("shield") == 1, "Ana kayıt eksikse yedek kayıt ilerlemeyi kurtarıyor")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(state.save_path + ".interrupted"), ProjectSettings.globalize_path(state.save_path))
	state.free()
	restored.free()
	if failures == 0:
		print("BUNEO_SAVE_TEST_OK")
	quit(failures)
