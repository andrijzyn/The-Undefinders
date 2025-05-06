# OilRig.gd
extends StaticBody3D

@onready var control_area: Area3D = $ControlArea

var unit_counts: Dictionary = {}

func _ready():
	control_area.body_entered.connect(_on_body_entered)
	control_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		unit_counts[player_id] = unit_counts.get(player_id, 0) + 1
		_update_control()

func _on_body_exited(body: Node):
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		if player_id in unit_counts:
			unit_counts[player_id] -= 1
			if unit_counts[player_id] <= 0:
				unit_counts.erase(player_id)
			_update_control()

func _update_control():
	var max_units: int = -1
	var max_player_id: int = -1
	var tie: bool = false

	for player_id in unit_counts:
		var count = unit_counts[player_id]
		if count > max_units:
			max_units = count
			max_player_id = player_id
			tie = false
		elif count == max_units:
			tie = true

	if not tie and max_player_id != -1:
		# TODO
		_allocate_income_to(max_player_id)
	else:
		pass

func _allocate_income_to(player_id):
	# TODO
	print("Гравець", player_id, "отримує дохід з качалки")
