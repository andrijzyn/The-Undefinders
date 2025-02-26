extends Control
class_name HealthBar

@onready var greenBar :ColorRect = $GreenBar

func setHealthPercentage(percent:float):
	greenBar.size.x = percent * self.size.x
