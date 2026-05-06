extends Area2D

signal closed(burrow: Node)
signal enemy_spawned(enemy: Node)

const CLOSE_TIME := 1.5
const RADIUS     := 22.0

const LarvaScene     = preload("res://scenes/larva.tscn")
const SaltadoraScene = preload("res://scenes/saltadora.tscn")
const EscupidorScene = preload("res://scenes/escupidor.tscn")
const BlindadoScene  = preload("res://scenes/blindado.tscn")

var player:           Node2D
var base_pos:         Vector2 = Vector2.ZERO
var bullet_container: Node2D
var wave_num:         int     = 1
var escalation:       int     = 0   # incrementado por main.gd cuando se cierra una madriguera

var _spawn_cd: float = 3.5
var _close_t:  float = 0.0
var _closing:  bool  = false
var _t:        float = 0.0

func _ready() -> void:
	var shape    = CircleShape2D.new()
	shape.radius = RADIUS + 18.0
	var col      = CollisionShape2D.new()
	col.shape    = shape
	add_child(col)
	queue_redraw()

func _get_spawn_interval() -> float:
	return max(1.1, 4.5 - escalation * 1.1)

func _physics_process(delta: float) -> void:
	_t        += delta
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_spawn_enemy()
		_spawn_cd = _get_spawn_interval()

	if _closing:
		_close_t += delta
		queue_redraw()
		if _close_t >= CLOSE_TIME:
			closed.emit(self)
			queue_free()
			return

	queue_redraw()

func start_closing() -> void:
	_closing = true
	_close_t = 0.0

func is_closing() -> bool:
	return _closing

func _draw() -> void:
	var pulse := 0.6 + sin(_t * 3.0) * 0.25
	# Color se vuelve más rojo con cada escalada
	var rr  := lerpf(0.55, 1.0, escalation / 3.0)
	var gg  := lerpf(0.12, 0.05, escalation / 3.0)
	var col := Color(rr, gg, 0.72 * (1.0 - escalation * 0.2), pulse)

	draw_arc(Vector2.ZERO, RADIUS + 10, 0, TAU, 32, Color(0.4, 0.0, 0.6, 0.25 * pulse), 6.0)
	draw_arc(Vector2.ZERO, RADIUS + 4,  0, TAU, 32, Color(rr * 0.9, 0.1, 0.8, 0.45 * pulse), 3.0)

	draw_circle(Vector2.ZERO, RADIUS, Color(0.08, 0.0, 0.12))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, col, 3.0)

	for i in 4:
		var a  := _t * (1.8 + escalation * 0.6) + i * TAU / 4.0
		var p1 := Vector2(cos(a), sin(a)) * 6.0
		var p2 := Vector2(cos(a + 0.9), sin(a + 0.9)) * (RADIUS - 4.0)
		draw_line(p1, p2, Color(rr, 0.2, 0.9, 0.5), 1.5)

	if _closing:
		var pct := _close_t / CLOSE_TIME
		draw_arc(Vector2.ZERO, RADIUS + 7, -PI / 2.0,
			-PI / 2.0 + TAU * pct, 48, Color(0.2, 1.0, 0.5, 0.9), 4.0)
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(-18, -RADIUS - 14), "CERRANDO...",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.5))

	var f2 := ThemeDB.fallback_font
	draw_string(f2, Vector2(-22, RADIUS + 16), "MADRIGUERA",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.4, 1.0, 0.8))
	draw_string(f2, Vector2(-12, RADIUS + 28), "[F] cerrar",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6, 0.7))

	if escalation > 0:
		var warn := "⚠ x%d" % (escalation + 1)
		draw_string(f2, Vector2(-10, -RADIUS - 18), warn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.4 - escalation * 0.1, 0.1, 0.9))

func _spawn_enemy() -> void:
	if not is_instance_valid(player):
		return
	var e: CharacterBody2D
	var r := randf()
	match escalation:
		0:
			if r < 0.30: e = SaltadoraScene.instantiate()
			else:        e = LarvaScene.instantiate()
		1:
			if   r < 0.18: e = EscupidorScene.instantiate()
			elif r < 0.48: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()
		2:
			if   r < 0.22: e = BlindadoScene.instantiate()
			elif r < 0.46: e = EscupidorScene.instantiate()
			elif r < 0.66: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()
		_:
			if   r < 0.35: e = BlindadoScene.instantiate()
			elif r < 0.62: e = EscupidorScene.instantiate()
			elif r < 0.76: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()

	var hp_mult := 1.0 + escalation * 0.55
	e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * hp_mult))
	e.hp               = e.max_hp
	e.speed           *= 1.0 + escalation * 0.18
	e.player           = player
	e.base_pos         = base_pos
	e.bullet_container = bullet_container
	e.position         = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	enemy_spawned.emit(e)
