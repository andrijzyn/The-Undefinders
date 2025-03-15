extends Node3D
class_name Grid

var width: int
var height: int
var cell_size: float
var cells = []

@onready var debug_mesh = ImmediateMesh.new()
@onready var debug_instance = MeshInstance3D.new()

class GridCell:
	var x: int
	var y: int
	var walkable: bool
	var height: float # used for slopes

	func _init(x: int, y: int, walkable: bool, height: float):
		self.x = x
		self.y = y
		self.walkable = walkable
		self.height = height

func _init(w: int, h: int, size: float):
	width = w
	height = h
	cell_size = size

func generate_grid():
	cells.clear()
	var space_state = get_world_3d().direct_space_state  # Get the collision space
	
	for x in range(width):
		var row = []
		for y in range(height):
			var cell_world_pos = get_world_position(x, y)
			var is_walkable = detect_obstacles(space_state, cell_world_pos)  # Check for obstacles
			row.append(GridCell.new(x, y, is_walkable, 0))
		cells.append(row)

	update_debug_mesh()  # Update the visual display

func detect_obstacles(space_state, position: Vector3) -> bool:
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(cell_size * 0.9, 1, cell_size * 0.9)  # Size slightly smaller than the cell

	# Use a position slightly above the cell for the check
	query.shape = shape
	query.transform = Transform3D(Basis(), position + Vector3(0, 0.5, 0))  # Raise by 0.5 for the check

	# Set it to check only objects that don't belong to the landscape (layer 1)
	query.collide_with_bodies = true
	query.collision_mask = 1 << 1

	var result = space_state.intersect_shape(query)
	return result.is_empty()  # If there are no intersections, the cell is walkable

func get_world_position(x: int, y: int) -> Vector3:
	return global_transform.origin + Vector3(x * cell_size, 0, y * cell_size)

func is_within_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height

func set_walkable(x: int, y: int, walkable: bool):
	if is_within_bounds(x, y):
		cells[x][y].walkable = walkable
		update_debug_mesh()

func is_walkable(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return cells[x][y].walkable

func _ready():
	add_child(debug_instance)
	debug_instance.mesh = debug_mesh
	debug_instance.cast_shadow = false

	stretch_to_ground()
	update_debug_mesh()

# Display grid
func update_debug_mesh():
	debug_mesh.clear_surfaces()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw a grid
	for x in range(width):
		for y in range(height):
			var pos = Vector3(x * cell_size, 0, y * cell_size)
			var color = Color(0, 1, 0) if cells[x][y].walkable else Color(1, 0, 0)
			print("Cell[", x, "][", y, "] Walkable: ", cells[x][y].walkable)
			# Draw the cell borders
			debug_mesh.surface_set_color(color)
			debug_mesh.surface_add_vertex(pos)
			debug_mesh.surface_add_vertex(pos + Vector3(cell_size, 0, 0))

			debug_mesh.surface_set_color(color)
			debug_mesh.surface_add_vertex(pos)
			debug_mesh.surface_add_vertex(pos + Vector3(0, 0, cell_size))

	debug_mesh.surface_end()

# Function to find the optimal cell or the nearest walkable cell
func get_nearest_walkable(start_pos: Vector2, target_pos: Vector2) -> Vector2:
	var nearest = Vector2.ZERO
	var min_distance = INF

	# Check cells within a 40x40 range around the starting position for optimal cell
	for x in range(max(0, int(start_pos.x - 20)), min(width, int(start_pos.x + 20))):
		for y in range(max(0, int(start_pos.y - 20)), min(height, int(start_pos.y + 20))):
			if is_walkable(x, y):
				# Calculate the distance from the cell to the target
				var dist = Pathfinding.heuristic(cells[x][y], cells[int(target_pos.x)][int(target_pos.y)])

				if dist < min_distance:
					min_distance = dist
					nearest = Vector2(x, y)

	# If no suitable cell is found within the 40x40 range (e.g., all cells are occupied),
	# then search for the nearest walkable cell
	if nearest == Vector2.ZERO:
		min_distance = INF
		for x in range(width):
			for y in range(height):
				if is_walkable(x, y):
					var pos = Vector2(x, y)
					var dist = pos.distance_squared_to(start_pos)
					if dist < min_distance:
						min_distance = dist
						nearest = pos

	return nearest

func stretch_to_ground():
	var ground = get_parent().find_child("Ground", true, false)
	if ground and ground is StaticBody3D:
		var mesh_instance = ground.find_child("Mesh", true, false)
		var ground_scale = ground.scale  # Get the scale from StaticBody3D

		if mesh_instance and mesh_instance.mesh:
			var aabb: AABB = mesh_instance.mesh.get_aabb()
			var full_size = aabb.size * ground_scale  # Consider the scale of StaticBody3D
			var ground_position = ground.global_transform.origin  # Consider the position of Ground

			# Determine the bottom-left corner of the grid
			var grid_origin = ground_position + (aabb.position * ground_scale)

			# Round up to cover the entire area
			var new_width = ceil(full_size.x / cell_size)
			var new_height = ceil(full_size.z / cell_size)

			# Update grid size and position
			width = new_width
			height = new_height
			global_transform.origin = Vector3(grid_origin.x, ground_position.y, grid_origin.z)  # Adjust position

			# Rebuild the grid
			generate_grid()
			update_debug_mesh()
			get_parent().grid = self
			get_parent().init_path_finder()
