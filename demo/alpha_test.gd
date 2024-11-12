extends Node3D

@onready var vat_multi_mesh_instance_3d: VATMultiMeshInstance3D = $VATMultiMeshInstance3D

var node3D: Node3D = Node3D.new()
var location: Vector3 = Vector3.ZERO
var timer: float
var x: float = -40
var z: float = 10

func _ready() -> void:
	# setup all instances
	setupInstances()
		
func _process(delta: float) -> void:
	timer += delta
	for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
		if timer > instance: # start fading one instance every second
			if (1 - (timer-instance)) > 0.0: # fade
				vat_multi_mesh_instance_3d.update_instance_alpha(instance, (1 - (timer-instance)))
			else: # already faded
				vat_multi_mesh_instance_3d.update_instance_alpha(instance, 0.0)
	
	# reset after all have faded out
	if timer > vat_multi_mesh_instance_3d.multimesh.instance_count:
		x = -40
		z = 10
		timer = 0
		setupInstances()
		
func setupInstances():
	for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
		# randomize the animation offset
		vat_multi_mesh_instance_3d.update_instance_animation_offset(instance, randf())
		# randomize the animation track number
		vat_multi_mesh_instance_3d.update_instance_track(instance, randi_range(0, vat_multi_mesh_instance_3d.number_of_animation_tracks-1))
		# set alpha to 1.0 -> you can fade out a specific instance by setting alpha to 0
		vat_multi_mesh_instance_3d.update_instance_alpha(instance, 1.0)
		# randomize scale, rotation, and location
		randomizeInstance(instance)

func randomizeInstance(i: int):
	if randi() %2:
		node3D.scale = Vector3(1,1,1)
	else:
		node3D.scale = Vector3(2,2,1.5)
	
	location.x = x
	location.z = z
	location.y = 0
	
	x += 10
	if x > 40:
		x = - 40
		z += 10
	
	node3D.rotation.x = 0
	node3D.rotation.z = 0
	node3D.rotate_y(randf_range(0, TAU))
	node3D.position = location
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)
