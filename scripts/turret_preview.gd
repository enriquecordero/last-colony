extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color(0.5, 0.52, 0.62, 0.35))
	draw_arc(Vector2.ZERO, 16, 0, TAU, 24, Color(0.72, 0.75, 0.92, 0.80), 2.0)
	draw_line(Vector2.ZERO, Vector2(20, 0), Color(0.72, 0.75, 0.92, 0.60), 5.0)
