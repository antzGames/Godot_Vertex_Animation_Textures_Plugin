extends VATInstancedDemo

var isFadeOut: bool = true
var ind: int = 0
var x: float = -30
var z: float = 0

func _process(delta: float) -> void:
	super._process(delta)
	
	timer += delta
	
	if timer > 1:
		timer = 0
		
		if isFadeOut: # fade out
			vat_multi_mesh_instance_3d.fade_out_instance(ind)
		else:
			vat_multi_mesh_instance_3d.fade_in_instance(ind)
		
		ind += 1
		
	# reset after all have faded out
	if ind >= vat_multi_mesh_instance_3d.instance_count:
		ind = 0
		isFadeOut = !isFadeOut

func setupInstances():
	var a: int = 0 # animation track number
	for instance in vat_multi_mesh_instance_3d.multimesh.instance_count:
		# randomize the animation offset
		vat_multi_mesh_instance_3d.update_instance_animation_offset(instance, randf())
		# sets the animation track number
		vat_multi_mesh_instance_3d.update_instance_track(instance, a)
		# set alpha to 1.0 -> you can fade out a specific instance by setting alpha to 0
		vat_multi_mesh_instance_3d.update_instance_alpha(instance, 1.0)
		# randomize scale, rotation, and location
		randomizeInstance(instance)
		
		# this cycles through each animation track number
		a += 1
		if a > vat_multi_mesh_instance_3d.number_of_animation_tracks - 1: a = 0
			
func randomizeInstance(i: int):
	if randomize_scale:
		node3D.scale = Vector3(randf_range(base_scale, max_scale), randf_range(base_scale, max_scale), randf_range(base_scale, max_scale))
	
	location.x = x
	location.z = z
	location.y = 0
	
	x += 10
	if x > 30:
		x = -30
		z += 10
	
	node3D.rotation.x = 0
	node3D.rotation.z = 0
	if randomize_rotation:
		node3D.rotate_y(randf_range(0, TAU))
		
	node3D.position = location
	vat_multi_mesh_instance_3d.multimesh.set_instance_transform(i, node3D.transform)
