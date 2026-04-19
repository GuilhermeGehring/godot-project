class_name Enemy
extends CharacterBody2D

const STOMP_Y_THRESHOLD: float = 12.0
const DESPAWN_Y: float = 1500.0

signal died

@export var speed: float = 160.0
@export var max_health: int = 3

var target: Node2D

var _health: int
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _dying: bool = false

func _ready() -> void:
	_health = max_health

func _physics_process(delta: float) -> void:
	if global_position.y > DESPAWN_Y:
		queue_free()
		return

	if not is_on_floor():
		velocity.y += _gravity * delta

	if target != null:
		velocity.x = signf(target.global_position.x - global_position.x) * speed
	else:
		velocity.x = 0.0

	move_and_slide()

func hit(damage: int) -> void:
	if _dying:
		return
	_health -= damage
	if _health <= 0:
		_die()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if _dying or not (body is Player):
		return
	var player := body as Player
	var falling_from_above: bool = (
		player.velocity.y > 0.0
		and player.global_position.y < global_position.y - STOMP_Y_THRESHOLD
	)
	if falling_from_above:
		player.bounce()
		_die()
	else:
		player.take_damage(1)

func _die() -> void:
	_dying = true
	died.emit()
	queue_free()
