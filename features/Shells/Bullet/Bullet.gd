extends Node3D
class_name Bullet

const speed: float = 100.0  

var specs: ShellDamageSpecs
var sender: Node3D

func initialize(damage: float, penetrationRate:float, splashRadius: float, accuracy: float, ignoreCover: bool):
	specs = ShellDamageSpecs.new(damage, penetrationRate, splashRadius, accuracy, ignoreCover)

func _ready():
	call_deferred("_delete_after_time")

func _delete_after_time():
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _process(delta: float):
	position.z += speed * delta

func _on_body_entered(body):
	print("HIT")
	if body is Entity and body != sender:
		var entity: Entity = body as Entity
		if randf() <= specs.accuracy:
			entity.handleHealthChange(specs.damage)
		queue_free() 
