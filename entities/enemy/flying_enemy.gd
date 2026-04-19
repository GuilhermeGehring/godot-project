class_name FlyingEnemy
extends Enemy

@export var speed: float = 140.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	super()
	var shape := _col.shape as RectangleShape2D
	var tex := _sprite.sprite_frames.get_frame_texture("fly", 0)
	_sprite.scale = shape.size / Vector2(tex.get_width(), tex.get_height())

func _update_velocity(_delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		return
	var direction := (target.global_position - global_position).normalized()
	velocity = direction * speed
	_sprite.flip_h = direction.x < 0.0
