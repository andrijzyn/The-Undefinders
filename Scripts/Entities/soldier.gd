extends MovableUnit
class_name Soldier

func _init() -> void:
	super._init()
	maxHealth = 100
	currentHealth = 100

func _process(delta: float) -> void:
	super._process(delta)

	if isMoving:
		animPlayer.play("rig|walk ")
	if not isMoving:
		animPlayer.stop()

	
