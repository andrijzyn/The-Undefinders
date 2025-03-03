extends Node

class_name BuildingController

var phantom_building: Node3D = null
var can_place: bool = true
var ghost_shader = preload("res://shaders/ghost_shader.gdshader")

func start_building_placement(building_name: String) -> void:
	# If there is an old phantom object, delete and restore the materials
	if phantom_building:
		fix_building_transparency(phantom_building)
		phantom_building.queue_free()
		phantom_building = null
	
	# Load new phantom object
	var path = "res://entities/Buildings/" + building_name + ".tscn"
	if ResourceLoader.exists(path):
		var building_scene = load(path).instantiate()
		
		duplicate_meshes(building_scene)
	
		phantom_building = building_scene
		phantom_building.rotation = Vector3(phantom_building.rotation.x, 0.0, phantom_building.rotation.z)
		phantom_building.scale = Vector3(0.5, 0.5, 0.5)
	
		apply_ghost_shader(phantom_building)
		disable_colliders(phantom_building)
		setup_phantom_area(phantom_building)
		get_tree().get_current_scene().add_child(phantom_building)
	else:
		print("Error: Scene not found at path:", path)

	for child in phantom_building.get_children():
		fix_building_transparency(child)

func finish_building_placement() -> void:
	if phantom_building and can_place:
		for child in phantom_building.get_children():
			if child is Area3D:
				child.queue_free()
		enable_colliders(phantom_building)
		fix_building_transparency(phantom_building)
		phantom_building = null

func cancel_building_placement() -> void:
	if phantom_building:
		fix_building_transparency(phantom_building)
		phantom_building.queue_free()
		phantom_building = null

func apply_ghost_shader(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var surface_count = node.mesh.get_surface_count()
		for i in range(surface_count):
			var orig_mat = node.mesh.surface_get_material(i)
			if orig_mat and not (orig_mat is ShaderMaterial):
				var ghost_material := ShaderMaterial.new()
				ghost_material.shader = ghost_shader
				ghost_material.set_shader_parameter("ghost_alpha", 0.5)
				ghost_material.set_shader_parameter("original_material", orig_mat)

				if orig_mat is StandardMaterial3D:
					ghost_material.set_shader_parameter("albedo_texture", orig_mat.albedo_texture)
					ghost_material.set_shader_parameter("albedo_color", orig_mat.albedo_color)

				node.mesh.surface_set_material(i, ghost_material)

	for child in node.get_children():
		apply_ghost_shader(child)
		
		
		
# Addictions
func fix_building_transparency(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var surface_count = node.mesh.get_surface_count()
		for i in range(surface_count):
			var orig_mat = node.mesh.surface_get_material(i)
			if orig_mat and orig_mat is ShaderMaterial:
				var prev_mat = orig_mat.get_shader_parameter("original_material")
				if prev_mat:
					node.mesh.surface_set_material(i, prev_mat)
					
func duplicate_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		node.mesh = node.mesh.duplicate()
	for child in node.get_children():
		duplicate_meshes(child)
		
func disable_colliders(node: Node) -> void:
	if node is CollisionShape3D:
		node.disabled = true
	for child in node.get_children():
		disable_colliders(child)
		
func setup_phantom_area(node: Node) -> void:
	var area = Area3D.new()
	var new_collision_shape = CollisionShape3D.new()
	
	var original_collider = find_first_collision_shape(node)
	new_collision_shape.shape = original_collider.shape.duplicate()
	new_collision_shape.position = original_collider.position
	new_collision_shape.rotation = original_collider.rotation
	
	area.add_child(new_collision_shape)
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 2
	area.collision_mask = 2
	node.add_child(area)
	area.connect("body_entered", Callable(self,"_on_phantom_area_body_entered"))
	area.connect("body_exited", Callable(self, "_on_phantom_area_body_exited"))
	
func enable_colliders(node: Node) -> void:
	if node is CollisionShape3D:
		node.disabled = false
	for child in node.get_children():
		enable_colliders(child)

func find_first_collision_shape(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node
	for child in node.get_children():
		var collider = find_first_collision_shape(child)
		if collider:
			return collider
	return null
