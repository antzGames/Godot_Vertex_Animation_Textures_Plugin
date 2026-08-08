class_name VATAnimationTrack
extends RefCounted

var name: String
var startFrame: int
var endFrame: int
var framerate: int
var isLooping: bool

func set_track(name_in: String, start_in: int, end_in: int, framerate_in: int, loop: bool):
	name = name_in
	startFrame = start_in
	endFrame = end_in
	framerate = framerate_in
	isLooping = loop
	
func _to_string() -> String:
	return str("Animation Track Name: ",name, "   startFrame: ", startFrame, "    endFrame: ", endFrame, "   framerate: ", framerate, "   isLooping: ", isLooping)
