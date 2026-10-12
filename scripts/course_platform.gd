extends AnimatableBody3D

enum Kind { MOVING, CRUMBLE, BLINK, PHASE_2D, PHASE_3D }

var kind := Kind.MOVING
var origin := Vector3.ZERO
var travel := Vector3(0, 1.6, 0)
var dimensions := Vector3(3.6, 0.35, 3)
var clock := 0.0
var collapse_clock := -1.0
var world: Node3D
var visual: MeshInstance3D
var label: Label3D
var enabled := true
var phase := 0.0


func _ready() -> void:
	origin = position
	collision_layer = 2
	collision_mask = 1
	sync_to_physics = true
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual = MeshInstance3D.new()
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = _color()
	material.emission_enabled = true
	material.emission = _color()
	material.emission_energy_multiplier = 0.3
	material.roughness = 0.7
	visual.material_override = material
	add_child(visual)
	label = Label3D.new()
	label.text = ["↕", "!", "◷", "2D", "3D"][kind]
	label.position = Vector3(0, 0.55, 0)
	label.font_size = 54
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	if kind == Kind.PHASE_2D or kind == Kind.PHASE_3D:
		refresh_phase()


func _color() -> Color:
	return [Color("4be4c4"), Color("ffad50"), Color("ff79ca"), Color("59dfff"), Color("ab85ff")][kind]


func _physics_process(delta: float) -> void:
	clock += delta
	match kind:
		Kind.MOVING:
			position = origin + travel * (0.5 + 0.5 * sin(clock * 1.5 + phase))
		Kind.BLINK:
			var cycle := fmod(clock + phase, 4.5)
			_set_enabled(cycle < 3.2)
			label.text = "!" if cycle > 2.5 and cycle < 3.2 else "◷"
		Kind.CRUMBLE:
			if collapse_clock < 0.0 and _player_on_top():
				collapse_clock = 0.0
			if collapse_clock >= 0.0:
				collapse_clock += delta
				if collapse_clock < 0.7:
					position.x = origin.x + sin(collapse_clock * 65.0) * 0.04
				elif collapse_clock < 4.0:
					_set_enabled(false)
					position.y -= delta * 5.0
				else:
					position = origin
					collapse_clock = -1.0
					_set_enabled(true)


func _player_on_top() -> bool:
	if not is_instance_valid(world) or not is_instance_valid(world.player):
		return false
	var player: CharacterBody3D = world.player
	for index in range(player.get_slide_collision_count()):
		var contact := player.get_slide_collision(index)
		if contact.get_collider() == self and contact.get_normal().y > 0.7:
			return true
	return false


func refresh_phase() -> void:
	var required := "2D" if kind == Kind.PHASE_2D else "3D"
	_set_enabled(world.mode == required)
	# Inactive platforms remain visible as wirelike ghosts, so the next step is readable.
	var material := visual.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if enabled else BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = _color()
	material.albedo_color.a = 1.0 if enabled else 0.16
	material.emission_energy_multiplier = 0.3 if enabled else 0.0
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.visible = true
	label.modulate.a = 1.0 if enabled else 0.45


func _set_enabled(value: bool) -> void:
	enabled = value
	collision_layer = 2 if value else 0
	visual.visible = value
	label.visible = true
