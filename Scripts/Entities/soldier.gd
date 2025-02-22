extends MovableUnit
class_name Soldier

func _init() -> void:
	super._init()
	maxHealth = 100
	currentHealth = 100

func _process(delta: float) -> void:
	super._process(delta)

	# Плей анимации если движется, иначе стоп анимацию
	if isMoving:
		if not animPlayer.is_playing() or animPlayer.current_animation != "rig|walk ":
			animPlayer.play("rig|walk ")
	else:
		animPlayer.stop()
