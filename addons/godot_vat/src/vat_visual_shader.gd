# Visual Shader version of vat_multiple_anims.gdshader
# Allows for more advanced visuals while still being VAT-compatible.
#
# Instructions:
# - Inside Vertex mode, create an AdvancedVATSource node.
# - Use the vertex, normal, tangent, and binormal outputs as the basis for the vertex shader.
#
# Now you can also freely apply your own shader logic while still having VAT animations.
# Albedo textures can still be used like the original shader, just use the Fragment mode like normal.

@tool
extends VisualShaderNodeCustom
class_name VisualShaderVATNode

func _get_name() -> String:
	return "VATSource"

func _get_category() -> String:
	return "VAT"

func _get_description() -> String:
	return "Input source for VAT properties, including tangent and binormal."

func _get_return_icon_type() -> PortType:
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_input_port_count() -> int:
	return 0

func _get_output_port_count() -> int:
	return 4

func _get_output_port_name(port: int) -> String:
	match port:
		0: return "vat_vertex"
		1: return "vat_normal"
		2: return "vat_tangent"
		3: return "vat_binormal"
	return ""

func _get_output_port_type(port: int) -> PortType:
	match port:
		0: return PORT_TYPE_VECTOR_3D
		1: return PORT_TYPE_VECTOR_3D
		2: return PORT_TYPE_VECTOR_3D
		3: return PORT_TYPE_VECTOR_3D
	return PORT_TYPE_VECTOR_3D

func _get_global_code(mode: Shader.Mode) -> String:
	return """
	group_uniforms VAT;
	uniform sampler2D offset_map;
	uniform sampler2D normal_map;
	group_uniforms;
	"""

func _get_code(input_vars: Array[String], output_vars: Array[String], mode: Shader.Mode, type: VisualShader.Type) -> String:
	return """
	float use_looping = mod(floor(COLOR.r * 10.0 + 0.5), 10.0);
	float use_blended = mod(floor(COLOR.r * 100.0 + 0.5), 10.0);
	float is_reversed = mod(floor(COLOR.r * 1000.0 + 0.5), 10.0);
	
	float timestamp = COLOR.g;
	
	float start_frame = INSTANCE_CUSTOM.g;
	float end_frame = INSTANCE_CUSTOM.b;
	float num_frames = end_frame - start_frame;
	int frame_count = int(end_frame - start_frame);  
	
	float frame_offset = num_frames * INSTANCE_CUSTOM.r;

	float speed = max(1, COLOR.b);

	num_frames = clamp(num_frames, 0.0001, 8192.0);

	float time_scale_normalized = (TIME - timestamp) * (speed / num_frames);
	
	float loop_time  = mod(time_scale_normalized, 1.0);
	float frame_time = mix(time_scale_normalized, loop_time, use_looping);

	float frame_progress        = frame_time * num_frames;
	float frame_progress_offset = frame_progress + frame_offset;
		
	float stop_frame = start_frame + floor(frame_progress);

	float blend_frame = start_frame + mix(
		frame_progress_offset + 1.0,
		mod(frame_progress_offset, num_frames) + 1.0,
		use_looping
	);
		
	float current_frame_raw = mix(stop_frame, blend_frame, use_blended);
	float ceil_frame        = ceil(current_frame_raw);

	float current_frame = mix(
		clamp(current_frame_raw, start_frame, end_frame),
		mix(current_frame_raw, start_frame, step(end_frame, current_frame_raw)),
		use_looping
	);

	float frame_ceil = mix(
		clamp(ceil_frame, start_frame, end_frame),
		float(int(ceil_frame - start_frame) %% frame_count) + start_frame,
		use_looping
	);
		
	ivec2 tex_size = textureSize(offset_map, 0);
	float pixel_size = 1.0 / float(tex_size.y);

	float frame_floor = clamp(floor(current_frame), start_frame, end_frame);
	vec2 frame_floor_uv_offset = vec2(0.0, -((frame_floor + 0.5) * pixel_size));
	vec2 frame_ceil_uv_offset = vec2(0.0, -((frame_ceil + 0.5) * pixel_size));

	float lerp_factor = current_frame - frame_floor;

	vec3 offset_floor = texture(offset_map, UV2 + frame_floor_uv_offset).xyz;
	vec3 offset_ceil = texture(offset_map, UV2 + frame_ceil_uv_offset).xyz;
	vec3 offset_lerp = mix(offset_floor, offset_ceil, lerp_factor);
	vec3 new_offset = vec3(offset_lerp.x, offset_lerp.z, offset_lerp.y);
	
	%s = VERTEX + new_offset;

	vec3 normal_floor = texture(normal_map, UV2 + frame_floor_uv_offset).xyz;
	vec3 normal_ceil = texture(normal_map, UV2 + frame_ceil_uv_offset).xyz;
	vec3 normal_lerp = mix(normal_floor, normal_ceil, lerp_factor);
	vec3 new_normal = vec3((normal_lerp.x * 2.0) - 1.0, (normal_lerp.z * 2.0) - 1.0, (normal_lerp.y * 2.0) - 1.0);
	
	%s = new_normal;

	%s = normalize(vec3(abs(new_normal.y) + abs(new_normal.z), 0.0, -abs(new_normal.x)));
	%s = normalize(vec3(0.0, abs(new_normal.x) + abs(new_normal.z), -abs(new_normal.y)));
	""" % [output_vars[0], output_vars[1], output_vars[2], output_vars[3]]
