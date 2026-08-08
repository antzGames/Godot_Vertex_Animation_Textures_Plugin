class_name VATInstancedTrackChangeDemo
extends VATInstancedDemo

@onready var track_select: OptionButton = $UI/MarginContainer/VBox/HBoxTrack/TrackSelect
@onready var repeat: Button = $UI/MarginContainer/VBox/HBoxTrack/Repeat

func _ready() -> void:
	super._ready()
	mesh_floor.mesh.size = Vector2(200,200) 
	
	for track in vat_multi_mesh_instance_3d.vat_animation_tracks:
		track_select.add_item(str(track.name,"   FPS:", track.framerate, "   isLooping:", track.isLooping))
		
	_on_track_select_item_selected(0)

func _on_track_select_item_selected(index: int) -> void:
	vat_multi_mesh_instance_3d.update_all_instances(0, index, 1)
	if vat_multi_mesh_instance_3d.vat_animation_tracks[index].isLooping:
		repeat.visible = false
	else:
		repeat.visible = true

func _on_repeat_pressed() -> void:
	_on_track_select_item_selected(track_select.selected)
