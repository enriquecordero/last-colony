extends "res://scripts/larva.gd"

var is_excavador: bool = true  # main.gd lo usa para spawn interior

func _ready() -> void:
	max_hp       = 65
	melee_damage = 18
	body_color   = Color(0.45, 0.18, 0.58)
	body_radius  = 14.0
	speed        = 88.0
	super._ready()
	# Animación de emergencia desde el suelo
	scale    = Vector2(0.05, 0.05)
	modulate = Color(0.5, 0.1, 0.7)
	var tw := create_tween()
	tw.tween_property(self, "scale",    Vector2.ONE,   0.45).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 0.45)

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	# Sombra
	draw_circle(d * 2 + Vector2(0, 3), r * 0.95, Color(0, 0, 0, 0.28))

	# Cuerpo
	draw_circle(Vector2.ZERO, r, c.darkened(0.20))
	draw_circle(Vector2.ZERO, r * 0.82, c)

	# Patrón de "tierra" en el lomo
	for i in 4:
		var ang := TAU * i / 4.0 + PI * 0.25
		draw_circle(Vector2(cos(ang), sin(ang)) * r * 0.52, r * 0.12,
			c.darkened(0.35))

	# Garras excavadoras (delanteras, grandes)
	for s: float in [-1.0, 1.0]:
		var root := d * r * 0.65 + p * s * r * 0.22
		var claw1 := d * r * 1.20 + p * s * r * 0.12
		var claw2 := d * r * 1.10 + p * s * r * 0.55
		var claw3 := d * r * 1.30 + p * s * r * 0.35
		draw_line(root, claw1, c.lightened(0.20), 4.5)
		draw_line(claw1, claw2, c.lightened(0.30), 3.0)
		draw_line(claw1, claw3, c.lightened(0.30), 3.0)

	# Patas laterales de excavación
	for i in 3:
		var base := d * r * ((i - 1.0) * 0.45)
		for s: float in [-1.0, 1.0]:
			var tip := base + p * s * r * 0.90 - d * r * 0.15
			draw_line(base, tip, c.darkened(0.05), 3.0)

	# Ojos (brillan en la oscuridad)
	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.58 + p * s * r * 0.26
		draw_circle(ep, 3.2, Color(0.90, 0.45, 1.0, 0.95))
		draw_circle(ep, 1.4, Color(0.0,  0.0,  0.0))

	draw_arc(Vector2.ZERO, r, 0, TAU, 26, c.lightened(0.28), 1.2)
