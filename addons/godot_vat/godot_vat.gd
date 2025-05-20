@tool
extends EditorPlugin

func _ready() -> void:
	ResourceSaver.save(preload("res://addons/godot_vat/vat_multi_mesh_instance_3d.gd"))

func _enter_tree() -> void:
	add_custom_type("VATMultiMeshInstance3D", "MultiMeshInstance3D", preload("vat_multi_mesh_instance_3d.gd"), preload("VATMultiMeshInstance3D.svg"))


func _exit_tree() -> void:
	remove_custom_type("VATMultiMeshInstance3D")
