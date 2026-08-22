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
## Use to desync the animation of many instances.
@export var rand_anim_offset: bool = false

## Default FPS: [br]
## Overwrites any [VATAnimationTrack] with framerate = 0 with this value.[br]
@export var default_fps: int = 30

## Animation tracks: [br]
## Use values from your Blender project.[br]
@export var vat_animation_tracks: Array[VATAnimationTrack] = []

var frames: int
var custom_data: Color
var custom_color: Color
var number_of_animation_tracks: int
var _rollover_value : float = ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs")

func _create_multimesh() -> void:
	multimesh = MultiMesh.new()
	multimesh.instance_count = 0
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true

func _enter_tree() -> void:
	pass
	
func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

func _init() -> void:
	pass

func _get_configuration_warnings() -> PackedStringArray: # display the warning on the scene dock
	var warnings = []
	if !multimesh:
		warnings.push_back('Multimesh not set')
	if vat_animation_tracks.size() == 0:
		warnings.push_back('No animation tracks defined')
	return warnings
	
func _validate_property(property: Dictionary) -> void: # update the config warnings
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
		return

	# Clean up empty VAT tracks
	var original_vat_tracks: Array[VATAnimationTrack] = vat_animation_tracks.duplicate()
	vat_animation_tracks.clear()

	for vat_track: VATAnimationTrack in original_vat_tracks:
		if vat_track: vat_animation_tracks.push_back(vat_track)
		
	number_of_animation_tracks = vat_animation_tracks.size()

	if number_of_animation_tracks == 0:
		printerr("VATMultiMeshInstance3D: You have not defined any animation tracks!")
	else:
		print_rich("\n[color=cyan]Beginning VAT animation configuration...")

		var i : int = 0
		for vat_anim: VATAnimationTrack in vat_animation_tracks:
			if vat_anim.framerate == 0: vat_anim.framerate = default_fps
			if !vat_anim.name or vat_anim.name.is_empty():
				vat_anim.name = str("Track", i)
			print_rich(str("  🎞️ Animation track: [color=yellow]", vat_anim.name, "[/color]   Start/End Frames: [color=yellow]", vat_anim.startFrame , "-", vat_anim.endFrame, "[/color]   isLooping: [color=yellow]", vat_anim.isLooping ,"[/color]   FPS: [color=yellow]", vat_anim.framerate,"[/color]"))
			i += 1

		print_rich("[color=cyan]Animation configuration completed.[/color]")
		
#region Texture Atlas Helper
	# TODO MAKE NOT CRUMMY / POLISH CODE, ITS SPREAD OUTEVERYWHERE BUT I GOTTA GET THIS DONE FOR PERFORMANCE TESTING ASAP
	_generate_texture_atlas()
	match RenderingServer.get_current_rendering_method():
		"forward_plus","mobile":
			atlas_manager = ComputeAtlasManager.new()
			atlas_manager.atlas_texture = atlas_texture
			atlas_manager.atlas_image = atlas_image
		"gl_compatibility":
			atlas_manager = TextureAtlasManager.new()
			atlas_manager.atlas_texture = atlas_texture
			atlas_manager.atlas_image = atlas_image

	add_child(atlas_manager)
	# This will crash during the brick test one, but thats cause exported_mesh isn't in there?
	var material: ShaderMaterial = exported_mesh.surface_get_material(0)
	
	# TODO READ ME IN THE SHADER!
	# NOTE - THE SHADER I ASSUME IS A GLOBAL SHADER SO WHEN THE PREVIOUS OUTPUT SHADER TEXTURE IS FREED IT CAUSES AN ERROR. WILL NEED TO FIX IT SOON BUT ITS HARMLESS FOR NOW
	material.set_shader_parameter("atlas_texture", atlas_manager.output_shader_texture)
	material.set_shader_parameter("cell_size_x", CELL_SIZE_X)
	material.set_shader_parameter("cells_per_row", CELLS_PER_ROW)
	material.set_shader_parameter("max_width", MAX_WIDTH)

# -- Member Variables --
var atlas_manager: AtlasManager
var atlas_image: Image
var atlas_texture: ImageTexture

const MAX_WIDTH = 4096
const CELL_SIZE_X = 8
const CELLS_PER_ROW = MAX_WIDTH / CELL_SIZE_X

# TODO - CREATE DEFAULT TRACK WHEN SPAWNING @EXPORT VAR
func _generate_texture_atlas() -> void:
	# -- Setup Atlas Dimensions --
	var num_rows = ceil(float(instance_count) / CELLS_PER_ROW)
	var atlas_width = min(instance_count, CELLS_PER_ROW) * CELL_SIZE_X
	atlas_image = Image.create(atlas_width, num_rows, false, Image.FORMAT_R8)
	
	# -- Populate Atlas --
	var default_track = vat_animation_tracks[0]
	for i in instance_count:
		var row = i / CELLS_PER_ROW
		var col = i % CELLS_PER_ROW
		var x = col * CELL_SIZE_X
		var y = row
		
		# -- Start Frame Bytes 0-2 --
		var start_frame = default_track.startFrame
		atlas_image.set_pixel(x + 0, y, Color8(start_frame & 0xFF, 0, 0))
		atlas_image.set_pixel(x + 1, y, Color8((start_frame >> 8) & 0xFF, 0, 0))
		atlas_image.set_pixel(x + 2, y, Color8((start_frame >> 16) & 0xFF, 0, 0))
		
		# -- End Frame Bytes 3-5 --
		var end_frame = default_track.endFrame
		atlas_image.set_pixel(x + 3, y, Color8(end_frame & 0xFF, 0, 0))
		atlas_image.set_pixel(x + 4, y, Color8((end_frame >> 8) & 0xFF, 0, 0))
		atlas_image.set_pixel(x + 5, y, Color8((end_frame >> 16) & 0xFF, 0, 0))
		
		# -- Framerate Byte 6 --
		atlas_image.set_pixel(x + 6, y, Color8(default_track.framerate, 0, 0))
		
		# -- Blended Byte 7 --
		atlas_image.set_pixel(x + 7, y, Color8(int(default_track.isBlended), 0, 0))
	
	# -- Create Texture From Image --
	atlas_texture = ImageTexture.create_from_image(atlas_image)

func _generate_instance_track_update(index: int, track: VATAnimationTrack) -> Array[Variant]:
	var row: int = index / CELLS_PER_ROW
	var col: int = index % CELLS_PER_ROW
	var x: int = col * CELL_SIZE_X
	var y: int = row
	
	var pixels: Array[Variant] = []
	
	# -- Start Frame Bytes 0-2 --
	var start_frame: int = track.startFrame
	pixels.append(x + 0)
	pixels.append(y)
	pixels.append(start_frame & 0xFF)
	
	pixels.append(x + 1)
	pixels.append(y)
	pixels.append((start_frame >> 8) & 0xFF)
	
	pixels.append(x + 2)
	pixels.append(y)
	pixels.append((start_frame >> 16) & 0xFF)
	
	# -- End Frame Bytes 3-5 --
	var end_frame: int = track.endFrame
	pixels.append(x + 3)
	pixels.append(y)
	pixels.append(end_frame & 0xFF)
	
	pixels.append(x + 4)
	pixels.append(y)
	pixels.append((end_frame >> 8) & 0xFF)
	
	pixels.append(x + 5)
	pixels.append(y)
	pixels.append((end_frame >> 16) & 0xFF)
	
	# -- Framerate Byte 6 --
	pixels.append(x + 6)
	pixels.append(y)
	pixels.append(track.framerate)
	
	# -- Blended Byte 7 --
	pixels.append(x + 7)
	pixels.append(y)
	pixels.append(int(track.isBlended))
	
	return pixels

func _get_atlas_base_coord(instance_index: int) -> Vector2i:
	var row: int = instance_index / CELLS_PER_ROW
	var col: int = instance_index % CELLS_PER_ROW
	var x: int = col * CELL_SIZE_X
	var y: int = row
	return Vector2i(x, y)

#endregion

#region instanced helper functions

## Updates the current instance_id with the provided animation_offset (0..1),
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_instance_animation_offset(instance_id: int, animation_offset: float) -> void:
	animation_offset = clamp(animation_offset, 0.0, 1.0)
	custom_data = multimesh.get_instance_custom_data(instance_id)
	if rand_anim_offset:
		custom_data.r = animation_offset
	else:
		custom_data.r = 0.0
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Updates the current instance_id with the provided track_number (0..animation_tracks.size()- 1)
func update_instance_track(instance_id: int, track_number: int) -> void:
	if track_number < 0 or track_number > vat_animation_tracks.size() - 1: 
		printerr("[VATMultiMeshInstance3D] -> update_instance_track(instance_id: int, track_number: int)]: track_number is out of bounds.")
		return 
	#custom_data = multimesh.get_instance_custom_data(instance_id)
	#custom_data.g = vat_animation_tracks[track_number].startFrame 
	#custom_data.b = vat_animation_tracks[track_number].endFrame
	#multimesh.set_instance_custom_data(instance_id, custom_data)
		
	reset_one_shot(instance_id)
	
	## TODO GET RID OF PREVIOUS SHADER STUFF, ALSO MAKE MORE READABLE THIS IS CRAP
	atlas_manager.update_texture_with_commands(_generate_instance_track_update(instance_id, vat_animation_tracks[track_number]))

## Updates the current instance_id with the provided alpha (0..1)
func update_instance_alpha(instance_id: int, alpha: float) -> void:
	alpha = clampf(alpha, 0.0, 1.0)
	custom_data = multimesh.get_instance_custom_data(instance_id)
	custom_data.a = alpha
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Update the instance_id with the provided animation_offset, track_number, and alpha
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_instance(instance_id: int, animation_offset: float, track_number: int, alpha: float) -> void:
	update_instance_animation_offset(instance_id, animation_offset)
	update_instance_track(instance_id, track_number)
	update_instance_alpha(instance_id, alpha)

## Update ALL INSTANCES with the provided animation_offset, track_number, and alpha
## unless rand_anim_offset = false, where it sets the animation_offset to 0
func update_all_instances(animation_offset: float, track_number: int, alpha: float) -> void: # TODO THESE ARENT SETTING IT RIGHT :(
	var batch_atlas_update_array: Array[Variant] = []
	for instance in multimesh.instance_count:
		update_instance_animation_offset(instance, animation_offset)
		#update_instance_track(instance, track_number)
		batch_atlas_update_array += _generate_instance_track_update(instance, vat_animation_tracks[track_number])
		update_instance_alpha(instance, alpha)
	atlas_manager.update_texture_with_commands(batch_atlas_update_array)

# Tweens

## Fade out a specific instance.[br][br]
## [param instance_id] is the specific instance to fade.[br]
## [param fade_out_time] the duration of the fade.[br]
## [param start_delay] is the delay before fade starts.
func fade_out_instance(instance_id: int, fade_out_time: float = 1.0, start_delay: float = 0.0) -> void:
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
func fade_in_instance(instance_id: int, fade_in_time: float = 1.0, start_delay: float = 0.0) -> void:
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

func _do_tween_fade(value: float, instance_id: int) -> void:
	var custom_data: Color = multimesh.get_instance_custom_data(instance_id)
	custom_data.a = value
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Sink a specific instance.[br][br]
## [param instance_id] is the specific instance to sink down.[br]
## [param y_amount] the amount to move the instance in the y-axis (negative value will float up)[br]
## [param fade_out_time] the duration of the fade.[br]
## [param start_delay] is the delay before fade starts.
func sink_instance(instance_id: int, y_amount: float, fade_out_time: float = 1.0, start_delay: float = 0.0) -> void:
	if fade_out_time < 0: return
	if instance_id >= multimesh.instance_count: return

	var fade_tween = create_tween()
	fade_tween.tween_method(
		_do_tween_sink.bind(instance_id),
		multimesh.get_instance_transform(instance_id).origin.y,
		multimesh.get_instance_transform(instance_id).origin.y - y_amount,
		fade_out_time).set_delay(start_delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func _do_tween_sink(value: float, instance_id: int) -> void:
	var trans: Transform3D
	trans = multimesh.get_instance_transform(instance_id)
	trans.origin.y = value
	multimesh.set_instance_transform(instance_id, trans)
	
# Play next track

## Plays the next animation track for the provided instance_id
func play_next_track_instance(instance_id: int) -> void:
	var track_number: int = get_track_number_from_instance(instance_id)
	track_number += 1
	if track_number > vat_animation_tracks.size() - 1: track_number = 0
	update_instance_track(instance_id, track_number)
	
## Plays the next animation track for ALL INSTANCES
func play_next_track_all_instances() -> void:
	var track_number : int
	for instance in multimesh.instance_count:
		track_number = get_track_number_from_instance(instance)
		track_number += 1
		if track_number > vat_animation_tracks.size() - 1: track_number = 0
		update_instance_track(instance, track_number)

# Get functions

func _read_u24_from_image(image: Image, x: int, y: int) -> int:
	var byte0: int = int(image.get_pixel(x, y).r * 255.0)
	var byte1: int = int(image.get_pixel(x + 1, y).r * 255.0)
	var byte2: int = int(image.get_pixel(x + 2, y).r * 255.0)
	return byte0 | (byte1 << 8) | (byte2 << 16)

func _get_track_data_from_atlas(instance_id: int) -> Dictionary:
	var base_coord: Vector2i = _get_atlas_base_coord(instance_id)
	var image_data: Image = atlas_manager.output_shader_texture.get_image()
	
	var start_frame: int = _read_u24_from_image(image_data, base_coord.x, base_coord.y)
	var end_frame: int = _read_u24_from_image(image_data, base_coord.x + 3, base_coord.y)
	var framerate: int = int(image_data.get_pixel(base_coord.x + 6, base_coord.y).r * 255.0)
	var is_blended: int = int(image_data.get_pixel(base_coord.x + 7, base_coord.y).r * 255.0)
	
	return {
		"start_frame": start_frame,
		"end_frame": end_frame,
		"framerate": framerate,
		"is_blended": bool(is_blended)
	}

## get [VATAnimationTrack] from instance.
## instance must have been initialized. 
## Returns null if instance_id not found
func get_animation_from_instance(instance_id: int) -> VATAnimationTrack:
	var base_coord: Vector2i = _get_atlas_base_coord(instance_id)
	var image_data: Image = atlas_manager.output_shader_texture.get_image()
	
	var start_frame: int = _read_u24_from_image(image_data, base_coord.x, base_coord.y)
	var end_frame: int = _read_u24_from_image(image_data, base_coord.x + 3, base_coord.y)
	#return {
	#	"start_frame": start_frame,
	#	"end_frame": end_frame,
	#	"framerate": framerate,
	#	"is_blended": bool(is_blended)
	#}
	#custom_data = multimesh.get_instance_custom_data(instance_id)
	
	for track: VATAnimationTrack in vat_animation_tracks:
		if is_equal_approx(start_frame, float(track.startFrame)) and is_equal_approx(end_frame, float(track.endFrame)):
			return track
			
	return null

## get track_number using an animation object to search animation_tracks.
## Returns -1 if not found or animation object is null.
func get_track_number_from_animation(animation: VATAnimationTrack) -> int:
	if !animation: return -1
	for i in range(vat_animation_tracks.size()):
		if animation == vat_animation_tracks[i]: return i
	
	return -1

## get track_number from animation track name
## Returns -1 if not found.
func get_track_number_from_name(name: String) -> int:
	for i in range(vat_animation_tracks.size()):
		if vat_animation_tracks[i].name.to_lower() == name.to_lower():
			return i
	
	return -1
	
## get track_number from start/end frames.[br]
## However [get_track_number_from_animation] is a better option.
## Returns -1 if not found.
func get_track_number_from_start_end_frames(start: int, end: int) -> int:
	for i in range(vat_animation_tracks.size()):
		if Vector2i(start,end) == Vector2i(vat_animation_tracks[i].startFrame, vat_animation_tracks[i].endFrame): return i
	
	return -1

## get current track_number from instance_id
## Returns -1 if not found.
func get_track_number_from_instance(instance_id: int) -> int:
	return get_track_number_from_animation(get_animation_from_instance(instance_id))

func get_current_timestamp() -> float:
	return fmod((float(Time.get_ticks_msec()) / 1000.0), _rollover_value) - 0.5
#endregion

#region theHoodaloo Custom Code

## Restarts the one shot animation for a specific instance_id.[br][br]
## Only valid if instanced animation track  [is_looping] is true
func reset_one_shot(instance_id: int):
	custom_color = multimesh.get_instance_color(instance_id)
	
	var track: VATAnimationTrack = get_animation_from_instance(instance_id)
	
	custom_color.r = _encode_color_channel_red(track)
	custom_color.g = get_current_timestamp()
	
	multimesh.set_instance_color(instance_id, custom_color)

## Generates a float that represents isLooping, isBlended, isReversed, and framerate to be encoded into custom_color.r [br]
func _encode_color_channel_red(track: VATAnimationTrack) -> float:
	var toggle_array: Array[int] = []
	toggle_array.append(1 if track.isLooping  else 0)
	toggle_array.append(1 if track.isBlended  else 0)
	toggle_array.append(1 if track.isReversed else 0)
	
	var framerate: int = clamp(track.framerate, 0, 999)
	var framerate_length: int = len(str(abs(framerate)))
	
	var zeros_to_add: int = 3 - framerate_length
	for i in range(zeros_to_add): # TODO: Make Integer Padding Helper Function
		toggle_array.append(0)
	toggle_array.append(track.framerate) # 0-999FPS
	
	return _encode_float_from_digits(toggle_array)

## Encodes a float from array of integers: [br]
## Example: [1,0,9,0,0,2] = 0.109002 [br]
## Example: [10,900,2]    = 0.109002 [br]
## NOTE: Integer values discard the 0 when in front of the value! Plese pad values instead: [br]
## Example: [10,9,002]   = 0.1092      ❌ [br]
## Example: [10,9,0,0,2] = 0.109002 ✅ [br]
func _encode_float_from_digits(float_digits: Array[int]) -> float:
	var result:           float = 0.0
	var decimal_position: int   = 1
	
	for value: int in float_digits:
		var digit_count: int   = len(str(value)) if value > 0 else 1
		var exponent:    float = -float(decimal_position + digit_count - 1)
		
		result += float(value) * pow(10.0, exponent)
		decimal_position += digit_count
	
	return result

## Sets start and end frame while keeping current track parameters
func set_section(instance_id: int, start_frame: int, end_frame: int,) -> void:
	custom_data   = multimesh.get_instance_custom_data(instance_id)
	custom_data.r = 0.0
	custom_data.g = start_frame
	custom_data.b = end_frame
	multimesh.set_instance_custom_data(instance_id, custom_data)
	
	custom_color   = multimesh.get_instance_color(instance_id)
	custom_color.g = get_current_timestamp()
	multimesh.set_instance_color(instance_id, custom_color)
	
@export_tool_button("Import VATAnimationTrack(s) from JSON File", "File") var import_vat_animation_track = _import_vat_animation_track
func _import_vat_animation_track() -> void:
	if !Engine.is_editor_hint(): return
	
	var dialog: EditorFileDialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.json ; JSON Files"]
	
	dialog.file_selected.connect(func(path: String) -> void:
		var json_as_text: String = FileAccess.open(path, FileAccess.READ).get_as_text()
		var json_as_array: Array = JSON.parse_string(json_as_text)
		
		var vat_animation_track_new: Array[VATAnimationTrack] = []
		for track: Dictionary in json_as_array:
			var vat_animation_track: VATAnimationTrack = VATAnimationTrack.new()
			vat_animation_track.name       = track.get("name", "Animation")
			vat_animation_track.startFrame = track.get("startFrame", 0)
			vat_animation_track.endFrame   = track.get("endFrame",   0)
			vat_animation_track.isLooping  = track.get("isLooping", true)
			vat_animation_track.isBlended  = track.get("isBlended", true)
			vat_animation_track.framerate  = track.get("framerate", 0.0)
			vat_animation_track_new.append(vat_animation_track)
			
		vat_animation_tracks = vat_animation_track_new
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	
	get_tree().root.add_child(dialog)
	dialog.popup_centered_ratio(0.70)

## Updates the current instance_id with the provided frame number
## Frame number is in VAT scope
## Animation offset will be reset to 0
func freeze_frame(instance_id: int, frame: int) -> void:
	custom_data = multimesh.get_instance_custom_data(instance_id)
	
	frame = clampi(frame, 0, 8192)
	custom_data.r = 0.0
	custom_data.g = frame
	custom_data.b = frame
	multimesh.set_instance_custom_data(instance_id, custom_data)

## Identical to shader
func _extractDigitGroup(value: float, groupIndex: int, digitCount: int) -> int:
	var exp: float = pow(10.0, float(digitCount))
	return int(fmod(value * exp * pow(10.0, float(groupIndex * digitCount)),exp))

## Get current frame from instance_id (0...last_frame - first_frame)
func get_current_frame_from_instance(instance_id: int, relative_to_all_tracks: bool = false) -> int:
	var color_data: Color = multimesh.get_instance_color(instance_id)
	var frame_data: Color = multimesh.get_instance_custom_data(instance_id)
	
	var start_time:   float = color_data.g
	var current_time: float = get_current_timestamp()
	var elapsed_time: float = current_time - start_time
	
	var first_frame:  float = frame_data.g
	var last_frame:   float = frame_data.b
	var frame_count:  float = last_frame - first_frame + 1.0
	
	var framerate:    float = _extractDigitGroup(color_data.r, 1, 3);
	var time_scale:   float = elapsed_time * (framerate / (frame_count + 0.0001))
	var is_looping:   float = _extractDigitGroup(color_data.r, 0, 1)
	var blend_amount: float = _extractDigitGroup(color_data.r, 1, 1)
	
	var frame_time:         float = lerp(time_scale, fmod(time_scale, 1.0), is_looping)
	var frame_progress:     float = frame_time * frame_count + frame_data.r
	var frame_progress_mod: float = fmod(frame_progress, frame_count)
	
	var stop_frame:    float = first_frame + floor(frame_progress)
	var loop_frame:    float = first_frame + lerp(frame_progress + 1.0, frame_progress_mod + 1.0, is_looping)
	var current_frame: float = ceil(lerp(stop_frame, loop_frame, blend_amount))
	
	var result: float = lerp(
		clamp(current_frame, first_frame, last_frame),
		fmod(current_frame - first_frame, frame_count) + first_frame,
		is_looping
	)
	
	if !relative_to_all_tracks:
		result -= first_frame
	
	return int(result)
#endregion
