class_name FlyingEnemy
extends Enemy

@export var speed: float = 140.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _update_velocity(_delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		return
	var direction := (target.global_position - global_position).normalized()
	velocity = direction * speed
	_sprite.flip_h = direction.x < 0.0
