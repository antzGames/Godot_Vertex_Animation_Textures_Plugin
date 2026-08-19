@tool
class_name VATAnimationTrack
extends Resource

## Name of Animation Track.[br]
## If empty, a track number is assigned automatically.
@export var name: String

## Start frame of animation track.[br]
## Must be between [0..8191].
@export_range(0, 8191) var startFrame: int

## End frame of animation track.[br]
## Must be between [0..8191].[br]
## Should be equal or greater than start frame.
@export_range(0, 8191) var endFrame: int

## Is the animation track only to be played once,[br]
## like a death animation, or does it loop?
@export var isLooping: bool = true

## Each animation track can have it own unique fps.[br]
## If set to 0, then it will be replaced by [member VATMultiMeshInstance3D.default_fps].
@export_range(0, 120) var framerate: int

## Is the animation track interpolated/blended, or stepped/constant?[br]
@export var isBlended: bool = true

## Is the animation track played in reverse? (UNUSED FOR NOW)
@export var isReversed: bool = false

func set_track(name_in: String, start_in: int, end_in: int, framerate_in: int, loop: bool, blend: bool, reversed: bool):
	name = name_in
	startFrame = start_in
	endFrame   = end_in
	framerate  = framerate_in
	isLooping  = loop
	isBlended  = blend
	isReversed = reversed
	
func _to_string() -> String:
	return str("Animation Track Name: ",name, "   startFrame: ", startFrame, "    endFrame: ", endFrame, "   framerate: ", framerate, "   isLooping: ", isLooping, "isReversed: ", isReversed)
