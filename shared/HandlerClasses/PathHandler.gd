## Управляет построением и обновлением путей перемещения юнитов
class_name PathHandler

static var grid: Grid
static var pathfinder: Pathfinding
static var scene: MainScene

## Строит новый маршрут для юнита на основе его очереди точек перемещения[br]
## [param node: MovableUnit] - юнит, для которого строится маршрут[br]
## [method PathHandler.newPath]
static func newPath(node: MovableUnit) -> void:
	if node.waypointQueue.is_empty():
		if Global.is_debugging: print("Error: Empty waypoint queue!")
		return

	grid = scene.get_player_by_multiplayer_id(node.get_multiplayer_authority()).grid
	var start = node.global_position
	var target = node.waypointQueue[0]

	var start_grid_pos = normalizeByGrid(start.x, grid.position.x, start.z, grid.position.z, grid.cell_size)
	var target_grid_pos = normalizeByGrid(target.x, grid.position.x, target.z, grid.position.z, grid.cell_size)
	
	if not grid.is_within_bounds(start_grid_pos.x, start_grid_pos.y):
		if Global.is_debugging:
			print("Start position outside grid boundary! Searching for nearest available point...")
		start_grid_pos = grid.get_nearest_walkable(start_grid_pos, target_grid_pos)

	if not grid.is_walkable(start_grid_pos.x, start_grid_pos.y):
		if Global.is_debugging:
			print("Start position is blocked! Searching for nearest walkable point...")
		start_grid_pos = grid.get_nearest_walkable(start_grid_pos, target_grid_pos)

	if not grid.is_within_bounds(target_grid_pos.x, target_grid_pos.y):
		if Global.is_debugging:
			print("Target point outside grid boundary! Searching for nearest available point...")
		target_grid_pos = grid.get_nearest_walkable(target_grid_pos, start_grid_pos)

	if not grid.is_walkable(target_grid_pos.x, target_grid_pos.y):
		if Global.is_debugging:
			print("Target position is blocked! Searching for nearest walkable point...")
		target_grid_pos = grid.get_nearest_walkable(target_grid_pos, start_grid_pos)

	pathfinder.request_path(node, start_grid_pos, target_grid_pos)

## Обновляет маршрут патрулирования юнита, переключая его между точками патруля[br]
## [param node: MovableUnit] - юнит, выполняющий патрулирование[br]
## [method PathHandler.updatePatrolPath]
static func updatePatrolPath(node: MovableUnit) -> void:
	node.waypointQueue = [
		node.patrolPoints[node.currentPatrolPoint],
		node.patrolPoints[(node.currentPatrolPoint + 1) % node.patrolPoints.size()]
	]
	newPath(node)
static func normalizeByGrid(targetX: float, gridX: float, targetZ: float, gridZ:float, cell_size) -> Vector2:
	return Vector2(
	round((targetX - gridX) / cell_size),
	round((targetZ - gridZ) / cell_size)
	)
	
