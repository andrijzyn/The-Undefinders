extends Node3D
class_name Grid

var width: int
var depth: int
var cell_size: float
var cells = []
const MAX_SLOPE_ANGLE = 30.0

@onready var fog_of_war = FogOfWar.new(self)
@onready var debug_mesh = ImmediateMesh.new()
@onready var debug_instance = MeshInstance3D.new()
@onready var canvas_layer: = CanvasLayer.new()

class GridCell:
	var x: int
	var y: int
	var walkable: bool
	var height: float

	func _init(x: int, y: int, walkable: bool, height: float):
		self.x = x
		self.y = y
		self.walkable = walkable
		self.height = height

func _init(w: int, d: int, size: float):
	width = w
	depth = d
	cell_size = size

func generate_grid():
	cells.clear()
	var space_state = get_world_3d().direct_space_state
	
	for x in range(width):
		var row = []
		for z in range(depth):
			var cell_world_pos = get_world_position(x, z)
			var height_at_point = get_ground_height(cell_world_pos)
			cell_world_pos.y = height_at_point
			var is_walkable = detect_obstacles(space_state, cell_world_pos)  # Check for obstacles
			row.append(GridCell.new(x, z, is_walkable, 0))
		cells.append(row)

	check_slopes()
	update_debug_mesh()

func check_slopes():
	for x in range(width):
		for z in range(depth):
			if !cells[x][z].walkable:
				continue
				
			var neighbors = [
				Vector2(1, 0),
				Vector2(0, 1),
				Vector2(-1, 0),
				Vector2(0, -1)
			]
			
			for offset in neighbors:
				var nx = x + int(offset.x)
				var nz = z + int(offset.y)
				if is_within_bounds(nx, nz) and cells[nx][nz].walkable:
					var h1 = cells[x][z].height
					var h2 = cells[nx][nz].height
					var delta_h = h2 - h1
					var distance = cell_size
					var slope_angle = rad_to_deg(atan(abs(delta_h) / distance))
					
					if slope_angle > MAX_SLOPE_ANGLE:
						cells[x][z].walkable = false
						break

func get_ground_height(position: Vector3) -> float:
	var space_state = get_world_3d().direct_space_state
	var from_pos = position + Vector3(0, 10, 0)
	var to_pos = position + Vector3(0, -20, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.collision_mask = 1 << 0
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position.y
	else:
		return position.y

func update_walkability():
	var space_state = get_world_3d().direct_space_state  # Get the collision space

	for x in range(width):
		for y in range(depth):
			var cell_world_pos = get_world_position(x, y)
			cells[x][y].walkable = detect_obstacles(space_state, cell_world_pos)  # Update walkability

	update_debug_mesh()  # Update the visual display

func detect_obstacles(space_state, position: Vector3) -> bool:
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(cell_size * 0.9, 2, cell_size * 0.9)  # Size slightly smaller than the cell

	# Use a position slightly above the cell for the check
	query.shape = shape
	query.transform = Transform3D(Basis(), position + Vector3(0, 1, 0))  # Raise by 1 for the check

	# Set it to check only objects that don't belong to the landscape (layer 1)
	query.collide_with_bodies = true
	query.collision_mask = 1 << 1

	var result = space_state.intersect_shape(query)
	return result.is_empty()  # If there are no intersections, the cell is walkable

func get_world_position(x: int, z: int) -> Vector3:
	return global_transform.origin + Vector3(x * cell_size, 0, z * cell_size)

func is_within_bounds(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < width and z < depth

func is_area_walkable(x: int, y: int, unit_size: Vector2i) -> bool:
	for dx in range(unit_size.x):
		for dy in range(unit_size.y):
			var nx = x + dx
			var ny = y + dy
			if not is_within_bounds(nx, ny) or not cells[nx][ny].walkable:
				return false
	return true

func set_walkable(x: int, z: int, walkable: bool):
	if is_within_bounds(x, z):
		cells[x][z].walkable = walkable
		update_debug_mesh()

func is_walkable(x: int, z: int) -> bool:
	if x < 0 or z < 0 or x >= width or z >= depth:
		return false
	return cells[x][z].walkable

func _ready():
	add_child(debug_instance)
	debug_instance.mesh = debug_mesh
	debug_instance.cast_shadow = false

	stretch_to_ground()
	update_debug_mesh()

	fog_of_war.set_layer_mask(1 << get_parent().id + 1)
	#Fog Test
	add_child(fog_of_war)
	fog_of_war.reveal_fog(5.0, 5.0, 5.0) 

# Display grid
func update_debug_mesh():
	debug_mesh.clear_surfaces()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw a grid
	for x in range(width):
		for z in range(depth):
			var pos = Vector3(x * cell_size, 0, z * cell_size)
			var color = Color(0, 1, 0) if cells[x][z].walkable else Color(1, 0, 0)
			if !Global.is_debugging: print("Cell[", x, "][", z, "] Walkable: ", cells[x][z].walkable)
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
		for y in range(max(0, int(start_pos.y - 20)), min(depth, int(start_pos.y + 20))):
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
			for y in range(depth):
				if is_walkable(x, y):
					var pos = Vector2(x, y)
					var dist = pos.distance_squared_to(start_pos)
					if dist < min_distance:
						min_distance = dist
						nearest = pos

	return nearest

func stretch_to_ground():
	var ground = get_tree().current_scene.find_child("Ground", true, false)
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
			var new_depth = ceil(full_size.z / cell_size)

			# Update grid size and position
			width = new_width
			depth = new_depth
			global_transform.origin = Vector3(grid_origin.x, ground_position.y, grid_origin.z)  # Adjust position

			# Rebuild the grid
			generate_grid()
			update_debug_mesh()
			get_parent().grid = self
