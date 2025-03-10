extends MovableUnit
class_name Soldier

var isWalking: bool = false
var icon: Texture2D = preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG")

func _init() -> void:
	super._init()
	max_health = 100
	speed = 3.0
	rotation_speed = 5.0


func _process(delta: float) -> void:
	super._process(delta)
	if isMoving or isPatrolling:
		if not isWalking:
			animPlayer.play("rig|walk ")
			isWalking = true
	else:
		if isWalking:
			animPlayer.play("rig|idle ")
			isWalking = false
