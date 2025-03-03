class_name HoverHandler

static var hoverItem: MovableUnit

static func handleHover(camera: MainCamera):
	var result: MovableUnit = RaycastHandler.getRaycastResult(camera) as MovableUnit

	if result:
		if hoverItem != result:
			if hoverItem and not hoverItem.isSelected:
				hoverItem.setHealthBarVisibility(false)
			result.setHealthBarVisibility(true)
			hoverItem = result
	elif hoverItem and not hoverItem.isSelected:
		hoverItem.setHealthBarVisibility(false)
		hoverItem = null
