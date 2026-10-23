# ============================================================
#   DUNGEON DASH
#   Script:        main.gd
#   Developers:    Timothy Finch, Tucker Stark
#   Engine:        Godot 4.7 (GDScript)
#   Last updated: October 23, 2026
#
#   Description:
#   Main level script. Carves a 10x10 maze, braids extra paths 
#   for loops, and dynamically instantiates/rotates 3D rooms.
# ============================================================
extends Node3D

# --- CONSTANTS & CONFIGURATION ---------------------------------

# The physical size/width of a single room in 3D world meters (20x20 meters)
const CELL_SIZE := 20.0  

# The grid dimensions: GRID_SIZE x GRID_SIZE cells (10x10 = 100 total cells)
const GRID_SIZE := 10     

# Direction Vectors Lookup Table:
# Maps cardinal directions to 2D grid offset vectors (Vector2i).
# Used by the maze generator to look at adjacent cells.
# Note: Row 0 is the top, so North subtracts 1 from Y/row.
const DIRECTIONS := {
	Room.NORTH: Vector2i(0, -1),
	Room.EAST: Vector2i(1, 0),
	Room.SOUTH: Vector2i(0, 1),
	Room.WEST: Vector2i(-1, 0),
}

# Opposite Doors Lookup Table:
# Maps a door direction to its complementary wall on the neighboring room.
# Example: If cell A opens East, the neighboring cell must open West.
const OPPOSITE := {
	Room.NORTH: Room.SOUTH,
	Room.EAST: Room.WEST,
	Room.SOUTH: Room.NORTH,
	Room.WEST: Room.EAST,
}

# --- EXPORTED VARIABLES (SET IN INSPECTOR) ---------------------

# Array of PackedScenes storing your 6 physical 3D room types.
# Assigned via drag-and-drop in the Godot Inspector.
@export var room_scenes: Array[PackedScene]

# A reference to the player we want to spawn in the dungeon
@export var player_scene: PackedScene

# --- DATA STORAGE ----------------------------------------------

# The Dungeon Grid Dictionary:
# Stores every active cell coordinate (Vector2i) as a key, 
# and its combined door bitmask (int) as its value.
# Example: grid[Vector2i(3, 4)] = 3 (North + East doors open)
# Serves simultaneously as our data map and our "visited" tracker.
var grid := {}

# --- STARTUP ---------------------------------------------------
func _ready() -> void:
	generate_dungeon()
	# Sanity check: every cell should be carved, so this must print 100
	print("Cells carved: ", grid.size())
	#print_maze()
	spawn_dungeon() 
	spawn_player()

# --- MAZE GENERATION (WITH LOOPS / MULTIPLE PATHS) ----------------
func generate_dungeon() -> void:
	grid.clear()  # wipe any old maze so this can be re-run

	# Pick a random starting cell.
	var start := Vector2i(randi_range(0, GRID_SIZE - 1), randi_range(0, GRID_SIZE - 1))
	grid[start] = 0  # visited, but no doors yet

	# The stack remembers our path so we can backtrack out of dead ends.
	var stack: Array[Vector2i] = [start]

	# Keep going until we've backed out of every cell
	while not stack.is_empty():
		var current: Vector2i = stack.back()

		# Find which sides lead to a cell we haven't visited yet
		var options: Array[int] = []
		for side in DIRECTIONS:
			var neighbor: Vector2i = current + DIRECTIONS[side]
			if is_in_grid(neighbor) and not grid.has(neighbor):
				options.append(side)

		if options.is_empty():
			stack.pop_back()
		else:
			var chosen: int = options.pick_random()
			var next_cell: Vector2i = current + DIRECTIONS[chosen]
			grid[current] |= chosen
			grid[next_cell] = OPPOSITE[chosen]
			stack.append(next_cell)

	# --- EXTRA PATH PASS (BRAIDING) ---
	# Now that the base maze is built, let's punch extra random doors 
	# to create loops and multi-path intersections for multiplayer traversal!
	for cell in grid:
		for side in DIRECTIONS:
			var neighbor: Vector2i = cell + DIRECTIONS[side]
			
			# Check if the neighbor exists on the grid
			if is_in_grid(neighbor):
				# If there isn't already a door connecting them...
				if not (grid[cell] & side):
					# Give it a 25% chance to punch an extra door open anyway!
					# (You can raise this to 0.4 for more paths, or lower to 0.1 for fewer)
					if randf() < 0.4:
						grid[cell] |= side
						grid[neighbor] |= OPPOSITE[side]

# Returns true if the cell is inside the 10x10 area
func is_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE

# --- DEBUGGING -------------------------------------------------
# Prints the maze as a table of door masks so we can check our work
# before any 3D rooms exist. Remove it once the dungeon spawns.
#func print_maze() -> void:
	#for z in range(GRID_SIZE):
		#var row := ""
		#for x in range(GRID_SIZE):
			# str() turns the number into text; pad_zeros(2) turns 5 into "05"
			#row += str(grid[Vector2i(x, z)]).pad_zeros(2) + " "
		#print(row)

# --- 3D SPAWNING ---
func spawn_dungeon() -> void:
	# Loop through every grid coordinate we calculated in our maze algorithm
	for cell in grid:
		# Get the exact door combination (bitmask) required for this specific cell
		var required_doors: int = grid[cell]
		
		# Variables to track our chosen room scene and how many 90° turns it needs
		var chosen_scene: PackedScene = null
		var valid_rotation := 0
		
		# Check every room scene assigned in our Inspector array
		for scene in room_scenes:
			# Instance the scene temporarily in memory just to read its default doors
			var temp_room = scene.instantiate() as Room
			if temp_room:
				var base_doors = temp_room.doors
				temp_room.queue_free() # Delete the temporary room so it doesn't clutter the game
				
				# Test all 4 possible rotations: 0, 1, 2, or 3 quarter turns (0°, 90°, 180°, 270°)
				# Why do we do this? Because a room might have a North door by default, 
				# but our maze might require that door to point East at this specific grid spot.
				for quarter_turns in range(4):
					var rotated_doors = Room.rotate_mask(base_doors, quarter_turns)
					
					# If the rotated room's doors match what our maze grid requires, we found our match!
					if rotated_doors == required_doors:
						chosen_scene = scene
						valid_rotation = quarter_turns
						break # Stop checking rotations for this room, we found a winner
						
				if chosen_scene:
					break # Stop checking other room scenes once we've found a working match
		
		# If we successfully found a matching room scene, spawn it into the 3D world
		if chosen_scene:
			var room_instance = chosen_scene.instantiate() as Node3D
			add_child(room_instance)
			
			# Position the room using world coordinates (cell size is 20.0 meters per room)
			room_instance.global_position = Vector3(cell.x * CELL_SIZE, 0, cell.y * CELL_SIZE)
			
			# Rotate the room visually in the game world to match the required rotation
			# (Each quarter turn is 90 degrees, which is PI / 2 radians in Godot)
			room_instance.rotation.y = valid_rotation * (PI / 2)
		else:
			print("WARNING: No matching room found for door mask: ", required_doors)

# --- PLAYER SPAWNING -------------------------------------------
func spawn_player() -> void:
	# Make sure the player scene was actually assigned in the Inspector
	if not player_scene:
		print("WARNING: No player scene assigned in the Inspector!")
		return
		
	# Check that our grid actually has cells generated
	if grid.is_empty():
		print("WARNING: Cannot spawn player, grid is empty!")
		return

	# Step 1: Get all the cell coordinates currently stored in our grid dictionary
	var all_cells = grid.keys()
	
	# Step 2: Pick one of those grid coordinates completely at random
	var random_cell = all_cells.pick_random()
	
	# Step 3: Instantiate the player scene into memory
	var player_instance = player_scene.instantiate() as Node3D
	add_child(player_instance)
	
	# Step 4: Calculate room center world coordinates
	var room_center_x = random_cell.x * CELL_SIZE
	var room_center_z = random_cell.y * CELL_SIZE
	
	# Step 5: Offset the player into a corner of the room 
	# (e.g., 5 meters right and 5 meters forward from the absolute center)
	var corner_offset := Vector3(6.0, 2.0, 6.0)
	
	player_instance.global_position = Vector3(
		room_center_x + corner_offset.x, 
		corner_offset.y, 
		room_center_z + corner_offset.z
	)
	
	print("Player spawned in the corner of grid cell: ", random_cell)
