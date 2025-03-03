extends MovableUnit
class_name Soldier

var isWalking: bool = false

func _ready() -> void:
	# Create a new soldier config and set its properties
	var soldier_config = Unit.new(100, 3.0, 5.0, 0.01)  # Example of passing values to the constructor
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
