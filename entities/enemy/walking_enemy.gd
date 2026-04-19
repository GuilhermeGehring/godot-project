class_name WalkingEnemy
extends Enemy

@export var speed: float = 160.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _update_velocity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

	if target != null:
		velocity.x = signf(target.global_position.x - global_position.x) * speed
	else:
		velocity.x = 0.0
