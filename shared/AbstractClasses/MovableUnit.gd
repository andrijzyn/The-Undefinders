extends CharacterBody3D
class_name MovableUnit

var currentHealth: float
var maxHealth: float
var target_angle: float = 0.0
var isMoving: bool = false
var isHealthBarVisible := false
var isSelected := false
var isPatrolling := false
var direction: Vector3
var waypointQueue: PackedVector3Array = []
var patrolPoints: PackedVector3Array = []
var currentPaths: PackedVector3Array = []
var currentPath: int = 0
var currentPatrolPoint: int = 0
var unit_config: UnitConfig

@onready var animPlayer := $AnimPlayer
@onready var healthBar :HealthBar = $SubViewport.get_child(0)
@onready var healthBarSprite :Sprite3D = $HealthBarSprite
@onready var mainCamera: MainCamera
@onready var mapRID: RID

func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.movable)

func _process(delta: float) -> void:
	direction = Vector3.ZERO
	handle_input()
	update_movement(delta)
	move_and_slide()

func _ready() -> void:
	mainCamera = get_tree().get_nodes_in_group(Constants.cameras)[0]
	mapRID = get_world_3d().navigation_map

func set_config(config: UnitConfig) -> void:
	unit_config = config
	maxHealth = unit_config.max_health
	currentHealth = maxHealth

func setSelected(val: bool) -> void:
	isSelected = val
	setHealthBarVisibility(val)

func setHealthBarVisibility(val: bool):
	healthBarSprite.visible = val

func handleHealthChange(val: float):
	currentHealth -= val
	changeHealthBar()

func changeHealthBar():
	var health_percentage = currentHealth / maxHealth
	healthBar.setHealthPercentage(health_percentage)

func handle_input():
	if isSelected:
		if Input.is_action_just_pressed("MRB"):
			if Input.is_action_pressed("rotate"):
				start_rotate_order()
			elif Input.is_action_pressed("patrol"):
				start_patrol_order()
			else:
				start_move_order()

		if Input.is_action_just_pressed("abort"):
			abort_order()

func start_rotate_order():
	var targetLocation = RaycastHandler.getRaycastResultPosition(mainCamera)
	var direction = (targetLocation - global_position).normalized()
	direction.y = 0
	if direction.length() > 0:
		target_angle = atan2(direction.x, direction.z)

func start_move_order():
	var targetLocation = RaycastHandler.getRaycastResultPosition(mainCamera)
	if not Input.is_action_pressed("shift"):
		waypointQueue.clear()
		velocity = Vector3.ZERO
	waypointQueue.append(targetLocation)
	update_path()
	isMoving = true

func start_patrol_order():
	var targetLocation = RaycastHandler.getRaycastResultPosition(mainCamera)
	if Input.is_action_pressed("shift"):
		if patrolPoints.is_empty():
			patrolPoints.append(global_position)
		patrolPoints.append(targetLocation)
	else:
		patrolPoints = [global_position, targetLocation]
	currentPatrolPoint = 0
	isPatrolling = true
	update_patrol_path()

func abort_order():
	isMoving = false
	isPatrolling = false
	velocity = Vector3.ZERO
	waypointQueue.clear()
	currentPaths.clear()
	patrolPoints.clear()
	currentPath = 0

func update_movement(delta: float):
	if isMoving:
		keep_moving(delta)
	elif isPatrolling:
		keep_patrolling(delta)
	else:
		keep_rotating(delta)

func keep_rotating(delta: float):
	if Utils.angle_diff(rotation.y, target_angle) > unit_config.threshold:
		rotation.y = lerp_angle(rotation.y, target_angle, unit_config.rotation_speed * delta)

func keep_moving(delta: float):
	var next_position = currentPaths[currentPath] - global_position
	handle_rotate_by_position(delta, next_position)
	velocity = velocity.lerp(next_position.normalized() * unit_config.speed, delta)
	
	if next_position.length_squared() < 1.0:
		if currentPath < currentPaths.size() - 1:
			currentPath += 1
		elif waypointQueue.size() > 1:
			if waypointQueue.size() > 0:
				waypointQueue.remove_at(0)
			velocity = Vector3.ZERO
			update_path()
		else:
			velocity = Vector3.ZERO
			isMoving = false

func keep_patrolling(delta: float):
	var next_position = currentPaths[currentPath] - global_position
	handle_rotate_by_position(delta, next_position)
	velocity = velocity.lerp(next_position.normalized() * unit_config.speed, delta)
	
	if next_position.length_squared() < 1.0:
		if currentPath < currentPaths.size() - 1:
			currentPath += 1
		else:
			currentPatrolPoint = (currentPatrolPoint + 1) % patrolPoints.size()
			update_patrol_path()

func handle_rotate_by_position(delta: float, move_direction: Vector3):
	if move_direction.length_squared() > unit_config.threshold:
		target_angle = atan2(move_direction.x, move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, unit_config.rotation_speed * delta)

func update_path():
	if waypointQueue.is_empty():
		return
	var safeTargetLocation = NavigationServer3D.map_get_closest_point(mapRID, waypointQueue[0])
	currentPaths = NavigationServer3D.map_get_path(mapRID, global_position, safeTargetLocation, true)
	currentPath = 0

func update_patrol_path():
	waypointQueue = [
		patrolPoints[currentPatrolPoint],
		patrolPoints[(currentPatrolPoint + 1) % patrolPoints.size()]
	]
	update_path()
