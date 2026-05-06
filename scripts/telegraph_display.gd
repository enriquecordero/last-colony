extends Control

# ─────────────────────────────────────────────────────────────────────────────
# TelegraphDisplay
# Muestra un panel "WAVE INCOMING" durante la build phase con:
# - Nombre del patrón de la próxima wave
# - Mini-radar visual con puntos rojos donde van a spawnear los enemigos
# - Lista de direcciones con porcentajes
# - Total de enemigos entrantes
# ─────────────────────────────────────────────────────────────────────────────

const PANEL_W := 215.0
const PANEL_H := 162.0
const RADAR_R := 38.0

var wave_num:     int        = 0
var pattern_name: String     = ""
var spawns:       Dictionary = {}
var enemy_count:  int        = 0

const DIR_OFFSETS := {
	"N":  Vector2( 0.0, -1.0),
	"NE": Vector2( 0.707, -0.707),
	"E":  Vector2( 1.0,  0.0),
	"SE": Vector2( 0.707,  0.707),
	"S":  Vector2( 0.0,  1.0),
	"SW": Vector2(-0.707,  0.707),
	"W":  Vector2(-1.0,  0.0),
	"NW": Vector2(-0.707, -0.707),
}

const DIR_NAMES := {
	"N": "Norte", "NE": "Noreste", "E": "Este",  "SE": "Sureste",
	"S": "Sur",   "SW": "Suroeste", "W": "Oeste", "NW": "Noroeste"
}

func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)

func set_data(wave: int, p_name: String, p_spawns: Dictionary, n_enemies: int) -> void:
	wave_num     = wave
	pattern_name = p_name
	spawns       = p_spawns
	enemy_count  = n_enemies
	queue_redraw()

func _draw() -> void:
	# ── Fondo del panel ──
	draw_rect(Rect2(0, 0, PANEL_W, PANEL_H), Color(0.05, 0.07, 0.12, 0.92))
	draw_rect(Rect2(0, 0, PANEL_W, PANEL_H), Color(0.85, 0.25, 0.15, 0.7), false, 2.0)

	var f := ThemeDB.fallback_font

	# ── Títulos ──
	draw_string(f, Vector2(0, 22), ("⚠ WAVE %d ⚠" % wave_num),
		HORIZONTAL_ALIGNMENT_CENTER, PANEL_W, 15,
		Color(1.0, 0.55, 0.15))
	draw_string(f, Vector2(0, 40), pattern_name,
		HORIZONTAL_ALIGNMENT_CENTER, PANEL_W, 13,
		Color(1.0, 0.85, 0.3))

	# ── Radar (izquierda) ──
	var rc := Vector2(46, 110)
	draw_rect(Rect2(rc - Vector2(RADAR_R, RADAR_R), Vector2(RADAR_R*2, RADAR_R*2)),
		Color(0.10, 0.14, 0.20, 0.85))
	draw_rect(Rect2(rc - Vector2(RADAR_R, RADAR_R), Vector2(RADAR_R*2, RADAR_R*2)),
		Color(0.30, 0.45, 0.55, 0.9), false, 1.0)
	draw_line(rc + Vector2(-RADAR_R, 0), rc + Vector2(RADAR_R, 0),
		Color(0.25, 0.35, 0.45, 0.4), 1.0)
	draw_line(rc + Vector2(0, -RADAR_R), rc + Vector2(0, RADAR_R),
		Color(0.25, 0.35, 0.45, 0.4), 1.0)
	draw_circle(rc, 4.0, Color(0.3, 1.0, 0.5))
	for dir in spawns:
		var pct: float   = spawns[dir]
		var off: Vector2 = DIR_OFFSETS.get(dir, Vector2.ZERO)
		var sp: Vector2  = rc + off * RADAR_R
		draw_line(sp, rc + off * 8.0, Color(1.0, 0.4, 0.2, 0.55), 1.5)
		draw_circle(sp, 3.0 + pct * 10.0, Color(1.0, 0.20, 0.20, 0.55 + pct * 0.45))

	# ── Direcciones (derecha del radar) ──
	var lx := 100.0
	var ly := 62.0
	draw_string(f, Vector2(lx, ly), "VECTORES",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.65, 0.80, 0.95))
	var sorted_dirs: Array = spawns.keys()
	sorted_dirs.sort_custom(func(a, b): return spawns[a] > spawns[b])
	for i in mini(sorted_dirs.size(), 4):
		var dir: String   = sorted_dirs[i]
		var pct: float    = spawns[dir] * 100.0
		var col := Color(1.0, 0.75, 0.40) if pct >= 50.0 \
			else Color(0.95, 0.85, 0.55) if pct >= 25.0 \
			else Color(0.80, 0.80, 0.65)
		draw_string(f, Vector2(lx, ly + 16 + i * 18),
			"▸ %s %d%%" % [DIR_NAMES.get(dir, dir), int(round(pct))],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

	draw_string(f, Vector2(0, PANEL_H - 8), "%d enemigos" % enemy_count,
		HORIZONTAL_ALIGNMENT_CENTER, PANEL_W, 12, Color(0.95, 0.55, 0.55))
