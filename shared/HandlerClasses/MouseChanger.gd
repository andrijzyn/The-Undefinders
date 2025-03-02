class_name MouseChanger

static func mouseChange(camera: MainCamera):
	var result := RaycastHandler.getRaycastResult(camera)
	
	if result and result.is_in_group(Constants.mouseChanger):
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
