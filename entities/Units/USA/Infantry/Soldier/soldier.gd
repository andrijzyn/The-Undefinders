extends Unit
class_name Soldier

var icon: Texture2D = preload("res://entities/Units/USA/Infantry/Soldier/soldier_icon.PNG")

@onready var animPlayer := $AnimPlayer

func _init() -> void:
	super._init()

func _ready() -> void:
	self.Component_Basic = $"Basic_(Entity)"
	self.Component_Moving = $"Moving-on-Ground_(MovableUnit)"
	self.Component_Attack = $"Attacking-on-Ground_(attackUnit)"
	
	self.Component_Moving.PARENT = self
	self.Component_Attack.PARENT = self
	
	self.Component_Basic.max_health = 100
	self.Component_Basic.currentHealth = self.Component_Basic.max_health
	
	self.Component_Moving.speed = 3.0
	self.Component_Moving.rotation_speed = 10.0
	
	self.Component_Attack.damage = 15
	self.Component_Attack.penetrationRate = 3
	self.Component_Attack.accuracy = 0.9
	self.Component_Attack.splashRadius = 0
	self.Component_Attack.ignoreCover = false
	
	self.Component_Attack.reloadTime = 1
	self.Component_Attack.isSingleShooting = false
	self.Component_Attack.shootsAmount = 3
	self.Component_Attack.fireRate = 0.1
	self.Component_Attack.attack_radius = 15
	self.Component_Attack.isAutoAttackEnabled = true

func _process(delta: float) -> void:
	#super._process(delta)
	if self.Component_Moving.isMoving or self.Component_Moving.isPatrolling:
		animPlayer.play("rig|walk ")
	else:
		animPlayer.play("rig|idle ")
