extends Node2D

const DURATION  := 8.0
const RADIUS    := 38.0
const TICK_RATE := 0.5
const DMG_TICK  := 4

var player:  Node2D = null
var _allies: Array  = []
var _t:        float = 0.0
var _tick_cd:  float = 0.0


func _physics_process(delta: float) -> void:
	_t       += delta
	_tick_cd -= delta
	queue_redraw()
	if _tick_cd <= 0.0:
		_tick_cd = TICK_RATE
		_tick_damage()
	if _t >= DURATION:
		queue_free()


func _tick_damage() -> void:
	if is_instance_valid(player) \
			and global_position.distance_to(player.global_position) < RADIUS:
		player.take_damage(DMG_TICK)
	for a in _allies:
		if is_instance_valid(a) and a.has_method("take_damage") \
				and global_position.distance_to(a.global_position) < RADIUS:
			a.take_damage(DMG_TICK)


func _draw() -> void:
	var pct  := minf(_t / DURATION, 1.0)
	var fade := 1.0 - maxf(0.0, (pct - 0.72) / 0.28)

	draw_circle(Vector2.ZERO, RADIUS,        Color(0.38, 0.75, 0.04, fade * 0.52))
	draw_circle(Vector2.ZERO, RADIUS * 0.55, Color(0.60, 1.00, 0.08, fade * 0.70))
	draw_arc(Vector2.ZERO,   RADIUS, 0, TAU, 24, Color(0.70, 1.0, 0.15, fade * 0.80), 2.5)

	for i in 6:
		var a   := _t * 1.6 + i * TAU / 6.0
		var br  := RADIUS * (0.30 + 0.38 * abs(sin(_t * 1.1 + i * 1.3)))
		var bpos := Vector2(cos(a), sin(a)) * br
		draw_circle(bpos, 4.0 * fade, Color(0.80, 1.0, 0.12, fade * 1.1))
		draw_circle(bpos, 1.6 * fade, Color(1.0,  1.0, 0.55, fade * 1.3))

	draw_string(ThemeDB.fallback_font, Vector2(-16, RADIUS + 14), "ÁCIDO",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 1.0, 0.18, fade * 0.7))
