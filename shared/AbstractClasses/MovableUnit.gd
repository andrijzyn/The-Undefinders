extends Entity
## Абстрактный класс для юнитов которые могут двигатся
class_name MovableUnit

var speed: float = 2.0
# ----- Rotating vars -----
var threshold: float = 0.01
var target_angle: float
var rotation_speed: float = 5.0
# ----- Flags --------
var isMoving := false
var isRotating := false
var isPatrolling := false
var isLeavingBuilding := false

# ----- PathFinding vars --------
var waypointQueue: PackedVector3Array = []
var patrolPoints: PackedVector3Array = []
var currentPaths: PackedVector3Array = []
var currentPath: int = 0
var currentPatrolPoint: int = 0

# ----------- Other vars -------------------
var direction: Vector3
var velocity: Vector3

# ---------- Nodes-containing vars -----------
@onready var animPlayer := $AnimPlayer
@onready var collider := $CollisionPolygon3D2
@onready var mainCamera: MainCamera
@onready var mapRID: RID

# ------------ Signals -----------
signal reached_exit

# ----------- In-build timeline methods implementation -----------
func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.movable)

func _process(delta: float) -> void:
	direction = Vector3.ZERO
	OrderHandler.listen(self, delta)
	MovementContinuator.listen(self, delta)
	position += velocity * delta

func _ready() -> void:
	#mainCamera = get_tree().get_nodes_in_group(Constants.cameras)[0]
	mapRID = get_world_3d().navigation_map
	currentHealth = max_health

# ---------------- Other stuff ------------------ 
func rotate_by_position(delta: float, move_direction: Vector3):
	if move_direction.length_squared() > threshold:
		target_angle = atan2(move_direction.x, move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)

## Перемещает юнит к выходной точке, с возможностью следования к флагу после выхода[br]
## [param exit_position] Vector3 - координаты выходной точки[br]
## [param target_location_active] bool - флаг, указывающий, следует ли двигаться к дополнительной точке после выхода (по умолчанию false)[br]
## [param flag_position] Vector3 - координаты точки флага (по умолчанию Vector3.ZERO)[br]
## [method move_to_exit_point]
func move_to_exit_point(exit_position: Vector3, target_location_active: bool = false, flag_position: Vector3 = Vector3.ZERO):
	isLeavingBuilding = true
	collider.disabled = true
	waypointQueue.clear()
	waypointQueue.append(exit_position)
	if target_location_active:
		waypointQueue.append(flag_position)
	PathHandler.newPath(self)
	isMoving = true

## Отвечает за продолжение движения, поворота и патрулирования юнита
class MovementContinuator:
	
	## Управляет движением юнита в зависимости от его текущего состояния[br]
	## [param node: MovableUnit] - юнит, который отслеживается [br]
	## [method MovementContinuator.continueMovement]
	static func listen(node: MovableUnit, delta: float):
		if node.isMoving:
			keep_moving(node, delta)
		elif node.isPatrolling:
			keep_patrolling(node, delta)
		elif node.isRotating:
			keep_rotating(node, delta)

	## Плавно поворачивает юнит в направлении целевого угла[br]
	## [param node: MovableUnit] - юнит, который должен продолжить поворот[br]
	## [method MovementContinuator.keep_rotating]
	static func keep_rotating(node: MovableUnit, delta: float):
		if Utils.angle_diff(node.rotation.y, node.target_angle) > node.threshold:
			node.rotation.y = lerp_angle(node.rotation.y, node.target_angle, node.rotation_speed * delta)
		else:
			node.isRotating = false

	## Обрабатывает движение юнита к следующей точке маршрута[br]
	## [param node: MovableUnit] - юнит, который должен продолжать двигаться[br]
	## [method MovementContinuator.keep_moving]
	static func keep_moving(node: MovableUnit, delta: float):
		var next_position = node.currentPaths[node.currentPath] - node.global_position
		node.rotate_by_position(delta, next_position)
		node.velocity = node.velocity.lerp(next_position.normalized() * node.speed, delta)
		
		# Не устанавливать ниже 0.1 - может вызвать ошибки
		if next_position.length_squared() < 0.1:
			if node.currentPath < node.currentPaths.size() - 1:
				node.currentPath += 1
			elif node.waypointQueue.size() > 1:
				if node.waypointQueue.size() > 0:
					node.waypointQueue.remove_at(0)
				node.velocity = Vector3.ZERO
				PathHandler.newPath(node)
			else:
				node.velocity = Vector3.ZERO
				node.isMoving = false
				if node.isLeavingBuilding:
					node.isLeavingBuilding = false
					node.collider.disabled = false
					node.reached_exit.emit()

	## Обрабатывает движение юнита по маршруту патрулирования[br]
	## [param node: MovableUnit] - юнит, который должен продолжить патрулирование[br]
	## [method MovementContinuator.keep_patrolling]
	static func keep_patrolling(node: MovableUnit, delta: float):
		var next_position = node.currentPaths[node.currentPath] - node.global_position
		node.rotate_by_position(delta, next_position)
		node.velocity = node.velocity.lerp(next_position.normalized() * node.speed, delta)
		
		if next_position.length_squared() < 1.0:
			node.velocity = Vector3.ZERO
			if node.currentPath < node.currentPaths.size() - 1:
				node.currentPath += 1
			else:
				node.currentPatrolPoint = (node.currentPatrolPoint + 1) % node.patrolPoints.size()
				PathHandler.updatePatrolPath(node)

## Отвечает за обработку команд для перемещаемых юнитов[br]
class OrderHandler:
	## Ожидает ввода и вызывает соответствующий обработчик команды[br]
	## [param node: MovableUnit] - юнит, которому передаются команды[br]
	## [method OrderHandler.listen]
	static func listen(node: MovableUnit, delta):
		if node.isSelected:
			if Input.is_action_just_pressed("CONTEXT"):
				if Input.is_action_pressed("ROTATE"):
					handleRotateOrder(node)
				elif Input.is_action_pressed("PATROL"):
					handlePatrolOrder(node)
				else:
					handleMovingOrder(node)
			if Input.is_action_just_pressed("ABORT"):
				handleAbortOrder(node)

	## Обрабатывает команду поворота юнита в указанном направлении[br]
	## [param node: MovableUnit] - юнит, который должен начать поворот[br]
	## [method OrderHandler.handleRotateOrder]
	static func handleRotateOrder(node: MovableUnit) -> void:
		var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
		var direction = (targetLocation - node.global_position).normalized()
		direction.y = 0
		if direction.length() > 0:
			node.target_angle = atan2(direction.x, direction.z)
			node.isRotating = true

	## Обрабатывает команду перемещения юнита в указанную точку или массив точек(через shift)[br]
	## [param node: MovableUnit] - юнит, который должен начать двигаться[br]
	## [method OrderHandler.handleMovingOrder]
	static func handleMovingOrder(node: MovableUnit) -> void:
		var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
		if not Input.is_action_pressed("MULTI_SELECT"):
			node.waypointQueue.clear()
			node.velocity = Vector3.ZERO
		node.waypointQueue.append(targetLocation)
		PathHandler.newPath(node)
		node.isMoving = true

	## Обрабатывает команду патрулирования между текущей позицией и указанной точкой или между массивом точек(через shift)[br]
	## [param node: MovableUnit] - юнит, который должен начать патрулирование[br]
	## [method OrderHandler.handlePatrolOrder]
	static func handlePatrolOrder(node: MovableUnit) -> void:
		var targetLocation = RaycastHandler.getRaycastResultPosition(node.mainCamera)
		if Input.is_action_pressed("MULTI_SELECT"):
			if node.patrolPoints.is_empty():
				node.patrolPoints.append(node.global_position)
			node.patrolPoints.append(targetLocation)
		else:
			node.patrolPoints = [node.global_position, targetLocation]
		
		node.currentPatrolPoint = 0
		node.isPatrolling = true
		PathHandler.updatePatrolPath(node)

	## Обрабатывает команду отмены всех действий юнита[br]
	## [param node: MovableUnit] - юнит, чьи выполняемые действия необходимо немедленно прекратить[br]
	## [method OrderHandler.handleAbortOrder]
	static func handleAbortOrder(node: MovableUnit) -> void:
		node.isMoving = false
		node.isPatrolling = false
		node.velocity = Vector3.ZERO
		node.waypointQueue.clear()
		node.currentPaths.clear()
		node.patrolPoints.clear()
		node.currentPath = 0
