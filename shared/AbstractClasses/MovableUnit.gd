# MovableUnit.gd
extends Node3D  # or Node2D, depending on your setup

class_name MovableUnit

var max_health: int
var speed: float
var rotation_speed: float
var threshold: float

var health: int
var isMoving: bool = false
var isPatrolling: bool = false
var animPlayer: AnimationPlayer

func _ready():
	health = max_health
	animPlayer = $AnimationPlayer  # Assuming an AnimationPlayer node is attached

func _process(_delta: float) -> void:
	if isMoving:
		# Movement logic here
		pass

func set_config(config: Unit) -> void:
	max_health = config.max_health
	speed = config.speed
	rotation_speed = config.rotation_speed
	threshold = config.threshold
