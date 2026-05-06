extends Node2D
class_name Fortress

# ─────────────────────────────────────────────────────────────────────────────
# Fortress — La fortaleza completa.
# Reemplaza al BaseVisual + spawn_starting_walls.
# Maneja geometría, dibujado, zonas de elevación, escaleras, puertas, slots.
#
# Estructura:
#   - Hexágono central (piso 0)
#   - 3 brazos cardinales (N, E, W) — piso 0, con puerta al final
#   - Muralla SUR (piso 1) — sólida, sin puerta
#   - 4 plataformas en vértices del hex (piso 1)
#   - Torre central de 3 niveles sobre la muralla sur
#   - Escaleras a cada zona elevada
#   - 3 slots de construcción (taller, generador, enfermería)
# ─────────────────────────────────────────────────────────────────────────────

# La base se posiciona con position. Todas las coordenadas internas son relativas.
# Usamos `center_offset` = Vector2.ZERO porque dibujamos centrado.

# ── Geometría (en coordenadas locales relativas al centro) ──
const HEX_RADIUS := 140.0   # tamaño del hexágono central
const ARM_W      := 80.0    # ancho de cada brazo
const ARM_LEN    := 130.0   # largo del brazo (desde el borde del hex)

# Plataformas de torreta (esquinas del hex)
const PLAT_SIZE  := 60.0

# Muralla sur
const SOUTH_W    := 280.0
const SOUTH_H    := 40.0

# Torre central (sobre muralla sur)
const TOWER_L2_W := 100.0
const TOWER_L2_H := 50.0
const TOWER_L3_W := 70.0
const TOWER_L3_H := 38.0

# Escaleras
const STAIR_SIZE := 26.0

# Núcleo
const CORE_R     := 22.0

# ── Colores ──
const COL_FLOOR_0      := Color(0.10, 0.13, 0.18)
const COL_FLOOR_0_EDGE := Color(0.20, 0.26, 0.34)
const COL_FLOOR_1      := Color(0.13, 0.17, 0.23)
const COL_FLOOR_1_EDGE := Color(0.30, 0.40, 0.55)
const COL_FLOOR_2      := Color(0.16, 0.22, 0.32)
const COL_FLOOR_2_EDGE := Color(0.45, 0.60, 0.75)
const COL_FLOOR_3      := Color(0.23, 0.34, 0.50)
const COL_FLOOR_3_EDGE := Color(0.65, 0.78, 0.88)
const COL_WALL         := Color(0.23, 0.27, 0.32)
const COL_WALL_EDGE    := Color(0.36, 0.41, 0.47)
const COL_GATE_LINE    := Color(1.0,  0.85, 0.20, 0.85)
const COL_AMBER        := Color(1.0,  0.55, 0.0)
const COL_PLATFORM     := Color(0.12, 0.16, 0.22)
const COL_STAIR        := Color(0.13, 0.20, 0.29)
const COL_STAIR_EDGE   := Color(0.55, 0.70, 0.85)
const COL_CORE_OUTER   := Color(0.0,  0.83, 1.0)
const COL_CORE_INNER   := Color(0.55, 0.95, 1.0)
const COL_TOWER        := Color(0.24, 0.34, 0.50)
const COL_TOWER_EDGE   := Color(0.66, 0.78, 0.88)

# ── Slots de estaciones ──
enum StationType { TALLER, GENERATOR, ENFERMERIA }

# Cada slot tiene posición relativa, color, label, y si está construida
class Slot:
	var pos:    Vector2
	var size:   Vector2
	var stype:  int
	var built:  bool = false
	var hp:     int  = 0
	var max_hp: int  = 300
	var color:  Color
	var label:  String

# ── Datos calculados en _ready (en coords globales) ──
var hex_center:        Vector2
var hex_vertices:      Array          # 6 puntos del hexágono central
var arm_polygons:      Dictionary     # "N"/"E"/"W" -> Array de 4 puntos
var door_centers:      Dictionary     # "N"/"E"/"W" -> Vector2
var platform_polygons: Array          # 4 plataformas (NW, NE, SW, SE) - rects
var south_wall_rect:   Rect2
var tower_l2_rect:     Rect2
var tower_l3_rect:     Rect2

# Zonas de escalera: pares (rect, from_level, to_level)
var stair_zones: Array = []

# Slots de estaciones
var slots: Array = []

# Pulse animation timing
var _pulse_t: float = 0.0


func _ready() -> void:
	z_index = 0
	_build_geometry()
	set_process(true)


func _process(delta: float) -> void:
	_pulse_t += delta
	queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
# Geometría
# ─────────────────────────────────────────────────────────────────────────────

func _build_geometry() -> void:
	hex_center = global_position

	# Hexágono central — 6 vértices (apuntando a los lados)
	# Vértices a 0°, 60°, 120°, 180°, 240°, 300° desde el centro
	# Pero queremos que tenga lados N, S y diagonales NE/NW/SE/SW.
	# Con apex en N/S → puntos a 30°, 90°, 150°, 210°, 270°, 330°.
	# Mejor para layout: planos N/S → 0°, 60°, 120°, 180°, 240°, 300°.
	hex_vertices = []
	for i in 6:
		var a: float = deg_to_rad(60.0 * i)
		hex_vertices.append(hex_center + Vector2(cos(a), sin(a)) * HEX_RADIUS)
	# Esto da: V0 derecha, V1 abajo-derecha, V2 abajo-izquierda, V3 izquierda, V4 arriba-izquierda, V5 arriba-derecha

	# Brazos: salen de los lados del hexágono. El brazo NORTE sale del lado superior (entre V4 y V5).
	# Centro del lado superior = (V4 + V5) / 2
	var top_mid:    Vector2 = (hex_vertices[4] + hex_vertices[5]) * 0.5
	var bottom_mid: Vector2 = (hex_vertices[1] + hex_vertices[2]) * 0.5
	var right_mid:  Vector2 = hex_vertices[0]
	var left_mid:   Vector2 = hex_vertices[3]

	# Brazo NORTE — rectángulo 80×130 saliendo hacia arriba desde top_mid
	var arm_n_base_l := Vector2(top_mid.x - ARM_W * 0.5, top_mid.y)
	var arm_n_base_r := Vector2(top_mid.x + ARM_W * 0.5, top_mid.y)
	var arm_n_top_l  := Vector2(top_mid.x - ARM_W * 0.5, top_mid.y - ARM_LEN)
	var arm_n_top_r  := Vector2(top_mid.x + ARM_W * 0.5, top_mid.y - ARM_LEN)
	arm_polygons = {
		"N": [arm_n_base_l, arm_n_top_l, arm_n_top_r, arm_n_base_r],
		"E": [right_mid, Vector2(right_mid.x + ARM_LEN, right_mid.y - ARM_W * 0.5),
			  Vector2(right_mid.x + ARM_LEN, right_mid.y + ARM_W * 0.5), right_mid],
		"W": [left_mid, Vector2(left_mid.x - ARM_LEN, left_mid.y - ARM_W * 0.5),
			  Vector2(left_mid.x - ARM_LEN, left_mid.y + ARM_W * 0.5), left_mid],
	}
	# Para E y W el rect es horizontal — corrijo los puntos para que sean rect bien formado:
	arm_polygons["E"] = [
		Vector2(right_mid.x, right_mid.y - ARM_W * 0.5),
		Vector2(right_mid.x + ARM_LEN, right_mid.y - ARM_W * 0.5),
		Vector2(right_mid.x + ARM_LEN, right_mid.y + ARM_W * 0.5),
		Vector2(right_mid.x, right_mid.y + ARM_W * 0.5),
	]
	arm_polygons["W"] = [
		Vector2(left_mid.x - ARM_LEN, left_mid.y - ARM_W * 0.5),
		Vector2(left_mid.x, left_mid.y - ARM_W * 0.5),
		Vector2(left_mid.x, left_mid.y + ARM_W * 0.5),
		Vector2(left_mid.x - ARM_LEN, left_mid.y + ARM_W * 0.5),
	]

	# Puertas — al final de cada brazo, un poco hacia adentro
	door_centers = {
		"N": Vector2(top_mid.x, top_mid.y - ARM_LEN + 8.0),
		"E": Vector2(right_mid.x + ARM_LEN - 8.0, right_mid.y),
		"W": Vector2(left_mid.x - ARM_LEN + 8.0, left_mid.y),
	}

	# Plataformas (60×60) en los vértices NW, NE, SW, SE (ajustadas hacia afuera del hex)
	# V5 = arriba-derecha (NE), V4 = arriba-izquierda (NW), V1 = abajo-derecha (SE), V2 = abajo-izquierda (SW)
	platform_polygons = [
		Rect2(hex_vertices[4] - Vector2(PLAT_SIZE * 0.5, PLAT_SIZE * 0.5), Vector2(PLAT_SIZE, PLAT_SIZE)),  # NW
		Rect2(hex_vertices[5] - Vector2(PLAT_SIZE * 0.5, PLAT_SIZE * 0.5), Vector2(PLAT_SIZE, PLAT_SIZE)),  # NE
		Rect2(hex_vertices[2] - Vector2(PLAT_SIZE * 0.5, PLAT_SIZE * 0.5), Vector2(PLAT_SIZE, PLAT_SIZE)),  # SW
		Rect2(hex_vertices[1] - Vector2(PLAT_SIZE * 0.5, PLAT_SIZE * 0.5), Vector2(PLAT_SIZE, PLAT_SIZE)),  # SE
	]

	# Muralla sur — debajo del hex, sin entrada
	south_wall_rect = Rect2(
		Vector2(hex_center.x - SOUTH_W * 0.5, bottom_mid.y + 5.0),
		Vector2(SOUTH_W, SOUTH_H))

	# Torre central — sobre la muralla sur
	tower_l2_rect = Rect2(
		Vector2(hex_center.x - TOWER_L2_W * 0.5, south_wall_rect.position.y - 12.0),
		Vector2(TOWER_L2_W, TOWER_L2_H))
	tower_l3_rect = Rect2(
		Vector2(hex_center.x - TOWER_L3_W * 0.5, tower_l2_rect.position.y - TOWER_L3_H + 6.0),
		Vector2(TOWER_L3_W, TOWER_L3_H))

	# ── Zonas de escalera ──
	# Cada plataforma tiene una escalera al lado (dirección hacia el hex)
	# Escalera al lado de NW (a la derecha de la plataforma NW, mirando hacia el hex)
	for i in 4:
		var plat_rect: Rect2 = platform_polygons[i]
		var plat_center := plat_rect.position + plat_rect.size * 0.5
		var to_hex: Vector2 = (hex_center - plat_center).normalized()
		var stair_pos: Vector2 = plat_center + to_hex * (PLAT_SIZE * 0.5 + 4.0)
		var stair_rect := Rect2(
			stair_pos - Vector2(STAIR_SIZE * 0.5, STAIR_SIZE * 0.5),
			Vector2(STAIR_SIZE, STAIR_SIZE))
		stair_zones.append({
			"rect":       stair_rect,
			"from_level": 0,
			"to_level":   1,
			"plat_idx":   i,
		})

	# Escalera de la muralla sur (laterales)
	stair_zones.append({
		"rect": Rect2(south_wall_rect.position - Vector2(STAIR_SIZE + 2.0, 0),
			Vector2(STAIR_SIZE, south_wall_rect.size.y)),
		"from_level": 0, "to_level": 1, "plat_idx": -1
	})
	stair_zones.append({
		"rect": Rect2(south_wall_rect.position + Vector2(south_wall_rect.size.x + 2.0, 0),
			Vector2(STAIR_SIZE, south_wall_rect.size.y)),
		"from_level": 0, "to_level": 1, "plat_idx": -1
	})

	# Escalera muralla → torre L2 (centro de la muralla sur sube a torre L2)
	stair_zones.append({
		"rect": Rect2(
			Vector2(hex_center.x - 8.0, south_wall_rect.position.y - 4.0),
			Vector2(16.0, 22.0)),
		"from_level": 1, "to_level": 2, "plat_idx": -2
	})

	# Escalera torre L2 → L3 (parte superior de la torre L2)
	stair_zones.append({
		"rect": Rect2(
			Vector2(hex_center.x - 8.0, tower_l2_rect.position.y - 6.0),
			Vector2(16.0, 22.0)),
		"from_level": 2, "to_level": 3, "plat_idx": -3
	})

	# ── Slots de estaciones (dentro del hexágono) ──
	# Posicionados arriba (taller), izquierda (generador), abajo (enfermería)
	var taller := Slot.new()
	taller.pos    = hex_center + Vector2(-35.0, -55.0)
	taller.size   = Vector2(50.0, 36.0)
	taller.stype  = StationType.TALLER
	taller.color  = Color(0.80, 0.45, 0.20)
	taller.label  = "TALLER"
	slots.append(taller)

	var generator := Slot.new()
	generator.pos    = hex_center + Vector2(35.0, -55.0)
	generator.size   = Vector2(50.0, 36.0)
	generator.stype  = StationType.GENERATOR
	generator.color  = Color(0.0, 0.83, 1.0)
	generator.label  = "GENER."
	slots.append(generator)

	var enfermeria := Slot.new()
	enfermeria.pos    = hex_center + Vector2(0.0, 55.0)
	enfermeria.size   = Vector2(50.0, 36.0)
	enfermeria.stype  = StationType.ENFERMERIA
	enfermeria.color  = Color(0.22, 1.0, 0.30)
	enfermeria.label  = "ENFERM."
	slots.append(enfermeria)


# ─────────────────────────────────────────────────────────────────────────────
# Dibujado
# ─────────────────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Las coords son globales; convertimos a locales restando global_position
	var c := -global_position + hex_center

	# 1) BRAZOS (piso 0) — dibujar primero para que queden detrás del hex
	for k in arm_polygons:
		var poly: Array = arm_polygons[k]
		var local_poly := PackedVector2Array()
		for v in poly:
			local_poly.append(v - global_position)
		draw_colored_polygon(local_poly, COL_FLOOR_0)
		draw_polyline(local_poly + PackedVector2Array([local_poly[0]]),
			COL_FLOOR_0_EDGE, 1.5)

	# 2) MURALLA SUR (piso 1) con sombra simulada
	var sw_local := Rect2(south_wall_rect.position - global_position, south_wall_rect.size)
	# Sombra
	draw_rect(Rect2(sw_local.position + Vector2(0, 4), sw_local.size),
		Color(0, 0, 0, 0.5))
	# Cuerpo
	draw_rect(sw_local, COL_FLOOR_1)
	draw_rect(sw_local, COL_FLOOR_1_EDGE, false, 2.0)
	# Detalles
	draw_line(sw_local.position + Vector2(0, 8),
		sw_local.position + Vector2(sw_local.size.x, 8),
		COL_FLOOR_1_EDGE, 0.8)
	draw_line(sw_local.position + Vector2(0, sw_local.size.y - 4),
		sw_local.position + Vector2(sw_local.size.x, sw_local.size.y - 4),
		COL_FLOOR_1_EDGE, 0.8)

	# 3) HEXÁGONO CENTRAL (piso 0)
	var hex_local := PackedVector2Array()
	for v in hex_vertices:
		hex_local.append(v - global_position)
	draw_colored_polygon(hex_local, COL_FLOOR_0)
	draw_polyline(hex_local + PackedVector2Array([hex_local[0]]),
		COL_FLOOR_0_EDGE, 2.0)
	# Líneas decorativas internas
	draw_line(c + Vector2(-HEX_RADIUS * 0.7, 0), c + Vector2(HEX_RADIUS * 0.7, 0),
		Color(0.20, 0.26, 0.34, 0.4), 0.8)
	draw_line(c + Vector2(0, -HEX_RADIUS * 0.7), c + Vector2(0, HEX_RADIUS * 0.7),
		Color(0.20, 0.26, 0.34, 0.4), 0.8)

	# 4) MUROS DE LOS BRAZOS (líneas laterales con apertura para puerta)
	_draw_arm_walls()

	# 5) PUERTAS — líneas amarillas y luces ámbar
	_draw_gates()

	# 6) PLATAFORMAS de torreta (4 esquinas) - piso 1 con sombra
	for plat_rect in platform_polygons:
		var pr_local := Rect2(plat_rect.position - global_position, plat_rect.size)
		# Sombra
		draw_rect(Rect2(pr_local.position + Vector2(0, 3), pr_local.size),
			Color(0, 0, 0, 0.4))
		# Cuerpo
		draw_rect(pr_local, COL_PLATFORM)
		draw_rect(pr_local, COL_FLOOR_1_EDGE, false, 2.0)
		# Tornillos en las 4 esquinas
		var corners := [
			pr_local.position + Vector2(4, 4),
			pr_local.position + Vector2(pr_local.size.x - 4, 4),
			pr_local.position + Vector2(4, pr_local.size.y - 4),
			pr_local.position + Vector2(pr_local.size.x - 4, pr_local.size.y - 4),
		]
		for cp in corners:
			draw_circle(cp, 1.5, Color(0.36, 0.45, 0.55))
		# Marker ⊕
		var pc := pr_local.position + pr_local.size * 0.5
		draw_circle(pc, 5.0, Color(0, 0, 0, 0))
		draw_arc(pc, 5.0, 0, TAU, 12, Color(0.40, 0.55, 0.70, 0.6), 1.0)
		draw_line(pc + Vector2(-7, 0), pc + Vector2(7, 0),
			Color(0.40, 0.55, 0.70, 0.5), 1.0)
		draw_line(pc + Vector2(0, -7), pc + Vector2(0, 7),
			Color(0.40, 0.55, 0.70, 0.5), 1.0)

	# 7) ESCALERAS
	_draw_stairs()

	# 8) TORRE CENTRAL (L2 + L3) con sombras escalonadas
	_draw_tower()

	# 9) SLOTS DE ESTACIONES (dibujadas si built, silueta punteada si no)
	for slot in slots:
		_draw_slot(slot)

	# 10) NÚCLEO en el centro
	_draw_core(c)

	# 11) Antenas con LED rojo en plataformas y torre
	_draw_antennas()


func _draw_arm_walls() -> void:
	# Brazo N — paredes verticales (laterales) con apertura al final (la puerta)
	var arm_n: Array = arm_polygons["N"]
	var top_l_local: Vector2 = arm_n[1] - global_position
	var top_r_local: Vector2 = arm_n[2] - global_position
	var bot_l_local: Vector2 = arm_n[0] - global_position
	var bot_r_local: Vector2 = arm_n[3] - global_position
	# Pared izquierda completa (de arriba a la base del brazo)
	draw_line(top_l_local, bot_l_local, COL_WALL_EDGE, 4.0)
	# Pared derecha completa
	draw_line(top_r_local, bot_r_local, COL_WALL_EDGE, 4.0)
	# Esquinas del extremo (parte de la puerta — tope superior tiene "marco" de muro a los lados)
	draw_line(top_l_local, top_l_local + Vector2(8, 0), COL_WALL_EDGE, 4.0)
	draw_line(top_r_local, top_r_local + Vector2(-8, 0), COL_WALL_EDGE, 4.0)

	# Brazo E
	var arm_e: Array = arm_polygons["E"]
	# arm_e[0] = top-left, [1] = top-right, [2] = bottom-right, [3] = bottom-left
	var e_tl: Vector2 = arm_e[0] - global_position
	var e_tr: Vector2 = arm_e[1] - global_position
	var e_br: Vector2 = arm_e[2] - global_position
	var e_bl: Vector2 = arm_e[3] - global_position
	# Pared superior
	draw_line(e_tl, e_tr, COL_WALL_EDGE, 4.0)
	# Pared inferior
	draw_line(e_bl, e_br, COL_WALL_EDGE, 4.0)
	# Marco de la puerta
	draw_line(e_tr, e_tr + Vector2(0, 8), COL_WALL_EDGE, 4.0)
	draw_line(e_br, e_br + Vector2(0, -8), COL_WALL_EDGE, 4.0)

	# Brazo W
	var arm_w: Array = arm_polygons["W"]
	var w_tl: Vector2 = arm_w[0] - global_position
	var w_tr: Vector2 = arm_w[1] - global_position
	var w_br: Vector2 = arm_w[2] - global_position
	var w_bl: Vector2 = arm_w[3] - global_position
	draw_line(w_tl, w_tr, COL_WALL_EDGE, 4.0)
	draw_line(w_bl, w_br, COL_WALL_EDGE, 4.0)
	draw_line(w_tl, w_tl + Vector2(0, 8), COL_WALL_EDGE, 4.0)
	draw_line(w_bl, w_bl + Vector2(0, -8), COL_WALL_EDGE, 4.0)


func _draw_gates() -> void:
	var pulse: float = 0.6 + 0.4 * (sin(_pulse_t * 4.0) * 0.5 + 0.5)

	# Gate N — línea horizontal amarilla al final del brazo (arriba)
	var gn: Vector2 = door_centers["N"] - global_position
	draw_line(gn + Vector2(-30, 0), gn + Vector2(30, 0),
		COL_GATE_LINE, 2.5)
	draw_circle(gn + Vector2(-34, 0), 3.0, COL_AMBER * Color(1, 1, 1, pulse))
	draw_circle(gn + Vector2(34, 0), 3.0, COL_AMBER * Color(1, 1, 1, pulse))

	# Gate E — vertical
	var ge: Vector2 = door_centers["E"] - global_position
	draw_line(ge + Vector2(0, -30), ge + Vector2(0, 30),
		COL_GATE_LINE, 2.5)
	draw_circle(ge + Vector2(0, -34), 3.0, COL_AMBER * Color(1, 1, 1, pulse))
	draw_circle(ge + Vector2(0, 34), 3.0, COL_AMBER * Color(1, 1, 1, pulse))

	# Gate W
	var gw: Vector2 = door_centers["W"] - global_position
	draw_line(gw + Vector2(0, -30), gw + Vector2(0, 30),
		COL_GATE_LINE, 2.5)
	draw_circle(gw + Vector2(0, -34), 3.0, COL_AMBER * Color(1, 1, 1, pulse))
	draw_circle(gw + Vector2(0, 34), 3.0, COL_AMBER * Color(1, 1, 1, pulse))


func _draw_stairs() -> void:
	for sz in stair_zones:
		var sr: Rect2 = sz["rect"]
		var sr_local := Rect2(sr.position - global_position, sr.size)
		draw_rect(sr_local, COL_STAIR)
		draw_rect(sr_local, COL_STAIR_EDGE, false, 1.0)
		# Líneas de "escalones"
		var rows := 3
		for i in rows:
			var y: float = sr_local.position.y + sr_local.size.y * (float(i + 1) / float(rows + 1))
			draw_line(Vector2(sr_local.position.x + 2, y),
				Vector2(sr_local.position.x + sr_local.size.x - 2, y),
				COL_STAIR_EDGE * Color(1, 1, 1, 0.55), 0.7)


func _draw_tower() -> void:
	# Sombra del L2 (fuerte)
	var l2_local := Rect2(tower_l2_rect.position - global_position, tower_l2_rect.size)
	draw_rect(Rect2(l2_local.position + Vector2(0, 5), l2_local.size),
		Color(0, 0, 0, 0.55))
	# Cuerpo L2
	draw_rect(l2_local, COL_FLOOR_2)
	draw_rect(l2_local, COL_FLOOR_2_EDGE, false, 2.0)
	# Texto "TORRE 2do piso"
	var l2_center := l2_local.position + l2_local.size * 0.5
	draw_string(ThemeDB.fallback_font, l2_center + Vector2(-22, -2), "TORRE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COL_FLOOR_2_EDGE)

	# Sombra del L3 (más fuerte)
	var l3_local := Rect2(tower_l3_rect.position - global_position, tower_l3_rect.size)
	draw_rect(Rect2(l3_local.position + Vector2(0, 7), l3_local.size),
		Color(0, 0, 0, 0.65))
	# Cuerpo L3
	draw_rect(l3_local, COL_TOWER)
	draw_rect(l3_local, COL_TOWER_EDGE, false, 2.5)
	# Almenas en el techo
	var almena_w := 7.0
	var almena_h := 6.0
	var almena_y: float = l3_local.position.y - almena_h
	for i in 6:
		var almena_x: float = l3_local.position.x + 4.0 + i * 10.0
		draw_rect(Rect2(Vector2(almena_x, almena_y),
			Vector2(almena_w, almena_h)), COL_TOWER)
		draw_rect(Rect2(Vector2(almena_x, almena_y),
			Vector2(almena_w, almena_h)), COL_TOWER_EDGE, false, 1.0)
	# Línea brillante superior
	draw_rect(Rect2(l3_local.position, Vector2(l3_local.size.x, 4.0)),
		COL_TOWER_EDGE * Color(0.7, 0.85, 1.0, 1.0))


func _draw_slot(slot: Slot) -> void:
	var rect_local := Rect2(slot.pos - global_position - slot.size * 0.5, slot.size)
	if slot.built:
		# Estación construida con color sólido
		draw_rect(rect_local, slot.color * Color(0.25, 0.25, 0.25, 0.95))
		draw_rect(rect_local, slot.color, false, 1.5)
		# Banner color en la parte superior
		draw_rect(Rect2(rect_local.position, Vector2(rect_local.size.x, 6.0)),
			slot.color)
		# Label
		draw_string(ThemeDB.fallback_font,
			rect_local.position + Vector2(rect_local.size.x * 0.5 - 22, 18),
			slot.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, slot.color * Color(1.4, 1.4, 1.4))
		# HP bar si está dañada
		if slot.hp < slot.max_hp:
			var bar_w: float = rect_local.size.x - 6
			var bar_x: float = rect_local.position.x + 3
			var bar_y: float = rect_local.position.y + rect_local.size.y - 5
			draw_rect(Rect2(Vector2(bar_x, bar_y), Vector2(bar_w, 3)),
				Color(0.10, 0.0, 0.0, 0.85))
			var fill: float = bar_w * float(slot.hp) / float(slot.max_hp)
			draw_rect(Rect2(Vector2(bar_x, bar_y), Vector2(fill, 3)),
				Color(0.95, 0.20, 0.15))
	else:
		# Silueta punteada (proyecto)
		var dashed_color := slot.color * Color(1, 1, 1, 0.45)
		_draw_dashed_rect(rect_local, dashed_color, 4.0, 3.0)
		draw_string(ThemeDB.fallback_font,
			rect_local.position + Vector2(rect_local.size.x * 0.5 - 18, 16),
			slot.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, dashed_color)
		draw_string(ThemeDB.fallback_font,
			rect_local.position + Vector2(rect_local.size.x * 0.5 - 14, 28),
			"[20 ⚙]", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, dashed_color)


func _draw_dashed_rect(r: Rect2, color: Color, dash: float, gap: float) -> void:
	var perim := [
		[r.position, r.position + Vector2(r.size.x, 0)],
		[r.position + Vector2(r.size.x, 0), r.position + r.size],
		[r.position + r.size, r.position + Vector2(0, r.size.y)],
		[r.position + Vector2(0, r.size.y), r.position],
	]
	for seg in perim:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var dist: float = a.distance_to(b)
		var dir: Vector2 = (b - a).normalized()
		var t: float = 0.0
		while t < dist:
			var seg_end: float = minf(t + dash, dist)
			draw_line(a + dir * t, a + dir * seg_end, color, 1.2)
			t += dash + gap


func _draw_core(c: Vector2) -> void:
	var pulse: float = 0.85 + 0.15 * sin(_pulse_t * 3.0)
	# Plataforma octogonal
	var oct: PackedVector2Array = PackedVector2Array()
	for i in 8:
		var a: float = deg_to_rad(22.5 + i * 45.0)
		oct.append(c + Vector2(cos(a), sin(a)) * 30.0)
	draw_colored_polygon(oct, Color(0.04, 0.10, 0.16))
	draw_polyline(oct + PackedVector2Array([oct[0]]), COL_CORE_OUTER, 2.0)
	# Esfera del núcleo
	draw_circle(c, CORE_R, COL_CORE_OUTER * Color(pulse, pulse, pulse, 1.0))
	draw_circle(c, CORE_R * 0.55, COL_CORE_INNER * Color(1, 1, 1, 0.85))
	draw_circle(c, CORE_R * 0.25, Color(1, 1, 1, 0.85))
	# Anillo rotatorio
	var ring_r := CORE_R + 6.0
	var ring_segments := 16
	for i in ring_segments:
		var a0: float = (TAU / ring_segments) * i + _pulse_t * 0.6
		var a1: float = a0 + (TAU / ring_segments) * 0.5
		draw_arc(c, ring_r, a0, a1, 6, COL_CORE_OUTER * Color(1, 1, 1, 0.7), 1.0)


func _draw_antennas() -> void:
	var pulse_red: float = 0.5 + 0.5 * sin(_pulse_t * 5.0)
	# Antenas en plataformas
	for plat_rect in platform_polygons:
		var top_local: Vector2 = plat_rect.position - global_position + Vector2(plat_rect.size.x * 0.5, 0)
		draw_line(top_local, top_local + Vector2(0, -10),
			Color(0.36, 0.41, 0.47), 1.2)
		draw_circle(top_local + Vector2(0, -12), 2.0,
			Color(1.0, 0.22, 0.22, pulse_red))

	# Antena en la torre
	var tower_top: Vector2 = tower_l3_rect.position - global_position + Vector2(tower_l3_rect.size.x * 0.5, -6.0)
	draw_line(tower_top, tower_top + Vector2(0, -22),
		Color(0.36, 0.41, 0.47), 1.5)
	draw_circle(tower_top + Vector2(0, -24), 2.5,
		Color(1.0, 0.22, 0.22, pulse_red))


# ─────────────────────────────────────────────────────────────────────────────
# API pública — usado por main / player / enemigos
# ─────────────────────────────────────────────────────────────────────────────

# ¿Está la posición dentro de alguna zona de escalera? Devuelve dict o null.
func get_stair_at(pos: Vector2) -> Variant:
	for sz in stair_zones:
		if (sz["rect"] as Rect2).has_point(pos):
			return sz
	return null

# ¿Qué nivel tiene esta posición global?
# 0 = piso bajo (hex + brazos)
# 1 = plataformas o muralla sur
# 2 = torre L2
# 3 = torre L3 (cima)
func get_elevation_at(pos: Vector2) -> int:
	if (tower_l3_rect as Rect2).has_point(pos):
		return 3
	if (tower_l2_rect as Rect2).has_point(pos):
		return 2
	for plat_rect in platform_polygons:
		if (plat_rect as Rect2).has_point(pos):
			return 1
	if (south_wall_rect as Rect2).has_point(pos):
		return 1
	return 0

# Devuelve la posición global de la puerta más cercana (para pathfinding de enemigos)
func nearest_door_pos(from_pos: Vector2) -> Vector2:
	var best_d := INF
	var best_pos: Vector2 = door_centers["N"]
	for k in door_centers:
		var d: float = from_pos.distance_to(door_centers[k])
		if d < best_d:
			best_d = d
			best_pos = door_centers[k]
	return best_pos

# ¿El punto está adentro del hexágono central? (para saber si un enemigo ya entró)
func is_inside_hex(pos: Vector2) -> bool:
	# Test simple: distancia al centro < apothem aproximado
	var d: float = pos.distance_to(hex_center)
	return d < (HEX_RADIUS * 0.85)

# Obtener un slot por tipo (para construir la estación)
func get_slot_by_type(stype: int) -> Slot:
	for slot in slots:
		if slot.stype == stype:
			return slot
	return null

# ¿La posición está sobre algún slot vacío? (para colocar estación)
func get_slot_at(pos: Vector2) -> Slot:
	for slot in slots:
		var rect := Rect2(slot.pos - slot.size * 0.5, slot.size)
		if rect.has_point(pos):
			return slot
	return null

# Construir estación (consume biomasa fuera de aquí)
func build_station(stype: int) -> bool:
	var slot := get_slot_by_type(stype)
	if slot == null or slot.built:
		return false
	slot.built = true
	slot.hp = slot.max_hp
	queue_redraw()
	return true

# Posición global del Núcleo (para que enemigos lo ataquen)
func get_core_pos() -> Vector2:
	return hex_center

# Lista de centros de puerta para que el HUD muestre indicadores
func get_door_centers() -> Dictionary:
	return door_centers
