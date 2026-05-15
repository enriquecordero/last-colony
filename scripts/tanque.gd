extends "res://scripts/blindado.gd"

func _ready() -> void:
	max_hp       = 2400
	melee_damage = 80
	body_color   = Color(0.20, 0.28, 0.15)
	body_radius  = 26.0
	speed        = 28.0
	is_armored   = true
	_charge_cd   = 99999.0  # nunca carga
	super._ready()

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	# Sombra masiva
	draw_circle(d * 3 + Vector2(0, 6), r * 1.1, Color(0, 0, 0, 0.35))

	# Cuerpo principal
	draw_circle(Vector2.ZERO, r, c.darkened(0.30))
	draw_circle(Vector2.ZERO, r * 0.88, c)

	# Placas de blindaje frontales
	var ac := c.lightened(0.22)
	draw_arc(d * r * 0.10, r * 0.75, -PI * 0.45, PI * 0.45, 14, ac, 6.0)
	draw_arc(d * r * 0.25, r * 0.55, -PI * 0.38, PI * 0.38, 12, ac.lightened(0.1), 5.0)

	# Placas laterales
	for s: float in [-1.0, 1.0]:
		draw_arc(p * s * r * 0.50, r * 0.52, -PI * 0.6 * s, PI * 0.6 * s, 12,
			ac.darkened(0.05), 4.0)

	# Pinzas enormes
	for s: float in [-1.0, 1.0]:
		var root := d * r * 0.75 + p * s * r * 0.28
		var mid  := d * r * 1.25 + p * s * r * 0.55
		var tipA := d * r * 1.65 + p * s * r * 0.25
		var tipB := d * r * 1.48 + p * s * r * 0.78
		draw_line(root, mid,  c.lightened(0.15), 7.0)
		draw_line(mid,  tipA, c.lightened(0.28), 5.0)
		draw_line(mid,  tipB, c.lightened(0.28), 5.0)

	# Patas cortas y gruesas
	for i in 3:
		var base := d * r * ((i - 1.0) * 0.40)
		for s: float in [-1.0, 1.0]:
			var knee := base + p * s * r * 0.80
			var foot := knee + p * s * r * 0.22 + d * r * 0.06
			draw_line(base, knee, c.darkened(0.08), 5.5)
			draw_line(knee, foot, c.darkened(0.22), 4.0)

	# Ojos pequeños pero intensos
	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.65 + p * s * r * 0.22
		draw_circle(ep, 4.5, Color(0.85, 0.92, 0.28, 0.90))
		draw_circle(ep, 2.0, Color(0.0,  0.0,  0.0))

	draw_arc(Vector2.ZERO, r * 0.90, 0, TAU, 36, c.lightened(0.18), 2.0)
