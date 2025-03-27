class_name HoverHandler

static var hoverItem: Unit

static func handleHover(camera: MainCamera):
	var result := RaycastHandler.getRaycastResult(camera)
	
	if result and result is Unit:
		result.Component_Basic.setHealthBarVisibility(true)
		hoverItem = result
	elif hoverItem and not hoverItem.Component_Basic.isSelected:
		hoverItem.Component_Basic.setHealthBarVisibility(false)
		hoverItem = null
