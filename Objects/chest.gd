# ============================================================
#   CHEST SCRIPT - chest.gd
#   Handles Tarkov-style hold-to-loot timers, progress UI, 
#   and opening states.
# ============================================================
extends StaticBody3D

@export var total_loot_time: float = 2.0  # Time required to open the chest (in seconds)
@export var progress_ui_scene: PackedScene # Drag loot_progress_ui.tscn here in the Inspector

var current_loot_time: float = 0.0     # Tracks current hold time
var is_being_looted: bool = false      # True while the player is holding F
var is_opened: bool = false            # True once successfully looted
var active_ui: Control = null          # Reference to the active radial progress UI

func _process(delta: float) -> void:
	if is_opened:
		return

	if is_being_looted:
		# Count up while holding F
		current_loot_time += delta
		
		# Update the circular progress bar (scales 0 to 100%)
		update_progress_ui()
		
		# Check if we've held it long enough to finish
		if current_loot_time >= total_loot_time:
			complete_loot()
	else:
		# Drain progress quickly if the player lets go early
		if current_loot_time > 0.0:
			current_loot_time -= delta * 2.0
			if current_loot_time < 0.0:
				current_loot_time = 0.0
			
			update_progress_ui()

# Updates the TextureProgressBar value on the spawned UI
func update_progress_ui() -> void:
	if active_ui and active_ui.has_node("ProgressBar"):
		var progress_bar = active_ui.get_node("ProgressBar") as TextureProgressBar
		progress_bar.value = (current_loot_time / total_loot_time) * 100.0

# Called by the player script when they press and hold F
func start_looting() -> void:
	if is_opened:
		return
	is_being_looted = true
	
	# Spawn the radial progress UI on the screen if it isn't already there
	if not active_ui and progress_ui_scene:
		active_ui = progress_ui_scene.instantiate() as Control
		get_tree().root.add_child(active_ui)

# Called by the player script when they let go of F or look away
func stop_looting() -> void:
	is_being_looted = false
	
	# Clean up and remove the progress UI from the screen
	if active_ui:
		active_ui.queue_free()
		active_ui = null

# Triggered when the timer hits 100%
func complete_loot() -> void:
	is_opened = true
	is_being_looted = false
	
	# Clean up the UI
	if active_ui:
		active_ui.queue_free()
		active_ui = null
		
	print("SUCCESS: Chest opened!")
	
	# Remove the placeholder box mesh (we can swap this for an open chest model later!)
	if has_node("MeshInstance3D"):
		$MeshInstance3D.queue_free()
