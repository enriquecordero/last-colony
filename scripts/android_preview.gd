extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12, Color(0.30, 0.50, 0.75, 0.35))
	draw_arc(Vector2.ZERO, 12, 0, TAU, 24, Color(0.50, 0.78, 1.0, 0.80), 2.0)
