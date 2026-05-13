extends Node2D

signal struck(pos: Vector2, damage: int, radius: float)

const WARNING_TIME := 2.4   # seconds between marker and beam
const BEAM_TIME    := 0.55  # how long the beam visual lingers
const BEAM_RADIUS  := 130.0
const BEAM_DAMAGE  := 600

var target: Vector2 = Vector2.ZERO

var _t:     float = 0.0
var _phase: int   = 0   # 0 = warning, 1 = beam, 2 = done


func _ready() -> void:
	z_index = 12
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _phase == 0 and _t >= WARNING_TIME:
		_phase = 1
		_t     = 0.0
		struck.emit(target, BEAM_DAMAGE, BEAM_RADIUS)
	elif _phase == 1 and _t >= BEAM_TIME:
		queue_free()


func _draw() -> void:
	var p: Vector2 = target - global_position
	if _phase == 0:
		# Pulsing crosshair + countdown ring
		var pulse: float = 0.55 + 0.45 * absf(sin(_t * 9.0))
		var ring_r: float = lerpf(BEAM_RADIUS * 1.6, BEAM_RADIUS, _t / WARNING_TIME)
		draw_arc(p, ring_r, 0.0, TAU, 40,
			Color(1.0, 0.30, 0.30, pulse * 0.85), 3.0)
		draw_arc(p, BEAM_RADIUS, 0.0, TAU, 40,
			Color(1.0, 0.85, 0.30, 0.45), 1.8)
		# Crosshair
		draw_line(p + Vector2(-20, 0), p + Vector2(20, 0),
			Color(1.0, 0.30, 0.30, pulse), 2.0)
		draw_line(p + Vector2(0, -20), p + Vector2(0, 20),
			Color(1.0, 0.30, 0.30, pulse), 2.0)
		# Tick countdown number
		var remaining: float = WARNING_TIME - _t
		var f := ThemeDB.fallback_font
		draw_string(f, p + Vector2(-6, 6), "%.1f" % remaining,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color(1.0, 0.90, 0.40, pulse))
	elif _phase == 1:
		# Beam from sky to target
		var alpha: float = 1.0 - clampf(_t / BEAM_TIME, 0.0, 1.0)
		var top: Vector2 = p + Vector2(0, -1200.0)
		draw_line(top, p, Color(0.55, 0.85, 1.0, alpha * 0.85), 18.0)
		draw_line(top, p, Color(1.0, 1.0, 1.0, alpha), 8.0)
		# Ground impact ring
		draw_circle(p, BEAM_RADIUS * (0.4 + (1.0 - alpha) * 0.6),
			Color(1.0, 0.95, 0.55, alpha * 0.4))
		draw_arc(p, BEAM_RADIUS, 0.0, TAU, 48,
			Color(1.0, 0.95, 0.55, alpha), 4.0)
