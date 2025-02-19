extends CharacterBody3D
class_name MovableUnit

const SPEED = 2.0
const JUMP_VELOCITY = 4.5
const rotatingSpeed = 0.05

var rotation_speed: float = 5.0
var target_angle: float = 0.0
var is_rotating: bool = false
var threshold: float = 0.01

var isSelected := false

@onready var animPlayer := $AnimPlayer
@onready var mainCamera: MainCamera
func _init() -> void:
	add_to_group(Constants.selectable)
	add_to_group(Constants.movable)

func _process(delta: float) -> void:
	OrderHandler.handleRotateOrder(self, mainCamera, delta)
	

func _ready() -> void:
	mainCamera = get_tree().get_nodes_in_group(Constants.cameras)[0]
	if not mainCamera: print(1)

func setSelected(val:bool) -> void:
	isSelected = val
	if isSelected == true:
		print("Soldier Picked")
	else: print("Soldier Unpicked")
