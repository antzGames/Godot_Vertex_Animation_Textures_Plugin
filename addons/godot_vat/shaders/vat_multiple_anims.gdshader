shader_type spatial;
render_mode blend_mix,depth_draw_always,depth_prepass_alpha,cull_back,diffuse_burley,specular_schlick_ggx;

//depth_draw_opaque

uniform sampler2D offset_map;
uniform sampler2D normal_map;
uniform sampler2D texture_albedo;

uniform float fps = 24.0; // change this to what the fps is in Blender

uniform float specular : hint_range(0,1);
uniform float metallic : hint_range(0,1);
uniform float roughness : hint_range(0,1);

varying flat vec4 custom_data;

void vertex(){
	custom_data = INSTANCE_CUSTOM;

	// frame
	float start_frame = custom_data.g;
	float end_frame = custom_data.b;
	float num_frames = end_frame - start_frame;
	
	// time
	float time_scale_normalized = fps / num_frames;
	float time = mod(TIME * time_scale_normalized, 1.0);

	float frame_offset = num_frames * custom_data.r;
	float current_frame = start_frame + mod((time * num_frames) + frame_offset, num_frames);

	ivec2 tex_size = textureSize(offset_map, 0);

	float pixel_size = 1.0 / float(tex_size.y);
	float frame_floor = clamp(floor(current_frame), start_frame, end_frame);
	float frame_ceil = clamp(ceil(current_frame), start_frame, end_frame);

	vec2 frame_floor_uv_offset = vec2(0.0, -((frame_floor + 0.5) * pixel_size));
	vec2 frame_ceil_uv_offset = vec2(0.0, -((frame_ceil + 0.5) * pixel_size));

	float lerp_factor = current_frame - frame_floor;

	vec3 offset_floor = texture(offset_map, UV2 + frame_floor_uv_offset).xyz;
	vec3 offset_ceil = texture(offset_map, UV2 + frame_ceil_uv_offset).xyz;
	vec3 offset_lerp = mix(offset_floor, offset_ceil, lerp_factor);
	vec3 new_offset = vec3(offset_lerp.x, offset_lerp.z, offset_lerp.y);

	VERTEX += new_offset;

	vec3 normal_floor = texture(normal_map, UV2 + frame_floor_uv_offset).xyz;
	vec3 normal_ceil = texture(normal_map, UV2 + frame_ceil_uv_offset).xyz;
	vec3 normal_lerp = mix(normal_floor, normal_ceil, lerp_factor);
	vec3 new_normal = vec3((normal_lerp.x * 2.0) - 1.0, (normal_lerp.z * 2.0) - 1.0, (normal_lerp.y * 2.0) - 1.0);

	NORMAL = new_normal;
}

void fragment(){
	vec3 albedo_col = texture(texture_albedo, UV).rgb;

	ALPHA = custom_data.a;  // fader
	ALBEDO = albedo_col.rgb;

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
