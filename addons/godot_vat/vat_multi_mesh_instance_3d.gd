@tool
## Allows [MultiMeshInstance3D] vertex animation functionality.
##
## See tutorials for more information.
##
## @tutorial:             https://example.com/tutorial_1
extends MultiMeshInstance3D
class_name VATMultiMeshInstance3D

## Total number of instances in the multimesh.
@export var instance_count: int = 10

## Random animation offset on/off. [br]
## Recommend to keep this on.
@export var rand_anim_offset: bool = true

## Animation tracks: [br]
## x = start frame, y = end frame.[br]
## Use values from your Blender project.[br]
@export var animation_tracks: Array[Vector2i] = []

var custom_data: Color
var number_of_animation_tracks: int

func _enter_tree():
	pass
	
func _exit_tree():
	# Clean-up of the plugin goes here.
	pass

func _init() -> void:
	pass

func _get_configuration_warnings(): # display the warning on the scene dock
	var warnings = []
	if !multimesh:
		warnings.push_back('Multimesh not set')
	if animation_tracks.size() == 0:
		warnings.push_back('No animation tracks defined')
	return warnings
	
func _validate_property(property: Dictionary): # update the config warnings
	if property.name == "animation_tracks" or property.name == "multimesh":
		update_configuration_warnings()
	
func _ready() -> void:
	if multimesh:
		multimesh.instance_count = 0
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.instance_count = instance_count
	else:
		printerr("VATMultiMeshInstance3D: No multimesh defined")
		
	number_of_animation_tracks = animation_tracks.size()
	if number_of_animation_tracks == 0:
		printerr("VATMultiMeshInstance3D: You have not defined any animation tracks!")
	else:
		print("VATMultiMeshInstance3D: Number of animation tracks defined is: ", number_of_animation_tracks)

func _process(delta: float) -> void:
	pass

## Updates the current instance_id with the provided animation_offset (0..1),
## unless rand_anim_offset = false, where it sets the offset to 0
func update_instance_animation_offset(instance_id: int, animation_offset: float):
	custom_data = multimesh.get_instance_custom_data(instance_id)
	if rand_anim_offset:
		custom_data.r = animation_offset
	else:
		custom_data.r = 0.0
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Updates the current instance_id with the provided track_number (0..number_of_animation_tracks - 1)
func update_instance_track(instance_id: int, track_number: int):
	custom_data = multimesh.get_instance_custom_data(instance_id)
	custom_data.g = get_start_end_frames_from_track_number(track_number).x # start frame
	custom_data.b = get_start_end_frames_from_track_number(track_number).y # end frame
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Updates the current instance_id with the provided alpha (0..1)
func update_instance_alpha(instance_id: int, alpha: float):
	custom_data = multimesh.get_instance_custom_data(instance_id)
	custom_data.a = alpha
	multimesh.set_instance_custom_data(instance_id, custom_data)

## get animation start/end frames from track_number.
## track_number must be within (0..number_of_animation_tracks - 1)
func get_start_end_frames_from_track_number(track_number: int) -> Vector2i:
	return animation_tracks[track_number]
