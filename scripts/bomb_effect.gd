extends Node2D

var max_r:    float = 820.0
var tint:     Color = Color(1.0, 0.50, 0.10)

var _t:       float = 0.0
const DURATION := 0.85

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= DURATION:
		queue_free()

func _draw() -> void:
	var p     := _t / DURATION
	var r     := p * max_r
	var alpha := 1.0 - p
	draw_arc(Vector2.ZERO, r,        0, TAU, 72, Color(tint.r, tint.g, tint.b, alpha * 0.88), 6.0)
	draw_arc(Vector2.ZERO, r * 0.65, 0, TAU, 56, Color(tint.r * 1.0, tint.g * 1.6, tint.b * 2.5, alpha * 0.55).clamp(), 3.5)
	draw_arc(Vector2.ZERO, r * 0.35, 0, TAU, 40, Color(1.0, 1.00, 0.55, alpha * 0.35), 2.0)
	if p < 0.25:
		var core_a := (0.25 - p) / 0.25
		draw_circle(Vector2.ZERO, r * 0.2 + 22.0, Color(1.0, 0.95, 0.60, core_a * 0.40))
