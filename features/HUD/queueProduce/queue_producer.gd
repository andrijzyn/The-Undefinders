extends Control

@onready var grid_container = $GridContainer

func update_grid_layout():
	var count = grid_container.get_child_count()

	if count == 0:
		return

	grid_container.columns = min(count, 5)

	var total_height = grid_container.size.y
	var spacing = 10
	var rows = ceil(float(count) / grid_container.columns)
	var element_height = (total_height - spacing * (rows - 1)) / rows
	grid_container.add_theme_constant_override("vseparation", spacing)

	for child in grid_container.get_children():
		if child is Button:
			if child.has_node("TextureRect/Label") and child.has_node("ProgressBar") and child.has_node("TextureRect"):
				var label = child.get_node("TextureRect/Label")
				var progress_bar = child.get_node("ProgressBar")
				var texture_rect = child.get_node("TextureRect")

				var child_height = element_height
				var child_width = child_height * 0.8

				child.set_custom_minimum_size(Vector2(child_width, child_height))
				child.size_flags_vertical = Control.SIZE_EXPAND_FILL
				child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

				label.set_custom_minimum_size(Vector2(child_width, child_height * 0.8))
				progress_bar.set_custom_minimum_size(Vector2(child_width, child_height * 0.2))
				texture_rect.set_custom_minimum_size(Vector2(child_width, child_height * 0.8))

	grid_container.queue_sort()
