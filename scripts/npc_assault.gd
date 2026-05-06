extends "res://scripts/npc_soldier.gd"

# ─────────────────────────────────────────────────────────────────────────────
# NPC Asalto — dispara al enemigo más cercano dentro de rango.
# Se mueve hacia la amenaza si está lejos, mantiene posición si está en rango.
# Si no hay amenazas, sigue al jugador a una distancia.
# ─────────────────────────────────────────────────────────────────────────────

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

const RANGE       := 420.0   # cubre toda la puerta asignada
const SPEED       := 130.0
const FIRE_RATE   := 0.4
const FOLLOW_DIST := 90.0
const POST_DIST   := 55.0    # se queda quieto si está a menos de esto de su puesto

var bullet_container: Node2D
var enemies_node:     Node2D
var _fire_cd: float   = 0.0
var _aim_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	role        = "ASSAULT"
	max_hp      = 100
	hp          = max_hp
	_sprite_tex = "res://assets/sprites/npc_assault.png"
	super._ready()

func _act(delta: float) -> void:
	_fire_cd -= delta
	var threat := _find_threat()
	if is_instance_valid(threat):
		var to_t: Vector2 = threat.global_position - global_position
		var dist: float = to_t.length()
		_aim_dir = to_t.normalized()
		if dist > RANGE * 0.7:
			velocity = _aim_dir * SPEED
		else:
			velocity = Vector2.ZERO
		if _fire_cd <= 0.0:
			_shoot()
	else:
		# Sin amenaza: volver al puesto asignado (o seguir al player si no hay puesto)
		var idle_target: Vector2
		if post_pos != Vector2.ZERO:
			idle_target = post_pos
		elif is_instance_valid(player):
			idle_target = player.global_position
		else:
			velocity = Vector2.ZERO
			return
		var to_idle: Vector2 = idle_target - global_position
		if to_idle.length() > POST_DIST:
			velocity = to_idle.normalized() * SPEED * 0.65
		else:
			velocity = Vector2.ZERO
	queue_redraw()

func _find_threat() -> Node2D:
	if not is_instance_valid(enemies_node):
		return null
	var best: Node2D = null
	var best_d := RANGE * RANGE
	for e in enemies_node.get_children():
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best   = e
	return best

func _shoot() -> void:
	if not is_instance_valid(bullet_container):
		return
	var b := BULLET_SCENE.instantiate()
	b.global_position = global_position + _aim_dir * 18.0
	b.direction       = _aim_dir
	b.bcolor          = Color(0.45, 0.75, 1.0)
	b.bradius         = 5.0
	bullet_container.call_deferred("add_child", b)
	_fire_cd = FIRE_RATE

func _draw() -> void:
	super._draw()
	if not down:
		# Cañón apuntando a la dirección de tiro
		draw_line(Vector2(2, 0), _aim_dir * 18.0,
			Color(0.55, 0.65, 0.75), 4.0)
