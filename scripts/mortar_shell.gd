extends Node2D

signal exploded(pos: Vector2, damage: int, radius: float)

const FLIGHT_TIME := 1.4

var start_pos:    Vector2 = Vector2.ZERO
var target_pos:   Vector2 = Vector2.ZERO
var damage:       int     = 80
var radius:       float   = 110.0

var _t:    float = 0.0
var _done: bool  = false


func _ready() -> void:
	start_pos       = global_position
	z_index         = 8
	set_process(true)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var u: float = clampf(_t / FLIGHT_TIME, 0.0, 1.0)
	# Lateral interpolation
	var pos: Vector2 = start_pos.lerp(target_pos, u)
	# Arc — peak at u=0.5, height proportional to distance
	var dist: float  = start_pos.distance_to(target_pos)
	var peak: float  = clampf(dist * 0.25, 60.0, 240.0)
	var arc_y: float = -peak * 4.0 * u * (1.0 - u)
	global_position  = pos + Vector2(0, arc_y)
	queue_redraw()
	if u >= 1.0:
		_explode()


func _explode() -> void:
	if _done:
		return
	_done = true
	global_position = target_pos
	exploded.emit(target_pos, damage, radius)
	queue_free()


func _draw() -> void:
	if _done:
		return
	draw_circle(Vector2.ZERO, 6.0, Color(0.20, 0.18, 0.16))
	draw_circle(Vector2.ZERO, 4.0, Color(0.55, 0.45, 0.30))
	# Shadow on ground (offset by arc_y inverse for fake depth)
	var below: Vector2 = Vector2(0, 8.0)
	draw_circle(below, 4.5, Color(0, 0, 0, 0.35))
