extends VisualInstance3D
## Абстрактный класс, для всех играбельных сущностей игры здания / юниты
class_name Entity

# ------- PLAYER ID -----
var playerID: int

func setPlayerID(id:int) -> void:
	self.playerID = id

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
		var fog_alpha = player.grid.fog_of_war.get_pixel_alpha(int(pos.x), int(pos.z))
		if fog_alpha < 0.1:  # <0.1 to account for fog attenuation
			visible_layers |= player.team  # Add to bit mask

	set_layer_mask(visible_layers)
