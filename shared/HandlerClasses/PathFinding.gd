extends Node
class_name Pathfinding

var grid: Grid
const SEGMENT_SIZE = 50

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
static func heuristic(a: Grid.GridCell, b: Grid.GridCell) -> float:
	var dx = abs(a.x - b.x)
	var dy = abs(a.y - b.y)
	return sqrt(dx * dx + dy * dy)

func find_path(start: Vector2, end: Vector2) -> Array:
	if not grid.is_within_bounds(start.x, start.y) or not grid.is_within_bounds(end.x, end.y):
		return []  # Points are out of bounds

	# Check the distance
	var distance = heuristic(grid.cells[start.x][start.y], grid.cells[end.x][end.y])
	if distance > 200:
		return find_segmented_path(start, end)  # Use segmentation

	return find_full_path(start, end)  # Use standard A*

# Function for pathfinding with segmentation
func find_segmented_path(start: Vector2, end: Vector2) -> Array:
	var full_path = []
	var current_start = start
	var max_attempts = 100  # Limit attempts to prevent infinite loops
	var attempts = 0

	while current_start != end and attempts < max_attempts:
		var segment = find_path_segment(current_start, end, SEGMENT_SIZE)
		if segment.is_empty():
			break  # If no further path is found, exit

		full_path.append_array(segment)
		current_start = segment[-1]  # Last point of the segment becomes the new start
		attempts += 1  # Increment attempt counter

	return full_path

# Function for finding a SINGLE path segment
func find_path_segment(start: Vector2, end: Vector2, segment_length: int) -> Array:
	var path = find_path(start, end)
	if path.size() > segment_length:
		path = path.slice(0, segment_length)  # Trim the path to the required length
	return path

# A* pathfinding
func find_full_path(start: Vector2, end: Vector2) -> Array:
	var start_cell = grid.cells[start.x][start.y]
	var end_cell = grid.cells[end.x][end.y]

	var open_list = PriorityQueue.new()
	var closed_list = {}

	var start_node = AStarNode.new(start_cell, 0, heuristic(start_cell, end_cell))
	open_list.push(start_node, start_node.f_cost())

	var node_map = {}  # Store nodes to update paths
	node_map[start_cell] = start_node

	while not open_list.is_empty():
		var current_node = open_list.pop()  # Extract min (fastest node)

		if current_node.cell == end_cell:
			return reconstruct_path(current_node)  # Found the way

		closed_list[current_node.cell] = true

		for neighbor in get_neighbors_with_diagonals(current_node.cell):
			if neighbor in closed_list:
				continue

			var is_diagonal = abs(neighbor.x - current_node.cell.x) == 1 and abs(neighbor.y - current_node.cell.y) == 1
			var move_cost = 1.41 if is_diagonal else 1  # 1.41 ~ sqrt(2) for diagonals
			var g_cost = current_node.g_cost + move_cost

			if neighbor in node_map and g_cost >= node_map[neighbor].g_cost:
				continue  # If there is already a better way

			var h_cost = heuristic(neighbor, end_cell)
			var neighbor_node = AStarNode.new(neighbor, g_cost, h_cost, current_node)

			node_map[neighbor] = neighbor_node
			open_list.push(neighbor_node, neighbor_node.f_cost())

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

func update_grid(new_grid: Grid):
	grid = new_grid

# Binary Heap (Priority Queue) Implementation
class PriorityQueue:
	var heap = []

	func push(item, priority):
		heap.append([priority, item])
		_heapify_up(heap.size() - 1)

	func pop():
		if heap.is_empty():
			return null
		var min_item = heap[0][1]
		if heap.size() == 1:
			heap.pop_back()
		else:
			heap[0] = heap[heap.size() - 1]
			heap.pop_back()
			_heapify_down(0)
		return min_item

	func is_empty() -> bool:
		return heap.is_empty()

	func _heapify_up(index):
		while index > 0:
			var parent_index = (index - 1) / 2
			if heap[index][0] >= heap[parent_index][0]:
				break
			var temp = heap[index]
			heap[index] = heap[parent_index]
			heap[parent_index] = temp
			index = parent_index

	func _heapify_down(index):
		while true:
			var left = 2 * index + 1
			var right = 2 * index + 2
			var smallest = index

			if left < heap.size() and heap[left][0] < heap[smallest][0]:
				smallest = left
			if right < heap.size() and heap[right][0] < heap[smallest][0]:
				smallest = right
			if smallest == index:
				break

			var temp = heap[index]
			heap[index] = heap[smallest]
			heap[smallest] = temp
			index = smallest
