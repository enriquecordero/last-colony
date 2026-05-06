extends "res://scripts/larva.gd"

func _ready() -> void:
	max_hp       = 400
	melee_damage = 40
	body_color   = Color(0.3, 0.32, 0.38)
	body_radius  = 20.0
	super._ready()

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	draw_circle(Vector2(3, 5), r * 1.05, Color(0, 0, 0, 0.32))

	draw_circle(Vector2.ZERO, r * 0.90, c.darkened(0.25))
	draw_circle(d * r * 0.22, r * 0.78, c)

	# Armor plate arcs
	var ac := c.lightened(0.18)
	draw_arc(Vector2.ZERO,    r * 0.82, PI * 0.55, PI * 1.45, 16, ac, 3.5)
	draw_arc(d * r * 0.18,   r * 0.68, -PI * 0.38, PI * 0.38, 12, ac, 4.0)
	draw_arc(-d * r * 0.12,  r * 0.70, PI * 0.65,  PI * 1.35, 12, ac.darkened(0.1), 3.0)

	# Carapace spikes on back
	for i in 3:
		var sp := -d * r * 0.60 + p * r * ((i - 1.0) * 0.42)
		draw_line(sp, sp - d * r * 0.30, c.lightened(0.28), 3.5)

	# Stubby legs (2 pairs)
	for i in 2:
		var base := d * r * ((i - 0.5) * 0.48)
		for s: float in [-1.0, 1.0]:
			var knee := base + p * s * r * 0.72
			var foot := knee + p * s * r * 0.28 + d * r * 0.08
			draw_line(base, knee, c.darkened(0.05), 4.5)
			draw_line(knee, foot, c.darkened(0.20), 3.5)

	# Two massive front claws
	for s: float in [-1.0, 1.0]:
		var root := d * r * 0.72 + p * s * r * 0.30
		var mid  := d * r * 1.18 + p * s * r * 0.58
		var tipA := d * r * 1.50 + p * s * r * 0.32
		var tipB := d * r * 1.35 + p * s * r * 0.78
		draw_line(root, mid,  c.lightened(0.12), 5.5)
		draw_line(mid,  tipA, c.lightened(0.22), 3.8)
		draw_line(mid,  tipB, c.lightened(0.22), 3.8)

	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.68 + p * s * r * 0.20
		draw_circle(ep, 3.8, Color(0.55, 0.78, 1.0, 0.85))
		draw_circle(ep, 1.6, Color(0.0,  0.0,  0.12))

	draw_arc(Vector2.ZERO, r * 0.90, 0, TAU, 32, c.lightened(0.22), 1.8)
