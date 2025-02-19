extends Button


func play() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_scene.tscn")

func options() -> void:
	get_tree().change_scene_to_file("res://Scenes/options.tscn")

func exit() -> void:
	get_tree().quit()
