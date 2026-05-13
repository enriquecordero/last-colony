extends StaticBody2D

const WARN_THRESHOLD := 0.30

var hp:     int = 200
var max_hp: int = 200

var _hit_t:   float = 0.0   # flash on impact
var _warn_t:  float = 0.0   # pulse when below threshold
var _shake_x: float = 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 0
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	var redraw := false
	if _hit_t > 0.0:
		_hit_t = maxf(0.0, _hit_t - delta * 4.0)
		redraw = true
	if _shake_x != 0.0:
		_shake_x = lerpf(_shake_x, 0.0, delta * 12.0)
		if absf(_shake_x) < 0.1:
			_shake_x = 0.0
		redraw = true
	if float(hp) / float(max_hp) < WARN_THRESHOLD and hp > 0:
		_warn_t += delta * 6.5
		redraw = true
	if redraw:
		queue_redraw()

func _draw() -> void:
	var t: float    = float(hp) / float(max_hp)
	var fill: Color = Color(0.32, 0.32, 0.44).lerp(Color(0.55, 0.18, 0.18), 1.0 - t)
	if _hit_t > 0.0:
		fill = fill.lerp(Color(1.0, 0.85, 0.55), _hit_t * 0.7)
	var ox: float = _shake_x

	draw_rect(Rect2(-20 + ox, -10, 40, 20), fill)
	draw_rect(Rect2(-20 + ox, -10, 40, 20), Color(0.55, 0.55, 0.68), false, 2.0)
	for dx in [-12.0, 0.0, 12.0]:
		draw_circle(Vector2(dx + ox, 0), 2.0, Color(0.65, 0.65, 0.75))

	# Critical warning: pulsing red border + smoke puff
	if t < WARN_THRESHOLD and hp > 0:
		var pulse: float = 0.55 + 0.45 * absf(sin(_warn_t))
		draw_rect(Rect2(-22 + ox, -12, 44, 24),
			Color(1.0, 0.20, 0.10, pulse * 0.85), false, 2.5)
		var smoke_y: float = -14.0 - sin(_warn_t * 0.7) * 3.0
		draw_circle(Vector2(-6 + ox, smoke_y), 3.5, Color(0.55, 0.35, 0.25, 0.45 * pulse))
		draw_circle(Vector2( 8 + ox, smoke_y - 2.0), 2.8, Color(0.55, 0.35, 0.25, 0.35 * pulse))

	# HP bar
	if hp < max_hp:
		draw_rect(Rect2(-20 + ox, -15, 40, 3), Color(0.1, 0.0, 0.0))
		var bar_col: Color = Color(0.3, 0.75, 0.3)
		if t < WARN_THRESHOLD:
			bar_col = Color(1.0, 0.25, 0.10)
		elif t < 0.6:
			bar_col = Color(0.95, 0.75, 0.20)
		draw_rect(Rect2(-20 + ox, -15, 40.0 * t, 3), bar_col)

func take_damage(amount: int) -> void:
	hp -= amount
	_hit_t   = 1.0
	_shake_x = randf_range(-2.5, 2.5)
	queue_redraw()
	if hp <= 0:
		# Small dust burst on destruction would be nice but main spawns death effects
		queue_free()
