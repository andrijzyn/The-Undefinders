extends MovableUnit
class_name Soldier

func _process(delta: float) -> void:
	super._process(delta)

	if isMoving:
		animPlayer.play("rig|walk ")
	if not isMoving:
		animPlayer.stop()

	
