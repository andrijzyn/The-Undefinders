class_name ShellDamageSpecs
var damage: float
var penetrationRate: float
var splashRadius: float
var accuracy: float

func _init(damage: float, penetrationRate:float, splashRadius: float, accuracy: float) -> void:
	self.damage = damage
	self.penetrationRate = penetrationRate
	self.accuracy = accuracy
	self.splashRadius = splashRadius
