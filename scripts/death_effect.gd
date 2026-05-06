extends Node2D

var _color:   Color = Color(0.85, 0.1, 0.1)
var _scale_f: float = 1.0   # 1=larva, 2=blindado, 3=boss

const SPARKS := 12
var _particles: Array = []
var _t: float = 0.0

func _ready() -> void:
	for i in SPARKS:
		var angle := randf() * TAU
		var speed := randf_range(70.0, 220.0) * _scale_f
		_particles.append({
			"pos":  Vector2.ZERO,
			"vel":  Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(2.5, 5.5) * _scale_f,
			"life": randf_range(0.25, 0.55),
		})

func _process(delta: float) -> void:
	_t += delta
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"]  = p["vel"].lerp(Vector2.ZERO, delta * 5.5)
	queue_redraw()
	if _t > 0.65:
		queue_free()

func _draw() -> void:
	# Ring flash
	var ring_pct := minf(_t / 0.18, 1.0)
	var ring_r   := lerpf(3.0, 38.0 * _scale_f, ring_pct)
	var ring_a   := lerpf(1.0, 0.0, ring_pct)
	draw_arc(Vector2.ZERO, ring_r, 0, TAU, 28,
		Color(_color.r, _color.g, _color.b, ring_a), 3.5 * _scale_f)

	# Core white flash
	if _t < 0.08:
		var fa := lerpf(1.0, 0.0, _t / 0.08)
		draw_circle(Vector2.ZERO, 12.0 * _scale_f, Color(1.0, 1.0, 0.9, fa))

	# Flying sparks
	for p in _particles:
		var age: float = minf(_t / float(p["life"]), 1.0)
		var a   := lerpf(0.95, 0.0, age)
		if a <= 0.0:
			continue
		draw_circle(p["pos"], p["size"] * (1.0 - age * 0.5),
			Color(_color.r, _color.g, _color.b, a))
