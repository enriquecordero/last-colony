extends Node2D

signal activated(sat: Node)

const ACTIVATE_TIME := 3.0
const RADIUS        := 20.0

var _activating: bool  = false
var _activate_t: float = 0.0
var _t:          float = 0.0

func _physics_process(delta: float) -> void:
	_t += delta
	if _activating:
		_activate_t += delta
		if _activate_t >= ACTIVATE_TIME:
			activated.emit(self)
			queue_free()
			return
	queue_redraw()

func start_activating() -> void:
	_activating = true
	_activate_t = 0.0

func is_activating() -> bool:
	return _activating

func _draw() -> void:
	var pulse := 0.55 + sin(_t * 3.5) * 0.25

	# Tower stem
	draw_rect(Rect2(-3, -RADIUS, 6, RADIUS * 2), Color(0.35, 0.45, 0.65))
	draw_rect(Rect2(-RADIUS * 0.55, -3, RADIUS * 1.1, 6), Color(0.35, 0.45, 0.65))

	# Dish arc
	draw_arc(Vector2(0, -RADIUS * 0.3), RADIUS * 0.65, -PI * 0.85, -PI * 0.15, 20,
		Color(0.55, 0.80, 1.0), 2.5)
	draw_circle(Vector2(0, -RADIUS * 0.3), 3.5, Color(0.55, 0.80, 1.0))

	# Pulse rings
	var r1 := RADIUS + 10 + pulse * 12
	draw_arc(Vector2.ZERO, r1, 0, TAU, 28,
		Color(0.3, 0.65, 1.0, 0.2 * (1.3 - pulse)), 2.0)
	draw_arc(Vector2.ZERO, RADIUS + 5, 0, TAU, 28,
		Color(0.45, 0.75, 1.0, 0.55 * pulse), 2.0)

	# Activation progress arc
	if _activating:
		var pct := _activate_t / ACTIVATE_TIME
		draw_arc(Vector2.ZERO, RADIUS + 9, -PI / 2.0,
			-PI / 2.0 + TAU * pct, 48, Color(0.2, 1.0, 0.85, 0.95), 4.0)
		var f2 := ThemeDB.fallback_font
		draw_string(f2, Vector2(-20, -RADIUS - 14), "ACTIVANDO...",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.85))

	# Labels
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-24, RADIUS + 16), "SATÉLITE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.45, 0.80, 1.0, 0.9))
	if not _activating:
		draw_string(f, Vector2(-18, RADIUS + 28), "[F] activar",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6, 0.7))
