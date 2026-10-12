extends Node2D

signal request_3d

const Player2D := preload("res://scripts/player_2d.gd")
const BACKGROUND_TEXTURE := preload("res://assets/kenney/bg_grasslands.png")
const GROUND_TEXTURE := preload("res://assets/kenney/grassHalfMid.png")
const COIN_TEXTURE := preload("res://assets/kenney/coinGold.png")

var player: CharacterBody2D


func _ready() -> void:
	_build_background()
	_build_level()
	player = Player2D.new()
	player.position = Vector2(150, 520)
	player.collision_layer = 1
	player.collision_mask = 2
	add_child(player)


func _build_background() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2(-500, -300), Vector2(4500, -300), Vector2(4500, 850), Vector2(-500, 850)])
	sky.color = Color("c8f1f4")
	sky.z_index = -20
	add_child(sky)
	for i in range(5):
		var background := Sprite2D.new()
		background.texture = BACKGROUND_TEXTURE
		background.position = Vector2(512 + 1024 * i, 360)
		background.scale = Vector2(1.0, 1.5)
		background.z_index = -15
		add_child(background)


func _build_level() -> void:
	_add_platform(Vector2(450, 650), Vector2(900, 100))
	_add_platform(Vector2(1160, 560), Vector2(280, 38))
	_add_platform(Vector2(1510, 460), Vector2(250, 38))
	_add_platform(Vector2(1870, 580), Vector2(300, 38))
	_add_platform(Vector2(2260, 490), Vector2(260, 38))
	_add_platform(Vector2(2630, 390), Vector2(220, 38))
	_add_platform(Vector2(3060, 560), Vector2(500, 38))
	_add_platform(Vector2(3680, 650), Vector2(900, 100))

	var coin_positions := [
		Vector2(420, 535), Vector2(680, 535), Vector2(1160, 495),
		Vector2(1510, 395), Vector2(1870, 515), Vector2(2260, 425),
		Vector2(2630, 325), Vector2(2970, 495), Vector2(3190, 495)
	]
	for coin_pos in coin_positions:
		_add_coin(coin_pos)
	_add_portal(Vector2(3790, 515))


func _add_platform(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 2
	body.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		-size * 0.5, Vector2(size.x * 0.5, -size.y * 0.5),
		size * 0.5, Vector2(-size.x * 0.5, size.y * 0.5)
	])
	visual.color = Color("a77546")
	body.add_child(visual)
	for index in range(ceili(size.x / 70.0)):
		var tile := Sprite2D.new()
		tile.texture = GROUND_TEXTURE
		tile.centered = false
		tile.region_enabled = true
		tile.region_rect = Rect2(0, 0, minf(70.0, size.x - index * 70.0), 70)
		tile.position = Vector2(-size.x * 0.5 + index * 70.0, -size.y * 0.5)
		body.add_child(tile)
	add_child(body)


func _add_coin(pos: Vector2) -> void:
	var coin := Area2D.new()
	coin.position = pos
	coin.collision_layer = 4
	coin.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	coin.add_child(collision)
	var visual := Sprite2D.new()
	visual.texture = COIN_TEXTURE
	visual.scale = Vector2(0.7, 0.7)
	coin.add_child(visual)
	coin.body_entered.connect(func(body: Node) -> void:
		if body == player:
			GameState.add_coin()
			coin.queue_free()
	)
	add_child(coin)
	var tween := create_tween().set_loops()
	tween.tween_property(coin, "scale", Vector2(0.55, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(coin, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func _add_portal(pos: Vector2) -> void:
	var portal := Area2D.new()
	portal.position = pos
	portal.collision_layer = 4
	portal.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(105, 170)
	collision.shape = shape
	portal.add_child(collision)
	var frame := Line2D.new()
	frame.points = PackedVector2Array([Vector2(-52, 85), Vector2(-52, -85), Vector2(52, -85), Vector2(52, 85)])
	frame.width = 13.0
	frame.default_color = Color("b657ff")
	portal.add_child(frame)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-40, 75), Vector2(-40, -72), Vector2(40, -72), Vector2(40, 75)])
	core.color = Color(0.32, 0.1, 0.55, 0.72)
	portal.add_child(core)
	var label := Label.new()
	label.text = "3D KAPI"
	label.position = Vector2(-50, -125)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("e5b9ff"))
	portal.add_child(label)
	portal.body_entered.connect(func(body: Node) -> void:
		if body == player:
			request_3d.emit()
	)
	add_child(portal)
	var tween := create_tween().set_loops()
	tween.tween_property(core, "modulate:a", 0.25, 0.55)
	tween.tween_property(core, "modulate:a", 1.0, 0.55)


func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
