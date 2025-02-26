extends CharacterBody3D
class_name MovableUnit

var currentHealth: float
var maxHealth: float

const SPEED = 2.0
const JUMP_VELOCITY = 4.5
const rotatingSpeed = 0.05
const threshold: float = 0.01
const rotation_speed: float = 5.0

var target_angle: float = 0.0
var is_rotating: bool = false


var isMoving: bool = false
var isHealthBarVisible := false
var isSelected := false
var isPatrolling := false

var direction: Vector3

var waypointQueue: PackedVector3Array = []
var patrolPoints: PackedVector3Array = []
var currentPaths: PackedVector3Array = []
var currentPath: int = 0
var currentPatrolPoint: int = 0

@onready var animPlayer := $AnimPlayer
@onready var healthBar :HealthBar = $SubViewport.get_child(0)
@onready var healthBarSprite :Sprite3D = $HealthBarSprite
@onready var mainCamera: MainCamera
@onready var mapRID: RID

func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.movable)

func _process(delta: float) -> void:
	direction = Vector3.ZERO
	OrderHandler.listen(self, delta)
	#OrderHandler.handleMovingOrder(self, delta)
	#OrderHandler.handleAbortOrder(self)
	move_and_slide()

func _ready() -> void:
	mainCamera = get_tree().get_nodes_in_group(Constants.cameras)[0]
	mapRID = get_world_3d().navigation_map

func setSelected(val: bool) -> void:
	isSelected = val
	setHealthBarVisibility(val)

func setHealthBarVisibility(val: bool):
	healthBarSprite.visible = val

func handleHealthChange(val: float):
	currentHealth -= val
	changeHealthBar()

func changeHealthBar():
	healthBar.setHealthPercentage(currentHealth / maxHealth)
