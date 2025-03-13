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
## [b]Значение строго больше 0[/b]
var reloadTime: float

# --------- Flags ----------
var isAttacking := false
# ----------- Nodes-containing vars ----------
@onready var firePoint: Marker3D = $FirePoint
var bullet: PackedScene = preload("res://features/Shells/Bullet/bullet.tscn")
#var explosion: PackedScene = preload("")


func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("CONTEXT") and mainCamera.isReadytoAttack and isSelected:
		MovementOrderHandler.handleRotateOrder(self)
		isAttacking = true
		mainCamera.toggleReadyAttack()
	if isAttacking and not isRotating:
		var bulletInstance = bullet.instantiate() as Bullet
		add_child(bulletInstance)
		bulletInstance.initialize(damage, penetrationRate, splashRadius, accuracy)
		bulletInstance.sender = self
		bulletInstance.global_transform = firePoint.global_transform
		#bulletInstance.scale = Vector3(0.05, 0.05, 0.05)
		isAttacking = false
