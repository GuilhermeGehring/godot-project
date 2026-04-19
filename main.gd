extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://entities/enemy/enemy.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullet/bullet.tscn")
const SPAWN_OFFSET_X: float = 700.0
const SPAWN_HEIGHT_ABOVE_PLAYER: float = 120.0
const FALL_DEATH_Y: float = 900.0
const HEALTH_BAR_WIDTH: float = 200.0
const SPRAY_BAR_WIDTH: float = 200.0

@onready var player: Player = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var health_fill: ColorRect = $UI/HealthBarFill
@onready var spray_fill: ColorRect = $UI/SprayBarFill
@onready var game_over_panel: Control = $UI/GameOver

var _game_over: bool = false

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	player.health_changed.connect(_on_player_health_changed)
	player.spray_changed.connect(_on_player_spray_changed)
	player.died.connect(_on_player_died)
	player.fired.connect(_on_player_fired)
	game_over_panel.hide()

func _process(_delta: float) -> void:
	if not _game_over and player.global_position.y > FALL_DEATH_Y:
		player.kill()

func _unhandled_input(event: InputEvent) -> void:
	if _game_over and event.is_action_pressed("jump"):
		get_tree().reload_current_scene()

func _on_spawn_timer_timeout() -> void:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	var side: float = 1.0 if randf() < 0.5 else -1.0
	enemy.position = Vector2(
		player.global_position.x + side * SPAWN_OFFSET_X,
		player.global_position.y - SPAWN_HEIGHT_ABOVE_PLAYER
	)
	enemy.target = player
	add_child(enemy)

func _on_player_fired(at: Vector2, direction: Vector2, bullet_speed: float) -> void:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	bullet.position = at
	bullet.velocity = direction * bullet_speed
	bullet.rotation = direction.angle()
	add_child(bullet)

func _on_player_health_changed(current: int, maximum: int) -> void:
	var ratio: float = float(current) / float(maximum)
	health_fill.size.x = HEALTH_BAR_WIDTH * ratio

func _on_player_spray_changed(current: float, maximum: float) -> void:
	var ratio: float = current / maximum
	spray_fill.size.x = SPRAY_BAR_WIDTH * ratio

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	spawn_timer.stop()
	game_over_panel.show()
