extends Node3D

class_name Building  # Це дозволяє використовувати цей клас в інших скриптах як тип

var health: int
var icon: Texture
var cost: int

# Метод для ініціалізації будівлі
func _init(_health: int, _icon: Texture, _cost: int):
	health = _health
	icon = _icon
	cost = _cost

# Метод для отримання шкоди
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		queue_free()  # Видалити будівлю після того, як її здоров'я знизиться до 0
