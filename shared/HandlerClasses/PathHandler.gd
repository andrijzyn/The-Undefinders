## Управляет построением и обновлением путей перемещения юнитов
class_name PathHandler

static var grid: Grid
static var pathfinder: Pathfinding

## Строит новый маршрут для юнита на основе его очереди точек перемещения[br]
## [param node: MovableUnit] - юнит, для которого строится маршрут[br]
## [method PathHandler.newPath]
static func newPath(node: MovableUnit) -> void:
	if node.waypointQueue.is_empty():
		print("Error: Empty waypoint queue!")
		return

	var start = node.global_position
	var target = node.waypointQueue[0]

	var start_grid_pos = Vector2(floor(start.x / grid.cell_size), floor(start.z / grid.cell_size))
	var target_grid_pos = Vector2(floor(target.x / grid.cell_size), floor(target.z / grid.cell_size))

	if not grid.is_within_bounds(floor(start.x / grid.cell_size), floor(start.z / grid.cell_size)):
		print("Unit out of grid! Searching for nearest available point...")
		start_grid_pos = grid.get_nearest_walkable(start_grid_pos)

	if not grid.is_within_bounds(floor(target.x / grid.cell_size), floor(target.z / grid.cell_size)):
		print("Target point outside grid boundary! Searching for nearest available point...")
		target_grid_pos = grid.get_nearest_walkable(target_grid_pos)

	var path = pathfinder.find_path(start_grid_pos, target_grid_pos)
	if path.is_empty():
		print("Error: Unable to find path from ", start_grid_pos, " to ", target_grid_pos)
		return

	var world_path = []
	for point in path:
		var world_pos = Vector3(point.x * grid.cell_size, start.y, point.y * grid.cell_size)
		world_path.append(world_pos)

	node.currentPaths = world_path
	node.currentPath = 0

## Обновляет маршрут патрулирования юнита, переключая его между точками патруля[br]
## [param node: MovableUnit] - юнит, выполняющий патрулирование[br]
## [method PathHandler.updatePatrolPath]
static func updatePatrolPath(node: MovableUnit) -> void:
	node.waypointQueue = [
		node.patrolPoints[node.currentPatrolPoint],
		node.patrolPoints[(node.currentPatrolPoint + 1) % node.patrolPoints.size()]
	]
	newPath(node)
