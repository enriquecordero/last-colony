extends Node2D

signal exploded(pos: Vector2)

const SPEED    := 420.0
const MAX_TIME := 2.2

var direction: Vector2 = Vector2.RIGHT
var _t:        float   = 0.0
var _done:     bool    = false

func _physics_process(delta: float) -> void:
	if _done: return
	_t              += delta
	global_position += direction * SPEED * delta
	queue_redraw()
	if _t >= MAX_TIME:
		_do_explode()

func _do_explode() -> void:
	if _done: return
	_done = true
	exploded.emit(global_position)
	queue_free()

func _draw() -> void:
	if _done: return
	for i in 5:
		draw_circle(-direction * (8.0 + i * 7.0),
				maxf(3.5 - i * 0.55, 0.5),
				Color(1.0, 0.55 - i * 0.08, 0.1, 0.5 - i * 0.09))
	draw_circle(Vector2.ZERO, 5.5, Color(0.72, 0.70, 0.76))
	draw_arc(Vector2.ZERO, 5.5, 0, TAU, 12, Color(0.88, 0.86, 0.90), 1.2)
	draw_circle(direction * 5.5, 3.8, Color(1.0, 0.45, 0.15))
	draw_circle(direction * 6.5, 2.0, Color(1.0, 0.90, 0.40))
