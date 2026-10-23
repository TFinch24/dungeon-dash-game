# ============================================================
#  DUNGEON DASH
#  Script:       room.gd
#  Developers:   Timothy Finch, Tucker Stark
#  Engine:       Godot 4.7 (GDScript)
#  Last updated: October 23, 2026
#
#  Description:
#  Shared script for all room scenes. Stores which sides of
#  the room have doorways so the generator can match rooms
#  to their neighbors. Set the flags in the Inspector.
# ============================================================
class_name Room

extends Node3D

const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8

# Tick the sides that have doorways.
# Bit values: North = 1, East = 2, South = 4, West = 8
# Compass: -Z is North, +X is East, +Z is South, -X is West
@export_flags("North", "East", "South", "West") var doors := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


	# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Rotation - 
# North door → moves to West
# West door → moves to South
# South door → moves to East
# East door → moves to North
# Returns the door mask after turning the room 90 degrees, quarter_turns times
static func rotate_mask(mask: int, quarter_turns: int) -> int:
	for i in range(quarter_turns):
		var new_mask := 0
		# Check each side. If it has a door
		# Then once it turns 90 degrees the door will be on the new side
		if mask & NORTH:
			new_mask = new_mask | WEST
		if mask & WEST:
			new_mask = new_mask | SOUTH
		if mask & SOUTH:
			new_mask = new_mask | EAST
		if mask & EAST:
			new_mask = new_mask | NORTH
		mask = new_mask
	return mask
