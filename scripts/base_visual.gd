extends Node2D

const S := 40.0  # half of 80px

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Platform
	draw_rect(Rect2(-S, -S, S * 2, S * 2), Color(0.18, 0.38, 0.18))
	draw_rect(Rect2(-S, -S, S * 2, S * 2), Color(0.32, 0.62, 0.32), false, 2.5)

	# Corner brackets
	var bc  := Color(0.48, 0.85, 0.48)
	var cl  := 13.0
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			var cx := float(sx) * S
			var cy := float(sy) * S
			draw_line(Vector2(cx, cy), Vector2(cx - float(sx) * cl, cy), bc, 2.5)
			draw_line(Vector2(cx, cy), Vector2(cx, cy - float(sy) * cl), bc, 2.5)

	# Inner cross
	draw_line(Vector2(-S * 0.55, 0), Vector2(S * 0.55, 0), Color(0.28, 0.52, 0.28), 1.5)
	draw_line(Vector2(0, -S * 0.55), Vector2(0, S * 0.55), Color(0.28, 0.52, 0.28), 1.5)

	# Nucleus layers
	draw_circle(Vector2.ZERO, 16, Color(0.08, 0.28, 0.08))
	draw_circle(Vector2.ZERO, 11, Color(0.22, 0.72, 0.28))
	draw_circle(Vector2.ZERO,  6, Color(0.65, 1.00, 0.65))
	draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color(0.38, 0.88, 0.38, 0.5), 2.0)
