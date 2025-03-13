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
	cells = []
	
	for x in range(width):
		var row = []
		for y in range(height):
			row.append(GridCell.new(x, y, true, 0))  # By default all cells are passable
		cells.append(row)

func is_within_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height

func set_walkable(x: int, y: int, walkable: bool):
	if is_within_bounds(x, y):
		cells[x][y].walkable = walkable
		update_debug_mesh()

# Getting Neighbors
func get_neighbors(cell: GridCell) -> Array:
	var neighbors = []
	var directions = [[1,0], [-1,0], [0,1], [0,-1]]  # 4 directions (no diagonals)
	
	for dir in directions:
		var nx = cell.x + dir[0]
		var ny = cell.y + dir[1]
		
		if is_within_bounds(nx, ny) and cells[nx][ny].walkable:
			neighbors.append(cells[nx][ny])
	
	return neighbors

# Display grid
func _ready():
	add_child(debug_instance)
	debug_instance.mesh = debug_mesh
	debug_instance.cast_shadow = false
	debug_instance.set_surface_override_material(0, StandardMaterial3D.new())
	update_debug_mesh()

func update_debug_mesh():
	debug_mesh.clear_surfaces()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Draw a grid
	for x in range(width):
		for y in range(height):
			var pos = Vector3(x * cell_size, 0, y * cell_size)
			var color = Color(0, 1, 0) if cells[x][y].walkable else Color(1, 0, 0)

			# Draw the cell borders
			debug_mesh.surface_set_color(color)
			debug_mesh.surface_add_vertex(pos)
			debug_mesh.surface_add_vertex(pos + Vector3(cell_size, 0, 0))

			debug_mesh.surface_set_color(color)
			debug_mesh.surface_add_vertex(pos)
			debug_mesh.surface_add_vertex(pos + Vector3(0, 0, cell_size))

	debug_mesh.surface_end()

func get_nearest_walkable(grid_pos: Vector2) -> Vector2:
	var min_dist = INF
	var nearest_pos = grid_pos

	for x in range(width):
		for y in range(height):
			var pos = Vector2(x, y)
			if cells[x][y].walkable:
				var dist = pos.distance_squared_to(grid_pos)
				if dist < min_dist:
					min_dist = dist
					nearest_pos = pos

	return nearest_pos
