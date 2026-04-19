extends Node2D

const WALKING_ENEMY_SCENE: PackedScene = preload("res://entities/enemy/enemy.tscn")
const FLYING_ENEMY_SCENE: PackedScene = preload("res://entities/enemy/flying_enemy.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullet/bullet.tscn")

const SPAWN_OFFSET_X: float = 700.0
const WALKING_SPAWN_HEIGHT_ABOVE: float = 120.0
const FLYING_SPAWN_HEIGHT_ABOVE: float = 250.0
const FLYING_CHANCE: float = 0.5

# Limites do mapa (paredes em x=±530, com margem de 50px pro inimigo nascer dentro do playable)
const WALKING_SPAWN_X_MIN: float = -480.0
const WALKING_SPAWN_X_MAX: float = 480.0

# Se o player tá a essa distância (px) de uma parede, walker spawna sempre do lado oposto
const WALL_PROXIMITY_THRESHOLD: float = 200.0

const FALL_DEATH_Y: float = 900.0
const HEALTH_BAR_WIDTH: float = 200.0
const SPRAY_BAR_WIDTH: float = 200.0

@onready var player: Player = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var health_fill: ColorRect = $UI/HealthBarFill
@onready var spray_fill: ColorRect = $UI/SprayBarFill
@onready var game_over_panel: Control = $UI/GameOver
@onready var level_complete_panel: Control = $UI/LevelComplete
@onready var fade_overlay: ColorRect = $UI/FadeOverlay

var _game_over: bool = false
var _level_complete: bool = false

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	player.health_changed.connect(_on_player_health_changed)
	player.spray_changed.connect(_on_player_spray_changed)
	player.died.connect(_on_player_died)
	player.fired.connect(_on_player_fired)
	game_over_panel.hide()
	level_complete_panel.hide()

func _process(_delta: float) -> void:
	if not _game_over and not _level_complete and player.global_position.y > FALL_DEATH_Y:
		player.kill()

func _unhandled_input(event: InputEvent) -> void:
	if (_game_over or _level_complete) and event.is_action_pressed("jump"):
		get_tree().reload_current_scene()

func _on_finish_zone_body_entered(body: Node2D) -> void:
	if _level_complete or not (body is Player):
		return
	_level_complete = true
	spawn_timer.stop()
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.2)
	tween.tween_callback(level_complete_panel.show)

func _on_spawn_timer_timeout() -> void:
	var flying: bool = randf() < FLYING_CHANCE
	var scene: PackedScene = FLYING_ENEMY_SCENE if flying else WALKING_ENEMY_SCENE
	var height_above: float = FLYING_SPAWN_HEIGHT_ABOVE if flying else WALKING_SPAWN_HEIGHT_ABOVE
	var enemy := scene.instantiate() as Enemy
	var side: float = _pick_spawn_side(flying)
	var spawn_x: float = player.global_position.x + side * SPAWN_OFFSET_X
	if not flying:
		spawn_x = clampf(spawn_x, WALKING_SPAWN_X_MIN, WALKING_SPAWN_X_MAX)
	enemy.position = Vector2(
		spawn_x,
		player.global_position.y - height_above
	)
	enemy.target = player
	add_child(enemy)

func _pick_spawn_side(flying: bool) -> float:
	if flying:
		return 1.0 if randf() < 0.5 else -1.0
	var px: float = player.global_position.x
	if px > WALKING_SPAWN_X_MAX - WALL_PROXIMITY_THRESHOLD:
		return -1.0
	if px < WALKING_SPAWN_X_MIN + WALL_PROXIMITY_THRESHOLD:
		return 1.0
	return 1.0 if randf() < 0.5 else -1.0

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
