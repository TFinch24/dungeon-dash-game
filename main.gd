# ============================================================
#   DUNGEON DASH - main.gd
#   Builds the 10x10 maze, braids loops, and spawns rooms, 
#   players, and chests.
# ============================================================
extends Node3D

# --- SETTINGS --------------------------------------------------

const CELL_SIZE := 20.0  # How big each room is in 3D meters
const GRID_SIZE := 10    # 10x10 grid of rooms

# Direction offsets for checking neighbor rooms
const DIRECTIONS := {
	Room.NORTH: Vector2i(0, -1),
	Room.EAST: Vector2i(1, 0),
	Room.SOUTH: Vector2i(0, 1),
	Room.WEST: Vector2i(-1, 0),
}

# Flips directions so connecting doors match up
const OPPOSITE := {
	Room.NORTH: Room.SOUTH,
	Room.EAST: Room.WEST,
	Room.SOUTH: Room.NORTH,
	Room.WEST: Room.EAST,
}

# --- INSPECTOR EXPORTS -----------------------------------------
@export var room_scenes: Array[PackedScene] 
@export var player_scene: PackedScene 
@export var chest_scene: PackedScene 

# --- DATA ------------------------------------------------------
# Keeps track of all carved rooms and their door layouts
var grid := {}

# --- GAME START ------------------------------------------------
func _ready() -> void:
	generate_dungeon()
	print("Cells carved: ", grid.size())
	spawn_dungeon() 
	spawn_player()
	spawn_chests()

# --- MAZE GENERATION -------------------------------------------
func generate_dungeon() -> void:
	grid.clear() # Clear out any old map data

	# Pick a random starting room
	var start := Vector2i(randi_range(0, GRID_SIZE - 1), randi_range(0, GRID_SIZE - 1))
	grid[start] = 0 

	# Stack to keep track of our path so we can backtrack
	var stack: Array[Vector2i] = [start]

	# Carve out paths until we've hit every spot
	while not stack.is_empty():
		var current: Vector2i = stack.back()

		# Find unvisited neighbor rooms
		var options: Array[int] = []
		for side in DIRECTIONS:
			var neighbor: Vector2i = current + DIRECTIONS[side]
			if is_in_grid(neighbor) and not grid.has(neighbor):
				options.append(side)

		if options.is_empty():
			stack.pop_back() # Dead end, go back
		else:
			# Pick a random unvisited neighbor and knock down the wall between them
			var chosen: int = options.pick_random()
			var next_cell: Vector2i = current + DIRECTIONS[chosen]
			grid[current] |= chosen
			grid[next_cell] = OPPOSITE[chosen]
			stack.append(next_cell)

	# --- LOOP BRAIDING PASS ---
	# Punch extra random doors so players don't get stuck in boring dead ends
	for cell in grid:
		for side in DIRECTIONS:
			var neighbor: Vector2i = cell + DIRECTIONS[side]
			if is_in_grid(neighbor):
				if not (grid[cell] & side):
					# 40% chance to punch an extra door open
					if randf() < 0.4:
						grid[cell] |= side
						grid[neighbor] |= OPPOSITE[side]

# Checks if a coordinate is inside our 10x10 bounds
func is_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE

# --- SPAWN 3D ROOMS --------------------------------------------
func spawn_dungeon() -> void:
	for cell in grid:
		var required_doors: int = grid[cell]
		
		var chosen_scene: PackedScene = null
		var valid_rotation := 0
		
		# Test scenes to see which one fits the doors we need
		for scene in room_scenes:
			var temp_room = scene.instantiate() as Room
			if temp_room:
				var base_doors = temp_room.doors
				temp_room.queue_free() # Clean up temp room
				
				# Try all 4 rotations (0, 90, 180, 270 degrees)
				for quarter_turns in range(4):
					var rotated_doors = Room.rotate_mask(base_doors, quarter_turns)
					
					if rotated_doors == required_doors:
						chosen_scene = scene
						valid_rotation = quarter_turns
						break 
						
				if chosen_scene:
					break 
		
		# Spawn the room into the 3D world if we found a match
		if chosen_scene:
			var room_instance = chosen_scene.instantiate() as Node3D
			add_child(room_instance)
			
			# Place it based on grid coordinates
			room_instance.global_position = Vector3(cell.x * CELL_SIZE, 0, cell.y * CELL_SIZE)
			room_instance.rotation.y = valid_rotation * (PI / 2)
		else:
			print("WARNING: No matching room found for door mask: ", required_doors)

# --- SPAWN PLAYER ----------------------------------------------
func spawn_player() -> void:
	if not player_scene or grid.is_empty():
		print("WARNING: Missing player scene or empty grid!")
		return

	# Grab a random room from our grid
	var random_cell = grid.keys().pick_random()
	
	# Instantiate player
	var player_instance = player_scene.instantiate() as Node3D
	add_child(player_instance)
	
	# Offset player into the corner of the room so they aren't dead center
	var room_center_x = random_cell.x * CELL_SIZE
	var room_center_z = random_cell.y * CELL_SIZE
	var corner_offset := Vector3(6.0, 2.0, 6.0)
	
	player_instance.global_position = Vector3(
		room_center_x + corner_offset.x, 
		corner_offset.y, 
		room_center_z + corner_offset.z
	)
	
	print("Player spawned in grid cell: ", random_cell)

# --- SPAWN CHESTS ----------------------------------------------
func spawn_chests() -> void:
	if not chest_scene or grid.is_empty():
		return

	for child in get_children():
		if "doors" in child:
			if randf() < 0.4: # 40% chance per room
				var chest_instance = chest_scene.instantiate() as Node3D
				child.add_child(chest_instance)
				
				# Push out to 9.5 meters (assuming a 20x20 room where walls are at 10.0)
				var wall_offset := 9
				var random_wall = randi() % 4
				var local_pos := Vector3.ZERO
				var local_rot := 0.0
				
				match random_wall:
					0: # Room's North wall (-Z)
						local_pos = Vector3(randf_range(-6.0, 6.0), 0.0, -wall_offset)
						local_rot = 0.0
					1: # Room's South wall (+Z)
						local_pos = Vector3(randf_range(-6.0, 6.0), 0.0, wall_offset)
						local_rot = PI
					2: # Room's East wall (+X)
						local_pos = Vector3(wall_offset, 0.0, randf_range(-6.0, 6.0))
						local_rot = -PI / 2
					3: # Room's West wall (-X)
						local_pos = Vector3(-wall_offset, 0.0, randf_range(-6.0, 6.0))
						local_rot = PI / 2

				# Apply local position and rotation relative to the room
				chest_instance.position = local_pos
				chest_instance.rotation.y = local_rot
				
	print("Chests spawned and aligned to room walls!")
