@tool
extends EditorPlugin

func _ready() -> void:
	ResourceSaver.save(preload("res://addons/openvat_animated/open_vat_multi_mesh_instance_3d.gd"))

func _enter_tree() -> void:
	add_custom_type("OpenMultiMeshInstance3D", "MultiMeshInstance3D", preload("open_vat_multi_mesh_instance_3d.gd"), preload("OpenVATMultiMeshInstance3D.svg"))


func _exit_tree() -> void:
	remove_custom_type("OpenVATMultiMeshInstance3D")
