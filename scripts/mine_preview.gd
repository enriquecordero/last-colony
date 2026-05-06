extends Node2D

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13, Color(1.0, 0.70, 0.05, 0.55))
	draw_arc(Vector2.ZERO, 13, 0, TAU, 20, Color(1.0, 0.92, 0.3, 0.85), 2.0)
	draw_line(Vector2(-5, -5), Vector2(5, 5),  Color(0.08, 0.04, 0.0, 0.7), 2.0)
	draw_line(Vector2( 5, -5), Vector2(-5, 5), Color(0.08, 0.04, 0.0, 0.7), 2.0)
	draw_arc(Vector2.ZERO, 45, 0, TAU, 24, Color(1.0, 0.55, 0.1, 0.22), 1.0)
