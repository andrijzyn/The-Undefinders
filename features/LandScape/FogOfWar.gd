extends Node3D
class_name FogOfWar

var grid
var fog_material: ShaderMaterial
var fog_instance: MeshInstance3D
var fog_image: Image  # Stores the image
var fog_map: ImageTexture  # Texture storing the fog transparency level

func _init(g: Grid):
	grid = g

func _ready():
	create_fog_of_war()

# Creates the fog mesh, assigns material, and adjusts height
func create_fog_of_war():
	fog_material = ShaderMaterial.new()
	fog_material.shader = preload("res://features/LandScape/test.gdshader")

	var fog_mesh = create_fog_mesh()

	fog_instance = MeshInstance3D.new()
	fog_instance.mesh = fog_mesh
	fog_instance.material_override = fog_material
	add_child(fog_instance)

	adjust_fog_to_terrain(fog_instance)
	fog_instance.position.y = 0.2
	create_fog_texture()
	fog_instance.visible = true

# Creates a grid mesh for the fog
func create_fog_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(grid.width):
		for y in range(grid.height):
			var cell_size = grid.cell_size
			
			# Vertex positions for the cell
			var p1 = Vector3(x * cell_size, 0, y * cell_size)
			var p2 = Vector3((x + 1) * cell_size, 0, y * cell_size)
			var p3 = Vector3(x * cell_size, 0, (y + 1) * cell_size)
			var p4 = Vector3((x + 1) * cell_size, 0, (y + 1) * cell_size)
			
			# UV coordinates for the cell (normalized grid coordinates)
			var uv1 = Vector2(x / float(grid.width), y / float(grid.height))
			var uv2 = Vector2((x + 1) / float(grid.width), y / float(grid.height))
			var uv3 = Vector2(x / float(grid.width), (y + 1) / float(grid.height))
			var uv4 = Vector2((x + 1) / float(grid.width), (y + 1) / float(grid.height))
			
			# First triangle of the cell
			st.set_uv(uv1)
			st.add_vertex(p1)
			st.set_uv(uv2)
			st.add_vertex(p2)
			st.set_uv(uv3)
			st.add_vertex(p3)
			
			# Second triangle of the cell
			st.set_uv(uv2)
			st.add_vertex(p2)
			st.set_uv(uv4)
			st.add_vertex(p4)
			st.set_uv(uv3)
			st.add_vertex(p3)
	
	st.generate_normals()
	st.commit(mesh)
	return mesh

# Adjusts the fog height based on terrain
func adjust_fog_to_terrain(fog: MeshInstance3D):
	var ground = get_tree().current_scene.find_child("Ground", true, false)
	if not (ground and ground is StaticBody3D):
		print("Ground not found or not a StaticBody3D!")
		return

	var mesh_instance = ground.find_child("Mesh", true, false)
	if not (mesh_instance and mesh_instance is MeshInstance3D):
		print("MeshInstance3D not found inside Ground!")
		return

	var terrain_mesh = mesh_instance.mesh
	if not (terrain_mesh and terrain_mesh is ArrayMesh):
		print("Ground mesh not found or not an ArrayMesh!")
		return

	# Retrieve terrain vertices
	var st = SurfaceTool.new()
	st.create_from(terrain_mesh, 0)
	var terrain_array = st.commit_to_arrays()
	var terrain_vertices = terrain_array[Mesh.ARRAY_VERTEX]

	# Adjust fog vertices
	var fog_mesh = fog.mesh
	var fog_st = SurfaceTool.new()
	fog_st.create_from(fog_mesh, 0)
	var fog_array = fog_st.commit_to_arrays()
	var fog_vertices = fog_array[Mesh.ARRAY_VERTEX]

	for i in range(fog_vertices.size()):
		var fog_pos = fog_vertices[i]
		var closest_height = 0.0
		var min_dist = INF
		for terrain_v in terrain_vertices:
			var dist = Vector2(fog_pos.x, fog_pos.z).distance_squared_to(Vector2(terrain_v.x, terrain_v.z))
			if dist < min_dist:
				min_dist = dist
				closest_height = terrain_v.y
		fog_vertices[i].y = closest_height + 0.2

	# Update the fog mesh
	fog_array[Mesh.ARRAY_VERTEX] = fog_vertices
	fog_mesh.clear_surfaces()
	fog_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	fog_st.add_vertex_array(fog_array)
	fog_st.commit(fog_mesh)

# Creates the fog texture (alpha channel for transparency)
func create_fog_texture():
	print("Creating fog texture...")  # Debug

	fog_image = Image.create_empty(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	if fog_image == null:
		print("Error: fog_image was not created!")
		return

	fog_image.fill(Color(1, 1, 1, 1))  # Completely obscure the map

	fog_map = ImageTexture.create_from_image(fog_image)
	if fog_map == null:
		print("Error: fog_map was not created!")
		return

	fog_material.set_shader_parameter("fog_texture", fog_map)

	# Debug
	print("Fog texture successfully created!")  
	print("fog_image size:", fog_image.get_size())
	print("fog_texture size:", fog_map.get_size())

# Reveals fog in a circular area
func reveal_fog(world_x: float, world_y: float, r: float):
	# Convert world coordinates to texture indices
	var cx = int((world_x - grid.position.x) / grid.cell_size)
	var cy = int((world_y - grid.position.z) / grid.cell_size)

	# Optimize by iterating only within a bounding square
	var x_min = max(cx - r, 0)
	var x_max = min(cx + r, grid.width - 1)
	var y_min = max(cy - r, 0)
	var y_max = min(cy + r, grid.height - 1)

	# Update pixels within the circular radius
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			var dx = x - cx
			var dy = y - cy
			if dx * dx + dy * dy <= r * r:
				# Set alpha to 0 (fully transparent)
				fog_image.set_pixel(x, y, Color(1, 1, 1, 0))

	# Update texture and pass it to the shader
	fog_map.set_image(fog_image)
	fog_material.set_shader_parameter("fog_texture", fog_map)
