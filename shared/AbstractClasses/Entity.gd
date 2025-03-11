extends Node3D
## Абстрактный класс, для всех играбельных сущностей игры здания / юниты
class_name Entity

# -------- Health vars ----------
var max_health: float
var currentHealth: float

# ---------- Nodes-containing vars -----------
@onready var healthBar :HealthBar = $SubViewport.get_child(0)
@onready var healthBarSprite :Sprite3D = $HealthBarSprite

# ----- Flags --------
var isHealthBarVisible := false
var isSelected := false

# --------------- Selection setting ------------
## Устанавливает состояние выделения сущности, также вызывает [method Entity.setHealthBarVisibility] передавая входной параметр[br]
## [param val: bool] - true, если сущность выбрана, иначе false[br]
## [method Entity.setSelected]
func setSelected(val: bool) -> void:
	isSelected = val
	setHealthBarVisibility(val)

# ------------- Обработка здоровья и отображения полосы здоровья ---------------
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
	changeHealthBar()

## Обновляет отображение полосы здоровья в зависимости от текущего здоровья[br]
## [method Entity.changeHealthBar]
func changeHealthBar():
	var health_percentage = currentHealth / max_health
	healthBar.setHealthPercentage(health_percentage)
