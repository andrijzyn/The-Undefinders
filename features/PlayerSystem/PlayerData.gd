class_name PlayerData
var id: int
var is_ai: bool
var ai_mode: int
var base_money: int
var handicap: int   #from -3 to 3
var team: int
var nickname: String
var color: Color
var faction: String

func _init(id: int, is_ai: bool, ai_mode: int, base_money: int, handicap: int, team: int, nickname: String, color: Color, faction: String):
	self.id = id
	self.is_ai = is_ai
	self.ai_mode = clamp(ai_mode, 0, 4)
	self.base_money = base_money
	self.handicap = clamp(handicap, -3, 3)
	self.team = team
	self.nickname = nickname
	self.color = color
	self.faction = faction
