extends Node
class_name Player

var id: int
var nickname: String
var team: int
var money: int
var color: Color
var faction: String
var development_factor: float = 1.0

var buildings: Array
var units: Array
var camera: MainCamera
var ui: Control
var grid: Grid

func _init(player_id: int, player_name: String, player_money: int, player_team: int, player_color: Color, player_faction: String):
	id = player_id
	nickname = player_name
	money = player_money
	team = player_team
	color = player_color
	faction = player_faction

func _process(delta: float) -> void:
	if grid.fog_of_war:
		for unit in units:
			if unit.global_position.distance_squared_to(unit.last_position) > 1.0:
				grid.fog_of_war.reveal_fog(unit.global_position.x, unit.global_position.z, 20, unit.id)
				unit.last_position = unit.global_position

# Looking for the first available ID
func get_next_available_unit_id() -> int:
	var occupied_ids := {}
	for unit in units:
		occupied_ids[unit.id] = true

	var next_id = 0
	while next_id in occupied_ids:
		next_id += 1

	return next_id
