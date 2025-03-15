extends AttackUnit
class_name Soldier

var icon: Texture2D = preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG")

func _init() -> void:
	super._init()
	
	max_health = 100
	currentHealth = max_health
	
	speed = 3.0
	rotation_speed = 10.0
	
	damage = 15
	penetrationRate = 3
	accuracy = 0.9
	splashRadius = 0
	ignoreCover = false
	
	reloadTime = 1
	isSingleShooting = false
	shootsAmount = 3
	fireRate = 0.1
	attack_radius = 30
	isAutoAttackEnabled = false

func _process(delta: float) -> void:
	super._process(delta)
	if isMoving or isPatrolling:
		animPlayer.play("rig|walk ")
	else:
		animPlayer.play("rig|idle ")
