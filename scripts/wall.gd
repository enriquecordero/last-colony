extends StaticBody2D

var hp:     int = 200
var max_hp: int = 200

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 0
	queue_redraw()

func _draw() -> void:
	var t    := float(hp) / float(max_hp)
	var fill := Color(0.32, 0.32, 0.44).lerp(Color(0.55, 0.18, 0.18), 1.0 - t)
	draw_rect(Rect2(-20, -10, 40, 20), fill)
	draw_rect(Rect2(-20, -10, 40, 20), Color(0.55, 0.55, 0.68), false, 2.0)
	# Rivets
	for dx in [-12.0, 0.0, 12.0]:
		draw_circle(Vector2(dx, 0), 2.0, Color(0.65, 0.65, 0.75))
	# HP bar
	if hp < max_hp:
		draw_rect(Rect2(-20, -15, 40, 3), Color(0.1, 0.0, 0.0))
		draw_rect(Rect2(-20, -15, 40.0 * t, 3), Color(0.3, 0.75, 0.3))

func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		queue_free()
