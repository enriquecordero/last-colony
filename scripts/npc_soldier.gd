extends CharacterBody2D
class_name NPCSoldier

# ─────────────────────────────────────────────────────────────────────────────
# Clase base para NPCs aliados (Asalto, Médico, Ingeniero).
# Maneja: HP, daño, estado "incapacitado" (down), revivir, dibujado base.
# Las subclases override `_act(delta)` para su comportamiento específico.
# ─────────────────────────────────────────────────────────────────────────────

signal died(npc: Node)

const DOWN_TIMEOUT := 45.0
const RADIUS := 14.0

const ROLE_COLORS := {
	"ASSAULT":  Color(0.25, 0.55, 0.95),
	"MEDIC":    Color(0.20, 0.85, 0.45),
	"ENGINEER": Color(0.95, 0.55, 0.15),
}
const ROLE_ICONS := {
	"ASSAULT":  "⚔",
	"MEDIC":    "✚",
	"ENGINEER": "⚙",
}
const ROLE_NAMES := {
	"ASSAULT":  "ASALTO",
	"MEDIC":    "MEDICO",
	"ENGINEER": "INGENIERO",
}

var role: String = "ASSAULT"
var max_hp: int  = 100
var hp: int      = 100
var down: bool   = false
var down_t: float = 0.0
var player: Node2D
var base_pos: Vector2 = Vector2.ZERO

var _sprite_tex: String  = ""
var _sprite:     Sprite2D

func _ready() -> void:
	add_to_group("allies")
	collision_layer = 16
	collision_mask  = 8
	if not _sprite_tex.is_empty():
		_sprite         = Sprite2D.new()
		_sprite.texture = load(_sprite_tex)
		_sprite.scale   = Vector2(0.52, 0.52)
		add_child(_sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if down:
		velocity = Vector2.ZERO
		down_t -= delta
		if down_t <= 0.0:
			died.emit(self)
			queue_free()
		return
	_act(delta)
	move_and_slide()
	if _sprite and velocity.length() > 5.0:
		_sprite.rotation = velocity.angle()

# Override en subclases
func _act(_delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	if down:
		return
	hp = max(0, hp - amount)
	modulate = Color(1.6, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	queue_redraw()
	if hp <= 0:
		_go_down()

func _go_down() -> void:
	down = true
	down_t = DOWN_TIMEOUT
	if _sprite:
		_sprite.modulate = Color(0.25, 0.25, 0.25)
	queue_redraw()

func revive(amount: int = 50) -> void:
	if not down:
		return
	down = false
	hp = mini(amount, max_hp)
	if _sprite:
		_sprite.modulate = Color.WHITE
	queue_redraw()

func _draw() -> void:
	var col: Color = ROLE_COLORS.get(role, Color.WHITE)
	if down:
		# X roja sobre el sprite
		draw_line(Vector2(-7, -7), Vector2(7,  7), Color(0.95, 0.20, 0.20), 3.0)
		draw_line(Vector2(-7,  7), Vector2(7, -7), Color(0.95, 0.20, 0.20), 3.0)
		# Timer arc + revival hint
		var pct := down_t / DOWN_TIMEOUT
		draw_arc(Vector2.ZERO, RADIUS + 4, -PI/2, -PI/2 + TAU * pct, 32,
			Color(1.0, 0.65, 0.20, 0.85), 2.0)
		var fhint := ThemeDB.fallback_font
		draw_string(fhint, Vector2(-22, RADIUS + 14), "[F] REVIVIR",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 1.0, 0.55, 0.9))
		draw_string(fhint, Vector2(-10, RADIUS + 26), "%ds" % int(down_t),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.65, 0.20, 0.75))
	else:
		# HP bar arriba si está dañado
		if hp < max_hp:
			var w := RADIUS * 2.0
			draw_rect(Rect2(-RADIUS, -RADIUS - 9, w, 3), Color(0.10, 0.0, 0.0, 0.85))
			draw_rect(Rect2(-RADIUS, -RADIUS - 9, w * float(hp) / float(max_hp), 3), col)

	# Ícono de rol arriba
	var f := ThemeDB.fallback_font
	var icon: String = ROLE_ICONS.get(role, "")
	if icon != "":
		draw_string(f, Vector2(-5, -RADIUS - 14), icon,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col.lightened(0.2))
