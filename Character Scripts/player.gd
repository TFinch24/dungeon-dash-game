# ============================================================
#  DUNGEON DASH
#  Script:       player.gd
#  Developers:   Timothy Finch, Tucker Stark
#  Engine:       Godot 4.7 (GDScript)
#  Last updated: October 22, 2026
#
#  Description:
#  First-person player controller. Handles mouse look,
#  WASD / left stick movement, gravity, and jumping.
#  Press Escape to free or recapture the mouse.
# ============================================================
extends CharacterBody3D

# How fast the mouse turns the camera
@export var mouse_sensitivity := 0.003
# Walking speed in meters per second
@export var speed := 5.0
# How strong the jump is (higher = jump higher)
@export var jumpstr := 4.5

# Grab the camera child node once the scene is ready
@onready var camera: Camera3D = $Camera3D

# Pull gravity from the project settings (about 9.8)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Runs once when the player enters the scene
func _ready() -> void:
	print("Player ready!")
	# Hide the cursor and lock it to the window
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Runs every time an input event happens (mouse move, key press, etc.)
func _unhandled_input(event: InputEvent) -> void:
	# Only look around if the event is mouse movement and the mouse is captured
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw: turn the whole body left/right
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Pitch: tilt only the camera up/down
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Limit the pitch so the camera can't flip upside down
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	# Escape toggles between a free cursor and a captured one
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Runs 60 times a second, used for anything involving physics
func _physics_process(delta: float) -> void:
	# Apply gravity only while we're in the air
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Read WASD / left stick as a 2D direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Turn that into a 3D direction based on where the player is facing
	# normalized() keeps diagonal movement from being faster
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# Set horizontal speed (leave velocity.y alone so gravity still works)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Jump only if the button was just pressed and we're standing on something
	if Input.is_action_just_pressed("action_jump") and is_on_floor():
		velocity.y = jumpstr

	# Actually move the player and handle collisions
	move_and_slide()
