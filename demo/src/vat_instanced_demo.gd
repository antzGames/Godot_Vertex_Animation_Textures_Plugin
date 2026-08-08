class_name VATInstancedDemo
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

@export_category("Instance Rotation")
@export var randomize_rotation: bool

@export_category("Instance Scale")
@export var randomize_scale: bool
@export var base_scale: float = 1.0
@export var max_scale: float = 1.5

@export_category("Instance Animation")
@export var cycle_animations: bool = false
@export var cycle_all_instances: bool = true
@export_range(0.01, 10, 0.01) var cycle_time: float = 3
var anim_timer: float

@export_category("Camera")
@export var rotate_camera: bool
@export_range(0.5, 5, 0.1) var camera_speed: float = 1.0
@export var camera_position: Vector3 = Vector3(0,20,55)
@export var camera_lookat: Vector3 = Vector3(0,0,0)

var node3D: Node3D = Node3D.new()
var location: Vector3 = Vector3.ZERO
var timer: float
var counter: int

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v_sync_check_button.button_pressed else DisplayServer.VSYNC_DISABLED)
	if OS.get_name() == "Web": v_sync_check_button.disabled = true
	instance_count.text = str(vat_multi_mesh_instance_3d.multimesh.instance_count)
	title_label.text = title
	camera_3d.global_position = camera_position
	camera_3d.look_at(camera_lookat)
	
	# setup all instances
	setupInstances()
		
func setupInstances():
	# change floor size based on instance count
	var s: float = sqrt(vat_multi_mesh_instance_3d.multimesh.instance_count) * 5
	mesh_floor.mesh.size = Vector2(s,s) 
	
	var count: int = 0 # animation track number
	for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
		# randomize the animation offset
		vat_multi_mesh_instance_3d.update_instance_animation_offset(instance, randf())
		# set the animation track number
		vat_multi_mesh_instance_3d.update_instance_track(instance, count)
		# set alpha to 1.0 -> you can fade out a specific instance by setting alpha to 0
		vat_multi_mesh_instance_3d.update_instance_alpha(instance, 1.0)
		
		# OR you can just use one call:
		#vat_multi_mesh_instance_3d.update_instance(instance, randf(), count, 1.0)
		
		# randomize scale, rotation, and location
		randomizeInstance(instance)
		
		#func get_track_number_from_instance(instance_id: int) -> int:
		#func get_animation_from_instance(instance_id: int) -> OpenVATAnimationTrack:
		#func get_track_number_from_animation(animation: OpenVATAnimationTrack) -> int:
		#func get_track_number_from_start_end_frames(start: int, end: int) -> int:
			
		# Unit tests for helper functions - you can comment this out
		#if instance < 50:
			#var track: OpenVATAnimationTrack = vat_multi_mesh_instance_3d.get_animation_from_instance(instance)
			#var tn: int = vat_multi_mesh_instance_3d.get_track_number_from_instance(instance)
			#var tn_anim: int = vat_multi_mesh_instance_3d.get_track_number_from_animation(track)
			#var tn_se: int = vat_multi_mesh_instance_3d.get_track_number_from_start_end_frames(track.startFrame, track.endFrame)
			#
			## Print the test results
			#print(track, " >>> Tests: ",
				## is the assigned animation object correct                     Are all three track_number methods the same?
				#track == vat_multi_mesh_instance_3d.animation_tracks[tn], " ", bool(tn == tn_anim and tn == tn_se))
			#
		
		# this cycles through each animation track number
		count += 1
		if count > vat_multi_mesh_instance_3d.animation_tracks.size() - 1:
			count = 0
		
func randomizeInstance(i: int):
	var x = mesh_floor.mesh.size.x / 2
	var y = mesh_floor.mesh.size.y / 2
	
	node3D.scale = Vector3(base_scale,base_scale,base_scale)
	
	if randomize_scale:
		node3D.scale = Vector3(randf_range(base_scale, max_scale),randf_range(base_scale, max_scale),randf_range(base_scale, max_scale))
		
	location.x = randf_range(-x,x)
	location.z = randf_range(-y,y)
	location.y = 0
	
	if randomize_rotation:
		node3D.rotation.y = randf_range(0,TAU)
	
	node3D.position = location
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)

func _process(delta: float) -> void:
	if rotate_camera:
		pivot.rotate_y(delta * 0.1 * camera_speed)
	
	if cycle_animations:
		anim_timer += delta
		counter += 1
		if counter > vat_multi_mesh_instance_3d.instance_count -1: counter = 0
		
		if cycle_all_instances and anim_timer > cycle_time: 
			anim_timer = 0
			vat_multi_mesh_instance_3d.play_next_track_all_instances()
		elif anim_timer > cycle_time: 
			anim_timer = 0
			vat_multi_mesh_instance_3d.play_next_track_instance(counter)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("next_scene"):
		if next_scene: get_tree().change_scene_to_packed(next_scene)
		else:
			if OS.get_name() != "Web":
				get_tree().quit()
			else:
				get_tree().change_scene_to_file("res://demo/skeletons_track_change.tscn")

func _on_shadows_check_button_toggled(toggled_on: bool) -> void:
	shadows_check_button.text = str(toggled_on).capitalize()
	directional_light_3d.shadow_enabled = toggled_on

func _on_v_sync_check_button_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)
