extends Node
class_name Pathfinding

var grid: Grid
const SEGMENT_SIZE = 50
const FULLPATH_DISTANCE = 200
var path_cache = {}  # Cache for already found paths
var path_mutex = Mutex.new()  # Mutex to protect path_cache
var request_mutex = Mutex.new()

var thread_pool = []
var request_queue = []
var processing_thread = Thread.new()
var processing_active = true

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

# Path request structure
class PathRequest:
	var unit: MovableUnit
	var start: Vector2
	var end: Vector2
	
	func _init(unit: MovableUnit, start: Vector2, end: Vector2):
		self.unit = unit
		self.start = start
		self.end = end

# Euclidean distance
static func heuristic(a: Grid.GridCell, b: Grid.GridCell) -> float:
	var dx = abs(a.x - b.x)
	var dy = abs(a.y - b.y)
	return max(dx, dy) + (sqrt(2) - 1) * min(dx, dy)

func _init():
	processing_thread.start(Callable(self, "_process_requests"))

# Add a pathfinding request to the queue
func request_path(unit: MovableUnit, start: Vector2, end: Vector2) -> void:
	request_mutex.lock()
	request_queue.append(PathRequest.new(unit, start, end))
	request_mutex.unlock()

# Main request processing thread
func _process_requests():
	while processing_active:
		request_mutex.lock()
		if request_queue.is_empty():
			request_mutex.unlock()
			OS.delay_msec(10)  # Wait to reduce CPU load
			continue

		var request = request_queue.pop_front()
		request_mutex.unlock()

		if Global.is_debugging: print(request)
		var result_path = find_path(request.start, request.end)
		if not result_path.is_empty():
			if Global.is_debugging: print(result_path)
			call_deferred("_deliver_path", request.unit, result_path)

# Deliver the path to the unit in the main thread
func _deliver_path(unit: MovableUnit, path: Array):
	var world_path = []
	for point in path:
		var world_pos = Vector3(
			(point.x + 0.5) * grid.cell_size + grid.position.x, 
			unit.global_position.y, 
			(point.y + 0.5) * grid.cell_size + grid.position.z
		)
		world_path.append(world_pos)
	if Global.is_debugging: print(world_path)
	unit.currentPaths = world_path
	unit.currentPath = 0
	unit.isMoving = true

# Stop processing thread when the node is removed
func _exit_tree():
	processing_active = false
	processing_thread.wait_to_finish()

func simplify_path(path: Array) -> Array:
	if path.size() < 3:
		return path
	
	var simplified_path = [path[0]]

	for i in range(1, path.size() - 1):
		var prev = simplified_path[-1]
		var next = path[i + 1]

		if not has_line_of_sight(prev, next):
			simplified_path.append(path[i])

	simplified_path.append(path[-1])
	return simplified_path

func has_line_of_sight(start: Vector2, end: Vector2) -> bool:
	var direction = (end - start).normalized()
	var current_pos = start

	while (current_pos - start).length() < (end - start).length():
		var cell = grid.cells[current_pos.x][current_pos.y]
		if not cell or not cell.walkable:
			return false
		current_pos += direction * grid.cell_size

	return true

func find_path(start: Vector2, end: Vector2) -> Array:
	if not grid.is_within_bounds(start.x, start.y) or not grid.is_within_bounds(end.x, end.y):
		return []

	if has_line_of_sight(start, end):
		return [start, end]

	var distance = heuristic(grid.cells[start.x][start.y], grid.cells[end.x][end.y])
	var result = find_segmented_path(start, end) if distance > FULLPATH_DISTANCE else find_full_path(start, end)

	return simplify_path(result)

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
		if full_path.is_empty() or full_path[-1] != end:
			var last_segment = find_full_path(current_start, end)
			if last_segment.is_empty(): break
			full_path.append_array(last_segment)  # Add last segment of the path

		current_start = segment[-1]  # Last point of the segment becomes the new start
		attempts += 1  # Increment attempt counter

	return full_path

# Function for finding a SINGLE path segment
func find_path_segment(start: Vector2, end: Vector2, segment_length: int) -> Array:
	var path = find_full_path(start, end)
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
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),  # Main directions
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1) # Diagonals
	]

	for dir in directions:
		var nx = cell.x + dir.x
		var ny = cell.y + dir.y

		if not grid.is_within_bounds(nx, ny) or not grid.cells[nx][ny].walkable:
			continue

		# Diagonal movement is allowed only if there are no obstacles on the sides
		if abs(dir.x) == 1 and abs(dir.y) == 1:
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
	path_cache.clear()

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

# Functions that I started to do but haven't finished yet
#func find_nearby_cached_path(start: Vector2, end: Vector2, radius: int) -> Dictionary:
#	for key in path_cache.keys():
#		var cached_path = path_cache[key]
#		if cached_path.size() < 2:
#			continue  # Skip incorrect paths

#		var cached_start = cached_path[0]
#		var cached_end = cached_path[-1]

		# Check direct match (start → start, end → end)
#		if is_within_reachable_area(start, cached_start, radius) and is_within_reachable_area(end, cached_end, radius):
#			return {"path": cached_path, "reverse": false}

		# Check reverse match (start → end, end → start)
#		if is_within_reachable_area(start, cached_end, radius) and is_within_reachable_area(end, cached_start, radius):
#			return {"path": cached_path, "reverse": true}

#	return {}

#func is_within_reachable_area(start: Vector2, target: Vector2, radius: int) -> bool:
#	var open_set = [start]
#	var visited = {}
#	visited[start] = true

#	while not open_set.is_empty():
#		var current = open_set.pop_front()
#		if (current - target).length() <= radius * grid.cell_size:
#			return true  # The point is reachable within the radius

#		for neighbor in get_neighbors_with_diagonals(grid.cells[current.x][current.y]):
#			if not visited.has(Vector2(neighbor.x, neighbor.y)):
#				visited[Vector2(neighbor.x, neighbor.y)] = true
#				open_set.append(Vector2(neighbor.x, neighbor.y))

#	return false  # The point is not reachable within the given radius
