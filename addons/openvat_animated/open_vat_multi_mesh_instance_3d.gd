@tool
extends MultiMeshInstance3D
class_name OpenVATMultiMeshInstance3D
## Allows [MultiMeshInstance3D] vertex animation functionality that is OpenVAT compatible.

## Total number of instances in the multimesh.
@export var instance_count: int = 10

## Random animation offset on/off. [br]
## Recommend to keep this on.
@export var rand_anim_offset: bool = true

## OpenVAT auto and manual configuration
@export_category("OpenVAT Config")
@export_file("*.json") var openvat_json_config_file: String
@export_tool_button("Import JSON") var import_json_action = import_json

@export var min_values: Vector3
@export var max_values: Vector3
var frames: int

func import_json():
	if !openvat_json_config_file or openvat_json_config_file.length() == 0:
		printerr("No JSON file set. Select the OpenVAT JSON file.")
		return

	var file = FileAccess.open(openvat_json_config_file, FileAccess.READ)
	var content = file.get_as_text()

	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		var data_received = json.data
		print_rich("OpenVAT JSON file: [color=yellow]" + openvat_json_config_file + "[/color] contents: ")
		print_rich(str("[color=green]"), data_received, "[/color]")
		var j = JSON.parse_string(content)
		var os_remap = j["os-remap"]
		
		# Min/Max vectors
		var min_array = os_remap["Min"]
		min_values.x = float(min_array[0])
		min_values.y = float(min_array[1])
		min_values.z = float(min_array[2])
		print_rich(str("Minimum values parsed: [color=yellow]",min_values,"[/color]"))
		
		var max_array = os_remap["Max"]
		max_values.x = float(max_array[0])
		max_values.y = float(max_array[1])
		max_values.z = float(max_array[2])
		print_rich(str("Maximum values parsed: [color=yellow]",max_values,"[/color]"))
		
		# animation
		var anim_dict = j["animations"]
		if anim_dict.is_empty():
			printerr("No animation meta data found.  You will need to manually enter Animation Tracks.")
		else:
			# Loop threw animation dictionary
			for key in anim_dict:
				pass
		
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())


## Animation tracks: [br]
## x = start frame, y = end frame.[br]
## Import them if OpenVAT JSON config has track information[br]
## or you can set them manually.
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
		#multimesh.use_colors = true
		multimesh.instance_count = instance_count
	else:
		printerr("OpenVATMultiMeshInstance3D: No multimesh defined")
		
	number_of_animation_tracks = animation_tracks.size()
	if number_of_animation_tracks == 0:
		printerr("OpenVATMultiMeshInstance3D: You have not defined any animation tracks!")
	else:
		print("OpenVATMultiMeshInstance3D: Number of animation tracks defined is: ", number_of_animation_tracks)

func _process(delta: float) -> void:
	pass

# Set/Update functions

## Update ALL INSTANCES with the provided animation_offset, track_number, and alpha
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_all_instances(animation_offset: float, track_number: int, alpha: float):
	for instance in multimesh.instance_count:
		update_instance_animation_offset(instance, animation_offset)
		update_instance_track(instance, track_number)
		update_instance_alpha(instance, alpha)

## Updates the current instance_id with the provided animation_offset (0..1),
## unless rand_anim_offset = false, where it sets the animation_offset to 0
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


# Get functions

## get animation start/end frames from track_number.
## track_number must be within (0..number_of_animation_tracks - 1)
func get_start_end_frames_from_track_number(track_number: int) -> Vector2i:
	return animation_tracks[track_number]

## get animation start/end frames from instance.
## instance must have been initialized. 
func get_start_end_frames_from_instance(instance_id: int) -> Vector2i:
	var vec2: Vector2i
	custom_data = multimesh.get_instance_custom_data(instance_id)
	vec2.x = custom_data.g # start frame
	vec2.y = custom_data.b # end frame
	return vec2

## get track_number from start/end frame Vector2i.
## Returns -1 if not found.
func get_track_number_from_track_vector(track_vector: Vector2i) -> int:
	for i in range(animation_tracks.size()):
		if track_vector == animation_tracks[i]: return i
	
	return -1

## get track_number from instance_id
## Returns -1 if not found.
func get_track_number_from_instance(instance_id: int) -> int:
	return get_track_number_from_track_vector(get_start_end_frames_from_instance(instance_id))
