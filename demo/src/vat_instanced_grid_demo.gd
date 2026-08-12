class_name VATInstancedGridDemo
extends Node3D

@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

@onready var vat_multi_mesh_instance_3d: VATMultiMeshInstance3D = $VATMultiMeshInstance3D
@onready var mesh_floor: MeshInstance3D = $Floor
@onready var pivot: Node3D = $Pivot
@onready var camera_3d: Camera3D = $Pivot/Camera3D

@onready var title_label: Label = $UI/Title
@onready var instance_count: Label = $UI/MarginContainer/VBox/HBoxCount/InstanceCount
@onready var shadows_check_button: CheckButton = $UI/MarginContainer/VBox/HBoxShadows/ShadowsCheckButton
@onready var v_sync_check_button: CheckButton = $UI/MarginContainer/VBox/HBoxShadows2/VSyncCheckButton

@export var title: String
@export var next_scene: PackedScene
@export_enum("Explosion", "Wave", "Random") var demo_type: String = "Explosion"

@export_category("Camera")
@export var rotate_camera: bool
@export_range(0.5, 5, 0.1) var camera_speed: float = 1.0
@export var camera_position: Vector3 = Vector3(0,20,55)
@export var camera_lookat: Vector3 = Vector3(0,0,0)

@export_category("Grid")
@export var grid_size: Vector2 = Vector2(1,1)

var node3D: Node3D = Node3D.new()
var location: Vector3 = Vector3.ZERO
var counter: int
var square_rt: int
var count: int = 0 # animation track number

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v_sync_check_button.button_pressed else DisplayServer.VSYNC_DISABLED)
	if OS.get_name() == "Web": v_sync_check_button.disabled = true
	instance_count.text = str(vat_multi_mesh_instance_3d.multimesh.instance_count)
	title_label.text = title
	camera_3d.global_position = camera_position
	camera_3d.look_at(camera_lookat)
	_on_demo_type_select_item_selected(0) # 0 = Explosion

func _process(delta: float) -> void:
	if rotate_camera:
		pivot.rotate_y(delta * 0.1 * camera_speed)

func setupInstances() -> void:
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
	location.y = randf_range(0.1,0.2) # prevent z-fighting between tiles
	
	# different demo behaviors
	if demo_type.to_lower() == "explosion":
		vat_multi_mesh_instance_3d.update_instance_track(i, 0)
		vat_multi_mesh_instance_3d.update_instance_animation_offset(i, cos(location.distance_to(Vector3.ZERO)/(square_rt * grid_size.y))) 
	elif demo_type.to_lower() == "wave":
		vat_multi_mesh_instance_3d.update_instance_track(i, 0)
		vat_multi_mesh_instance_3d.update_instance_animation_offset(i, float((i % square_rt)) * 0.5 / float(square_rt)) 
	elif demo_type.to_lower() == "random":
		vat_multi_mesh_instance_3d.update_instance_track(i, count)
		vat_multi_mesh_instance_3d.update_instance_animation_offset(i, randf())
		count += 1
		if count > vat_multi_mesh_instance_3d.number_of_animation_tracks - 1:
			count = 0
	
	node3D.rotation.y = randi_range(0,3) * (PI/2)
	node3D.position = location
	
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_scene"):
		if next_scene: get_tree().change_scene_to_packed(next_scene)

func _on_shadows_check_button_toggled(toggled_on: bool) -> void:
	shadows_check_button.text = str(toggled_on).capitalize()
	directional_light_3d.shadow_enabled = toggled_on

func _on_v_sync_check_button_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)

func _on_demo_type_select_item_selected(index: int) -> void:
	match index:
		0: demo_type = "Explosion"
		1: demo_type = "Wave"
		2: demo_type = "Random"
	setupInstances()
