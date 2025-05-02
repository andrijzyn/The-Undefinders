extends VisualInstance3D
class_name FogOfWar

var grid
var fog_material: ShaderMaterial
var fog_instance: MeshInstance3D
var fog_image: Image  # Stores the image
var fog_map: ImageTexture  # Texture storing the fog transparency level

var fade_timer = Timer.new()  # Timer for units
var special_area_timers = {}
var special_area_counter = 0  # Unique ID for special areas

# Stores the areas that have been revealed
var vision_areas = {}
var special_areas = {}

func _init(g: Grid):
	grid = g

func _ready():
	create_fog_of_war()
	add_child(fade_timer)
	fade_timer.wait_time = 0.5  # Time before fading
	fade_timer.one_shot = false
	fade_timer.timeout.connect(_fade_fog)
	fade_timer.start()

# Creates the fog mesh, assigns material, and adjusts height
func create_fog_of_war():
	fog_material = ShaderMaterial.new()
	fog_material.shader = preload("res://features/LandScape/test.gdshader")

	var fog_mesh = create_fog_mesh()

	fog_instance = MeshInstance3D.new()
	fog_instance.set_layer_mask(get_layer_mask())
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
		for z in range(grid.depth):
			var cell_size = grid.cell_size
			
			# Vertex positions for the cell
			var p1 = Vector3(x * cell_size, 0, z * cell_size)
			var p2 = Vector3((x + 1) * cell_size, 0, z * cell_size)
			var p3 = Vector3(x * cell_size, 0, (z + 1) * cell_size)
			var p4 = Vector3((x + 1) * cell_size, 0, (z + 1) * cell_size)
			
			# UV coordinates for the cell (normalized grid coordinates)
			var uv1 = Vector2(x / float(grid.width), z / float(grid.depth))
			var uv2 = Vector2((x + 1) / float(grid.width), z / float(grid.depth))
			var uv3 = Vector2(x / float(grid.width), (z + 1) / float(grid.depth))
			var uv4 = Vector2((x + 1) / float(grid.width), (z + 1) / float(grid.depth))
			
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
	var img = Image.new()
	var err = img.load("res://features/LandScape/textures/FogImage.png")
	
	if err != OK:
		push_error("Failed to load fog image: res://features/LandScape/textures/FogImage.png")
		return
		
	if img.get_width() != grid.width or img.get_height() != grid.depth:
		push_warning("Fog image size does not match grid size. Resizing image.")
		img.resize(grid.width, grid.depth, Image.INTERPOLATE_LANCZOS)
		
	fog_image = img  # Completely obscure the map

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
func reveal_fog(world_x: float, world_y: float, r: float, unit: Node = null):
	# Convert world coordinates to texture indices
	var cx = int((world_x - grid.position.x) / grid.cell_size)
	var cy = int((world_y - grid.position.z) / grid.cell_size)

	# Optimize by iterating only within a bounding square
	var x_min = max(cx - r, 0)
	var x_max = min(cx + r, grid.width - 1)
	var y_min = max(cy - r, 0)
	var y_max = min(cy + r, grid.depth - 1)

	if unit:
		# Remember the unit's vision radius
		vision_areas[unit] = { "cx": cx, "cy": cy, "r": r }
	else:
		# Create a unique ID for the area
		var area_id = special_area_counter
		special_area_counter += 1

		# Add a temporary area
		special_areas[area_id] = { "cx": cx, "cy": cy, "r": r }

		# Create a timer for this area
		var area_timer = Timer.new()
		add_child(area_timer)
		area_timer.wait_time = 10.0
		area_timer.one_shot = true
		area_timer.timeout.connect(func(): _on_special_area_time_out(area_id, area_timer))
		area_timer.start()

		# Save the timer in the dictionary
		special_area_timers[area_id] = area_timer

	# Update pixels within the circular radius
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			var dx = x - cx
			var dy = y - cy
			var color = fog_image.get_pixel(x, y)
			if dx * dx + dy * dy <= r * r:
				fog_image.set_pixel(x, y, Color(color.r, color.g, color.b, 0))

	# Update texture and pass it to the shader
	fog_map.set_image(fog_image)
	fog_material.set_shader_parameter("fog_texture", fog_map)

func _on_special_area_time_out(area_id: int, area_timer: Timer):
	if area_id in special_areas:
		special_areas.erase(area_id)

	area_timer.queue_free()
	special_area_timers.erase(area_id)

func _fade_fog():
	for x in range(grid.width):
		for y in range(grid.depth):
			var is_visible = false

			# Check if this pixel belongs to any vision area
			for unit in vision_areas.keys():
				if not is_instance_valid(unit):
					vision_areas.erase(unit)
					continue
				var area = vision_areas[unit]
				var dx = x - area["cx"]
				var dy = y - area["cy"]
				if dx * dx + dy * dy <= area["r"] * area["r"]:
					is_visible = true
					break

			for key in special_areas:
				var area = special_areas[key]
				var dx = x - area["cx"]
				var dy = y - area["cy"]
				if dx * dx + dy * dy <= area["r"] * area["r"]:
					is_visible = true
					break

			# If the pixel is no longer visible, darken it
			var color = fog_image.get_pixel(x, y)
			if not is_visible and color.a == 0:
				fog_image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.20))

	fog_map.set_image(fog_image)
	fog_material.set_shader_parameter("fog_texture", fog_map)

func get_pixel_alpha(x: float, y: float):
	var rx = int((x - grid.position.x) / grid.cell_size)
	var ry = int((y - grid.position.z) / grid.cell_size)
	if (rx <= grid.width and ry <= grid.depth):
		return fog_image.get_pixel(rx, ry).a
