extends "res://scripts/larva.gd"

func _ready() -> void:
	max_hp       = 90
	melee_damage = 12
	body_color   = Color(0.95, 0.45, 0.05)
	body_radius  = 9.0
	super._ready()

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	draw_circle(Vector2(1, 2.5), r * 0.90, Color(0, 0, 0, 0.25))

	draw_circle(-d * r * 0.65, r * 0.82, c.darkened(0.15))
	draw_circle(Vector2.ZERO,   r * 0.70, c)
	draw_circle(d  * r * 0.62,  r * 0.50, c.lightened(0.12))

	# Massive rear jumping legs
	for s: float in [-1.0, 1.0]:
		var hip  := -d * r * 0.45 + p * s * r * 0.30
		var knee := -d * r * 0.02 + p * s * r * 1.25
		var foot := -d * r * 0.68 + p * s * r * 0.95
		draw_line(hip,  knee, c.darkened(0.05), 3.2)
		draw_line(knee, foot, c.darkened(0.25), 2.4)

	# Small front claws
	for s: float in [-1.0, 1.0]:
		draw_line(d * r * 0.48 + p * s * r * 0.20,
		          d * r * 1.05 + p * s * r * 0.52,
		          c.lightened(0.18), 1.8)

	draw_line(-d * r * 0.08 - p * r * 0.45, -d * r * 0.08 + p * r * 0.45, c.darkened(0.40), 1.2)

	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.64 + p * s * r * 0.24
		draw_circle(ep, 2.0, Color(1.0, 0.75, 0.0))
		draw_circle(ep, 0.9, Color(0.0,  0.0,  0.0))

	draw_arc(Vector2.ZERO, r, 0, TAU, 20, c.lightened(0.35), 1.2)
