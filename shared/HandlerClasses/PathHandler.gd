## Управляет построением и обновлением путей перемещения юнитов
class_name PathHandler

## Строит новый маршрут для юнита на основе его очереди точек перемещения[br]
## [param node: MovableUnit] - юнит, для которого строится маршрут[br]
## [method PathHandler.newPath]
static func newPath(node: MovableUnit) -> void:
	if node.waypointQueue.is_empty():
		return
	var safeTargetLocation = NavigationServer3D.map_get_closest_point(node.mapRID, node.waypointQueue[0])
	node.currentPaths = NavigationServer3D.map_get_path(node.mapRID, node.global_position, safeTargetLocation, true)
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
