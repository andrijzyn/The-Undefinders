# Unit.gd
extends Object
class_name Unit

var max_health: int
var speed: float
var rotation_speed: float
var threshold: float

# Constructor that requires 4 arguments
func _init(max_health: int, speed: float, rotation_speed: float, threshold: float) -> void:
	self.max_health = max_health
	self.speed = speed
	self.rotation_speed = rotation_speed
	self.threshold = threshold
