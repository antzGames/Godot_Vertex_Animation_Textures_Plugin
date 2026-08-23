class_name ComputeAtlasManager extends AtlasManager

# -- Render Device --
var render_device: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var uniform_set: RID

# -- Texture --
var texture_rid: RID
var texture_format: RDTextureFormat

# -- Buffers --
var update_buffer: RID
var count_buffer: RID
var update_buffer_data: PackedByteArray
var count_data: PackedByteArray

# -- Cached Data --
var commands_packed: PackedInt32Array

# -- Constants --
const SHADER_PATH: String = "res://addons/compute-atlas-manager/compute_atlas_1024.glsl" ## TODO - USE DIFFERENT WORKER FOR DIFFERENT RESOLUTION
const COMMAND_STRUCT_SIZE: int = 12
const COMMAND_COMPONENTS: int = 3

func _ready() -> void:
	render_device = RenderingServer.get_rendering_device()
	
	# -- Shader Setup --
	var shader_file: RDShaderFile = load(SHADER_PATH) ## TODO PRELOAD
	shader_rid = render_device.shader_create_from_spirv(shader_file.get_spirv())
	pipeline_rid = render_device.compute_pipeline_create(shader_rid)
	
	# -- Texture Setup --
	texture_format = RDTextureFormat.new()
	texture_format.width = atlas_texture.get_width()
	texture_format.height = atlas_texture.get_height()
	texture_format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT |
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)
	
	var image: Image = atlas_texture.get_image()
	image.convert(Image.FORMAT_R8)
	texture_rid = render_device.texture_create(texture_format, RDTextureView.new(), [image.get_data()])
	
	# -- Buffer Setup --
	update_buffer_data = PackedByteArray()
	update_buffer_data.resize(max_commands_per_physics_frame * COMMAND_STRUCT_SIZE)
	update_buffer = render_device.storage_buffer_create(update_buffer_data.size(), update_buffer_data)
	
	count_data = PackedByteArray()
	count_data.resize(4)
	count_data.encode_u32(0, 0)
	count_buffer = render_device.storage_buffer_create(count_data.size(), count_data)
	
	# -- Uniform Set --
	var tex_uniform: RDUniform = RDUniform.new()
	tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	tex_uniform.binding = 0
	tex_uniform.add_id(texture_rid)
	
	var update_uniform: RDUniform = RDUniform.new()
	update_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	update_uniform.binding = 1
	update_uniform.add_id(update_buffer)
	
	var count_uniform: RDUniform = RDUniform.new()
	count_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	count_uniform.binding = 2
	count_uniform.add_id(count_buffer)
	
	uniform_set = render_device.uniform_set_create([tex_uniform, update_uniform, count_uniform], shader_rid, 0)
	
	# -- Apply Texture to Mesh --
	var texture_2d_rd: Texture2DRD = Texture2DRD.new()
	texture_2d_rd.texture_rd_rid = texture_rid
	
	output_shader_texture = texture_2d_rd
	
	commands_packed = PackedInt32Array()

func update_texture_with_commands(commands: PackedInt32Array) -> void:
	var command_count: int = commands.size() / COMMAND_COMPONENTS
	
	if command_count == 0: return
	
	if command_count > max_commands_per_physics_frame:
		push_error("Command count %d exceeds max %d" % [command_count, max_commands_per_physics_frame])
		return
	
	# -- Encode Commands --
	var offset: int = 0
	for i in range(0, commands.size(), COMMAND_COMPONENTS):
		update_buffer_data.encode_u32(offset + 0, commands[i])
		update_buffer_data.encode_u32(offset + 4, commands[i + 1])
		update_buffer_data.encode_u32(offset + 8, commands[i + 2])
		offset += COMMAND_STRUCT_SIZE
	
	# -- Upload Buffers --
	var data_size: int = command_count * COMMAND_STRUCT_SIZE
	render_device.buffer_update(update_buffer, 0, data_size, update_buffer_data)
	count_data.encode_u32(0, command_count)
	render_device.buffer_update(count_buffer, 0, 4, count_data)
	
	# -- Dispatch Compute --
	var workgroups_x: int = (command_count + 1023) / 1024 ## TODO - USE DIFFERENT WORKER FOR DIFFERENT RESOLUTION
	var compute_list: int = render_device.compute_list_begin()
	render_device.compute_list_bind_compute_pipeline(compute_list, pipeline_rid)
	render_device.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	render_device.compute_list_dispatch(compute_list, workgroups_x, 1, 1)
	render_device.compute_list_end()

## Free Compute Shader RIDs
func _exit_tree() -> void:
	render_device.free_rid(shader_rid)
	#render_device.free_rid(pipeline_rid) AUTOMATICALLY FREED
	#render_device.free_rid(uniform_set)  AUTOMATICALLY FREED
	render_device.free_rid(texture_rid)
	render_device.free_rid(update_buffer)
	render_device.free_rid(count_buffer)
