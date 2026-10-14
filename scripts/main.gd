extends Node3D
## BlockForge 3D: lightweight first-person block puzzle foundation.
## Click/tap the three glowing cubes in numerical order to complete the puzzle.

const PLAYER_SCENELESS_SPEED := 5.0
const LOOK_SENSITIVITY := 0.0022
const INTERACTION_DISTANCE := 7.0

var player: CharacterBody3D
var camera: Camera3D
var pitch := 0.0
var mouse_captured := false
var targets: Array[StaticBody3D] = []
var next_target := 0
var status_label: Label
var hint_label: Label
var puzzle_complete := false

func _ready() -> void:
	_build_world()
	_build_player()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101827")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b9d4f5")
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	_add_box("Puzzle Floor", Vector3(0, -0.25, 0), Vector3(18, 0.5, 18), Color("#263447"), false)
	_add_box("Back Wall", Vector3(0, 2, -8), Vector3(18, 4, 0.4), Color("#182538"), false)
	_add_box("Left Wall", Vector3(-8, 2, 0), Vector3(0.4, 4, 16), Color("#182538"), false)
	_add_box("Right Wall", Vector3(8, 2, 0), Vector3(0.4, 4, 16), Color("#182538"), false)

	# A small block-built path leads to the puzzle stations.
	for i in range(5):
		_add_box("Path Block %d" % i, Vector3(0, 0.08, -1.5 - i * 0.85),
			Vector3(1.2, 0.16, 0.7), Color("#43566f"), false)

	var target_positions := [Vector3(-2.5, 1.0, -5.0), Vector3(0, 1.0, -5.0), Vector3(2.5, 1.0, -5.0)]
	var target_colors := [Color("#ff784f"), Color("#ffd166"), Color("#56d6c2")]
	for i in range(target_positions.size()):
		var target := _add_box("Sequence Cube %d" % (i + 1), target_positions[i],
			Vector3(1.0, 1.0, 1.0), target_colors[i], true)
		target.set_meta("sequence_index", i)
		targets.append(target)

func _add_box(box_name: String, position: Vector3, dimensions: Vector3,
		color: Color, is_target: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	if is_target:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.35
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	return body

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.0, 5.5)
	player.floor_snap_length = 0.25
	add_child(player)

	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	collider.shape = capsule
	collider.position.y = 0.85
	player.add_child(collider)

	camera = Camera3D.new()
	camera.name = "FirstPersonCamera"
	camera.position.y = 1.55
	camera.current = true
	camera.fov = 78.0
	player.add_child(camera)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(300, 94)
	layer.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)

	var title := Label.new()
	title.text = "BLOCKFORGE 3D  /  PUZZLE 01"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#ff966f"))
	stack.add_child(title)

	status_label = Label.new()
	status_label.text = "SEQUENCE: 1  →  2  →  3"
	status_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(status_label)

	hint_label = Label.new()
	hint_label.text = "WASD move  •  Mouse look  •  Click cubes"
	hint_label.position = Vector2(20, 126)
	hint_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(hint_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 26)
	crosshair.add_theme_color_override("font_color", Color("#ffffff"))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	layer.add_child(crosshair)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_captured = not mouse_captured
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_captured:
				mouse_captured = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				_try_interact()
	elif event is InputEventMouseMotion and mouse_captured:
		player.rotate_y(-event.relative.x * LOOK_SENSITIVITY)
		pitch = clamp(pitch - event.relative.y * LOOK_SENSITIVITY, -1.35, 1.35)
		camera.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventScreenTouch and event.pressed:
		# Basic tap-to-interact fallback; dedicated mobile look controls are a follow-up milestone.
		_try_interact()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := player.global_transform.basis * Vector3(input_vector.x, 0, -input_vector.y)
	direction.y = 0
	direction = direction.normalized()
	player.velocity.x = direction.x * PLAYER_SCENELESS_SPEED
	player.velocity.z = direction.z * PLAYER_SCENELESS_SPEED
	if not player.is_on_floor():
		player.velocity.y -= 20.0 * delta
	else:
		player.velocity.y = 0
	player.move_and_slide()

func _try_interact() -> void:
	if puzzle_complete or camera == null:
		return
	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * INTERACTION_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider = hit.get("collider")
	if collider == null or not collider.has_meta("sequence_index"):
		return
	var selected_index: int = collider.get_meta("sequence_index")
	if selected_index == next_target:
		_complete_target(collider)
	else:
		status_label.text = "NOT YET — FIND CUBE %d" % (next_target + 1)
		status_label.add_theme_color_override("font_color", Color("#ff784f"))

func _complete_target(target: StaticBody3D) -> void:
	target.visible = false
	target.collision_layer = 0
	target.collision_mask = 0
	next_target += 1
	if next_target >= targets.size():
		puzzle_complete = true
		status_label.text = "PUZZLE COMPLETE  ✓"
		status_label.add_theme_color_override("font_color", Color("#56d6c2"))
		hint_label.text = "Excellent! Puzzle 01 complete."
	else:
		status_label.text = "SEQUENCE: %d / 3 COMPLETE" % next_target
		status_label.add_theme_color_override("font_color", Color("#ffffff"))
