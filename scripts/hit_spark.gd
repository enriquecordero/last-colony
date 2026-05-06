extends Node2D

var _color: Color = Color(1.0, 0.95, 0.1)
var _t:     float = 0.0

const LINES := 6

func _process(delta: float) -> void:
	_t += delta * 9.0
	queue_redraw()
	if _t >= 1.0:
		queue_free()

func _draw() -> void:
	var alpha := lerpf(1.0, 0.0, _t)
	for i in LINES:
		var angle  := (TAU / LINES) * i
		var len    := lerpf(9.0, 2.0, _t)
		var origin := Vector2(cos(angle), sin(angle)) * 3.0
		var tip    := Vector2(cos(angle), sin(angle)) * (3.0 + len)
		draw_line(origin, tip, Color(_color.r, _color.g, _color.b, alpha), 1.8)
	# Central dot
	draw_circle(Vector2.ZERO, lerpf(3.5, 0.5, _t),
		Color(1.0, 1.0, 0.9, alpha * 0.9))
