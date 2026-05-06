extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-20, -10, 40, 20), Color(0.5, 0.5, 0.75, 0.38))
	draw_rect(Rect2(-20, -10, 40, 20), Color(0.7, 0.7, 1.0, 0.75), false, 2.0)
