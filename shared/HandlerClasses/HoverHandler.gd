class_name HoverHandler

static var hoverItem: MovableUnit

static func handleHover(camera: MainCamera):
	var result := RaycastHandler.getRaycastResult(camera)
	
	if result and result is MovableUnit:
		result.setHealthBarVisibility(true)
		hoverItem = result
	elif hoverItem and hoverItem.isSelected != true: 
		hoverItem.setHealthBarVisibility(false)
		hoverItem = null
