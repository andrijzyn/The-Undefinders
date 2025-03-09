extends MovableUnit
class_name Soldier

var isWalking: bool = false
var icon: Texture2D = preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG")

func _init() -> void:
	super._init()
	var soldier_config = UnitConfig.new()
	soldier_config.max_health = 100
	soldier_config.speed = 3.0
	soldier_config.rotation_speed = 5.0
	soldier_config.threshold = 0.01
	set_config(soldier_config)

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
