## Класс для обработки лучевого трассирования
class_name RaycastHandler

## [constant RaycastHandler.RAY_LENGTH]
## Константа, определяющая длину луча
const RAY_LENGTH := 1000

## Возвращает объект, на который указывает луч от камеры[br]
## [param camera: MainCamera]  - камера, от которой производится трассировка луча[br]
## [param return]  - объект, с которым пересекся луч, или null, если пересечения нет[br]
## [method RaycastHandler.getRaycastResult]
static func getRaycastResult(camera: MainCamera) -> Node3D:
	var space_state := camera.get_world_3d().direct_space_state
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	
	return result.collider if result else null

## Возвращает координаты точки, с которой пересёкся луч от камеры[br]
## [param camera: MainCamera] - камера, от которой производится трассировка луча[br]
## [param return] Vector3 - координаты точки пересечения, либо Vector3.ZERO, если пересечения нет[br]
## [method RaycastHandler.getRaycastResultPosition]
static func getRaycastResultPosition(camera: MainCamera) -> Vector3:
	var space_state := camera.get_world_3d().direct_space_state
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	
	return result.position if result else Vector3.ZERO
