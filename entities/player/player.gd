class_name Player
extends CharacterBody2D

const BOUNCE_VELOCITY: float = -380.0
const INVINCIBILITY_TIME: float = 1.0

const MAX_SPRAY_CHARGE: float = 100.0
const SPRAY_DRAIN_PER_SEC: float = 40.0
const SPRAY_FIRE_INTERVAL: float = 0.04
const SPRAY_SPREAD_RAD: float = 0.30
const SPRAY_BULLET_SPEED: float = 750.0

const SHAKE_RECHARGE_PER_FLIP: float = 2.0
const SHAKE_MIN_DELTA: float = 5.0

signal health_changed(current: int, maximum: int)
signal died
signal spray_changed(current: float, maximum: float)
signal fired(at: Vector2, direction: Vector2, speed: float)

@export var speed: float = 320.0
@export var jump_velocity: float = -520.0
@export var max_health: int = 5

var health: int
var spray_charge: float = MAX_SPRAY_CHARGE

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _col: CollisionShape2D = $CollisionShape2D
@onready var _arm: Node2D = $Arm
@onready var _arm_sprite: Sprite2D = $Arm/Sprite2D
@onready var _muzzle: Marker2D = $Arm/Muzzle

var _invincible: bool = false
var _dead: bool = false
var _fire_accumulator: float = 0.0
var _last_shake_dy_sign: int = 0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	var shape := _col.shape as RectangleShape2D
	var tex := _sprite.sprite_frames.get_frame_texture("walk", 0)
	_sprite.scale = shape.size / Vector2(tex.get_width(), tex.get_height())
	health = max_health
	health_changed.emit(health, max_health)
	spray_changed.emit(spray_charge, MAX_SPRAY_CHARGE)

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_on_floor():
		velocity.y += _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()
	_update_sprite(direction)
	_update_arm()
	_update_spray(delta)

func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event.is_action_released("recharge"):
		_last_shake_dy_sign = 0
		return
	if not Input.is_action_pressed("recharge"):
		return
	if not (event is InputEventMouseMotion):
		return
	_process_shake(event as InputEventMouseMotion)

func _process_shake(motion: InputEventMouseMotion) -> void:
	if absf(motion.relative.y) < SHAKE_MIN_DELTA:
		return
	var current_sign: int = 1 if motion.relative.y > 0.0 else -1
	if _last_shake_dy_sign != 0 and current_sign != _last_shake_dy_sign:
		spray_charge = minf(MAX_SPRAY_CHARGE, spray_charge + SHAKE_RECHARGE_PER_FLIP)
		spray_changed.emit(spray_charge, MAX_SPRAY_CHARGE)
	_last_shake_dy_sign = current_sign

func take_damage(amount: int) -> void:
	if _invincible or _dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_dead = true
		died.emit()
	else:
		_start_invincibility()

func bounce() -> void:
	if _dead:
		return
	velocity.y = BOUNCE_VELOCITY

func kill() -> void:
	if _dead:
		return
	health = 0
	_dead = true
	health_changed.emit(0, max_health)
	died.emit()

func _update_arm() -> void:
	var mouse_pos := get_global_mouse_position()
	var facing_left: bool = mouse_pos.x < global_position.x
	_arm.look_at(mouse_pos)
	_arm_sprite.flip_v = facing_left
	_sprite.flip_h = facing_left

func _update_sprite(direction: float) -> void:
	if direction != 0.0:
		_sprite.play("walk")
	else:
		_sprite.stop()

func _update_spray(delta: float) -> void:
	var wants_to_fire: bool = Input.is_action_pressed("fire") and spray_charge > 0.0
	if not wants_to_fire:
		_fire_accumulator = 0.0
		return
	spray_charge = max(0.0, spray_charge - SPRAY_DRAIN_PER_SEC * delta)
	_fire_accumulator += delta
	while _fire_accumulator >= SPRAY_FIRE_INTERVAL and spray_charge > 0.0:
		_fire_accumulator -= SPRAY_FIRE_INTERVAL
		_emit_spray_bullet()
	spray_changed.emit(spray_charge, MAX_SPRAY_CHARGE)

func _emit_spray_bullet() -> void:
	var aim := get_global_mouse_position() - global_position
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var direction := aim.normalized().rotated(randf_range(-SPRAY_SPREAD_RAD, SPRAY_SPREAD_RAD))
	fired.emit(_muzzle.global_position, direction, SPRAY_BULLET_SPEED)

func _start_invincibility() -> void:
	_invincible = true
	modulate.a = 0.5
	await get_tree().create_timer(INVINCIBILITY_TIME).timeout
	if is_instance_valid(self):
		_invincible = false
		modulate.a = 1.0
