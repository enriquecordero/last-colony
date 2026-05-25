extends Node2D

signal landed(target: Vector2, type: int)

const FALL_TIME := 2.2   # delay before drop arrives

enum Type { SUPPLY, SENTRY, AIRSTRIKE, REINFORCEMENTS }

var target: Vector2 = Vector2.ZERO
var type:   int     = Type.SUPPLY

var _t:     float = 0.0
var _done:  bool  = false


func _ready() -> void:
	z_index = 11
	set_process(true)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	queue_redraw()
	if _t >= FALL_TIME:
		_done = true
		landed.emit(target, type)
		queue_free()


func _draw() -> void:
	if _done:
		return
	var p: Vector2 = target - global_position
	var u: float = clampf(_t / FALL_TIME, 0.0, 1.0)
	var c: Color = _type_color()

	# Falling pod (small circle that moves down from sky)
	var pod_y: float = lerpf(-700.0, 0.0, u)
	var pod_pos: Vector2 = p + Vector2(0, pod_y)
	draw_circle(pod_pos, 7.0, c)
	draw_arc(pod_pos, 7.0, 0.0, TAU, 12, c.lightened(0.4), 1.5)
	# Tail / smoke trail
	for i in 5:
		var tail_y: float = pod_y - (i + 1) * 14.0
		var fade: float = 1.0 - float(i) / 5.0
		draw_circle(p + Vector2(randf_range(-2, 2), tail_y),
			3.5 - i * 0.4,
			Color(c.r, c.g, c.b, fade * 0.55))

	# Ground beacon marker (pulses)
	var pulse: float = 0.5 + 0.5 * absf(sin(_t * 8.0))
	draw_arc(p, 32.0, 0.0, TAU, 32,
		Color(c.r, c.g, c.b, pulse * 0.85), 3.0)
	draw_line(p + Vector2(-16, 0), p + Vector2(16, 0),
		Color(c.r, c.g, c.b, pulse), 2.0)
	draw_line(p + Vector2(0, -16), p + Vector2(0, 16),
		Color(c.r, c.g, c.b, pulse), 2.0)


func _type_color() -> Color:
	match type:
		Type.SUPPLY:         return Color(1.0, 0.85, 0.30)
		Type.SENTRY:         return Color(0.55, 0.85, 1.0)
		Type.AIRSTRIKE:      return Color(1.0, 0.40, 0.20)
		Type.REINFORCEMENTS: return Color(0.45, 1.0, 0.55)
	return Color.WHITE
