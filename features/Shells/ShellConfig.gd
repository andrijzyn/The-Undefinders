class_name ShellDamageSpecs
var damage: float
var penetrationRate: float
var splashRadius: float
var accuracy: float
var ignoreCover: bool

func _init(damage: float, penetrationRate:float, splashRadius: float, accuracy: float, ignoreCover: bool) -> void:
	self.damage = damage
	self.penetrationRate = penetrationRate
	self.accuracy = accuracy
	self.splashRadius = splashRadius
	self.ignoreCover = ignoreCover
