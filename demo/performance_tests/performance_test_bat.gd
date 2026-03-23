extends Node3D

@onready var vat_multi_mesh_instance_3d: VATMultiMeshInstance3D = $VATMultiMeshInstance3D
@onready var pivot: Node3D = $Pivot

var node3D: Node3D = Node3D.new()
var location: Vector3 = Vector3.ZERO

func _ready() -> void:
	# setup all instances
	setupInstances()
		
func setupInstances():
	
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
	
	var rand: float = randf_range(1, 1.15)
	node3D.scale = Vector3(rand,rand,rand)

	location.x = randf_range(-50, 50)
	location.z = randf_range(-50, 50)
	location.y = 0
	
	node3D.rotation.y = randf_range(0,TAU)
	node3D.position = location
	
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)

func _process(delta: float) -> void:
	pivot.rotate_y(delta * 0.1)
