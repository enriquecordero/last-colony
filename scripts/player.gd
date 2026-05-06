extends CharacterBody2D

signal died
signal health_changed(new_hp: int)
signal infection_changed(is_infected: bool)
signal weapon_changed(wname: String)
signal ammo_changed(wname: String, mag: int, mag_max: int, reserve: int, reserve_max: int, reloading: bool)
signal elevation_changed(level: int)
signal stair_state_changed(can_climb: bool, target_level: int)

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

enum Weapon { RIFLE, SHOTGUN }

# ── Munición ──
const RIFLE_MAG_SIZE      := 30
const RIFLE_MAX_RESERVE   := 90
const RIFLE_RELOAD_TIME   := 1.5
const SHOTGUN_MAG_SIZE    := 6
const SHOTGUN_MAX_RESERVE := 18
const SHOTGUN_RELOAD_TIME := 2.0

# ── Bonus por elevación ──
# Nivel:    0      1      2      3
# Rango:  ×1.0  ×1.30  ×1.60  ×2.00
# Daño:   ×1.0  ×1.15  ×1.30  ×1.50
const ELEV_RANGE_MULT := [1.0, 1.30, 1.60, 2.00]
const ELEV_DMG_MULT   := [1.0, 1.15, 1.30, 1.50]

var max_hp:           int    = 100
var hp:               int    = 100
var bullet_container: Node2D
var fortress:         Node2D
var building:         bool   = false
var infected:         bool   = false
var serum:            bool   = false
var _infect_tick:     float  = 0.0
var _speed:           float  = 200.0
var _rifle_rate:      float  = 0.125
var _shotgun_rate:    float  = 0.45
var _fire_cd:         float  = 0.0
var _weapon:          Weapon = Weapon.RIFLE

# Munición
var _rifle_mag:       int   = RIFLE_MAG_SIZE
var _rifle_reserve:   int   = RIFLE_MAX_RESERVE
var _shotgun_mag:     int   = SHOTGUN_MAG_SIZE
var _shotgun_reserve: int   = SHOTGUN_MAX_RESERVE
var _reloading:       bool  = false
var _reload_t:        float = 0.0

# Elevación
var _elevation_level: int     = 0
var _stair_cooldown:  float   = 0.0
var _current_stair:   Variant = null

# Dash
const DASH_SPEED    := 620.0
const DASH_DURATION := 0.13
const DASH_COOLDOWN := 1.2
var _dash_t:   float = 0.0   # tiempo restante del dash activo
var _dash_cd:  float = 0.0   # cooldown entre dashes
var _dash_dir: Vector2 = Vector2.ZERO


func _ready() -> void:
	collision_layer = 1
	collision_mask  = 10
	queue_redraw()
	call_deferred("_emit_ammo")


func _draw() -> void:
	# Sombra elíptica cuando está elevado
	if _elevation_level > 0:
		var shadow_offset := float(_elevation_level) * 4.0
		var rx := 18.0 + _elevation_level * 1.5
		var ry := 5.0  + float(_elevation_level)
		var cy := shadow_offset + 14.0
		var pts := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			pts.append(Vector2(cos(a) * rx, cy + sin(a) * ry))
		draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.45))

	# Trail de dash
	if _dash_t > 0.0:
		var pct := _dash_t / DASH_DURATION
		for k in 4:
			var offset := -_dash_dir * (12.0 + k * 10.0)
			draw_circle(offset, 16.0 * (1.0 - k * 0.18),
				Color(0.28, 0.78, 0.28, pct * (0.35 - k * 0.07)))
	# Indicador de cooldown de dash (arco debajo del jugador)
	elif _dash_cd > 0.0:
		var ready_pct := 1.0 - (_dash_cd / DASH_COOLDOWN)
		draw_arc(Vector2.ZERO, 19.0, -PI * 0.5, -PI * 0.5 + TAU * ready_pct, 24,
			Color(0.28, 0.78, 0.28, 0.5), 2.0)

	# Cuerpo (se escala ligeramente al subir de nivel)
	var sf := 1.0 + _elevation_level * 0.04
	var r  := 16.0 * sf
	draw_circle(Vector2.ZERO, r, Color(0.13, 0.52, 0.13))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.28, 0.78, 0.28), 2.5)
	draw_circle(Vector2(4, 0), 9 * sf, Color(0.08, 0.40, 0.08))
	draw_rect(Rect2(Vector2(1, -4), Vector2(11, 8) * sf), Color(0.1, 0.72, 1.0, 0.88))
	draw_rect(Rect2(Vector2(14, -2.5), Vector2(14, 5)), Color(0.58, 0.58, 0.62))
	draw_rect(Rect2(Vector2(14, -2.5), Vector2(14, 5)), Color(0.75, 0.75, 0.8), false, 1.0)

	# Indicador de nivel
	if _elevation_level > 0:
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(-9, -r - 6), "L%d" % _elevation_level,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 1.0, 0.5))

	# Arco de recarga
	if _reloading:
		var total: float = RIFLE_RELOAD_TIME if _weapon == Weapon.RIFLE else SHOTGUN_RELOAD_TIME
		var pct: float   = clampf(1.0 - _reload_t / total, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 22, -PI / 2, -PI / 2 + TAU * pct, 32,
			Color(1.0, 0.85, 0.2), 3.0)


func _physics_process(delta: float) -> void:
	_dash_t  = maxf(_dash_t  - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	if _dash_t > 0.0 or _dash_cd > 0.0:
		queue_redraw()
	if _dash_t > 0.0:
		velocity = _dash_dir * DASH_SPEED
	else:
		_move()
	look_at(get_global_mouse_position())
	move_and_slide()
	_clamp_to_elevation_platform()

	_fire_cd -= delta
	_stair_cooldown = maxf(_stair_cooldown - delta, 0.0)

	# Detección de escalera
	_check_stair_zone()

	# Recarga
	if _reloading:
		_reload_t -= delta
		queue_redraw()
		if _reload_t <= 0.0:
			_finish_reload()

	# Infección
	if infected and not serum:
		_infect_tick -= delta
		if _infect_tick <= 0.0:
			_infect_tick = 2.0
			hp = max(0, hp - 3)
			health_changed.emit(hp)
			queue_redraw()
			if hp <= 0:
				infected = false
				infection_changed.emit(false)
				died.emit()

	# Disparo
	var rate := _shotgun_rate if _weapon == Weapon.SHOTGUN else _rifle_rate
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and _fire_cd <= 0.0 and not building and not _reloading:
		if _has_mag_ammo():
			_shoot()
			_fire_cd = rate
		else:
			if _can_reload():
				_start_reload()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_weapon(Weapon.RIFLE)
			KEY_2: _set_weapon(Weapon.SHOTGUN)
			KEY_R:
				if _can_reload():
					_start_reload()
			KEY_E:
				_try_climb()
			KEY_SPACE:
				_try_dash()


# ─────────────────────────────────────────────────────────────────────────────
# Dash
# ─────────────────────────────────────────────────────────────────────────────

func _try_dash() -> void:
	if _dash_cd > 0.0 or _elevation_level > 0:
		return
	var dir := Vector2(
		Input.get_axis("ui_left",  "ui_right"),
		Input.get_axis("ui_up",    "ui_down")).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.from_angle(rotation)
	_dash_dir = dir
	_dash_t   = DASH_DURATION
	_dash_cd  = DASH_COOLDOWN
	queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
# Elevación
# ─────────────────────────────────────────────────────────────────────────────

func _clamp_to_elevation_platform() -> void:
	if _elevation_level == 0 or not is_instance_valid(fortress):
		return
	var bounds: Rect2 = fortress.get_level_bounds(_elevation_level, global_position)
	if bounds.size == Vector2.ZERO:
		return
	const MARGIN := 8.0
	global_position.x = clamp(global_position.x,
		bounds.position.x + MARGIN, bounds.end.x - MARGIN)
	global_position.y = clamp(global_position.y,
		bounds.position.y + MARGIN, bounds.end.y - MARGIN)

func _check_stair_zone() -> void:
	if not is_instance_valid(fortress):
		return
	var stair = fortress.get_stair_at(global_position)
	var prev  = _current_stair
	_current_stair = stair
	if stair != null:
		var can_climb := false
		var target    := _elevation_level
		if int(stair["from_level"]) == _elevation_level:
			target    = int(stair["to_level"])
			can_climb = true
		elif int(stair["to_level"]) == _elevation_level:
			target    = int(stair["from_level"])
			can_climb = true
		if can_climb and prev != stair:
			stair_state_changed.emit(true, target)
	elif prev != null:
		stair_state_changed.emit(false, _elevation_level)


func _try_climb() -> void:
	if _stair_cooldown > 0.0 or _current_stair == null:
		return
	var stair = _current_stair
	var target := _elevation_level
	if int(stair["from_level"]) == _elevation_level:
		target = int(stair["to_level"])
	elif int(stair["to_level"]) == _elevation_level:
		target = int(stair["from_level"])
	else:
		return
	_elevation_level = target
	_stair_cooldown  = 0.4
	elevation_changed.emit(_elevation_level)
	modulate = Color(1.3, 1.3, 1.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.25)
	queue_redraw()


func get_elevation_level() -> int:
	return _elevation_level

func get_range_mult() -> float:
	return ELEV_RANGE_MULT[clamp(_elevation_level, 0, 3)]

func get_damage_mult() -> float:
	return ELEV_DMG_MULT[clamp(_elevation_level, 0, 3)]


# ─────────────────────────────────────────────────────────────────────────────
# Armas
# ─────────────────────────────────────────────────────────────────────────────

func _set_weapon(w: Weapon) -> void:
	if _weapon == w:
		return
	if _reloading:
		_reloading = false
		_reload_t  = 0.0
		queue_redraw()
	_weapon  = w
	_fire_cd = 0.0
	weapon_changed.emit("RIFLE" if w == Weapon.RIFLE else "ESCOPETA")
	_emit_ammo()


func _move() -> void:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    d.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  d.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  d.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d.x += 1
	velocity = d.normalized() * _speed


func _shoot() -> void:
	if not is_instance_valid(bullet_container):
		return
	SoundManager.play("shoot")
	match _weapon:
		Weapon.RIFLE:   _shoot_rifle()
		Weapon.SHOTGUN: _shoot_shotgun()


func _shoot_rifle() -> void:
	var b := BULLET_SCENE.instantiate()
	b.global_position = global_position
	b.direction = (get_global_mouse_position() - global_position).normalized()
	if "lifetime" in b:
		b.lifetime = float(b.lifetime) * get_range_mult()
	if "damage" in b:
		b.damage = int(int(b.damage) * get_damage_mult())
	bullet_container.add_child(b)
	_rifle_mag -= 1
	_emit_ammo()
	if _rifle_mag <= 0 and _rifle_reserve > 0:
		_start_reload()


func _shoot_shotgun() -> void:
	var base_dir := (get_global_mouse_position() - global_position).normalized()
	for i in 6:
		var b := BULLET_SCENE.instantiate()
		b.global_position = global_position
		b.direction       = base_dir.rotated(randf_range(deg_to_rad(-20.0), deg_to_rad(20.0)))
		b.lifetime        = 0.45 * get_range_mult()
		b.damage          = int(15 * get_damage_mult())
		b.bcolor          = Color(1.0, 0.55, 0.1)
		b.bradius         = 5.0
		bullet_container.add_child(b)
	_shotgun_mag -= 1
	_emit_ammo()
	if _shotgun_mag <= 0 and _shotgun_reserve > 0:
		_start_reload()


# ─────────────────────────────────────────────────────────────────────────────
# Munición
# ─────────────────────────────────────────────────────────────────────────────

func _has_mag_ammo() -> bool:
	return _rifle_mag > 0 if _weapon == Weapon.RIFLE else _shotgun_mag > 0

func _can_reload() -> bool:
	if _reloading:
		return false
	if _weapon == Weapon.RIFLE:
		return _rifle_mag < RIFLE_MAG_SIZE and _rifle_reserve > 0
	return _shotgun_mag < SHOTGUN_MAG_SIZE and _shotgun_reserve > 0

func _start_reload() -> void:
	_reloading = true
	_reload_t  = RIFLE_RELOAD_TIME if _weapon == Weapon.RIFLE else SHOTGUN_RELOAD_TIME
	queue_redraw()
	_emit_ammo()

func _finish_reload() -> void:
	_reloading = false
	if _weapon == Weapon.RIFLE:
		var needed: int = RIFLE_MAG_SIZE - _rifle_mag
		var taken: int  = mini(needed, _rifle_reserve)
		_rifle_mag     += taken
		_rifle_reserve -= taken
	else:
		var needed: int = SHOTGUN_MAG_SIZE - _shotgun_mag
		var taken: int  = mini(needed, _shotgun_reserve)
		_shotgun_mag     += taken
		_shotgun_reserve -= taken
	queue_redraw()
	_emit_ammo()

func _emit_ammo() -> void:
	if _weapon == Weapon.RIFLE:
		ammo_changed.emit("RIFLE", _rifle_mag, RIFLE_MAG_SIZE,
			_rifle_reserve, RIFLE_MAX_RESERVE, _reloading)
	else:
		ammo_changed.emit("ESCOPETA", _shotgun_mag, SHOTGUN_MAG_SIZE,
			_shotgun_reserve, SHOTGUN_MAX_RESERVE, _reloading)

func add_ammo(rifle_amt: int = 0, shotgun_amt: int = 0) -> void:
	_rifle_reserve   = mini(_rifle_reserve   + rifle_amt,   RIFLE_MAX_RESERVE)
	_shotgun_reserve = mini(_shotgun_reserve + shotgun_amt, SHOTGUN_MAX_RESERVE)
	_emit_ammo()

func refill_ammo() -> void:
	_rifle_reserve   = RIFLE_MAX_RESERVE
	_shotgun_reserve = SHOTGUN_MAX_RESERVE
	if _rifle_mag < RIFLE_MAG_SIZE:
		var n: int = mini(RIFLE_MAG_SIZE - _rifle_mag, _rifle_reserve)
		_rifle_mag     += n
		_rifle_reserve -= n
	if _shotgun_mag < SHOTGUN_MAG_SIZE:
		var n: int = mini(SHOTGUN_MAG_SIZE - _shotgun_mag, _shotgun_reserve)
		_shotgun_mag     += n
		_shotgun_reserve -= n
	if _reloading:
		_reloading = false
		_reload_t  = 0.0
		queue_redraw()
	_emit_ammo()


# ─────────────────────────────────────────────────────────────────────────────
# Upgrades / daño
# ─────────────────────────────────────────────────────────────────────────────

func upgrade_speed() -> void:
	_speed = minf(_speed * 1.25, 500.0)

func upgrade_fire_rate() -> void:
	_rifle_rate   = maxf(_rifle_rate   * 0.80, 0.055)
	_shotgun_rate = maxf(_shotgun_rate * 0.80, 0.18)

func upgrade_armor() -> void:
	max_hp += 25
	hp      = mini(hp + 20, max_hp)

func heal_full() -> void:
	hp = max_hp

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	health_changed.emit(hp)
	modulate = Color(1.0, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		died.emit()
