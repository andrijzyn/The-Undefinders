extends MovableUnit
## Абстрактный класс для юнитов имеющих способность атаковать
class_name AttackUnit

# --------- Attack Specs ----------
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

# --------- Flags ----------
var isAttacking := false
var canShoot := true
var isAutoAttackEnabled: bool

# ----------- AutoAttack vars ------------
@onready var detection_area: Area3D = $DetectionArea  # Узел зоны обнаружения
@onready var detection_shape: CollisionShape3D = $DetectionArea/CollisionShape3D  # Коллизия зоны
var enemies_in_range: Array[Entity] = []
var currentAttackGoal: Entity = null

# ----------- Nodes-containing vars ----------
@onready var firePoint: Marker3D = $FirePoint
var bullet: PackedScene = preload("res://features/Shells/Bullet/bullet.tscn")
#var explosion: PackedScene = preload("")


func _ready():
	super._ready()
	# Устанавливаем радиус зоны атаки
	var sphere_shape = detection_shape.shape as SphereShape3D
	if sphere_shape:
		sphere_shape.radius = attack_radius
	detection_area.connect("body_entered", Callable(self, "_on_enemy_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_enemy_exited"))

func _process(delta: float) -> void:
	super._process(delta)
	if isAutoAttackEnabled:
		if currentAttackGoal == null and not enemies_in_range.is_empty() and not isMoving:
			currentAttackGoal = enemies_in_range[0]
		if not enemies_in_range.is_empty():
			isAttacking = true
		if Input.is_action_just_pressed("CONTEXT") and mainCamera.isReadytoAttack and isSelected:
			var targetLocation = RaycastHandler.getRaycastResultPosition(mainCamera)
			MovementOrderHandler.handleRotateOrder(self, targetLocation)
			currentAttackGoal = RaycastHandler.getRaycastResult(mainCamera)
			print(currentAttackGoal)
			isAttacking = true
			mainCamera.toggleReadyAttack()
		elif isSelected and  (Input.is_action_just_pressed("ABORT") or Input.is_action_just_pressed("CONTEXT")):
			currentAttackGoal = null
			mainCamera.isReadytoAttack = false
			isAttacking = false
		# Если цель изменила позицию и юнит уже атакует — проверяем, нужно ли повернуться
		if isAttacking and not isRotating and currentAttackGoal and is_instance_valid(currentAttackGoal):
			var targetLocation = currentAttackGoal.global_position
			# Проверяем, нужно ли повернуться к цели
			if not is_facing_target(targetLocation):
				MovementOrderHandler.handleRotateOrder(self, targetLocation)
		# Если атака активна и поворот завершён — стреляем
		if isAttacking and not isRotating:
			shoot()

# Функция проверки, смотрит ли юнит на цель
func is_facing_target(targetLocation: Vector3) -> bool:
	var direction_to_target = (targetLocation - global_position).normalized()
	direction_to_target.y = 0
	var forward = global_transform.basis.z.normalized()
	return direction_to_target.dot(forward) > 0.98  # Почти смотрит на цель

func _on_enemy_entered(body):
	if body is Entity and body != self:  # Проверяем, что это враг и не сам юнит
		enemies_in_range.append(body)
		if currentAttackGoal == null:
			currentAttackGoal = body  # Если цели нет, выбираем нового врага

func _on_enemy_exited(body):
	enemies_in_range.erase(body)
	if currentAttackGoal == body:
		currentAttackGoal = enemies_in_range.front() if enemies_in_range.size() > 0 else null  # Меняем цель

func shoot():
	if currentAttackGoal and is_instance_valid(currentAttackGoal):
		if canShoot:
			canShoot = false  # Блокируем стрельбу
			if isSingleShooting:
				var bulletInstance = bullet.instantiate() as Bullet
				#get_tree().current_scene.add_child(bulletInstance)
				add_child(bulletInstance)
				bulletInstance.initialize(damage, penetrationRate, splashRadius, accuracy, ignoreCover)
				bulletInstance.sender = self
				bulletInstance.global_transform = firePoint.global_transform
				#bulletInstance.scale = Vector3(0.05, 0.05, 0.05)
			else:
				for i in range(shootsAmount):
					var bulletInstance = bullet.instantiate() as Bullet
					#get_tree().current_scene.add_child(bulletInstance)
					add_child(bulletInstance)
					bulletInstance.initialize(damage, penetrationRate, splashRadius, accuracy, ignoreCover)
					bulletInstance.sender = self
					bulletInstance.global_transform = firePoint.global_transform
					#bulletInstance.scale = Vector3(0.05, 0.05, 0.05)
					await get_tree().create_timer(fireRate).timeout
			await get_tree().create_timer(reloadTime).timeout  # Ждём reloadTime
			canShoot = true  # Разрешаем стрельбу снова
	else :isAttacking = false
