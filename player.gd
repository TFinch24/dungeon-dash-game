extends CharacterBody3D

@export var mouse_sensitivity := 0.003

@onready var camera: Camera3D = $Camera3D
var mouse_on = false

func _ready() -> void:
	print("Player ready!")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# TODO: yaw the whole body
		rotate_y(-event.relative.x * mouse_sensitivity)
		# TODO: pitch the camera, clamped to about +/- 89 degrees
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Stop Camera from flipping over
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		pass
	if event.is_action_pressed("ui_cancel"):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
