extends MovableUnit
class_name Soldier

var icon: Texture2D = preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG")

func _init() -> void:
	super._init()
	max_health = 100
	speed = 3.0
	rotation_speed = 5.0

func _process(delta: float) -> void:
	super._process(delta)
	if isMoving or isPatrolling:
		animPlayer.play("rig|walk ")
	else:
		animPlayer.play("rig|idle ")
