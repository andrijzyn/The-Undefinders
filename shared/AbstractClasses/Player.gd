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
var camera: Camera3D
var ui: Control

func _init(player_id: int, player_name: String, player_money: int, player_team: int, player_color: Color, player_faction: String):
	id = player_id
	nickname = player_name
	money = player_money
	team = player_team
	color = player_color
	faction = player_faction
