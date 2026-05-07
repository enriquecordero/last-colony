extends StaticBody2D

signal destroyed

const MAX_HP := 300
const W      := 44.0
const H      := 18.0

var hp:     int = MAX_HP
var max_hp: int = MAX_HP

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 0
	var cs   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(W, H)
	cs.shape  = rect
	add_child(cs)
	queue_redraw()

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	queue_redraw()
	if hp <= 0:
		destroyed.emit()
		queue_free()

func _draw() -> void:
	var pct    := float(hp) / float(MAX_HP)
	var sand   := Color(0.45, 0.38, 0.24)
	var sand_d := Color(0.30, 0.24, 0.14)
	# Bottom row of sandbags
	for i in 4:
		var bx: float = -18.0 + i * 12.0
		draw_circle(Vector2(bx, 4.0),  5.5, sand_d)
	# Top row
	for i in 3:
		var bx: float = -12.0 + i * 12.0
		draw_circle(Vector2(bx, -3.5), 5.2, sand)
	draw_rect(Rect2(-W * 0.5, -H * 0.5, W, H), Color(0.6, 0.5, 0.3, 0.3), false, 1.0)
	# HP bar
	if hp < MAX_HP:
		draw_rect(Rect2(-18.0, -H * 0.5 - 6, 36.0, 3), Color(0.1, 0, 0, 0.85))
		draw_rect(Rect2(-18.0, -H * 0.5 - 6, 36.0 * pct, 3), Color(0.85, 0.65, 0.1))
	draw_string(ThemeDB.fallback_font, Vector2(-24, H * 0.5 + 12), "BARRICADA",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.75, 0.45, 0.8))
