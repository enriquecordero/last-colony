extends "res://scripts/larva.gd"

func _ready() -> void:
	max_hp       = 30
	melee_damage = 12
	body_color   = Color(0.95, 0.45, 0.05)
	body_radius  = 9.0
	super._ready()
