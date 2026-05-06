extends "res://scripts/larva.gd"

func _ready() -> void:
	max_hp       = 400
	melee_damage = 40
	body_color   = Color(0.3, 0.32, 0.38)
	body_radius  = 20.0
	_sprite_tex   = "res://assets/sprites/blindado.png"
	_sprite_scale = 0.82
	super._ready()

func _draw() -> void:
	super._draw()
