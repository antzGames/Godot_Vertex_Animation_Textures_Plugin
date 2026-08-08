@tool
extends MultiMeshInstance3D
class_name VATMultiMeshInstance3D
## Allows [MultiMeshInstance3D] vertex animation functionality.
##
## See tutorials for more information.
##
## @tutorial: https://github.com/antzGames/Godot_Vertex_Animation_Textures_Plugin

## Exported [Mesh] from Blender, with [ShaderMaterial] set in surface_0
@export var exported_mesh: ArrayMesh:
	set(value):
		exported_mesh = value
		if !multimesh:
			_create_multimesh()
		multimesh.mesh = exported_mesh

## Total number of instances in the multimesh.
@export var instance_count: int = 10

## Random animation offset on/off. [br]
## Recommend to keep this on.
@export var rand_anim_offset: bool = true

@export var default_fps: int = 30

## Animation tracks: [br]
## x = start frame, y = end frame, z = isLooping = 1, !isLooping = 0, w = fps [br]
## Use xy values from your Blender project.[br]
@export var animation_tracks: Array[Vector4i] = []
var vat_animation_tracks: Array[VATAnimationTrack] = []

var frames: int
var custom_data: Color
var custom_color: Color
var number_of_animation_tracks: int
var _rollover_value : float = ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs")


func _create_multimesh():
	multimesh = MultiMesh.new()
	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true

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
	if property.name.begins_with("multimesh"):
		property.usage = PROPERTY_USAGE_NO_EDITOR
	
func _ready() -> void:
	if multimesh:
		multimesh.instance_count = 0
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true # offsets, start/end frame, alpha
		multimesh.use_colors = true # isLooping, timestamp
		multimesh.instance_count = instance_count
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # becasue Godot interpolates custom_data, which we do not want
	else:
		printerr("VATMultiMeshInstance3D: No multimesh defined")
		
	number_of_animation_tracks = animation_tracks.size()

	if number_of_animation_tracks == 0:
		printerr("VATMultiMeshInstance3D: You have not defined any animation tracks!")
	else:
		print_rich("\n[color=cyan]Beginning VAT animation configuration...")

		var track_offset: int = 0
		if animation_tracks[0].x == 1:
			track_offset = 1
			print_rich(str("✅First animation track starts at: [color=yellow]1[/color]"))
			print_rich(str("✅Offset to 1 - All tracks start/end frames reduced by 1."))
		else:
			print_rich(str("✅First animation track starts at: [color=yellow]0[/color]"))
			print_rich(str("✅No offest needed!"))

		# create vat_animation_track array
		for i in number_of_animation_tracks:
			var vat_anim: VATAnimationTrack = VATAnimationTrack.new()
			var fps: int
			var isLooping: bool
			
			if animation_tracks[i].w == 0: fps = default_fps
			else: fps = animation_tracks[i].w
			
			if animation_tracks[i].z == 0: isLooping = false
			else: isLooping = true
			
			vat_anim.set_track(str("track", i), animation_tracks[i].x - track_offset, animation_tracks[i].y - track_offset, fps, isLooping)
			vat_animation_tracks.append(vat_anim)
			print_rich(str("  🎞️Animation track: [color=yellow]", vat_anim.name, "[/color]   isLooping: [color=yellow]", vat_anim.isLooping ,"[/color]   Start/End Frames: [color=yellow]", vat_anim.startFrame , "-", vat_anim.endFrame, "[/color]    FPS: [color=yellow]", vat_anim.framerate,"[/color]"))

		print_rich("[color=cyan]Animation configuration completed.[/color]")
		

func _process(delta: float) -> void:
	pass

#region instanced helper functions

## Updates the current instance_id with the provided animation_offset (0..1),
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_instance_animation_offset(instance_id: int, animation_offset: float):
	animation_offset = clamp(animation_offset, 0.0, 1.0)
	custom_data = multimesh.get_instance_custom_data(instance_id)
	if rand_anim_offset:
		custom_data.r = animation_offset
	else:
		custom_data.r = 0.0
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Updates the current instance_id with the provided track_number (0..animation_tracks.size()- 1)
func update_instance_track(instance_id: int, track_number: int):
	if track_number < 0 or track_number > animation_tracks.size() - 1: 
		printerr("[OpenVATMultiMeshInstance3D] -> update_instance_track(instance_id: int, track_number: int)]: track_number is out of bounds.")
		return 
	custom_data = multimesh.get_instance_custom_data(instance_id)
	custom_data.g = vat_animation_tracks[track_number].startFrame 
	custom_data.b = vat_animation_tracks[track_number].endFrame
	multimesh.set_instance_custom_data(instance_id, custom_data)
		
	reset_one_shot(instance_id)

## Updates the current instance_id with the provided alpha (0..1)
func update_instance_alpha(instance_id: int, alpha: float):
	alpha = clampf(alpha, 0.0, 1.0)
	custom_data = multimesh.get_instance_custom_data(instance_id)
	custom_data.a = alpha
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Update the instance_id with the provided animation_offset, track_number, and alpha
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_instance(instance_id: int, animation_offset: float, track_number: int, alpha: float):
	update_instance_animation_offset(instance_id, animation_offset)
	update_instance_track(instance_id, track_number)
	update_instance_alpha(instance_id, alpha)

## Update ALL INSTANCES with the provided animation_offset, track_number, and alpha
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_all_instances(animation_offset: float, track_number: int, alpha: float):
	for instance in multimesh.instance_count:
		update_instance_animation_offset(instance, animation_offset)
		update_instance_track(instance, track_number)
		update_instance_alpha(instance, alpha)

# Tweens

## Fade out a specific instance.[br][br]
## [param instance_id] is the specific instance to fade.[br]
## [param fade_out_time] the duration of the fade.[br]
## [param start_delay] is the delay before fade starts.
func fade_out_instance(instance_id: int, fade_out_time: float = 1.0, start_delay: float = 0.0):
	if fade_out_time < 0: return
	if instance_id >= multimesh.instance_count: return
	
	var custom_data: Color = multimesh.get_instance_custom_data(instance_id)
	if custom_data.a < 0: return
	
	var fade_tween = create_tween()
	fade_tween.tween_method(
		_do_tween_fade.bind(instance_id),
		multimesh.get_instance_custom_data(instance_id).a,
		0,
		fade_out_time).set_delay(start_delay)

## Fade in a specific instance.[br][br]
## [param instance_id] is the specific instance to fade in.[br]
## [param fade_out_time] the duration of the fade.[br]
## [param start_delay] is the delay before fade starts.
func fade_in_instance(instance_id: int, fade_in_time: float = 1.0, start_delay: float = 0.0):
	if fade_in_time < 0: return
	if instance_id >= multimesh.instance_count: return

	var custom_data: Color = multimesh.get_instance_custom_data(instance_id)
	if custom_data.a >= 1: return
	
	var fade_tween = create_tween()
	fade_tween.tween_method(
		_do_tween_fade.bind(instance_id),
		multimesh.get_instance_custom_data(instance_id).a,
		1,
		fade_in_time).set_delay(start_delay)

func _do_tween_fade(value: float, instance_id: int):
	var custom_data: Color = multimesh.get_instance_custom_data(instance_id)
	custom_data.a = value
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Sink a specific instance.[br][br]
## [param instance_id] is the specific instance to sink down.[br]
## [param y_amount] the amount to move the instance in the y-axis (negative value will float up)[br]
## [param fade_out_time] the duration of the fade.[br]
## [param start_delay] is the delay before fade starts.
func sink_instance(instance_id: int, y_amount: float, fade_out_time: float = 1.0, start_delay: float = 0.0):
	if fade_out_time < 0: return
	if instance_id >= multimesh.instance_count: return

	var fade_tween = create_tween()
	fade_tween.tween_method(
		_do_tween_sink.bind(instance_id),
		multimesh.get_instance_transform(instance_id).origin.y,
		multimesh.get_instance_transform(instance_id).origin.y - y_amount,
		fade_out_time).set_delay(start_delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func _do_tween_sink(value: float, instance_id: int):
	var trans: Transform3D
	trans = multimesh.get_instance_transform(instance_id)
	trans.origin.y = value
	multimesh.set_instance_transform(instance_id, trans)
	
# Play next track

## Plays the next animation track for the provided instance_id
func play_next_track_instance(instance_id: int):
	var track_number: int = get_track_number_from_instance(instance_id)
	track_number += 1
	if track_number > animation_tracks.size() - 1: track_number = 0
	update_instance_track(instance_id, track_number)
	
## Plays the next animation track for ALL INSTANCES
func play_next_track_all_instances():
	var track_number : int
	for instance in multimesh.instance_count:
		track_number = get_track_number_from_instance(instance)
		track_number += 1
		if track_number > animation_tracks.size() - 1: track_number = 0
		update_instance_track(instance, track_number)

# Get functions

## get [animationOpenVATAnimationTrack] from instance.
## instance must have been initialized. 
## Returns null if instance_id not found
func get_animation_from_instance(instance_id: int) -> VATAnimationTrack:
	custom_data = multimesh.get_instance_custom_data(instance_id)
	
	for track: VATAnimationTrack in vat_animation_tracks:
		if is_equal_approx(custom_data.g, float(track.startFrame)) and is_equal_approx(custom_data.b, float(track.endFrame)):
			return track
			
	return null

## get track_number using an animation object to search animation_tracks.
## Returns -1 if not found or animation object is null.
func get_track_number_from_animation(animation: VATAnimationTrack) -> int:
	if !animation: return -1
	for i in range(animation_tracks.size()):
		if animation == vat_animation_tracks[i]: return i
	
	return -1

## get track_number from animation track name
## Returns -1 if not found.
func get_track_number_from_name(name: String) -> int:
	for i in range(animation_tracks.size()):
		if vat_animation_tracks[i].name.to_lower() == name.to_lower():
			return i
	
	return -1
	
## get track_number from start/end frames.[br]
## However [get_track_number_from_animation] is a better option.
## Returns -1 if not found.
func get_track_number_from_start_end_frames(start: int, end: int) -> int:
	for i in range(animation_tracks.size()):
		if Vector2i(start,end) == Vector2i(vat_animation_tracks[i].startFrame, vat_animation_tracks[i].endFrame): return i
	
	return -1

## get current track_number from instance_id
## Returns -1 if not found.
func get_track_number_from_instance(instance_id: int) -> int:
	return get_track_number_from_animation(get_animation_from_instance(instance_id))

## Restarts the one shot animation for a specific instance_id.[br][br]
## Only valid if instanced animation track  [is_looping] is true
func reset_one_shot(instance_id: int):
	custom_color = multimesh.get_instance_color(instance_id)
	
	var anim: VATAnimationTrack = get_animation_from_instance(instance_id)
	
	if anim.isLooping:
		custom_color.r = 1.0
	else:
		custom_color.r = 0.0
	
	custom_color.g = get_current_timestamp()
	custom_color.b = anim.framerate
	
	multimesh.set_instance_color(instance_id, custom_color)

func get_current_timestamp() -> float:
	return fmod((float(Time.get_ticks_msec()) / 1000.0), _rollover_value) - 0.5
	
#endregion
