extends VisualInstance3D
## Абстрактный класс, для всех играбельных сущностей игры здания / юниты
class_name Entity

# ------- PLAYER ID -----
var playerID: int

func setPlayerID(id:int) -> void:
	self.playerID = id

# ------- UNIT ID -----
var id: int

# -------- HEALTH VARS ----------
## [b]Должно быть указано при инициализации конкретной сущностью.[/b][br]
## [b]Значение строго больше 0[/b]
var max_health: float
## [b]Стартовое значение по умолчанию == [member Entity.max_health][/b]
var currentHealth: float


# ---------- NODES-CONTAINING VARS -----------
@onready var healthBar :HealthBar = $SubViewport.get_child(0)
@onready var healthBarSprite :Sprite3D = $HealthBarSprite

# ----- FLAGS --------
var isHealthBarVisible := false
var isSelected := false

# ----- UNIT SIZE --------
var _cached_size_in_cells: Vector2i = Vector2i(0, 0)

# --------------- SELECTION SETTING ------------
## Устанавливает состояние выделения сущности, также вызывает [method Entity.setHealthBarVisibility] передавая входной параметр[br]
## [param val: bool] - true, если сущность выбрана, иначе false[br]
## [method Entity.setSelected]
func setSelected(val: bool) -> void:
	isSelected = val
	setHealthBarVisibility(val)

# ------------- ОБРАБОТКА ЗДОРОВЬЯ И ОТОБРАЖЕНИЯ ПОЛОСЫ ЗДОРОВЬЯ ---------------
## Устанавливает видимость полосы здоровья[br]
## [param val: bool] - true, если полоса здоровья должна отображаться, иначе false[br]
## [method Entity.setHealthBarVisibility]
func setHealthBarVisibility(val: bool):
	healthBarSprite.visible = val

## Обрабатывает изменение здоровья сущности[br]
## [param val: float] - количество урона или восстановления[br]
## [method Entity.handleHealthChange]
func handleHealthChange(val: float):
	currentHealth -= val
	if currentHealth < 0: queue_free()
	changeHealthBar()

## Обновляет отображение полосы здоровья в зависимости от текущего здоровья[br]
## [method Entity.changeHealthBar]
func changeHealthBar():
	var health_percentage = currentHealth / max_health
	healthBar.setHealthPercentage(health_percentage)

# Function for switching unit visibility
func update_entity_visibility():
	var pos = global_position
	var visible_layers = 0
	var scene = get_tree().current_scene

	for player in scene.players:
		var fog_alpha = player.grid.fog_of_war.get_pixel_alpha(pos.x, pos.z)
		if fog_alpha < 0.1:  # <0.1 to account for fog attenuation
			visible_layers |= (1 << (player.id + 1)) # Add to bit mask

	set_layer_mask_recursively(self, visible_layers)

static func set_layer_mask_recursively(node: Node, mask: int) -> void:
	if node is VisualInstance3D:
		node.set_layer_mask(mask)
	for child in node.get_children():
		set_layer_mask_recursively(child, mask)

func get_entity_size_in_cells(grid_cell_size: float) -> Vector2i:
	if _cached_size_in_cells != Vector2i(0, 0):
		return _cached_size_in_cells

	var body_node = null

	for child in get_children():
		if child is CharacterBody3D or child is StaticBody3D:
			body_node = child
			break

	if body_node == null:
		push_error("Entity does not have a CharacterBody3D or StaticBody3D.")
		_cached_size_in_cells = Vector2i(1, 1)
		return _cached_size_in_cells

	var collider_node = null
	for grandchild in body_node.get_children():
		if grandchild is CollisionShape3D or grandchild is CollisionPolygon3D:
			collider_node = grandchild
			break

	if collider_node == null:
		push_error("Entity's body node does not have a CollisionShape3D or CollisionPolygon3D.")
		_cached_size_in_cells = Vector2i(1, 1)
		return _cached_size_in_cells

	var size = Vector3(1, 1, 1)
	if collider_node is CollisionShape3D:
		var shape = collider_node.shape
		if shape is BoxShape3D:
			size = shape.extents * 2.0
		elif shape is CapsuleShape3D:
			size = Vector3(shape.radius * 2.0, shape.height, shape.radius * 2.0)
		elif shape is SphereShape3D:
			size = Vector3(shape.radius * 2.0, shape.radius * 2.0, shape.radius * 2.0)
		else:
			push_warning("Entity has unsupported collision shape: %s" % shape)

	elif collider_node is CollisionPolygon3D:
		push_warning("CollisionPolygon3D used; defaulting to 1x1 size.")
		size = Vector3(1, 1, 1)

	var size_x_in_cells = max(1, ceil(size.x / grid_cell_size))
	var size_z_in_cells = max(1, ceil(size.z / grid_cell_size))

	_cached_size_in_cells = Vector2i(size_x_in_cells, size_z_in_cells)
	return _cached_size_in_cells
