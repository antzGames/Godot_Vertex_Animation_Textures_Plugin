class_name VATInteractiveGridDemo
extends Node3D

@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

@onready var vat_multi_mesh_instance_3d: VATMultiMeshInstance3D = $OpenVATMultiMeshInstance3D
@onready var mesh_floor: MeshInstance3D = $Floor
@onready var pivot: Node3D = $Pivot
@onready var camera_3d: Camera3D = $Pivot/Camera3D

@onready var title_label: Label = $UI/Title
@onready var instance_count: Label = $UI/MarginContainer/VBox/HBoxCount/InstanceCount
@onready var shadows_check_button: CheckButton = $UI/MarginContainer/VBox/HBoxShadows/ShadowsCheckButton
@onready var v_sync_check_button: CheckButton = $UI/MarginContainer/VBox/HBoxShadows2/VSyncCheckButton

@export var title: String
@export var next_scene: PackedScene

@export_category("Camera")
@export var rotate_camera: bool
@export_range(0.5, 5, 0.1) var camera_speed: float = 1.0
@export var camera_position: Vector3 = Vector3(0,20,55)
@export var camera_lookat: Vector3 = Vector3(0,0,0)

@export_category("Grid")
@export var grid_size: Vector2 = Vector2(1,1)

var node3D: Node3D = Node3D.new()
var location: Vector3 = Vector3.ZERO
var square_rt: int
var demo_index: int = 0;

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v_sync_check_button.button_pressed else DisplayServer.VSYNC_DISABLED)
	if OS.get_name() == "Web": v_sync_check_button.disabled = true
	instance_count.text = str(vat_multi_mesh_instance_3d.multimesh.instance_count)
	title_label.text = title
	camera_3d.global_position = camera_position
	camera_3d.look_at(camera_lookat)
	setupInstances()

func _process(delta: float) -> void:
	if rotate_camera:
		pivot.rotate_y(delta * 0.1 * camera_speed)

func setupInstances():
	# change floor size based on instance count
	square_rt = int(sqrt(vat_multi_mesh_instance_3d.multimesh.instance_count))
	mesh_floor.mesh.size = Vector2(float(square_rt) * grid_size.x, float(square_rt) * grid_size.y) 

	for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
		placeInstance(instance)

func placeInstance(i: int):
	vat_multi_mesh_instance_3d.update_instance_alpha(i, 1.0)
	
	var x: float = (-square_rt * grid_size.x)/2.0 + (i % square_rt * grid_size.y)
	@warning_ignore("integer_division")
	var y: float = (-square_rt * grid_size.x)/2.0 + (int(i / square_rt) * grid_size.y)
	
	location.x = x
	location.z = y
	location.y = randf_range(0.1,0.2)

	vat_multi_mesh_instance_3d.update_instance_track(i, 2)

	node3D.rotation.y = randi_range(0,3) * (PI/2)
	node3D.position = location
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_scene"):
		if next_scene: get_tree().change_scene_to_packed(next_scene)
		else:
			if OS.get_name() != "Web":
				get_tree().quit()
			else:
				get_tree().change_scene_to_file("res://demo/skeletons_track_change.tscn")
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			do_raycast()

func do_raycast():
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = camera_3d.project_ray_origin(mousepos)
	var end = origin + camera_3d.project_ray_normal(mousepos) * 400
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	if result and result.get("collider").name == "Area3D": 
		for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
			var x: float = (-square_rt * grid_size.x)/2.0 + (instance % square_rt * grid_size.y)
			@warning_ignore("integer_division")
			var y: float = (-square_rt * grid_size.x)/2.0 + (int(instance / square_rt) * grid_size.y)
	
			location.x = x
			location.z = y
			location.y = 0.1
			
			if demo_index == 0:
				if location.distance_to(result["position"]) < grid_size.y:
					vat_multi_mesh_instance_3d.update_instance_track(instance, 0)
			elif demo_index == 1:
				if location.distance_to(result["position"]) < grid_size.y * 3:
					vat_multi_mesh_instance_3d.update_instance_track(instance, 1)

func _on_shadows_check_button_toggled(toggled_on: bool) -> void:
	shadows_check_button.text = str(toggled_on).capitalize()
	directional_light_3d.shadow_enabled = toggled_on

func _on_v_sync_check_button_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)

func _on_demo_type_select_item_selected(index: int) -> void:
	demo_index = index
