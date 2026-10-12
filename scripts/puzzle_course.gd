extends Node3D

const Platform := preload("res://scripts/course_platform.gd")
const CRATE := preload("res://assets/quaternius_platformer/Cube_Crate.gltf")
const GEM := preload("res://assets/quaternius_platformer/Gem_Blue.gltf")
const SAW := preload("res://assets/quaternius_platformer/Hazard_Saw.gltf")

var world: Node3D
var platforms: Array[AnimatableBody3D] = []
var phase_platforms: Array[AnimatableBody3D] = []
var traps: Array[Dictionary] = []
var crates: Array[StaticBody3D] = []
var secrets: Array[Area3D] = []
var secrets_found: Array[int] = []
var targets: Array[Area3D] = []
var switch_node: Node3D
var wall_door: StaticBody3D
var energy_door: StaticBody3D
var wall_open := false
var target_step := 0
var unlocked := false
var clock := 0.0
var pad_cooldown := 0.0
var dimension_cooldown := 0.0
var objective := ""
var prompt := ""
var aim_target: Area3D
var pad: Area3D
var shield_charges := 0
var bridge_entered := false
var bridge_completed := false
var bridge_modes: Array[String] = []


func _ready() -> void:
	world.mode_changed.connect(func(_mode: String) -> void: refresh_phases())
	_build_platforms()
	_build_traps()
	_build_wall_puzzle()
	_build_energy_lock()
	_build_secret_rooms()
	_build_crates()


func start_run() -> void:
	shield_charges = GameState.get_upgrade_level("shield")


func _physics_process(delta: float) -> void:
	clock += delta
	pad_cooldown = maxf(0.0, pad_cooldown - delta)
	dimension_cooldown = maxf(0.0, dimension_cooldown - delta)
	var x: float = world.player.position.x
	if x >= 148 and x <= 153:
		bridge_entered = true
	for platform in phase_platforms:
		if platform.enabled and platform._player_on_top():
			var step_mode: String = "2D" if platform.kind == Platform.Kind.PHASE_2D else "3D"
			if not bridge_modes.has(step_mode):
				bridge_modes.append(step_mode)
	if bridge_entered and x >= 166 and bridge_modes.size() == 2:
		bridge_completed = true
	world.player.depth_limits = Vector2(-3.95, 3.95)
	if x > 92 and x < 100:
		world.player.depth_limits.x = -9.5
	elif x > 219.5 and x < 224.5 and target_step == 3:
		world.player.depth_limits.y = 9.5
	for trap in traps:
		var area: Area3D = trap.area
		var active := true
		if trap.kind == "laser":
			var phase_time := fmod(clock + float(trap.phase), 4.0)
			active = phase_time < 1.8
			trap.visual.visible = active or phase_time > 3.5
			var material := trap.visual.material_override as StandardMaterial3D
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if active else BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = 1.0 if active else 0.25
			material.emission_energy_multiplier = 0.8 if active else 0.0
		else:
			area.position.z = sin(clock * 1.9 + float(trap.phase)) * 2.7
			trap.visual.rotation.y += delta * 2.0
		if active and area.overlaps_body(world.player):
			world._take_hit(false)
	if pad_cooldown <= 0.0 and pad.overlaps_body(world.player) and world.player.velocity.y <= 0.5:
		pad_cooldown = 0.8
		world.player.velocity.y = 17.0
		world.player.coyote_time = 0.0
		world.player.jumped.emit()
		world.message_requested.emit("BULUT YOLU • YUKARIDA BİR KRİSTAL VAR")
	_collect_magnet_coins(delta)
	_update_context()


func _add_platform(kind: int, location: Vector3, size: Vector3, travel: Vector3 = Vector3.ZERO, phase: float = 0.0) -> AnimatableBody3D:
	var platform := Platform.new()
	platform.world = world
	platform.kind = kind
	platform.position = location
	platform.dimensions = size
	platform.travel = travel
	platform.phase = phase
	add_child(platform)
	platforms.append(platform)
	return platform


func _build_platforms() -> void:
	_add_platform(Platform.Kind.MOVING, Vector3(29.5, 0.1, 0), Vector3(2.4, 0.35, 3), Vector3(0, 1.25, 0))
	_add_platform(Platform.Kind.CRUMBLE, Vector3(55.5, 0.15, 0), Vector3(2.5, 0.35, 3))
	_add_platform(Platform.Kind.BLINK, Vector3(85.5, 0.15, 0), Vector3(2.6, 0.35, 4))
	_add_platform(Platform.Kind.MOVING, Vector3(142.5, 0.1, 0), Vector3(2.5, 0.35, 4), Vector3(0, 0.6, 0), 1.4)
	for index in range(3):
		var kind := Platform.Kind.PHASE_2D if index != 1 else Platform.Kind.PHASE_3D
		phase_platforms.append(_add_platform(kind, Vector3(155 + index * 4, 0.15, 0), Vector3(2.9, 0.35, 8.8)))
	_add_platform(Platform.Kind.CRUMBLE, Vector3(200.5, 0.15, 0), Vector3(2.5, 0.35, 3))
	_add_platform(Platform.Kind.BLINK, Vector3(259.5, 0.15, 0), Vector3(2.5, 0.35, 3), Vector3.ZERO, 1.0)
	_add_platform(Platform.Kind.MOVING, Vector3(287.5, 0.15, 0), Vector3(2.5, 0.35, 3), Vector3(0, 1.4, 0), 2.0)
	_add_platform(Platform.Kind.MOVING, Vector3(190, 4.4, 0), Vector3(3.0, 0.35, 2.5), Vector3(0, 0, -1.6))
	_label("2D / 3D KÖPRÜSÜ\nMavi: 2D • Mor: 3D\nZıpla ve BOYUT'a bas", Vector3(150, 3.1, 0), Color("acddff"))
	_label("HAREKETLİ PLATFORMLAR\nTuruncu çöker • Pembe kaybolur", Vector3(24, 3.7, -1), Color("ffe199"))


func _build_traps() -> void:
	for x in [42.0, 122.0, 249.0]:
		var area := _area(Vector3(x, 0.95, 0), Vector3(0.3, 1.9, 8.8))
		var beam := _box(area, Vector3.ZERO, Vector3(0.12, 1.85, 8.8), Color("ff566d"), true)
		for z in [-4.0, 4.0]:
			_box(self, Vector3(x, 1.0, z), Vector3(0.5, 2.0, 0.5), Color("304859"))
		traps.append({"kind": "laser", "area": area, "visual": beam, "phase": x * 0.13})
	for x in [135.0, 263.0]:
		var area := _area(Vector3(x, 0.6, 0), Vector3(1.0, 1.2, 1.2))
		var visual := SAW.instantiate() as Node3D
		visual.scale = Vector3.ONE * 0.43
		area.add_child(visual)
		traps.append({"kind": "spike", "area": area, "visual": visual, "phase": x})
	pad = _area(Vector3(184, 0.18, 0), Vector3(2.0, 0.36, 2))
	_box(pad, Vector3.ZERO, Vector3(2, 0.2, 2), Color("ffce51"), true)
	_label("↑", Vector3(184, 0.8, 0), Color("fff1b3"))
	_solid(Vector3(186.5, 4.0, 0), Vector3(4, 0.4, 3), Color("90d6e5"))


func _build_wall_puzzle() -> void:
	_solid(Vector3(103, 2.9, 0), Vector3(1.3, 5.8, 5.4), Color("365b71"))
	for y in [0.5, 1.6, 2.7, 3.8, 4.9]:
		_box(self, Vector3(102.31, y, 0), Vector3(0.05, 0.15, 5.4), Color("69c4c7"))
	wall_door = _solid(Vector3(109.5, 3, 0), Vector3(0.7, 6, 9), Color("7856b1"))
	switch_node = Node3D.new()
	switch_node.position = Vector3(106.2, 0, -3.5)
	add_child(switch_node)
	_box(switch_node, Vector3(0, 0.45, 0), Vector3(1.0, 0.9, 0.8), Color("294a68"))
	_box(switch_node, Vector3(0, 1.05, 0), Vector3(0.8, 0.3, 0.7), Color("62f0c4"), true)
	_label("DUVARIN ARKASI\nFPS'de yanından dolaş\nArkadaki düğmeyle yolu aç", Vector3(99, 4.4, 0), Color("f4d88e"))
	_label("DÜĞME • ETKİLEŞ", Vector3(106.2, 2.0, -3.5), Color("89ffd5"))


func _build_energy_lock() -> void:
	energy_door = _solid(Vector3(218, 3.5, 0), Vector3(0.65, 7, 9), Color("287b90"))
	_box(energy_door, Vector3(-0.35, 0, 0), Vector3(0.06, 5.8, 7.8), Color("247384"))
	for z in [-4.0, 4.0]:
		_box(energy_door, Vector3(-0.4, 0, z), Vector3(0.12, 6.0, 0.12), Color("48d9ee"), true)
	for index in range(3):
		var z: float = [-2.2, 2.2, 0.0][index]
		var target := _area(Vector3(215.5, 2.0, z), Vector3(0.5, 1.0, 1.0))
		target.collision_layer = 8
		target.set_meta("target_id", index)
		var visual := GEM.instantiate() as Node3D
		visual.scale = Vector3.ONE * 0.45
		target.add_child(visual)
		targets.append(target)
		_label(str(index + 1), target.position + Vector3(0, 1.05, 0), Color("c2f9ff"))
	_label("ENERJİ KİLİDİ\nFPS: 1 → 2 → 3\nNişan al + ETKİLEŞ", Vector3(206, 3.7, 0), Color("99eaff"))


func _build_secret_rooms() -> void:
	# Side alcoves are real geometry in the existing map, not a separate scene.
	_solid(Vector3(96, -0.45, -7.0), Vector3(8, 0.9, 6), Color("527176"))
	_solid(Vector3(96, 2, -10), Vector3(8, 4, 0.5), Color("3b5669"))
	_solid(Vector3(92.1, 2, -7.3), Vector3(0.4, 4, 5.4), Color("3b5669"))
	_solid(Vector3(99.9, 2, -7.3), Vector3(0.4, 4, 5.4), Color("3b5669"))
	_solid(Vector3(96, 4, -7.5), Vector3(8, 0.3, 5), Color("4a656c"))
	_label("?", Vector3(95, 2.0, -4.5), Color("89fbe5"))
	_add_secret(0, Vector3(96, 1.3, -8.5))
	_add_secret(1, Vector3(188, 5.05, 0))
	_solid(Vector3(221.5, -0.45, 7), Vector3(6.0, 0.9, 6), Color("786153"))
	_solid(Vector3(221.5, 2, 10), Vector3(6, 4, 0.4), Color("786153"))
	_solid(Vector3(219, 2, 7.3), Vector3(0.4, 4, 5.4), Color("786153"))
	_solid(Vector3(224.5, 2, 7.3), Vector3(0.4, 4, 5.4), Color("786153"))
	_add_secret(2, Vector3(221.5, 1.3, 8.5))
	for location in [Vector3(94, 1.2, -6), Vector3(96, 1.2, -7), Vector3(98, 1.2, -8), Vector3(220.5, 1.2, 5.5), Vector3(221.5, 1.2, 7)]:
		world._add_coin(location)


func _add_secret(id: int, location: Vector3) -> void:
	var area := _area(location, Vector3(1.25, 1.8, 1.25))
	area.set_meta("secret_id", id)
	var visual := GEM.instantiate() as Node3D
	visual.scale = Vector3.ONE * 0.55
	area.add_child(visual)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body == world.player:
			collect_secret(id)
	)
	secrets.append(area)
	_label("KRİSTAL", location + Vector3(0, 1.1, 0), Color("b4fffc"))


func collect_secret(id: int) -> void:
	if id < 0 or id >= 3 or secrets_found.has(id):
		return
	secrets_found.append(id)
	GameState.discover_secret(id)
	GameState.add_coin(5)
	world.collected_coins += 5
	world.coin_collected.emit()
	secrets[id].set_deferred("monitoring", false)
	secrets[id].visible = false
	world.message_requested.emit("GİZLİ KRİSTAL %d/3 • +5 ALTIN" % secrets_found.size())


func _build_crates() -> void:
	for location in [Vector3(14, 0.6, 0), Vector3(59, 0.6, 0), Vector3(118, 0.6, 2), Vector3(239, 0.6, 0)]:
		var body := StaticBody3D.new()
		body.position = location
		body.collision_layer = 2
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * 1.1
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		var visual := CRATE.instantiate() as Node3D
		visual.scale = Vector3.ONE * 0.55
		body.add_child(visual)
		add_child(body)
		crates.append(body)


func break_crate(crate: StaticBody3D) -> void:
	if not is_instance_valid(crate) or crate.get_meta("broken", false):
		return
	if world.player.position.distance_to(crate.position) > 3.0:
		return
	crate.set_meta("broken", true)
	crate.collision_layer = 0
	GameState.add_coin(3)
	world.collected_coins += 3
	world.coin_collected.emit()
	create_tween().tween_property(crate, "scale", Vector3.ONE * 0.01, 0.2)
	world.message_requested.emit("SANDIK KIRILDI • +3 ALTIN")


func interact() -> void:
	if world.is_finished:
		return
	if is_instance_valid(aim_target) and world.is_fps:
		activate_target(int(aim_target.get_meta("target_id")))
		return
	if not wall_open and world.mode == "3D" and world.player.position.distance_to(switch_node.position) < 2.3:
		wall_open = true
		_open_door(wall_door)
		world.message_requested.emit("ARKA DÜĞME AÇILDI • ANA YOL SERBEST")
		world.checkpoint_activated.emit()
		return
	for crate in crates:
		if is_instance_valid(crate) and not crate.get_meta("broken", false) and world.player.position.distance_to(crate.position) <= 3.0:
			break_crate(crate)
			return
	world.message_requested.emit("Etkileşim için düğmeye veya sandığa yaklaş; FPS'de hedefe nişan al.")


func activate_target(index: int) -> bool:
	if not world.is_fps or index < 0 or index > 2 or target_step == 3:
		return false
	# Aim and visibility are checked here too; callers cannot activate from across the map.
	if not _target_in_sight(targets[index]):
		return false
	if index != target_step:
		target_step = 0
		_refresh_target_colors()
		world.message_requested.emit("SIRA SIFIRLANDI • 1 → 2 → 3")
		return false
	target_step += 1
	_refresh_target_colors()
	if target_step == 3:
		_open_door(energy_door)
		world.message_requested.emit("ENERJİ KİLİDİ ÇÖZÜLDÜ • SAĞDA GİZLİ HAZİNE")
		world.checkpoint_activated.emit()
	else:
		world.message_requested.emit("HEDEF %d/3 • SIRADAKİ: %d" % [target_step, target_step + 1])
	return true


func _target_in_sight(target: Area3D) -> bool:
	if not world.is_fps:
		return false
	var camera: Camera3D = world.camera
	var offset := target.global_position - camera.global_position
	if offset.length() > 12.0 or offset.length() < 0.01:
		return false
	if (-camera.global_basis.z).dot(offset.normalized()) < 0.985:
		return false
	var ray := PhysicsRayQueryParameters3D.create(camera.global_position, target.global_position, 2 | 8)
	ray.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.collider == target


func _refresh_target_colors() -> void:
	for index in range(targets.size()):
		var visual := targets[index].get_child(1) as Node3D
		visual.scale = Vector3.ONE * (0.32 if index < target_step else 0.45)
		visual.visible = index >= target_step


func _open_door(door: StaticBody3D) -> void:
	door.collision_layer = 0
	create_tween().tween_property(door, "position:y", door.position.y + 8.0, 0.8)


func toggle_dimension() -> bool:
	if not unlocked:
		world.message_requested.emit("Boyut gücü mor kapıda açılacak.")
		return false
	if dimension_cooldown > 0.0:
		return false
	var next_mode := "3D" if world.mode == "2D" else "2D"
	# Do not materialize a solid phase platform inside the character.
	for platform in phase_platforms:
		var required := "2D" if platform.kind == Platform.Kind.PHASE_2D else "3D"
		if required != next_mode:
			continue
		var relative: Vector3 = world.player.position - platform.position
		var half: Vector3 = platform.dimensions * 0.5
		if absf(relative.x) < half.x + 0.4 and absf(relative.z) < half.z + 0.4 and relative.y < half.y and relative.y + 1.85 > -half.y:
			world.message_requested.emit("Platformun içine geçemezsin • Önce zıpla")
			return false
	dimension_cooldown = 0.35
	world.transition_to_3d() if next_mode == "3D" else world.transition_to_2d()
	return true


func refresh_phases() -> void:
	for platform in phase_platforms:
		platform.refresh_phase()


func _update_context() -> void:
	var x: float = world.player.position.x
	if x < 81.8:
		objective = "MOR KAPIYA ULAŞ • Boyut gücünü aç"
	elif not wall_open:
		objective = "DUVARIN ARKASI • FPS'de düğmeyi bul"
	elif not bridge_completed:
		objective = "PERSPEKTİF KÖPRÜSÜ • Mavi 2D, mor 3D"
	elif target_step < 3:
		objective = "ENERJİ KİLİDİ • FPS'de 1 → 2 → 3"
	else:
		objective = "BİTİŞE ULAŞ • Üç gizli kristali ara"
	prompt = ""
	aim_target = null
	if world.is_fps:
		for target in targets:
			if _target_in_sight(target) and int(target.get_meta("target_id")) >= target_step:
				aim_target = target
				prompt = "HEDEF %d • ETKİLEŞ" % (int(target.get_meta("target_id")) + 1)
				break
	if not wall_open and world.mode == "3D" and world.player.position.distance_to(switch_node.position) < 2.3:
		prompt = "DÜĞMEYİ AÇ • ETKİLEŞ"
	elif prompt.is_empty():
		for crate in crates:
			if is_instance_valid(crate) and not crate.get_meta("broken", false) and world.player.position.distance_to(crate.position) < 3.0:
				prompt = "SANDIĞI KIR • ETKİLEŞ"
				break
	for index in range(secrets.size()):
		if not secrets_found.has(index):
			secrets[index].get_child(1).rotation.y += 0.018


func _collect_magnet_coins(delta: float) -> void:
	var level: int = GameState.get_upgrade_level("magnet")
	if level <= 0:
		return
	for coin in world.coins:
		if not is_instance_valid(coin) or coin.is_queued_for_deletion():
			continue
		var destination: Vector3 = world.player.position + Vector3(0, 1.0, 0)
		if coin.position.distance_to(destination) < 2.0 + level:
			var ray := PhysicsRayQueryParameters3D.create(coin.position, destination, 2)
			if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
				coin.set_meta("magnet_active", true)
				coin.position = coin.position.move_toward(destination, delta * 9.0)


func all_puzzles_solved() -> bool:
	return wall_open and bridge_completed and target_step == 3


func _solid(location: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = location
	body.collision_layer = 2
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_box(body, Vector3.ZERO, size, color)
	add_child(body)
	return body


func _area(location: Vector3, size: Vector3) -> Area3D:
	var area := Area3D.new()
	area.position = location
	area.collision_layer = 4
	area.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	return area


func _box(parent: Node3D, location: Vector3, size: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = location
	visual.material_override = world._material(color, glow)
	parent.add_child(visual)
	return visual


func _label(text: String, location: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = location
	label.font_size = 40
	label.pixel_size = 0.006
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	add_child(label)
	return label
