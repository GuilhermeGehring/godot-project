class_name Bullet
extends Area2D

const LIFETIME: float = 0.35
const DAMAGE: int = 1

var velocity: Vector2 = Vector2.ZERO

var _age: float = 0.0

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		(body as Enemy).hit(DAMAGE)
	queue_free()
