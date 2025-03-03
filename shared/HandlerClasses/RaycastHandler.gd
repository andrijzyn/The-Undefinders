extends Node

class_name RaycastHandler

const RAY_LENGTH := 1000  # Константа довжини променя

static func get_raycast_result(camera: MainCamera) -> Node3D:
	var space_state := camera.get_world_3d().direct_space_state
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	
	# Повертаємо collider, якщо є результат, інакше null
	return result.collider if result else null

static func get_raycast_result_position(camera: MainCamera) -> Vector3:
	var space_state := camera.get_world_3d().direct_space_state
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	
	# Повертаємо позицію зіткнення, якщо є результат, інакше Vector3.ZERO
	return result.position if result else Vector3.ZERO
