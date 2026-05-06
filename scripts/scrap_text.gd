extends Node2D

var amount: int   = 1
var _t:     float = 0.0

func _process(delta: float) -> void:
	_t          += delta
	position.y  -= 28.0 * delta
	queue_redraw()
	if _t >= 0.7:
		queue_free()

func _draw() -> void:
	var alpha := maxf(0.0, 1.0 - _t / 0.7)
	draw_string(ThemeDB.fallback_font, Vector2(-10, 0),
		"+%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.3, 1.0, 0.55, alpha))
