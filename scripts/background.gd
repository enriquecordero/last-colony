extends Node2D

var map_w: float = 2400.0
var map_h: float = 1600.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var gc  := Color(0.13, 0.13, 0.26, 0.4)
	var dot := Color(0.18, 0.18, 0.38, 0.5)
	var s   := 80.0

	var x := s
	while x < map_w:
		draw_line(Vector2(x, 0), Vector2(x, map_h), gc, 1.0)
		x += s
	var y := s
	while y < map_h:
		draw_line(Vector2(0, y), Vector2(map_w, y), gc, 1.0)
		y += s

	x = s
	while x < map_w:
		y = s
		while y < map_h:
			draw_circle(Vector2(x, y), 1.5, dot)
			y += s
		x += s

	draw_line(Vector2(map_w * 0.5, 0), Vector2(map_w * 0.5, map_h),
		Color(0.22, 0.48, 0.22, 0.22), 2.0)
	draw_line(Vector2(0, map_h * 0.5), Vector2(map_w, map_h * 0.5),
		Color(0.22, 0.48, 0.22, 0.22), 2.0)

	draw_rect(Rect2(0, 0, map_w, map_h), Color(0.45, 0.20, 0.20, 0.45), false, 4.0)
