class_name VATAnimationTrack
extends Resource

@export var name: String
@export_range(0, 8192) var startFrame: int
@export_range(0, 8192) var endFrame: int
@export var isLooping: bool = true
@export_range(0, 120) var framerate: int

func set_track(name_in: String, start_in: int, end_in: int, framerate_in: int, loop: bool):
	name = name_in
	startFrame = start_in
	endFrame = end_in
	framerate = framerate_in
	isLooping = loop
	
func _to_string() -> String:
	return str("Animation Track Name: ",name, "   startFrame: ", startFrame, "    endFrame: ", endFrame, "   framerate: ", framerate, "   isLooping: ", isLooping)
