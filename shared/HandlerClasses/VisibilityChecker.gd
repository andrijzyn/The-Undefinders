extends Node
class_name VisibilityChecker

var scene
var visibility_update_timer = 0.0

func _process(delta):
	visibility_update_timer += delta
	if visibility_update_timer >= 0.5:
		visibility_update_timer = 0.0
		for player in scene.players:
			for unit in player.units:
				unit.update_entity_visibility()
			for building in player.buildings:
				building.update_entity_visibility()
