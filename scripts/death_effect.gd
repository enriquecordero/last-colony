extends Node2D

var _color: Color = Color(0.85, 0.1, 0.1)
var _t:     float = 0.0

func _process(delta: float) -> void:
	_t = minf(_t + delta * 2.8, 1.0)
	queue_redraw()
	if _t >= 1.0:
		queue_free()

func _draw() -> void:
	var r := lerpf(4.0, 28.0, _t)
	var c := Color(_color.r, _color.g, _color.b, lerpf(0.85, 0.0, _t))
	draw_circle(Vector2.ZERO, r, c)
