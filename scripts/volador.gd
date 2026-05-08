extends "res://scripts/larva.gd"

func _ready() -> void:
	_is_aerial   = true
	max_hp       = 30
	melee_damage = 8
	body_color   = Color(0.60, 0.08, 0.90)
	body_radius  = 9.0
	speed        = 195.0
	super._ready()
	collision_mask = 0  # vuela sobre todo, daño por proximidad igual funciona

func _update_target() -> void:
	# Línea directa al jugador siempre — ignora puertas y paredes
	if is_instance_valid(player):
		_current_target = player.global_position
	else:
		_current_target = base_pos

func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	# Alas (triángulos semitransparentes)
	var wspan := r * 2.2
	var wback := -d * r * 0.6
	draw_colored_polygon(PackedVector2Array([
		wback + p * wspan, wback, d * r * 0.4
	]), Color(c.r, c.g, c.b, 0.50))
	draw_colored_polygon(PackedVector2Array([
		wback - p * wspan, wback, d * r * 0.4
	]), Color(c.r, c.g, c.b, 0.50))
	draw_line(wback + p * wspan, d * r * 0.4, c.lightened(0.25), 1.0)
	draw_line(wback - p * wspan, d * r * 0.4, c.lightened(0.25), 1.0)

	# Cuerpo
	draw_circle(d * 1.5 + Vector2(0, 2), r * 0.9, Color(0, 0, 0, 0.22))
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(d * r * 0.45, r * 0.58, c.lightened(0.18))

	# Ojos
	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.55 + p * s * r * 0.28
		draw_circle(ep, 2.2, Color(1.0, 0.15, 0.05))
		draw_circle(ep, 0.9, Color(0.0,  0.0,  0.0))

	# Cola
	draw_line(-d * r, -d * r * 1.8, c.darkened(0.25), 2.0)

	draw_arc(Vector2.ZERO, r, 0, TAU, 20, c.lightened(0.30), 1.0)
