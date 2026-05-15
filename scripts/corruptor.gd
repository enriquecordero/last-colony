extends "res://scripts/larva.gd"

# Aerial enemy — slow, bloated, leaves an acid pool on death.
var spawns_acid: bool = true

func _ready() -> void:
	_is_aerial   = true
	max_hp       = 500
	is_armored   = true
	melee_damage = 12
	body_color   = Color(0.52, 0.85, 0.12)
	body_radius  = 14.0
	speed        = 42.0
	super._ready()
	collision_mask = 0


func _update_target() -> void:
	if is_instance_valid(player):
		_current_target = player.global_position
	else:
		_current_target = base_pos


func _draw_body() -> void:
	var d := _draw_dir
	var r := body_radius
	var c := body_color
	var p := Vector2(-d.y, d.x)

	# Shadow
	draw_circle(Vector2(0, 4), r * 1.15, Color(0, 0, 0, 0.28))

	# Wide semi-transparent wings
	var wspan := r * 2.8
	var wback := -d * r * 0.55
	draw_colored_polygon(PackedVector2Array([
		wback + p * wspan, wback, d * r * 0.35
	]), Color(c.r, c.g, c.b, 0.30))
	draw_colored_polygon(PackedVector2Array([
		wback - p * wspan, wback, d * r * 0.35
	]), Color(c.r, c.g, c.b, 0.30))
	draw_line(wback + p * wspan, d * r * 0.35, c.lightened(0.20), 1.2)
	draw_line(wback - p * wspan, d * r * 0.35, c.lightened(0.20), 1.2)

	# Swollen body
	draw_circle(Vector2.ZERO, r,        c.darkened(0.28))
	draw_circle(Vector2.ZERO, r * 0.82, c)

	# Acid sacs — three glowing bubbles
	for i in 3:
		var a  := TAU * i / 3.0 + PI * 0.3
		var bp := Vector2(cos(a), sin(a)) * r * 0.40
		draw_circle(bp, r * 0.22, Color(0.80, 1.0, 0.08, 0.80))
		draw_circle(bp, r * 0.10, Color(1.0,  1.0, 0.40, 0.95))

	# Eyes
	for s: float in [-1.0, 1.0]:
		var ep := d * r * 0.58 + p * s * r * 0.30
		draw_circle(ep, 3.5, Color(0.90, 1.0, 0.0, 0.92))
		draw_circle(ep, 1.5, Color(0.0,  0.0, 0.0))

	# Drool strands
	for s: float in [-1.0, 1.0]:
		draw_line(d * r * 0.90 + p * s * r * 0.20,
		          d * r * 1.30 + p * s * r * 0.28,
		          Color(0.68, 1.0, 0.10, 0.70), 2.0)

	draw_arc(Vector2.ZERO, r, 0, TAU, 22, c.lightened(0.32), 1.5)
