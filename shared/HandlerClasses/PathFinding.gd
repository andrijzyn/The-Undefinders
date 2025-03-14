extends Node
class_name Pathfinding

var grid: Grid

# A* node for working with paths
class AStarNode:
	var cell: Grid.GridCell
	var g_cost: float
	var h_cost: float
	var parent: AStarNode = null

	func _init(cell: Grid.GridCell, g: float, h: float, parent: AStarNode = null):
		self.cell = cell
		self.g_cost = g
		self.h_cost = h
		self.parent = parent

	func f_cost() -> float:
		return g_cost + h_cost

# Euclidean distance
func heuristic(a: Grid.GridCell, b: Grid.GridCell) -> float:
	var dx = abs(a.x - b.x)
	var dy = abs(a.y - b.y)
	return sqrt(dx * dx + dy * dy)

# A* pathfinding
func find_path(start: Vector2, end: Vector2) -> Array:
	if not grid.is_within_bounds(start.x, start.y) or not grid.is_within_bounds(end.x, end.y):
		return []  # Start or end point outside the grid
	
	var start_cell = grid.cells[start.x][start.y]
	var end_cell = grid.cells[end.x][end.y]

	var open_list = []
	var closed_list = {}

	var start_node = AStarNode.new(start_cell, 0, heuristic(start_cell, end_cell))
	open_list.append(start_node)

	while not open_list.is_empty():
		open_list.sort_custom(func(a, b): return a.f_cost() < b.f_cost())
		var current_node = open_list.pop_front()

		if current_node.cell == end_cell:
			return reconstruct_path(current_node)  # Found the way

		closed_list[current_node.cell] = true

		for neighbor in get_neighbors_with_diagonals(current_node.cell):
			if neighbor in closed_list:
				continue

			var is_diagonal = abs(neighbor.x - current_node.cell.x) == 1 and abs(neighbor.y - current_node.cell.y) == 1
			var move_cost = 1.41 if is_diagonal else 1  # 1.41 ~ sqrt(2) for diagonals
			var g_cost = current_node.g_cost + move_cost
			var h_cost = heuristic(neighbor, end_cell)
			var neighbor_node = AStarNode.new(neighbor, g_cost, h_cost, current_node)

			var existing_node = open_list.filter(func(n): return n.cell == neighbor)
			if existing_node.is_empty() or g_cost < existing_node[0].g_cost:
				open_list.append(neighbor_node)

	return []  # No path

# Get neighbors with diagonal movement (prevent diagonal clipping)
func get_neighbors_with_diagonals(cell: Grid.GridCell) -> Array:
	var neighbors = []
	var directions = [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),  # Cardinal directions
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1) # Diagonal directions
	]

	for dir in directions:
		var nx = cell.x + dir.x
		var ny = cell.y + dir.y

		if grid.is_within_bounds(nx, ny) and grid.cells[nx][ny].walkable:
			# Prevent diagonal corner clipping
			if abs(dir.x) == 1 and abs(dir.y) == 1:  # Diagonal move
				if not (grid.cells[cell.x + dir.x][cell.y].walkable and grid.cells[cell.x][cell.y + dir.y].walkable):
					continue

			neighbors.append(grid.cells[nx][ny])

	return neighbors

# Recovering the path from nodes
func reconstruct_path(node: AStarNode) -> Array:
	var path = []
	while node:
		path.append(Vector2(node.cell.x, node.cell.y))
		node = node.parent
	path.reverse()
	return path
