extends Node2D

signal collected(cache: Node)

const RADIUS := 13.0

var _t: float = 0.0

func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()

func collect() -> void:
	collected.emit(self)
	queue_free()

func _draw() -> void:
	var bob   := sin(_t * 2.5) * 3.0
	var pulse := 0.65 + sin(_t * 3.2) * 0.25

	var offset := Vector2(0, bob)

	# Outer glow
	draw_circle(offset, RADIUS + 5, Color(0.25, 0.55, 0.95, 0.18 * pulse))

	# Data pad body
	draw_rect(Rect2(-RADIUS + offset.x, -RADIUS + offset.y, RADIUS * 2, RADIUS * 2),
		Color(0.10, 0.16, 0.28))
	draw_rect(Rect2(-RADIUS + offset.x, -RADIUS + offset.y, RADIUS * 2, RADIUS * 2),
		Color(0.35, 0.65, 1.0, pulse), false, 2.0)

	# Screen lines (circuit pattern)
	var cx := offset.x
	var cy := offset.y
	draw_line(Vector2(cx - 7, cy), Vector2(cx + 7, cy), Color(0.4, 0.8, 1.0, pulse), 1.5)
	draw_line(Vector2(cx, cy - 7), Vector2(cx, cy + 7), Color(0.4, 0.8, 1.0, pulse), 1.5)
	draw_line(Vector2(cx - 5, cy - 5), Vector2(cx - 5, cy), Color(0.4, 0.8, 1.0, pulse * 0.7), 1.0)
	draw_line(Vector2(cx + 5, cy + 5), Vector2(cx + 5, cy), Color(0.4, 0.8, 1.0, pulse * 0.7), 1.0)
	draw_circle(offset, 3.0, Color(0.5, 0.9, 1.0, pulse))

	# Labels
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-30, RADIUS + bob + 14), "INVESTIGACIÓN",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.75, 1.0, 0.9))
	draw_string(f, Vector2(-18, RADIUS + bob + 26), "[F] recoger",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6, 0.7))
