extends Node2D

signal completed(event_type: int)
signal failed(event_type: int)

enum Type { GENERATOR, SUPPLY, DOWNED_SOLDIER }

const RADIUS_INTERACT := 56.0
const DURATION        := 32.0
const HOLD_TIME       := 1.8   # seconds player must hold F adjacent

var type: int = Type.GENERATOR
var label: String = ""
var color: Color = Color(0.85, 0.95, 0.55)

var _t:        float = DURATION
var _hold_t:   float = 0.0
var _pulse:    float = 0.0
var _player:   Node2D = null
var _done:     bool = false


func _ready() -> void:
	z_index = 6
	set_process(true)


func setup(t: int, p: Node2D) -> void:
	type    = t
	_player = p
	match t:
		Type.GENERATOR:
			label = "REPARAR GENERADOR"
			color = Color(0.30, 0.90, 1.00)
		Type.SUPPLY:
			label = "RECOGER SUMINISTROS"
			color = Color(1.00, 0.80, 0.20)
		Type.DOWNED_SOLDIER:
			label = "RESCATAR SOLDADO"
			color = Color(0.30, 1.00, 0.55)


func _process(delta: float) -> void:
	if _done:
		return
	_t     -= delta
	_pulse += delta * 5.0
	if _t <= 0.0:
		_done = true
		failed.emit(type)
		queue_free()
		return

	if is_instance_valid(_player) and \
			global_position.distance_to(_player.global_position) <= RADIUS_INTERACT \
			and Input.is_key_pressed(KEY_F):
		_hold_t += delta
		if _hold_t >= HOLD_TIME:
			_done = true
			completed.emit(type)
			queue_free()
			return
	else:
		_hold_t = maxf(0.0, _hold_t - delta * 1.5)

	queue_redraw()


func _draw() -> void:
	# Outer interact ring (pulsing)
	var pulse_a: float = 0.45 + 0.45 * absf(sin(_pulse))
	draw_arc(Vector2.ZERO, RADIUS_INTERACT, 0.0, TAU, 40,
		Color(color.r, color.g, color.b, pulse_a * 0.55), 2.5)
	# Timer ring
	var pct: float = clampf(_t / DURATION, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 26.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 40,
		color, 4.0)
	# Hold-progress fill
	if _hold_t > 0.0:
		var hpct: float = clampf(_hold_t / HOLD_TIME, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 18.0, -PI * 0.5, -PI * 0.5 + TAU * hpct, 32,
			Color(1.0, 1.0, 1.0, 0.85), 3.0)
	# Icon (simple per-type glyph)
	match type:
		Type.GENERATOR:
			draw_line(Vector2(-7, -6), Vector2(2, -1), color.lightened(0.2), 3.0)
			draw_line(Vector2(2, -1),  Vector2(-3, 1), color.lightened(0.2), 3.0)
			draw_line(Vector2(-3, 1),  Vector2(7,  6), color.lightened(0.2), 3.0)
		Type.SUPPLY:
			draw_rect(Rect2(-9, -9, 18, 18), color, false, 2.5)
			draw_line(Vector2(-9, 0), Vector2(9, 0), color, 1.5)
			draw_line(Vector2(0, -9), Vector2(0, 9), color, 1.5)
		Type.DOWNED_SOLDIER:
			draw_circle(Vector2(0, -4), 5.0, color)
			draw_rect(Rect2(-4, 0, 8, 8), color)
	# Label
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-58, -RADIUS_INTERACT - 8), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
	# Countdown number
	draw_string(f, Vector2(-10, RADIUS_INTERACT + 16), "%ds" % int(ceil(_t)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.40, 0.85))
