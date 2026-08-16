/*
VAT Shader - Antz

INSTANCE_CUSTOM is used to display a unique animation per instance.
It has total of 4 floats. All renderers supported

	Red channel:
		animation offset: used to randomize instances playing the same animation track

	Green channel:
		animation start frame

	Blue channel:
		animation end frame

	Alpha channel:
		alpha of mesh: used to fade in/out a unique instance

		
Instanced COLOR is used for interpolation, looping / non-looping (also called one_shot) animations.
It has total of 4 floats. All renderers supported.

	Red channel:
		use_looping: 1.0 = true, 0.0 = false

	Green channel:
		timestamp:
			if looping - when the looping animation started.
			if non-lopping - Tells the shader when the one_shot has been reset.

	Blue channel: 
		animation frame rate - must be greater than 0
	
	Alpha channel:
		use_blended: 1.0 = true, 0.0 = false
		Animation track blend/interpolation, suggested by: @theHoodaloo
*/

shader_type spatial;
render_mode blend_mix,depth_draw_always,depth_prepass_alpha,cull_disabled; // change if needed

uniform sampler2D offset_map: filter_nearest;
uniform sampler2D normal_map: filter_nearest;

group_uniforms Albedo;
uniform vec4 albedo : source_color = vec4(1.0); // Opaque white by default
uniform sampler2D albedo_texture : source_color;
group_uniforms;

group_uniforms Metallic;
uniform sampler2D metallic_texture : hint_default_white;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec4 metallic_texture_channel: source_color = vec4(1.0, 0.0, 0.0, 0.0); // Red channel by default
uniform float specular : hint_range(0.0, 1.0) = 0.5;
group_uniforms;

group_uniforms Roughness;
uniform sampler2D roughness_texture : hint_roughness_r;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform vec4 roughness_texture_channel : source_color = vec4(1.0, 0.0, 0.0, 0.0); // Red channel by default
group_uniforms;

group_uniforms NormalMap;
uniform sampler2D normal_map_texture : hint_roughness_normal;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;
group_uniforms;

varying flat vec4 custom_data;
varying flat vec4 color_data;

void vertex(){
	custom_data = INSTANCE_CUSTOM;
	color_data = COLOR;

	float use_looping = color_data.r;
	float use_blended = color_data.a; // Suggested by: @theHoodaloo
	float timestamp = color_data.g;
	
	float start_frame = custom_data.g;
	float end_frame = custom_data.b;
	float num_frames = end_frame - start_frame;
	int frame_count = int(end_frame - start_frame);  // for % mod used later
	
	float frame_offset = num_frames * custom_data.r;
	float speed = max(1, color_data.b);

	// if start_frame and end_frame are the same - prevents divide by zero
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
		float(int(ceil_frame - start_frame) % frame_count) + start_frame,
		use_looping
	);
		
	ivec2 tex_size = textureSize(offset_map, 0);
	float pixel_size = 1.0 / float(tex_size.y);

	float frame_floor = clamp(floor(current_frame), start_frame, end_frame);
	vec2 frame_floor_uv_offset = vec2(0.0, -((frame_floor + 0.5) * pixel_size));
	vec2 frame_ceil_uv_offset = vec2(0.0, -((frame_ceil + 0.5) * pixel_size));

	float lerp_factor = current_frame - frame_floor;

	// Calculate vertex position
	vec3 offset_floor = texture(offset_map, UV2 + frame_floor_uv_offset).xyz;
	vec3 offset_ceil = texture(offset_map, UV2 + frame_ceil_uv_offset).xyz;
	vec3 offset_lerp = mix(offset_floor, offset_ceil, lerp_factor);
	vec3 new_offset = vec3(offset_lerp.x, offset_lerp.z, offset_lerp.y);
	VERTEX += new_offset;

	// Calculate normal
	vec3 normal_floor = texture(normal_map, UV2 + frame_floor_uv_offset).xyz;
	vec3 normal_ceil = texture(normal_map, UV2 + frame_ceil_uv_offset).xyz;
	vec3 normal_lerp = mix(normal_floor, normal_ceil, lerp_factor);
	vec3 new_normal = vec3((normal_lerp.x * 2.0) - 1.0, (normal_lerp.z * 2.0) - 1.0, (normal_lerp.y * 2.0) - 1.0);
	NORMAL = new_normal;
	
	//// Recomputes TANGENT & BIPLANAR based on the updated NORMAL (taken from the Godot source)
	TANGENT = normalize(vec3(abs(NORMAL.y) + abs(NORMAL.z), 0.0, -abs(NORMAL.x)));
	BINORMAL = normalize(vec3(0.0, abs(NORMAL.x) + abs(NORMAL.z), -abs(NORMAL.y)));
}

void fragment() {
	ALBEDO = albedo.rgb * texture(albedo_texture, UV).rgb;
	METALLIC = dot(texture(metallic_texture, UV), metallic_texture_channel) * metallic;
	SPECULAR = specular;
	ROUGHNESS = dot(texture(roughness_texture, UV), roughness_texture_channel) * roughness;
	NORMAL_MAP = texture(normal_map_texture, UV).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	ALPHA = custom_data.a;  // fader
}
