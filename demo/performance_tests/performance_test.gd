extends Node3D

@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

@onready var vat_multi_mesh_instance_3d: VATMultiMeshInstance3D = $VATMultiMeshInstance3D
@onready var mesh_floor: MeshInstance3D = $Floor
@onready var pivot: Node3D = $Pivot

@onready var instance_count: Label = $UI/MarginContainer/VBox/HBoxCount/InstanceCount
@onready var shadows_check_button: CheckButton = $UI/MarginContainer/VBox/HBoxShadows/ShadowsCheckButton

var node3D: Node3D = Node3D.new()
var location: Vector3 = Vector3.ZERO

func _ready() -> void:
	instance_count.text = str(vat_multi_mesh_instance_3d.multimesh.instance_count)
	# setup all instances
	setupInstances()
		
func setupInstances():
	# change floor size based on instance count
	var s: float = sqrt(vat_multi_mesh_instance_3d.multimesh.instance_count) * 5
	mesh_floor.mesh.size = Vector2(s,s) 
	
	var a: int = 0 # animation track number
	for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
		# randomize the animation offset
		vat_multi_mesh_instance_3d.update_instance_animation_offset(instance, randf())
		# set the animation track number
		vat_multi_mesh_instance_3d.update_instance_track(instance, a)
		# set alpha to 1.0 -> you can fade out a specific instance by setting alpha to 0
		vat_multi_mesh_instance_3d.update_instance_alpha(instance, 1.0)
		# randomize scale, rotation, and location
		randomizeInstance(instance)
		
		# Unit tests for helper functions - you can comment this out
		#print("Instance: ", instance, "   Track: ", vat_multi_mesh_instance_3d.get_track_number_from_instance(instance), \
			#"   Frame Start/End:", vat_multi_mesh_instance_3d.get_start_end_frames_from_instance(instance), \
			#"   Test Vector2i: ", vat_multi_mesh_instance_3d.get_start_end_frames_from_track_number(a) == vat_multi_mesh_instance_3d.get_start_end_frames_from_instance(instance), \
			#"   Test Track: ", vat_multi_mesh_instance_3d.get_track_number_from_track_vector(vat_multi_mesh_instance_3d.get_start_end_frames_from_track_number(a)) == vat_multi_mesh_instance_3d.get_track_number_from_instance(instance))

		# this cycles threw each animation track number
		a += 1
		if a > vat_multi_mesh_instance_3d.number_of_animation_tracks - 1:
			a = 0
		
func randomizeInstance(i: int):
	var x = mesh_floor.mesh.size.x / 2
	var y = mesh_floor.mesh.size.y / 2
	
	if randi() %2:
		node3D.scale = Vector3(1,1,1)
	else:
		node3D.scale = Vector3(2,2,1.5)
		
	location.x = randf_range(-x,x)
	location.z = randf_range(-y,y)
	location.y = 0
	
	node3D.rotation = Vector3.ZERO
	node3D.position = location
	
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)

func _process(delta: float) -> void:
	pivot.rotate_y(delta * 0.1)

func _on_shadows_check_button_toggled(toggled_on: bool) -> void:
	shadows_check_button.text = str(toggled_on).capitalize()
	directional_light_3d.shadow_enabled = toggled_on
