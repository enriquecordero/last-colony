extends Area2D

signal closed(burrow: Node)
signal enemy_spawned(enemy: Node)

const CLOSE_TIME := 1.5
const RADIUS     := 22.0

const LarvaScene     = preload("res://scenes/larva.tscn")
const SaltadoraScene = preload("res://scenes/saltadora.tscn")
const EscupidorScene = preload("res://scenes/escupidor.tscn")
const BlindadoScene  = preload("res://scenes/blindado.tscn")
const ExplosivoScene = preload("res://scenes/explosivo.tscn")

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
	return max(0.65, 3.8 - escalation * 1.1)

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
	# ── Ruinas humanas (contexto: madriguera irrumpe a través de estructura) ──
	var rc      := Color(0.17, 0.13, 0.10)
	var rhi     := Color(0.28, 0.22, 0.16)
	var crack_c := Color(0.07, 0.05, 0.04)
	var rebar_c := Color(0.42, 0.36, 0.28)

	# Losa de concreto agrietada
	var slab := PackedVector2Array([
		Vector2(-58, 22), Vector2(-40, 32), Vector2(42, 32),
		Vector2(60, 22),  Vector2(54, -26), Vector2(-52, -24)
	])
	draw_polygon(slab, PackedColorArray([Color(0.14, 0.11, 0.09)]))
	draw_line(Vector2.ZERO, Vector2(-40, 26), crack_c, 1.2)
	draw_line(Vector2.ZERO, Vector2(46, 24),  crack_c, 1.2)
	draw_line(Vector2.ZERO, Vector2(-24, -28), crack_c, 1.0)
	draw_line(Vector2(8, 10), Vector2(30, 28),  crack_c, 0.8)
	draw_line(Vector2(-6, -12), Vector2(-28, 6), crack_c, 0.8)

	# Pared izquierda — fragmento con tope dentado
	var lw := PackedVector2Array([
		Vector2(-62, 28), Vector2(-40, 28),
		Vector2(-40, -22), Vector2(-45, -36),
		Vector2(-52, -28), Vector2(-58, -14), Vector2(-62, 0)
	])
	draw_polygon(lw, PackedColorArray([rc]))
	draw_polyline(PackedVector2Array([
		Vector2(-40, 28), Vector2(-40, -22),
		Vector2(-45, -36), Vector2(-52, -28)
	]), rhi, 1.5)
	for bi in 3:
		draw_line(Vector2(-60, -4 + bi * 10), Vector2(-42, -4 + bi * 10),
				Color(0.10, 0.08, 0.06, 0.5), 0.8)
	draw_line(Vector2(-45, -36), Vector2(-43, -50), rebar_c, 1.5)
	draw_line(Vector2(-48, -30), Vector2(-54, -44), rebar_c, 1.5)

	# Pared derecha — más derrumbada
	var rw := PackedVector2Array([
		Vector2(38, 28), Vector2(60, 28),
		Vector2(60, 6), Vector2(56, -8),
		Vector2(48, -20), Vector2(42, -10), Vector2(38, 28)
	])
	draw_polygon(rw, PackedColorArray([rc]))
	draw_polyline(PackedVector2Array([
		Vector2(38, 28), Vector2(38, -10),
		Vector2(44, -20), Vector2(48, -20)
	]), rhi, 1.5)
	for bi in 2:
		draw_line(Vector2(40, 6 + bi * 10), Vector2(58, 6 + bi * 10),
				Color(0.10, 0.08, 0.06, 0.5), 0.8)
	draw_line(Vector2(48, -20), Vector2(51, -34), rebar_c, 1.5)

	# Escombros
	for rd in [Vector2(-28, 20), Vector2(28, 18), Vector2(-14, 26)]:
		draw_circle(rd, 4.0 + sin(_t * 0.7 + rd.x) * 0.3, rc.darkened(0.18))

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
			if   r < 0.15: e = ExplosivoScene.instantiate()
			elif r < 0.40: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()
		1:
			if   r < 0.18: e = ExplosivoScene.instantiate()
			elif r < 0.36: e = EscupidorScene.instantiate()
			elif r < 0.62: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()
		2:
			if   r < 0.20: e = BlindadoScene.instantiate()
			elif r < 0.38: e = ExplosivoScene.instantiate()
			elif r < 0.58: e = EscupidorScene.instantiate()
			elif r < 0.75: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()
		_:
			if   r < 0.28: e = BlindadoScene.instantiate()
			elif r < 0.48: e = ExplosivoScene.instantiate()
			elif r < 0.68: e = EscupidorScene.instantiate()
			elif r < 0.80: e = SaltadoraScene.instantiate()
			else:          e = LarvaScene.instantiate()

	var hp_mult := 1.0 + escalation * 0.80
	e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * hp_mult))
	e.hp               = e.max_hp
	e.speed           *= 1.0 + escalation * 0.22
	e.player           = player
	e.base_pos         = base_pos
	e.bullet_container = bullet_container
	e.position         = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	enemy_spawned.emit(e)
