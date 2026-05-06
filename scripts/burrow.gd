extends Area2D

signal closed(burrow: Node)
signal enemy_spawned(enemy: Node)

const SPAWN_INTERVAL := 5.0
const CLOSE_TIME     := 1.5
const RADIUS         := 22.0

const LarvaScene     = preload("res://scenes/larva.tscn")
const SaltadoraScene = preload("res://scenes/saltadora.tscn")

var player:           Node2D
var base_pos:         Vector2 = Vector2.ZERO
var bullet_container: Node2D
var wave_num:         int     = 1

var _spawn_cd:  float = 4.0
var _close_t:   float = 0.0
var _closing:   bool  = false
var _t:         float = 0.0

func _ready() -> void:
	var shape        = CircleShape2D.new()
	shape.radius     = RADIUS + 18.0
	var col          = CollisionShape2D.new()
	col.shape        = shape
	add_child(col)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_t        += delta
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_enemy()
		_spawn_cd = SPAWN_INTERVAL

	if _closing:
		_close_t += delta
		queue_redraw()
		if _close_t >= CLOSE_TIME:
			closed.emit(self)
			queue_free()
			return

	# Check player proximity for F-key close (driven from main.gd)
	queue_redraw()

func start_closing() -> void:
	_closing = true
	_close_t = 0.0

func is_closing() -> bool:
	return _closing

func _draw() -> void:
	var pulse := 0.6 + sin(_t * 3.0) * 0.25
	var col   := Color(0.55, 0.12, 0.72, pulse)

	# Outer glow rings
	draw_arc(Vector2.ZERO, RADIUS + 10, 0, TAU, 32, Color(0.4, 0.0, 0.6, 0.25 * pulse), 6.0)
	draw_arc(Vector2.ZERO, RADIUS + 4,  0, TAU, 32, Color(0.6, 0.1, 0.8, 0.45 * pulse), 3.0)

	# Main hole
	draw_circle(Vector2.ZERO, RADIUS, Color(0.08, 0.0, 0.12))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, col, 3.0)

	# Inner swirl lines
	for i in 4:
		var a := _t * 1.8 + i * TAU / 4.0
		var p1 := Vector2(cos(a), sin(a)) * 6.0
		var p2 := Vector2(cos(a + 0.9), sin(a + 0.9)) * (RADIUS - 4.0)
		draw_line(p1, p2, Color(0.7, 0.2, 0.9, 0.5), 1.5)

	# Closing progress arc
	if _closing:
		var pct := _close_t / CLOSE_TIME
		draw_arc(Vector2.ZERO, RADIUS + 7, -PI / 2.0,
			-PI / 2.0 + TAU * pct, 48, Color(0.2, 1.0, 0.5, 0.9), 4.0)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(-18, -RADIUS - 14), "CERRANDO...",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.5))

	# Label
	var f2 := ThemeDB.fallback_font
	draw_string(f2, Vector2(-22, RADIUS + 16), "MADRIGUERA",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.4, 1.0, 0.8))
	draw_string(f2, Vector2(-12, RADIUS + 28), "[F] cerrar",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6, 0.7))

func _spawn_enemy() -> void:
	if not is_instance_valid(player):
		return
	var e: CharacterBody2D
	if wave_num >= 3 and randf() < 0.35:
		e = SaltadoraScene.instantiate()
	else:
		e = LarvaScene.instantiate()
	var hp_mult := 1.0 + (wave_num - 1) * 0.08
	e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * hp_mult))
	e.hp               = e.max_hp
	e.player           = player
	e.base_pos         = base_pos
	e.bullet_container = bullet_container
	e.position         = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	enemy_spawned.emit(e)
