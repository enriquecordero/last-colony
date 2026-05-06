extends Area2D

const DAMAGE  := 85
const SHAPE_R := 45.0

var body_color := Color(1.0, 0.70, 0.05)

var _triggered := false

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	var sh := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = SHAPE_R
	sh.shape  = cs
	add_child(sh)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13, body_color)
	draw_arc(Vector2.ZERO, 13, 0, TAU, 20, Color(0.95, 0.95, 0.3), 2.0)
	draw_line(Vector2(-6, -6), Vector2(6, 6),  Color(0.08, 0.04, 0.0), 2.5)
	draw_line(Vector2( 6, -6), Vector2(-6, 6), Color(0.08, 0.04, 0.0), 2.5)

func _on_body_entered(_body: Node) -> void:
	if _triggered:
		return
	_triggered = true
	_blast()

func _blast() -> void:
	for b in get_overlapping_bodies():
		if is_instance_valid(b) and b.has_method("take_damage"):
			b.take_damage(DAMAGE)
	_spawn_ring()
	queue_free()

func _spawn_ring() -> void:
	var ef := _Ring.new()
	ef.position = global_position
	get_parent().add_child(ef)

class _Ring extends Node2D:
	var _r     := 8.0
	var _alpha := 1.0
	func _ready() -> void:
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: _r = v; queue_redraw(),     8.0, 82.0, 0.38)
		tw.parallel().tween_method(func(v: float) -> void: _alpha = v; queue_redraw(), 1.0, 0.0, 0.38)
		tw.tween_callback(queue_free)
	func _draw() -> void:
		draw_circle(Vector2.ZERO, _r, Color(1.0, 0.52, 0.08, _alpha * 0.45))
		draw_arc(Vector2.ZERO, _r, 0, TAU, 32, Color(1.0, 0.88, 0.3, _alpha), 3.0)
