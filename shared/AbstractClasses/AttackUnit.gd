extends MovableUnit
## Абстрактный класс для юнитов имеющих способность атаковать
class_name AttackUnit

# --------- ATTACK SPECS ----------
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение строго больше 0[/b]
var damage: float
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение строго больше 0[/b]
var penetrationRate: float
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение больше либо равно 0[/b]
var splashRadius: float
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение от 0 до 1 включительно[/b]
var accuracy: float
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Игнорирует укрытия или нет[/b]
var ignoreCover: bool
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение строго больше 0[/b]
var reloadTime: float
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Стреляет одиночными или нет[/b]
var isSingleShooting: bool
## [b]Если [member AttackUnit.isSingleShooting] == true, тогда НУЖНО УКАЗЫВАТЬ, в противном случае НЕТ[/b][br]
## [b]Значение строго больше 0[/b]
var shootsAmount: int
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение строго больше 0[/b]
var fireRate: float
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение строго больше 0[/b]
var attack_radius: float

# --------- FLAGS ----------
var isAttacking := false
var canShoot := true
var isReachingTarget := false
var isAutoAttackEnabled: bool

# ------------------------------------

var targetForReaching: Entity = null

# ----------- AUTOATTACK VARS ------------
@onready var detection_area: Area3D = $DetectionArea  # Узел зоны обнаружения
@onready var detection_shape: CollisionShape3D = $DetectionArea/CollisionShape3D  # Коллизия зоны
var enemies_in_range: Array[Entity] = []
var currentAttackGoal: Entity = null

# ----------- NODES-CONTAINING VARS ----------
@onready var firePoint: Marker3D = $FirePoint
var bullet: PackedScene = preload("res://features/Shells/Bullet/bullet.tscn")
#var explosion: PackedScene = preload("")

func _ready():
	# Устанавливаем радиус зоны атаки
	var sphere_shape = detection_shape.shape as SphereShape3D
	if sphere_shape:
		sphere_shape.radius = attack_radius
	detection_area.connect("body_entered", Callable(self, "_on_enemy_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_enemy_exited"))

func _process(delta: float) -> void:
	super._process(delta)
	
	if isAutoAttackEnabled:
		handle_auto_attack_logic()
	
	if isReachingTarget:
		handle_reaching_target()
	
	if isAttacking and not isRotating:
		handle_attack()

func handle_auto_attack_logic() -> void:
	if currentAttackGoal == null and not enemies_in_range.is_empty():
		var enemy = enemies_in_range[0]
		if check_line_of_sigth(enemy):
			currentAttackGoal = enemy
		elif not isReachingTarget:
			isReachingTarget = true
			targetForReaching = enemy
			MovementOrderHandler.handleMovingOrder(self, enemy.global_position)
	
	if not enemies_in_range.is_empty() and currentAttackGoal:
		start_attacking()

func start_attacking() -> void:
	isAttacking = true
	isMoving = false
	velocity = Vector3.ZERO

func handle_reaching_target() -> void:
	if targetForReaching and check_line_of_sigth(targetForReaching) and enemies_in_range.has(targetForReaching):
		MovementOrderHandler.handleAbortOrder(self)
		currentAttackGoal = targetForReaching
		isAttacking = true
		isReachingTarget = false
		targetForReaching = null

func handle_attack() -> void:
	if currentAttackGoal and is_instance_valid(currentAttackGoal):
		var targetLocation = currentAttackGoal.global_position
		rotate_towards_target(targetLocation)
		shoot()
	else:
		stop_attacking()

func stop_attacking() -> void:
	isAttacking = false
	currentAttackGoal = null
	isMoving = not waypointQueue.is_empty()
	isPatrolling = not isMoving and not patrolPoints.is_empty()

func shoot() -> void:
	if not canShoot:
		return
	
	canShoot = false
	
	if isSingleShooting:
		if currentAttackGoal and is_instance_valid(currentAttackGoal):
			currentAttackGoal.handleHealthChange(damage)
	else:
		for i in range(shootsAmount):
			if not (currentAttackGoal and is_instance_valid(currentAttackGoal)):
				stop_attacking()
				break
			currentAttackGoal.handleHealthChange(damage)
			await get_tree().create_timer(fireRate).timeout
	
	await get_tree().create_timer(reloadTime).timeout
	canShoot = true


# ----------- ATTACK HANDLING ----------
func start_attack() -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(mainCamera)
	MovementOrderHandler.handleRotateOrder(self, targetLocation)
	var target = RaycastHandler.getRaycastResult(mainCamera)
	if target is Entity and target.get_multiplayer_authority() != self.get_multiplayer_authority():
		if check_line_of_sigth(target):
			if enemies_in_range.has(target):
				currentAttackGoal = target
				isAttacking = true
				MovementOrderHandler.handleAbortOrder(self)
			else: 
				isReachingTarget = true
				MovementOrderHandler.handleMovingOrder(self, target.global_position)
				targetForReaching = target
		else:
			isReachingTarget = true
			MovementOrderHandler.handleMovingOrder(self, target.global_position)
			targetForReaching = target
		mainCamera.player.toggleReadyAttack()
	elif target is not Entity:
		MovementOrderHandler.handleMovingOrder(self, targetLocation)

func stop_attack() -> void:
	currentAttackGoal = null
	mainCamera.player.isReadytoAttack = false
	isAttacking = false




# ----------- HELPER FUNCTIONS ----------
# Create bullets
func create_bullets() -> void:
	var shoot_count = 1 if isSingleShooting else shootsAmount  # Corrected logic with if-else
	for i in range(shoot_count):
		var bulletInstance = bullet.instantiate() as Bullet
		add_child(bulletInstance)
		bulletInstance.initialize(damage, penetrationRate, splashRadius, accuracy, ignoreCover)
		bulletInstance.sender = self
		bulletInstance.global_transform = firePoint.global_transform
		if not isSingleShooting:
			await get_tree().create_timer(fireRate).timeout

func is_facing_target(targetLocation: Vector3) -> bool:
	var direction_to_target = (targetLocation - global_position).normalized()
	direction_to_target.y = 0
	var forward = global_transform.basis.z.normalized()
	return direction_to_target.dot(forward) > 0.98  # Почти смотрит на цель

# Rotate towards the target
func rotate_towards_target(targetLocation: Vector3) -> void:
	if not is_facing_target(targetLocation):
		MovementOrderHandler.handleRotateOrder(self, targetLocation)

# --------- SIGNALS ---------
func _on_enemy_entered(body):
	if body is MovableUnit and body != self and self.get_multiplayer_authority() != body.get_multiplayer_authority():  # Проверяем, что это враг и не сам юнит
		enemies_in_range.append(body)
		#if currentAttackGoal == null:
			#currentAttackGoal = body  # Если цели нет, выбираем нового врага

func _on_enemy_exited(body):
	enemies_in_range.erase(body)
	#if currentAttackGoal == body:
		#currentAttackGoal = enemies_in_range.front() if enemies_in_range.size() > 0 else null  # Меняем цель

func check_line_of_sigth(target: Entity) -> bool:
	var grid = PathHandler.grid
	var selfPos = PathHandler.normalizeByGrid(global_position.x, grid.position.x, global_position.z, grid.position.z, grid.cell_size)
	var targetPos = PathHandler.normalizeByGrid(target.global_position.x, grid.position.x, target.global_position.z, grid.position.z, grid.cell_size)
	return PathHandler.pathfinder.has_line_of_sight(selfPos, targetPos)
