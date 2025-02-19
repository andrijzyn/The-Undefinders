extends MovableUnit
class_name Soldier

func _physics_process(_delta: float) -> void:
	var direction := Vector3.ZERO 
	var movingDirection = Input.get_axis("down", "up")
	direction += transform.basis.z * movingDirection
	if Input.is_action_just_pressed("moving"):
		animPlayer.play("rig|walk ")
	if Input.is_action_just_released("moving"):
		animPlayer.stop()
	
	velocity = direction.normalized() * SPEED
	move_and_slide()
	
