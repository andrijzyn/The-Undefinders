class_name OrderHandler

static func listen(node: MovableUnit, delta):
	if node.isSelected:
		if Input.is_action_just_pressed("MRB"):
			if Input.is_action_pressed("rotate"):
				node.handle_order("rotate")
			elif Input.is_action_pressed("patrol"):
				node.handle_order("patrol")
			else:
				node.handle_order("move")

		if Input.is_action_just_pressed("abort"):
			node.handle_order("abort")
