extends Node2D

const DURATION  := 5.0
const RADIUS    := 32.0
const TICK_RATE := 0.5
const DMG_TICK  := 3

var player: Node2D = null
var _t:       float = 0.0
var _tick_cd: float = 0.0

func _physics_process(delta: float) -> void:
	_t       += delta
	_tick_cd -= delta
	queue_redraw()
	if _tick_cd <= 0.0:
		_tick_cd = TICK_RATE
		if is_instance_valid(player) and \
				global_position.distance_to(player.global_position) < RADIUS:
			player.take_damage(DMG_TICK)
	if _t >= DURATION:
		queue_free()

func _draw() -> void:
	var pct := 1.0 - _t / DURATION
	draw_circle(Vector2.ZERO, RADIUS, Color(0.10, 0.55, 0.10, 0.28 * pct))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, Color(0.35, 1.0, 0.18, 0.65 * pct), 2.0)
	for i in 6:
		var a  := _t * 1.8 + i * TAU / 6.0
		var br := RADIUS * (0.3 + 0.18 * sin(_t * 2.5 + i * 1.1))
		draw_circle(Vector2(cos(a), sin(a)) * br, 2.0 + sin(_t + i) * 0.8,
				Color(0.5, 1.0, 0.3, 0.55 * pct))
	draw_string(ThemeDB.fallback_font, Vector2(-14, RADIUS + 14), "ÁCIDO",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 1.0, 0.18, 0.6 * pct))
