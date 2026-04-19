class_name WalkingEnemy
extends Enemy

@export var speed: float = 160.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _col: CollisionShape2D = $CollisionShape2D

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	super()
	var shape := _col.shape as RectangleShape2D
	var tex := _sprite.sprite_frames.get_frame_texture("walk", 0)
	_sprite.scale = shape.size / Vector2(tex.get_width(), tex.get_height())

func _update_velocity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

	if target != null:
		var dir := signf(target.global_position.x - global_position.x)
		velocity.x = dir * speed
		_sprite.flip_h = dir < 0.0
	else:
		velocity.x = 0.0
