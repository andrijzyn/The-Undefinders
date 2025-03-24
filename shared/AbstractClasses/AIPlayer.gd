extends Player
class_name AIPlayer

var ai_mode: int # 0 - Peaceful, 1 - Easy, 2 - Medium, 3 - Hard, 4 - Adaptive

func _init(player_id: int, player_money: int, player_team: int, player_color: Color, ai_level: int, player_faction):
	ai_mode = ai_level
	var random_name = AI_NAMES.names[ai_mode][randi() % AI_NAMES.names[ai_mode].size()]
	super(player_id, random_name, player_money, player_team, player_color, player_faction)

#Placeholder function for the future
func make_decision():
	match ai_mode:
		0:
			pass
		1:
			pass
		2:
			pass
		3:
			pass
		4:
			pass
