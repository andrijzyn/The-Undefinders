extends AV_AttackUnit
class_name m1a1

func _init() -> void:
	max_health = 500
	currentHealth = max_health
	
	speed = 5.0
	rotation_speed = 5.0
	
	damage = 250
	penetrationRate = 50
	accuracy = 0.96
	splashRadius = 0
	ignoreCover = true
	
	reloadTime = 6
	isSingleShooting = true
	attack_radius = 30
	isAutoAttackEnabled = true
