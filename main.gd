# ============================================================
#  DUNGEON DASH
#  Script:       main.gd
#  Developers:   Timothy Finch, Tucker Stark
#  Engine:       Godot 4.7 (GDScript)
#  Last updated: October 22, 2026
#
#  Description:
#  Main level script. Spawns a grid of randomly chosen room
#  scenes at startup. Rooms are filled in through the
#  Inspector (Room Scenes array) and placed on a 20m grid.
# ============================================================
extends Node3D

# The width/length of one room cell in meters
const CELL_SIZE := 20.0

# List of room scenes, filled in through the Inspector
@export var room_scenes: Array[PackedScene]

# Runs once when the game starts
func _ready() -> void:
	# Loop through a 3x3 grid of cells
	for x in range(3):
		for z in range(3):
			# Pick a random room scene and make a copy of it
			var room := room_scenes.pick_random().instantiate() as Node3D
			# Convert the grid cell (x, z) into a world position
			room.position = Vector3(x * CELL_SIZE, 0, z * CELL_SIZE)
			# Add the room to the scene so it actually shows up
			add_child(room)
