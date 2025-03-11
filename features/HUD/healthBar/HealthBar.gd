extends Control
class_name HealthBar

@onready var greenBar :ColorRect = $GreenBar
var current_percentage: float = -1.0

func setHealthPercentage(percent: float):
	if percent != current_percentage:
		greenBar.size.x = percent * self.size.x
		current_percentage = percent
