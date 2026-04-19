class_name Coin
extends Area2D

signal collected(at: Vector2)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		collected.emit(global_position)
		queue_free()
