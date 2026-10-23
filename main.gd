extends Node3D

const CELL_SIZE := 20.0

@export var room_scenes: Array[PackedScene]

func _ready() -> void:
	for x in range(3):
		for z in range(3):
			var room := room_scenes.pick_random().instantiate() as Node3D
			room.position = Vector3(x * CELL_SIZE, 0, z * CELL_SIZE)
			add_child(room)
