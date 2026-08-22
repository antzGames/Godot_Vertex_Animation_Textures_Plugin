class_name AtlasManager extends Node

# -- Texture Initialization --
@onready var atlas_image:   Image
@onready var atlas_texture: Texture2D

@onready var output_shader_texture: Texture2D

@export var max_commands_per_physics_frame: int = 1000

func update_texture_with_commands(commands: PackedInt32Array) -> void:
	pass

func _exit_tree() -> void: ## TODO GET RID OF ME WHEN DONE DEBUG TESTING!
	atlas_image.save_png("res://test_atlas.png")
