class_name RaycastHandler

static func getRaycastResult(camera: MainCamera) -> Node3D:
	var space_state := camera.get_world_3d().direct_space_state
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000  # Длина луча
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	if result: return result.collider
	else: return null
	
static func getRaycastResultPosition(camera: MainCamera) -> Vector3:
	var space_state := camera.get_world_3d().direct_space_state
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000  # Длина луча
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	if result: return result.position
	else: return Vector3.ZERO
	
