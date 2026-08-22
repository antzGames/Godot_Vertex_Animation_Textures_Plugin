class_name TextureAtlasManager extends AtlasManager
## This Is A Performance Test For Direct Pixel Writing To An Atlas. [br]
## Made By theHoodaloo, MIT Licensed!

# -- Configuration --
@export_range(0,1) var write_version: int = 0

# -- Cached Data --
var image_data: PackedByteArray = PackedByteArray()
var commands: PackedInt32Array = PackedInt32Array()

# -- Frametime Tracking --
var total_elapsed: int = 0
var frame_count: int = 0

func _ready() -> void:
	image_data = atlas_image.get_data()
	output_shader_texture = atlas_texture

## TODO ONCE MORE PERFORMANT VER IS DECIDED GET RID OF THIS
func update_texture_with_commands(commands: PackedInt32Array) -> void:
	match write_version:
		0:
			_version_direct_pixel_write(commands)
		1:
			_version_bit_packed_buffer(commands)

func _version_direct_pixel_write(updates: PackedInt32Array) -> void:
	# -- Approach A: Direct Pixel Write --
	var width_cache: int = atlas_image.get_width()
	
	for command: int in updates:
		# -- Unpack Command Bits --
		var value: int = command & 0xFF
		var x: int = (command >> 8) & 0xFFF
		var y: int = (command >> 20) & 0xFFF
		# -- Write Pixel Directly --
		atlas_image.set_pixel(x, y, Color8(value, 0, 0, 255))
	
	# -- Batch Upload To GPU --
	atlas_texture.update(atlas_image)

func _version_bit_packed_buffer(updates: PackedInt32Array) -> void:
	# -- Approach B: Bit Packed Buffer --
	var start: int = Time.get_ticks_usec()
	var width_cache: int = atlas_image.get_width()
	
	# -- Write To Buffer --
	for command: int in updates:
		# -- Unpack Command Bits --
		var value: int = command & 0xFF
		var x: int = (command >> 8) & 0xFFF
		var y: int = (command >> 20) & 0xFFF
		# -- Write To 1D Array --
		image_data[y * width_cache + x] = value
	
	# -- Sync Buffer To Image --
	atlas_image.set_data(atlas_image.get_width(), atlas_image.get_height(), false, Image.FORMAT_R8, image_data)
	# -- Batch Upload To GPU --
	atlas_texture.update(atlas_image)
	
	var elapsed: int = Time.get_ticks_usec() - start
	
	# -- Track Average --
	total_elapsed += elapsed
	frame_count += 1
	var avg: float = float(total_elapsed) / float(frame_count) / 1000.0
	print("Frame: %.2f ms | Average: %.2f ms" % [elapsed / 1000.0, avg])
	
	# -- Reset Every 60 Frames --
	if frame_count >= 60:
		total_elapsed = 0
		frame_count = 0
