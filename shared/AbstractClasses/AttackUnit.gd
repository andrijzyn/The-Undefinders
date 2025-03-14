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

# --------- Flags ----------
var isAttacking := false
var canShoot := true

# ----------- Nodes-containing vars ----------
@onready var firePoint: Marker3D = $FirePoint
var bullet: PackedScene = preload("res://features/Shells/Bullet/bullet.tscn")
#var explosion: PackedScene = preload("")
var currentAttackGoal: Node3D = null

# ----------- Helper Functions ----------
# Create bullets
func create_bullets() -> void:
	var shoot_count = 1 if isSingleShooting else shootsAmount  # Corrected logic with if-else
	for i in range(shoot_count):
		var bulletInstance = bullet.instantiate() as Bullet
		add_child(bulletInstance)
		bulletInstance.initialize(damage, penetrationRate, splashRadius, accuracy, ignoreCover)
		bulletInstance.sender = self
		bulletInstance.global_transform = firePoint.global_transform

# Rotate towards the target
func rotate_towards_target(targetLocation: Vector3) -> void:
	if not is_facing_target(targetLocation):
		MovementOrderHandler.handleRotateOrder(self, targetLocation)

# ----------- Main Process ----------
func _process(delta: float) -> void:
	super._process(delta)

	if Input.is_action_just_pressed("ABORT"):
		stop_attack()

	if Input.is_action_just_pressed("CONTEXT") and mainCamera.isReadytoAttack and isSelected:
		start_attack()

	if isAttacking and not isRotating:
		if currentAttackGoal and is_instance_valid(currentAttackGoal):
			var targetLocation = currentAttackGoal.global_position
			rotate_towards_target(targetLocation)
			shoot()

# ----------- Attack Handling ----------
func start_attack() -> void:
	var targetLocation = RaycastHandler.getRaycastResultPosition(mainCamera)
	MovementOrderHandler.handleRotateOrder(self, targetLocation)
	currentAttackGoal = RaycastHandler.getRaycastResult(mainCamera)
	isAttacking = true
	mainCamera.toggleReadyAttack()

func stop_attack() -> void:
	currentAttackGoal = null
	mainCamera.isReadytoAttack = false
	isAttacking = false

# ----------- Shooting ----------
func shoot() -> void:
	if currentAttackGoal and is_instance_valid(currentAttackGoal):
		if canShoot:
			canShoot = false
			create_bullets()

			if not isSingleShooting:
				await get_tree().create_timer(fireRate).timeout

			await get_tree().create_timer(reloadTime).timeout
			canShoot = true
		else:
			isAttacking = false

# ----------- Helper for facing target ----------
func is_facing_target(targetLocation: Vector3) -> bool:
	var direction_to_target = (targetLocation - global_position).normalized()
	direction_to_target.y = 0
	var forward = global_transform.basis.z.normalized()
	return direction_to_target.dot(forward) > 0.98  # Почти смотрит на цель
