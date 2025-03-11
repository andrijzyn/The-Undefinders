class_name MouseChangeHandler

static func mouseChange(camera: MainCamera):
	var result := RaycastHandler.getRaycastResult(camera)
	
	if result and result.is_in_group(Constants.mouseChanger):
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
	else:
		DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
