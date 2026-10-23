extends Node3D

# Tick the boxes in the Inspector for the sides that have doors.
# The bit values are North = 1, East = 2, South = 4, West = 8
@export_flags("North", "East", "South", "West") var doors := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
