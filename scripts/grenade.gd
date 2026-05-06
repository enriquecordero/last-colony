extends Node2D

signal exploded(pos: Vector2)

const SPEED    := 420.0
const MAX_TIME := 3.5

var target:  Vector2 = Vector2.ZERO
var _t:      float   = 0.0
var _spin:   float   = 0.0

func _physics_process(delta: float) -> void:
	_t    += delta
	_spin += delta * 9.0
	var to_t := target - global_position
	if to_t.length() < SPEED * delta or _t >= MAX_TIME:
		global_position = target
		exploded.emit(global_position)
		queue_free()
		return
	global_position += to_t.normalized() * SPEED * delta
	queue_redraw()

func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, 5.5, Color(0.55, 0.70, 0.20))
	draw_arc(Vector2.ZERO, 5.5, _spin, _spin + TAU * 0.65, 10,
		Color(0.90, 0.95, 0.30, 0.95), 2.0)
	# Fuse spark
	var fuse_tip := Vector2(cos(_spin * 0.4), sin(_spin * 0.4)) * 7.0
	draw_line(Vector2.ZERO, fuse_tip, Color(1.0, 0.85, 0.1, 0.7), 1.5)
	draw_circle(fuse_tip, 2.0, Color(1.0, 0.55, 0.0, 0.9))
