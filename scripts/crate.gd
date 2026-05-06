extends Area2D

signal picked_up(crate_type: int, crate_pos: Vector2)

enum Type { BIOMASA, MEDKIT, BOMB }

const HALF  := 18.0
const GLOW  := 28.0

var type: Type  = Type.BIOMASA
var _t:   float = 0.0

func _ready() -> void:
	var shape  := RectangleShape2D.new()
	shape.size = Vector2(HALF * 2.2, HALF * 2.2)
	var col    := CollisionShape2D.new()
	col.shape  = shape
	add_child(col)
	collision_layer = 0
	collision_mask  = 1
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _color() -> Color:
	match type:
		Type.BOMB:   return Color(1.00, 0.35, 0.10)
		Type.MEDKIT: return Color(0.20, 1.00, 0.50)
		_:           return Color(0.10, 0.85, 1.00)

func _label() -> String:
	match type:
		Type.BOMB:   return "BOMBA"
		Type.MEDKIT: return "MEDKIT"
		_:           return "BIOMASA"

func _draw() -> void:
	var c      := _color()
	var pulse  := 0.70 + sin(_t * 3.0) * 0.30
	var bob    := sin(_t * 2.2) * 3.0   # desplazamiento vertical suave

	# Sombra difusa en el suelo
	draw_circle(Vector2(0, HALF * 0.6), HALF * 0.8,
		Color(0.0, 0.0, 0.0, 0.30 * pulse))

	# Halo exterior pulsante
	draw_arc(Vector2(0, bob), GLOW, 0, TAU, 36,
		Color(c.r, c.g, c.b, 0.22 * pulse), GLOW * 0.55)

	# Cuerpo principal (caja)
	var box := Rect2(-HALF, -HALF + bob, HALF * 2.0, HALF * 2.0)
	draw_rect(box, Color(c.r * 0.12, c.g * 0.12, c.b * 0.12, 0.95))
	draw_rect(box, Color(c.r, c.g, c.b, pulse), false, 2.5)

	# Brillo interior en la esquina superior izquierda
	draw_rect(Rect2(-HALF + 2, -HALF + 2 + bob, HALF * 0.55, HALF * 0.55),
		Color(1.0, 1.0, 1.0, 0.12 * pulse))

	# Ícono interior según tipo
	if type == Type.BOMB:
		# Círculo + mecha
		draw_circle(Vector2(0, bob), HALF * 0.52,
			Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, 0.95))
		draw_circle(Vector2(0, bob), HALF * 0.52,
			Color(c.r, c.g, c.b, 0.7 * pulse), false, 2.0)
		draw_line(Vector2(0, -HALF * 0.52 + bob),
			Vector2(HALF * 0.4, -HALF * 0.75 + bob),
			Color(1.0, 0.85, 0.4, 0.9 * pulse), 2.5)
		# Destello de mecha
		draw_circle(Vector2(HALF * 0.4, -HALF * 0.75 + bob),
			3.5 * pulse, Color(1.0, 0.9, 0.3, pulse))
	elif type == Type.MEDKIT:
		# Cruz blanca gruesa
		var arm := HALF * 0.55
		var thk := HALF * 0.28
		draw_rect(Rect2(-thk, -arm + bob, thk * 2.0, arm * 2.0),
			Color(c.r, c.g, c.b, 0.9 * pulse))
		draw_rect(Rect2(-arm, -thk + bob, arm * 2.0, thk * 2.0),
			Color(c.r, c.g, c.b, 0.9 * pulse))
	else:
		# BIOMASA: célula con núcleo
		draw_circle(Vector2(0, bob), HALF * 0.55,
			Color(c.r * 0.3, c.g * 0.3, c.b * 0.3, 0.9))
		draw_circle(Vector2(0, bob), HALF * 0.55,
			Color(c.r, c.g, c.b, 0.5 * pulse), false, 2.0)
		draw_circle(Vector2(0, bob), HALF * 0.22,
			Color(c.r, c.g, c.b, 0.85 * pulse))

	# Etiqueta flotante arriba
	var f   := ThemeDB.fallback_font
	var lbl := _label()
	var lbl_y := -HALF - 14.0 + bob
	# Sombra del texto
	draw_string(f, Vector2(-20 + 1, lbl_y + 1), lbl,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(0.0, 0.0, 0.0, 0.7 * pulse))
	draw_string(f, Vector2(-20, lbl_y), lbl,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
		Color(c.r, c.g, c.b, 0.95 * pulse))

func _on_body_entered(_body: Node) -> void:
	picked_up.emit(int(type), global_position)
	queue_free()
