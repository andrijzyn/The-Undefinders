extends Node3D
class_name MainScene

var loaded_players = [
	PlayerData.new(0, false, 0, 1000, 1, 1, "Player1", Color.RED, "Test"),
	PlayerData.new(1, false, 2, 1000, -1, 2, "", Color.BLUE, "Test")
]
var players: Array[Player]
var current_camera: Camera3D = null
var current_player_index: int = 0
var pathfinder
var visibilityChecker

func _ready() -> void:
	setup_players(loaded_players)
	pathfinder = Pathfinding.new()
	pathfinder.scene = self
	PathHandler.pathfinder = pathfinder
	PathHandler.scene = self
	visibilityChecker = VisibilityChecker.new()
	visibilityChecker.scene = self
	add_child(visibilityChecker)

func setup_players(player_list: Array):
	for player_data in player_list:
		if player_data is PlayerData:
			var adjusted_money = player_data.base_money * (1 + player_data.handicap * 0.1)
			var new_player
			if player_data.is_ai:
				new_player = PlayerAI.new(player_data.id, adjusted_money, player_data.team, player_data.color, player_data.ai_mode, player_data.faction)
			else:
				new_player = PlayerHuman.new(player_data.id, player_data.nickname, adjusted_money, player_data.team, player_data.color, player_data.faction)
			new_player.name = "Player" + str(new_player.id)
			new_player.set_multiplayer_authority(new_player.id)
			add_child(new_player)
			players.append(new_player)

			var grid = Grid.new(80, 80, 0.25)  # Map size 80x80, cell size 0.25
			new_player.add_child(grid)
			new_player.grid = grid

			var ui = load("res://features/HUD/UI/rts_ui.tscn").instantiate()
			ui.name = "PlayerUI"
			ui.set_multiplayer_authority(new_player.id)
			new_player.add_child(ui)
			var spawn_point = get_node_or_null("PlayerSpawn" + str(player_data.id))
			if spawn_point:
				var camera = Camera3D.new()
				camera.name = "PlayerCamera"
				camera.current = false
				camera.set_script(load("res://app/MainCamera.gd"))
				camera.position = spawn_point.position + Vector3(0, 20, 0)
				camera.rotation_degrees.x = -60
				camera.set_multiplayer_authority(new_player.id)
				camera.cull_mask = (1 << 0) | (1 << new_player.id + 1)
				new_player.add_child(camera)

				var building = preload("res://entities/Buildings/GLA/garage/garage_imp.tscn").instantiate()
				building.position = spawn_point.position
				building.set_multiplayer_authority(new_player.id)
				building.set_layer_mask(1 << new_player.id + 1)
				camera.duplicate_meshes(building)
				camera.change_fraction_color(building, new_player.color)
				new_player.buildings.append(building)
				new_player.add_child(building)
				new_player.grid.update_walkability()
				
				camera.ui = ui
				ui.player_camera = camera
				new_player.camera = camera
				new_player.ui = ui
				print("Camera cull_mask for player", new_player.id, ": ", camera.cull_mask)
				print("Building layer mask: ", building.get_layer_mask())

			else:
				print("Error: There's no spawn point for player" + str(new_player.id))

	if players.size() > 0:
		current_player_index = 0
		set_active_player(players[0].get_node("PlayerCamera"))

func set_active_player(new_camera: Camera3D):
	if current_camera:
		current_camera.current = false
		var old_player = current_camera.get_parent()
		if old_player.has_node("PlayerUI"):
			old_player.get_node("PlayerUI").visible = false  # Hide old GUI
	current_camera = new_camera
	current_camera.current = true
	
	var new_player = current_camera.get_parent()
	if new_player.has_node("PlayerUI"):
		new_player.get_node("PlayerUI").visible = true # Show new GUI

func switch_player():
	current_player_index = (current_player_index + 1) % players.size()
	var new_player = players[current_player_index]
	var new_camera = new_player.get_node_or_null("PlayerCamera")
	if new_camera:
		set_active_player(new_camera)

func _input(event):
	if event.is_action_pressed("SWITCH_PLAYER"):
		switch_player()

func get_player_by_multiplayer_id(multiplayerID: int):
	for player in players:
		if player.get_multiplayer_authority() == multiplayerID:
			return player
	return null
