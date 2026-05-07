extends Node2D

func _draw() -> void:
	var sand   := Color(0.45, 0.38, 0.24, 0.55)
	var sand_d := Color(0.30, 0.24, 0.14, 0.55)
	for i in 4:
		var bx: float = -18.0 + i * 12.0
		draw_circle(Vector2(bx, 4.0),  5.5, sand_d)
	for i in 3:
		var bx: float = -12.0 + i * 12.0
		draw_circle(Vector2(bx, -3.5), 5.2, sand)
	draw_rect(Rect2(-22.0, -9.0, 44.0, 18.0), Color(0.7, 0.6, 0.35, 0.35), false, 1.0)
