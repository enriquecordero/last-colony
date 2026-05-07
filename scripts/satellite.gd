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
	var pulse   := 0.55 + sin(_t * 3.5) * 0.25
	var flicker := sin(_t * 11.0) > 0.55

	# ── Concrete base ────────────────────────────────────────────────────────
	var bw := 84.0
	var bh := 20.0
	var by := 22.0
	draw_rect(Rect2(-bw * 0.5 + 3, by + 3, bw, bh), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(-bw * 0.5, by, bw, bh), Color(0.22, 0.20, 0.17))
	draw_line(Vector2(-bw * 0.5, by), Vector2(bw * 0.5, by), Color(0.36, 0.32, 0.27), 1.5)
	# cracks
	draw_line(Vector2(-22.0, by + 6), Vector2(-6.0,  by + 14), Color(0.10, 0.08, 0.06), 1.0)
	draw_line(Vector2( 14.0, by + 4), Vector2(28.0,  by + 17), Color(0.10, 0.08, 0.06), 1.0)
	# bolts
	for i in 4:
		draw_circle(Vector2(-bw * 0.5 + 12.0 + i * 20.0, by + 5), 2.2, Color(0.38, 0.35, 0.30))

	# ── Tower ────────────────────────────────────────────────────────────────
	var tt := -50.0   # tower top Y
	var tw :=  7.0
	draw_rect(Rect2(-tw * 0.5 + 2, tt + 2, tw, by - tt), Color(0, 0, 0, 0.28))
	draw_rect(Rect2(-tw * 0.5, tt, tw, by - tt), Color(0.28, 0.26, 0.22))
	draw_line(Vector2(-tw * 0.5, tt), Vector2(-tw * 0.5, by), Color(0.42, 0.38, 0.33), 1.5)
	# cross braces
	for i in 3:
		var bry := tt + (by - tt) * float(i + 1) / 4.0
		draw_line(Vector2(-tw * 0.5, bry), Vector2(tw * 0.5, bry), Color(0.38, 0.35, 0.30), 1.5)

	# ── Support cables ───────────────────────────────────────────────────────
	var anchor := Vector2(0, tt + 12)
	draw_line(anchor, Vector2(-32, by), Color(0.30, 0.27, 0.22, 0.85), 1.0)
	draw_line(anchor, Vector2( 32, by), Color(0.30, 0.27, 0.22, 0.85), 1.0)

	# ── Dish arm ─────────────────────────────────────────────────────────────
	var arm_root := Vector2(0,  tt + 6)
	var arm_tip  := Vector2(26, tt - 10)
	draw_line(arm_root, arm_tip, Color(0.35, 0.33, 0.28), 4.5)

	# ── Satellite dish ───────────────────────────────────────────────────────
	var dc  := Vector2(arm_tip.x + 4, arm_tip.y - 3)
	var dr  := 30.0
	var da  := -PI * 0.52
	var dsp := PI * 0.48
	# shadow
	draw_arc(dc + Vector2(2, 3), dr, da - dsp, da + dsp, 24, Color(0, 0, 0, 0.32), 9.0)
	# dish back plate
	draw_arc(dc, dr, da - dsp, da + dsp, 24, Color(0.30, 0.30, 0.32), 9.0)
	# dish face
	draw_arc(dc, dr * 0.88, da - dsp * 0.9, da + dsp * 0.9, 22, Color(0.46, 0.46, 0.50), 4.0)
	# ribs
	for ri in 4:
		var ra  := da - dsp * 0.9 + dsp * 0.6 * float(ri) / 3.0
		var rend := dc + Vector2(cos(ra), sin(ra)) * dr * 0.88
		draw_line(dc, rend, Color(0.52, 0.52, 0.56, 0.65), 1.2)
	# inner highlight
	draw_arc(dc, dr * 0.52, da - dsp * 0.55, da + dsp * 0.55, 14,
			Color(0.62, 0.62, 0.66, 0.5), 1.8)
	# feed arm + horn
	var horn := dc - Vector2(cos(da), sin(da)) * dr * 0.42
	draw_line(arm_tip, horn, Color(0.40, 0.38, 0.33), 2.0)
	draw_circle(horn, 4.5, Color(0.50, 0.78, 1.0, 0.90))
	draw_circle(horn, 2.0, Color(0.85, 0.95, 1.0))

	# ── Warning light ────────────────────────────────────────────────────────
	var wl := Vector2(0, tt - 6)
	if flicker or _activating:
		draw_circle(wl, 5.5, Color(1.0, 0.22, 0.12, 0.85))
		draw_circle(wl, 2.5, Color(1.0, 0.85, 0.80))
	else:
		draw_circle(wl, 4.0, Color(0.42, 0.08, 0.06, 0.70))

	# ── Signal rings ─────────────────────────────────────────────────────────
	var r1 := 58.0 + pulse * 16
	draw_arc(Vector2.ZERO, r1,  0, TAU, 36, Color(0.3, 0.65, 1.0, 0.14 * (1.4 - pulse)), 2.0)
	draw_arc(Vector2.ZERO, 50,  0, TAU, 36, Color(0.45, 0.75, 1.0, 0.35 * pulse),        2.0)

	# ── Activation progress ───────────────────────────────────────────────────
	if _activating:
		var pct := _activate_t / ACTIVATE_TIME
		draw_arc(Vector2.ZERO, 55, -PI * 0.5,
				-PI * 0.5 + TAU * pct, 56, Color(0.2, 1.0, 0.85, 0.95), 4.5)
		var f2 := ThemeDB.fallback_font
		draw_string(f2, Vector2(-22, tt - 20), "ACTIVANDO...",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.85))

	# ── Labels ───────────────────────────────────────────────────────────────
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(-24, by + bh + 14), "SATÉLITE",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.45, 0.80, 1.0, 0.9))
	if not _activating:
		draw_string(f, Vector2(-18, by + bh + 26), "[F] activar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.60, 0.60, 0.60, 0.70))
