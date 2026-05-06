extends Node2D

const PLAYER_SCENE    = preload("res://scenes/player.tscn")
const LARVA_SCENE     = preload("res://scenes/larva.tscn")
const SALTADORA_SCENE = preload("res://scenes/saltadora.tscn")
const BLINDADO_SCENE  = preload("res://scenes/blindado.tscn")
const ESCUPIDOR_SCENE = preload("res://scenes/escupidor.tscn")
const HUD_SCENE       = preload("res://scenes/hud.tscn")
const WALL_SCENE      = preload("res://scenes/wall.tscn")
const TURRET_SCENE    = preload("res://scenes/turret.tscn")
const DeathEffect     = preload("res://scripts/death_effect.gd")
const Background      = preload("res://scripts/background.gd")
const Fortress        = preload("res://scripts/fortress.gd")
const WallPreview     = preload("res://scripts/wall_preview.gd")
const TurretPreview   = preload("res://scripts/turret_preview.gd")
const ScrapText       = preload("res://scripts/scrap_text.gd")
const MINE_SCENE      = preload("res://scenes/mine.tscn")
const MinePreview     = preload("res://scripts/mine_preview.gd")
const Crate           = preload("res://scripts/crate.gd")
const BombEffect      = preload("res://scripts/bomb_effect.gd")
const Grenade         = preload("res://scripts/grenade.gd")
const _MissionData    = preload("res://scripts/mission_data.gd")
const _MissionRuntime = preload("res://scripts/mission_runtime.gd")
const Satellite       = preload("res://scripts/satellite.gd")
const ResearchCache   = preload("res://scripts/research_cache.gd")
const Burrow          = preload("res://scripts/burrow.gd")
const Engendro        = preload("res://scripts/engendro.gd")

const NPCAssault  = preload("res://scripts/npc_assault.gd")
const NPCMedic    = preload("res://scripts/npc_medic.gd")
const NPCEngineer = preload("res://scripts/npc_engineer.gd")

const VIEW_W   := 1280.0
const VIEW_H   := 720.0
const MAP_W    := 2400.0
const MAP_H    := 1600.0
const BASE_POS := Vector2(MAP_W * 0.5, MAP_H * 0.5)
const BASE_R   := 50.0

const SPAWN_POINTS := {
	"N":  Vector2(MAP_W * 0.5,   -55.0),
	"NE": Vector2(MAP_W + 55.0,   MAP_H * 0.18),
	"E":  Vector2(MAP_W + 55.0,   MAP_H * 0.5),
	"SE": Vector2(MAP_W + 55.0,   MAP_H * 0.82),
	"S":  Vector2(MAP_W * 0.5,    MAP_H + 55.0),
	"SW": Vector2(-55.0,          MAP_H * 0.82),
	"W":  Vector2(-55.0,          MAP_H * 0.5),
	"NW": Vector2(-55.0,          MAP_H * 0.18),
}


const AMMO_DROP_CHANCE  := 0.15
const AMMO_DROP_RIFLE   := 8
const AMMO_DROP_SHOTGUN := 2

enum BuildType { WALL, TURRET, WALL_PLUS, MINE }

const BUILD_PHASE_TIME := 15.0
const MAX_TURRETS      := 3

var _player:          CharacterBody2D
var _enemies:         Node2D
var _friendlies:      Node2D
var _bullets:         Node2D
var _walls:           Node2D
var _hud:             CanvasLayer
var _camera:          Camera2D
var _fortress:        Node2D
var _wall_preview:    Node2D
var _turret_preview:  Node2D
var _mine_preview:    Node2D
var _crates:           Node2D
var _mission_objects:  Node2D
var _title_ol:        CanvasLayer
var _title_bg:        ColorRect
var _title_blink:     Tween

var _assault_npc:  Node2D
var _medic_npc:    Node2D
var _engineer_npc: Node2D

var _wave:       int  = 0
var _kills:      int  = 0
var _killed:     int  = 0
var _game_over:  bool = false

var _mission_active:   bool = false
var _mission_runtime:  Node = null
var _mission_finished: bool = false
var _boss:             Node = null

var _base_hp:     int   = 1000
var _base_dmg_cd: float = 0.0
var _shake:       float = 0.0

var _bomb_count:    int  = 0
var _grenade_count: int  = 3
var _grenade_mode:  bool = false

var _biomasa:          int       = 0
var _build_phase:      bool      = false
var _build_phase_time: float     = 0.0
var _build_mode:       bool      = false
var _build_type:       BuildType = BuildType.WALL

var _upg_speed:         int  = 0
var _upg_fire:          int  = 0
var _upg_armor:         int  = 0
var _healed_this_phase: bool = false

func _ready() -> void:
	_build_scene()
	if StageManager.selected_mission_id.is_empty():
		_show_title()
	else:
		_start_game()

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size  = Vector2(MAP_W, MAP_H)
	bg.color = Color(0.06, 0.06, 0.11)
	add_child(bg)

	var grid := Background.new()
	grid.map_w = MAP_W
	grid.map_h = MAP_H
	add_child(grid)

	_fortress          = Fortress.new()
	_fortress.position = BASE_POS
	add_child(_fortress)

	_walls      = Node2D.new()
	_friendlies = Node2D.new()
	_enemies    = Node2D.new()
	_bullets    = Node2D.new()
	add_child(_walls)
	add_child(_friendlies)
	add_child(_enemies)
	add_child(_bullets)
	_crates = Node2D.new()
	add_child(_crates)
	_mission_objects = Node2D.new()
	add_child(_mission_objects)

	_player                  = PLAYER_SCENE.instantiate()
	_player.position         = BASE_POS
	_player.bullet_container = _bullets
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_hp_changed)
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	add_child(_player)
	if "fortress" in _player:
		_player.fortress = _fortress

	_wall_preview         = WallPreview.new()
	_wall_preview.z_index = 10
	_wall_preview.visible = false
	add_child(_wall_preview)

	_turret_preview         = TurretPreview.new()
	_turret_preview.z_index = 10
	_turret_preview.visible = false
	add_child(_turret_preview)

	_mine_preview         = MinePreview.new()
	_mine_preview.z_index = 10
	_mine_preview.visible = false
	add_child(_mine_preview)

	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.update_hp(100)
	_hud.update_wave(0)
	_hud.update_kills(0)
	_hud.update_base_hp(1000)
	_hud.update_biomasa(0)
	_hud.update_grenade(_grenade_count, false)
	_player.weapon_changed.connect(_hud.update_weapon)
	_player.ammo_changed.connect(_hud.update_ammo)
	_player.infection_changed.connect(_on_infection_changed)
	if _player.has_signal("elevation_changed"):
		_player.elevation_changed.connect(_on_player_elevation_changed)
	if _player.has_signal("stair_state_changed"):
		_player.stair_state_changed.connect(_on_stair_state_changed)
	_hud.build_type_selected.connect(_on_build_card_selected)
	_hud.upgrade_selected.connect(_on_upgrade_selected)
	_hud.init_minimap(_player, _enemies, _friendlies, BASE_POS, MAP_W, MAP_H)
	_hud.set_crates_node(_crates)

	_camera = Camera2D.new()
	_camera.position                = BASE_POS
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 6.0
	_camera.limit_left   = 0
	_camera.limit_top    = 0
	_camera.limit_right  = int(MAP_W)
	_camera.limit_bottom = int(MAP_H)
	add_child(_camera)
	_camera.make_current()

# ── Title screen ──────────────────────────────────────────────────────────────

func _show_title() -> void:
	_title_ol       = CanvasLayer.new()
	_title_ol.layer = 10
	add_child(_title_ol)

	_title_bg       = ColorRect.new()
	_title_bg.size  = Vector2(VIEW_W, VIEW_H)
	_title_bg.color = Color(0.03, 0.03, 0.07, 0.96)
	_title_ol.add_child(_title_bg)

	_add_line(130, Color(0.28, 0.72, 0.28, 0.55))
	_add_line(590, Color(0.28, 0.72, 0.28, 0.55))

	_title_lbl("◈  OPERATION: LAST COLONY  ◈", 40, Color(0.3, 1.0, 0.42), Vector2(0, 158), VIEW_W)
	_title_lbl("SECTOR ALPHA  ·  ESCUADRÓN ALPHA-7", 16, Color(0.38, 0.62, 0.38), Vector2(0, 208), VIEW_W)

	var lore_text := (
		"El planeta fue invadido por criaturas bioorgánicas.\n" +
		"Tu escuadrón es la última defensa del sector.\n\n" +
		"Refuerzos en camino:  ⚔ ASALTO   ✚ MÉDICO   ⚙ INGENIERO\n\n" +
		"Defiende el Núcleo.  Reconquista el mundo."
	)
	var lore := _title_lbl(lore_text, 19, Color(0.72, 0.85, 0.72), Vector2(240, 260), 800)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_title_lbl(
		"WASD — Mover  |  Click — Disparar  |  R — Recargar  |  1/2 — Arma  |  G — Granada  |  Q — Bomba  |  F — Interactuar",
		14, Color(0.46, 0.62, 0.46), Vector2(0, 490), VIEW_W)

	var prompt := _title_lbl(
		"[ PRESIONÁ  ENTER  O  ESPACIO  PARA  DESPLEGAR ]",
		22, Color(1.0, 0.85, 0.2), Vector2(0, 535), VIEW_W)
	_title_blink = create_tween().set_loops()
	_title_blink.tween_property(prompt, "modulate:a", 0.15, 0.65)
	_title_blink.tween_property(prompt, "modulate:a", 1.0,  0.65)

func _add_line(y: int, color: Color) -> void:
	var r := ColorRect.new()
	r.size     = Vector2(VIEW_W, 2)
	r.position = Vector2(0, y)
	r.color    = color
	_title_ol.add_child(r)

func _title_lbl(text: String, size: int, color: Color, pos: Vector2, w: float) -> Label:
	var l := Label.new()
	l.text      = text
	l.size      = Vector2(w, 0)
	l.position  = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	_title_ol.add_child(l)
	return l

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _build_mode:
				_place_structure()
				get_viewport().set_input_as_handled()
			elif _grenade_mode and _mission_active:
				_throw_grenade(get_global_mouse_position())
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and _build_phase:
			_repair_nearest()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_title_ol):
		var ok := false
		if event is InputEventKey and event.pressed and not event.echo:
			ok = event.keycode in [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER]
		elif event is InputEventMouseButton and event.pressed:
			ok = true
		if ok:
			_dismiss_title()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				if _build_phase: _set_build_type(BuildType.WALL)
			KEY_T:
				if _build_phase: _set_build_type(BuildType.TURRET)
			KEY_N:
				if _build_phase: _set_build_type(BuildType.WALL_PLUS)
			KEY_M:
				if _build_phase: _set_build_type(BuildType.MINE)
			KEY_ESCAPE:
				if _build_mode: _set_build_mode(false)
			KEY_F:
				_try_revive_nearby()
				_try_interact_mission_object()
			KEY_Q:
				_use_bomb()
			KEY_G:
				_toggle_grenade_mode()
			KEY_ENTER, KEY_KP_ENTER:
				if _build_phase: _end_build_phase()
			KEY_4:
				if _build_phase: _try_upgrade_speed()
			KEY_5:
				if _build_phase: _try_upgrade_fire()
			KEY_6:
				if _build_phase: _try_upgrade_armor()
			KEY_7:
				if _build_phase: _try_heal()

func _dismiss_title() -> void:
	if not is_instance_valid(_title_ol):
		return
	if is_instance_valid(_title_blink):
		_title_blink.kill()
	var tw := create_tween()
	tw.tween_property(_title_bg, "modulate:a", 0.0, 0.45)
	tw.tween_callback(func():
		_title_ol.queue_free()
		_title_ol = null)
	tw.tween_callback(_start_game)

func _start_game() -> void:
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_setup_mission_runtime()
	_start_build_phase()

func _setup_mission_runtime() -> void:
	var mid := StageManager.selected_mission_id
	if mid.is_empty():
		return
	var mission = StageRegistry.get_mission(mid)
	if mission == null:
		return

	if mission.type == _MissionData.MissionType.INCURSION:
		_fortress.position = Vector2(-9999.0, -9999.0)

	if StageManager.is_reward_unlocked("antiserum") and is_instance_valid(_player):
		_player.serum = true

	_spawn_pre_populate(mission.pre_populate_enemies)
	_spawn_mission_objects(mission)

	_mission_runtime = _MissionRuntime.new()
	_mission_runtime.mission = mission
	add_child(_mission_runtime)
	_mission_runtime.completed.connect(_on_mission_completed)
	_mission_runtime.failed.connect(_on_mission_failed)
	_mission_runtime.start()

func _spawn_pre_populate(count: int) -> void:
	if count <= 0:
		return
	for _i in count:
		var e = LARVA_SCENE.instantiate()
		e.speed            = 55.0
		e.max_hp           = 20
		e.hp               = 20
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e:
			e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		e.position = _pick_far_spawn_pos()
		_enemies.add_child(e)

func _pick_far_spawn_pos() -> Vector2:
	for _i in 30:
		var pos := Vector2(
			randf_range(200.0, MAP_W - 200.0),
			randf_range(200.0, MAP_H - 200.0))
		if pos.distance_to(BASE_POS) > 500.0:
			return pos
	return _pick_spawn_pos()

func _spawn_mission_objects(mission) -> void:
	var placed: Array = []
	match mission.objective_type:
		_MissionData.ObjectiveType.ACTIVATE_BEACONS:
			for _i in mission.objective_count:
				var pos := _pick_mission_obj_pos(placed)
				placed.append(pos)
				var sat := Satellite.new()
				sat.position = pos
				sat.activated.connect(_on_satellite_activated)
				_mission_objects.add_child(sat)
		_MissionData.ObjectiveType.COLLECT_CACHES:
			for _i in mission.objective_count:
				var pos := _pick_mission_obj_pos(placed)
				placed.append(pos)
				var cache := ResearchCache.new()
				cache.position = pos
				cache.collected.connect(_on_cache_collected)
				_mission_objects.add_child(cache)
		_MissionData.ObjectiveType.CLOSE_BURROWS:
			for _i in mission.objective_count:
				var pos := _pick_mission_obj_pos(placed)
				placed.append(pos)
				var burrow := Burrow.new()
				burrow.position         = pos
				burrow.player           = _player
				burrow.base_pos         = BASE_POS
				burrow.bullet_container = _bullets
				burrow.wave_num         = _wave
				burrow.closed.connect(_on_burrow_closed)
				burrow.enemy_spawned.connect(_on_burrow_enemy_spawned)
				_mission_objects.add_child(burrow)

func _pick_mission_obj_pos(existing: Array) -> Vector2:
	for _i in 40:
		var pos := Vector2(
			randf_range(250.0, MAP_W - 250.0),
			randf_range(250.0, MAP_H - 250.0))
		if pos.distance_to(BASE_POS) < 450.0:
			continue
		var ok := true
		for ep in existing:
			if pos.distance_to(ep) < 350.0:
				ok = false
				break
		if ok:
			return pos
	return BASE_POS + Vector2(650.0, 0.0).rotated(randf() * TAU)

func _on_satellite_activated(_sat: Node) -> void:
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_satellite_activated()

func _on_cache_collected(_cache: Node) -> void:
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_cache_collected()

func _spawn_boss() -> void:
	_boss                  = Engendro.new()
	_boss.position         = _pick_far_spawn_pos()
	_boss.player           = _player
	_boss.base_pos         = BASE_POS
	_boss.bullet_container = _bullets
	_boss.walls_node       = _walls
	if "fortress" in _boss:
		_boss.fortress = _fortress
	_boss.died.connect(_on_boss_died)
	_boss.summoned_larva.connect(_on_boss_summoned_larva)
	_boss.rugido_emitted.connect(_on_boss_rugido)
	_enemies.add_child(_boss)
	_hud.show_npc_announcement("¡EL ENGENDRO HA LLEGADO!", Color(1.0, 0.25, 0.1))

func _on_boss_died(e: Node) -> void:
	_boss = null
	_on_enemy_died(e)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_boss_killed()

func _on_boss_summoned_larva(e: Node) -> void:
	if not is_instance_valid(e):
		return
	e.died.connect(_on_enemy_died)
	_enemies.add_child(e)

func _on_boss_rugido() -> void:
	for s in _walls.get_children():
		if is_instance_valid(s) and s.get("_fire_cd") != null:
			s.set("_fire_cd", 4.0)
	_hud.show_npc_announcement("¡RUGIDO! TORRETAS PARALIZADAS 4s", Color(0.9, 0.35, 0.1))

func _on_burrow_closed(_burrow: Node) -> void:
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_burrow_closed()

func _on_burrow_enemy_spawned(e: Node) -> void:
	if not is_instance_valid(e):
		return
	e.died.connect(_on_enemy_died)
	_enemies.add_child(e)

func _try_interact_mission_object() -> void:
	if not is_instance_valid(_player) or not _mission_active:
		return
	var ppos := _player.global_position
	for obj in _mission_objects.get_children():
		if not is_instance_valid(obj):
			continue
		if ppos.distance_to(obj.global_position) > 80.0:
			continue
		if obj.has_method("start_activating") and not obj.is_activating():
			obj.start_activating()
			return
		if obj.has_method("collect"):
			obj.collect()
			return
		if obj.has_method("start_closing") and not obj.is_closing():
			obj.start_closing()
			return

func _on_mission_completed(chatarra: int, reward_id: String) -> void:
	_mission_active   = false
	_mission_finished = true
	_biomasa         += chatarra
	_hud.update_biomasa(_biomasa)
	StageManager.set_last_result({
		"success":   true,
		"chatarra":  chatarra,
		"reward_id": reward_id,
		"waves":     _wave,
		"kills":     _kills,
	})
	shake(12.0)
	_hud.announce_wave(_wave, "MISIÓN COMPLETADA")
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(self):
		get_tree().change_scene_to_file("res://scenes/mission_result.tscn")

func _on_mission_failed(reason: String) -> void:
	_game_over      = true
	_mission_active = false
	StageManager.set_last_result({
		"success": false,
		"reason":  reason,
		"waves":   _wave,
		"kills":   _kills,
	})
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_hud.hide_upgrades()
	_hud.hide_build_phase()
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(self):
		get_tree().change_scene_to_file("res://scenes/mission_result.tscn")

# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_tick_camera()
	_tick_base_damage(delta)
	_tick_shake(delta)
	_tick_build_phase(delta)
	_tick_build_preview()
	_tick_mission(delta)

func _tick_camera() -> void:
	if _game_over:
		return
	if is_instance_valid(_player):
		_camera.position = _player.global_position

func _tick_base_damage(delta: float) -> void:
	if _base_hp <= 0 or _game_over:
		return
	_base_dmg_cd -= delta
	if _base_dmg_cd > 0.0:
		return
	_base_dmg_cd = 0.5
	var dmg := 0
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.global_position.distance_to(BASE_POS) < BASE_R:
			dmg += 5
	if dmg == 0:
		return
	_base_hp = max(0, _base_hp - dmg)
	_hud.update_base_hp(_base_hp)
	_fortress.modulate = Color(1.5, 0.35, 0.35)
	var tw := create_tween()
	tw.tween_property(_fortress, "modulate", Color.WHITE, 0.2)
	if _base_hp == 0:
		_on_base_destroyed()

func _tick_shake(delta: float) -> void:
	if _shake <= 0.0:
		return
	_camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_shake = lerpf(_shake, 0.0, 12.0 * delta)
	if _shake < 0.3:
		_shake = 0.0
		_camera.offset = Vector2.ZERO

func _tick_build_phase(delta: float) -> void:
	if not _build_phase:
		return
	_build_phase_time -= delta
	_hud.update_build_timer(ceili(_build_phase_time))
	if _build_phase_time <= 0.0:
		_end_build_phase()

func _tick_build_preview() -> void:
	var preview := _active_preview()
	if not preview.visible:
		return
	var mp := get_global_mouse_position()
	preview.position = Vector2(
		round(mp.x / 40.0) * 40.0,
		round(mp.y / 20.0) * 20.0)

func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

func _on_player_elevation_changed(level: int) -> void:
	if _hud.has_method("update_elevation"):
		_hud.update_elevation(level)
	if _hud.has_method("show_stair_prompt"):
		_hud.show_stair_prompt(false, level, level)

func _on_stair_state_changed(can_climb: bool, target_level: int) -> void:
	var current_level := 0
	if is_instance_valid(_player) and _player.has_method("get_elevation_level"):
		current_level = _player.get_elevation_level()
	if _hud.has_method("show_stair_prompt"):
		_hud.show_stair_prompt(can_climb, target_level, current_level)

# ── Build phase ───────────────────────────────────────────────────────────────

func _start_build_phase() -> void:
	_build_phase        = true
	_build_phase_time   = BUILD_PHASE_TIME
	_healed_this_phase  = false
	_grenade_count      = mini(_grenade_count + 2, 6)
	_grenade_mode       = false
	_hud.show_build_phase(int(BUILD_PHASE_TIME))
	_hud.show_upgrades(_upg_speed, _upg_fire, _upg_armor, _healed_this_phase, _biomasa)
	_hud.update_grenade(_grenade_count, false)

	if is_instance_valid(_player):
		_player.refill_ammo()

	if is_instance_valid(_engineer_npc):
		_engineer_npc.build_phase_active = true
		_engineer_npc.current_threat_dir = Vector2.ZERO

func _end_build_phase() -> void:
	if not _build_phase:
		return
	_build_phase = false
	_set_build_mode(false)
	_hud.hide_build_phase()
	_hud.hide_upgrades()
	_hud.set_minimap_threat(Vector2.ZERO)
	for c in _crates.get_children():
		if is_instance_valid(c): c.queue_free()
	if is_instance_valid(_engineer_npc):
		_engineer_npc.build_phase_active = false
	_start_mission()

func _set_build_type(type: BuildType) -> void:
	if _build_mode and _build_type == type:
		_set_build_mode(false)
	else:
		_build_type = type
		_set_build_mode(true)

func _set_build_mode(on: bool) -> void:
	_build_mode             = on
	_player.building        = on
	_wall_preview.visible   = on and (_build_type == BuildType.WALL or _build_type == BuildType.WALL_PLUS)
	_turret_preview.visible = on and _build_type == BuildType.TURRET
	_mine_preview.visible   = on and _build_type == BuildType.MINE
	if on:
		_wall_preview.modulate = Color(0.6, 1.0, 0.6) if _build_type == BuildType.WALL_PLUS else Color.WHITE
		_active_preview().queue_redraw()
		_hud.update_build_selection(_build_type_name(), _build_cost())
	else:
		_wall_preview.modulate = Color.WHITE
		_hud.update_build_selection("", 0)

func _active_preview() -> Node2D:
	match _build_type:
		BuildType.TURRET:    return _turret_preview
		BuildType.WALL_PLUS: return _wall_preview
		BuildType.MINE:      return _mine_preview
		_:                   return _wall_preview

func _build_cost() -> int:
	match _build_type:
		BuildType.TURRET:    return 18
		BuildType.WALL_PLUS: return 5
		BuildType.MINE:      return 3
		_:                   return 3

func _build_type_name() -> String:
	match _build_type:
		BuildType.TURRET:    return "TORRETA"
		BuildType.WALL_PLUS: return "MURO +"
		BuildType.MINE:      return "MINA"
		_:                   return "MURO"

func _place_structure() -> void:
	var cost := _build_cost()
	if _biomasa < cost:
		return
	var pos := _active_preview().position
	match _build_type:
		BuildType.WALL:
			var w := WALL_SCENE.instantiate()
			w.position = pos
			_walls.add_child(w)
		BuildType.TURRET:
			if _count_turrets() >= MAX_TURRETS:
				_hud.show_npc_announcement("MÁX. 3 TORRETAS", Color(1.0, 0.4, 0.2))
				return
			var t := TURRET_SCENE.instantiate()
			t.position         = pos
			t.bullet_container = _bullets
			t.enemies_node     = _enemies
			if is_instance_valid(_fortress) and _fortress.has_method("get_elevation_at"):
				t.elevation_level = _fortress.get_elevation_at(pos)
			_walls.add_child(t)
		BuildType.WALL_PLUS:
			var w := WALL_SCENE.instantiate()
			w.position = pos
			_walls.add_child(w)
			w.hp     = 600
			w.max_hp = 600
			w.queue_redraw()
		BuildType.MINE:
			var m := MINE_SCENE.instantiate()
			m.position = pos
			_walls.add_child(m)
	_biomasa -= cost
	_hud.update_biomasa(_biomasa)
	_hud.update_upgrades(_upg_speed, _upg_fire, _upg_armor, _healed_this_phase, _biomasa)

func _repair_nearest() -> void:
	if _biomasa < 2:
		return
	var mp        := get_global_mouse_position()
	var best_dist := 65.0
	var best: Node2D = null
	for s in _walls.get_children():
		if not is_instance_valid(s):
			continue
		var hp_v:     Variant = s.get("hp")
		var max_hp_v: Variant = s.get("max_hp")
		if hp_v == null or max_hp_v == null or int(hp_v) >= int(max_hp_v):
			continue
		var d := mp.distance_to(s.global_position)
		if d < best_dist:
			best_dist = d
			best      = s
	if best == null:
		return
	var new_hp := mini(int(best.get("hp")) + 50, int(best.get("max_hp")))
	best.set("hp", new_hp)
	best.queue_redraw()
	_biomasa -= 2
	_hud.update_biomasa(_biomasa)
	_hud.update_upgrades(_upg_speed, _upg_fire, _upg_armor, _healed_this_phase, _biomasa)

func _count_turrets() -> int:
	var n := 0
	for s in _walls.get_children():
		if is_instance_valid(s) and s.get("bullet_container") != null:
			n += 1
	return n

# ── Upgrades ──────────────────────────────────────────────────────────────────

func _try_upgrade_speed() -> void:
	if _upg_speed >= 3 or _biomasa < 5:
		return
	_biomasa   -= 5
	_upg_speed += 1
	_player.upgrade_speed()
	_refresh_hud_upgrades()

func _try_upgrade_fire() -> void:
	if _upg_fire >= 3 or _biomasa < 6:
		return
	_biomasa  -= 6
	_upg_fire += 1
	_player.upgrade_fire_rate()
	_refresh_hud_upgrades()

func _try_upgrade_armor() -> void:
	if _upg_armor >= 2 or _biomasa < 8:
		return
	_biomasa   -= 8
	_upg_armor += 1
	_player.upgrade_armor()
	_hud.update_max_hp(_player.max_hp)
	_hud.update_hp(_player.hp)
	_refresh_hud_upgrades()

func _try_heal() -> void:
	if _healed_this_phase or _biomasa < 10 or _player.hp >= _player.max_hp:
		return
	_biomasa           -= 10
	_healed_this_phase  = true
	_player.heal_full()
	_hud.update_hp(_player.hp)
	_refresh_hud_upgrades()

func _refresh_hud_upgrades() -> void:
	_hud.update_biomasa(_biomasa)
	_hud.update_upgrades(_upg_speed, _upg_fire, _upg_armor, _healed_this_phase, _biomasa)

func _on_infection_changed(is_infected: bool) -> void:
	_hud.set_infected(is_infected)

# ── Crates & bomb ─────────────────────────────────────────────────────────────

func _drop_crate(pos: Vector2, type: Crate.Type) -> void:
	var c := Crate.new()
	c.type     = type
	c.position = pos
	c.picked_up.connect(_on_crate_picked_up)
	_crates.call_deferred("add_child", c)

func _spawn_crates() -> void:
	var spawned: Array[Vector2] = []
	for crate_type in [Crate.Type.BIOMASA, Crate.Type.BIOMASA, Crate.Type.MEDKIT]:
		var pos := _random_crate_pos(spawned)
		spawned.append(pos)
		var c       := Crate.new()
		c.type       = crate_type
		c.position   = pos
		c.picked_up.connect(_on_crate_picked_up)
		_crates.add_child(c)
	var is_boss := (_wave % 5 == 0)
	if is_boss or randf() < 0.40:
		var pos := _random_crate_pos(spawned)
		var c    := Crate.new()
		c.type       = Crate.Type.BOMB
		c.position   = pos
		c.picked_up.connect(_on_crate_picked_up)
		_crates.add_child(c)

func _random_crate_pos(existing: Array) -> Vector2:
	for _i in 30:
		var pos := Vector2(
			randf_range(180.0, MAP_W - 180.0),
			randf_range(180.0, MAP_H - 180.0))
		if pos.distance_to(BASE_POS) < 420.0:
			continue
		var ok := true
		for ep in existing:
			if pos.distance_to(ep) < 220.0:
				ok = false
				break
		if ok:
			return pos
	return BASE_POS + Vector2(500.0, 0.0).rotated(randf() * TAU)

func _on_crate_picked_up(crate_type: int, pos: Vector2) -> void:
	match crate_type:
		Crate.Type.BIOMASA:
			var amount := randi_range(8, 16)
			_biomasa += amount
			_hud.update_biomasa(_biomasa)
			_hud.update_upgrades(_upg_speed, _upg_fire, _upg_armor, _healed_this_phase, _biomasa)
			_spawn_scrap_text(pos, amount)
		Crate.Type.MEDKIT:
			if is_instance_valid(_player):
				_player.heal_full()
				_hud.update_hp(_player.hp)
		Crate.Type.BOMB:
			_bomb_count += 1
			_hud.update_bomb(_bomb_count)

func _use_bomb() -> void:
	if _bomb_count <= 0 or not _mission_active:
		return
	_bomb_count -= 1
	_hud.update_bomb(_bomb_count)
	var snapshot := _enemies.get_children()
	for e in snapshot:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(9999)
	var ef      := BombEffect.new()
	ef.position  = _player.global_position if is_instance_valid(_player) else BASE_POS
	add_child(ef)
	shake(22.0)

func _toggle_grenade_mode() -> void:
	if _grenade_count <= 0:
		return
	_grenade_mode = not _grenade_mode
	_hud.update_grenade(_grenade_count, _grenade_mode)

func _throw_grenade(target_pos: Vector2) -> void:
	if _grenade_count <= 0 or not is_instance_valid(_player):
		return
	_grenade_count -= 1
	_grenade_mode   = false
	_hud.update_grenade(_grenade_count, false)

	var g          := Grenade.new()
	g.target        = target_pos
	g.global_position = _player.global_position
	g.exploded.connect(_on_grenade_exploded)
	add_child(g)

func _on_grenade_exploded(pos: Vector2) -> void:
	const GRENADE_RADIUS := 140.0
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.has_method("take_damage"):
			if e.global_position.distance_to(pos) <= GRENADE_RADIUS:
				e.take_damage(75)
	var ef     := BombEffect.new()
	ef.position = pos
	ef.max_r    = 160.0
	ef.tint     = Color(0.70, 0.95, 0.20)
	add_child(ef)
	shake(8.0)

# ── Wave system ───────────────────────────────────────────────────────────────

func _start_mission() -> void:
	_wave           += 1
	_mission_active  = true
	_killed          = 0
	_hud.update_wave(_wave)
	_check_npc_spawn()
	SoundManager.play_wave()
	shake(4.0)
	_hud.announce_wave(_wave, "OLEADA %d" % _wave)
	_spawn_wave()
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		if _mission_runtime.mission != null:
			if _mission_runtime.mission.objective_type == _MissionData.ObjectiveType.KILL_BOSS and _wave == 4:
				_spawn_boss()

func _spawn_wave() -> void:
	var hp_mult  := 1.0 + (_wave - 1) * 0.22
	var base_spd := 85.0 + (_wave - 1) * 16.0
	var count    := 14 + _wave * 4
	for i in count:
		await get_tree().create_timer(0.25 * i).timeout
		if not _mission_active or not is_instance_valid(self):
			return
		var e: CharacterBody2D
		if _wave >= 4 and randf() < 0.15:
			e = BLINDADO_SCENE.instantiate(); e.speed = base_spd * 0.55
		elif _wave >= 2 and randf() < 0.28:
			e = ESCUPIDOR_SCENE.instantiate(); e.speed = base_spd * 0.85
		elif _wave >= 2 and randf() < 0.35:
			e = SALTADORA_SCENE.instantiate(); e.speed = base_spd * 1.9
		else:
			e = LARVA_SCENE.instantiate(); e.speed = base_spd
		e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * hp_mult))
		e.hp               = e.max_hp
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e:
			e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		e.position         = _pick_spawn_pos()
		_enemies.add_child(e)

func _tick_mission(_delta: float) -> void:
	if not _mission_active or _game_over:
		return
	if _killed > 0 and _enemies.get_child_count() == 0:
		_on_wave_complete()

func _on_wave_complete() -> void:
	if not _mission_active:
		return
	_mission_active = false
	_grenade_mode   = false
	_hud.update_grenade(_grenade_count, false)
	shake(8.0)
	var reward := 8 + _wave * 2
	_biomasa  += reward
	_hud.update_biomasa(_biomasa)
	_spawn_scrap_text(BASE_POS + Vector2(0, -80), reward)
	_hud.announce_wave(_wave, "OLEADA COMPLETADA  +%d CHATARRA" % reward)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_wave_completed()
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(self) and not _game_over and not _mission_finished:
		_start_build_phase()

# ── NPC squad ─────────────────────────────────────────────────────────────────

func _check_npc_spawn() -> void:
	if _wave == 1 and not is_instance_valid(_assault_npc):
		_spawn_assault_npc()
	elif _wave == 2 and not is_instance_valid(_medic_npc):
		_spawn_medic_npc()
	elif _wave == 3 and not is_instance_valid(_engineer_npc):
		_spawn_engineer_npc()

func _spawn_assault_npc() -> void:
	_assault_npc                  = NPCAssault.new()
	_assault_npc.position         = BASE_POS + Vector2(70, 0)
	_assault_npc.player           = _player
	_assault_npc.base_pos         = BASE_POS
	_assault_npc.bullet_container = _bullets
	_assault_npc.enemies_node     = _enemies
	_assault_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_assault_npc)
	_hud.show_npc_announcement("ASALTO", Color(0.45, 0.75, 1.0))

func _spawn_medic_npc() -> void:
	_medic_npc                  = NPCMedic.new()
	_medic_npc.position         = BASE_POS + Vector2(-70, 0)
	_medic_npc.player           = _player
	_medic_npc.base_pos         = BASE_POS
	_medic_npc.bullet_container = _bullets
	_medic_npc.enemies_node     = _enemies
	_medic_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_medic_npc)
	_hud.show_npc_announcement("MÉDICO", Color(0.30, 1.0, 0.55))

func _spawn_engineer_npc() -> void:
	_engineer_npc                  = NPCEngineer.new()
	_engineer_npc.position         = BASE_POS + Vector2(0, -70)
	_engineer_npc.player           = _player
	_engineer_npc.base_pos         = BASE_POS
	_engineer_npc.bullet_container = _bullets
	_engineer_npc.enemies_node     = _enemies
	_engineer_npc.walls_node       = _walls
	_engineer_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_engineer_npc)
	_hud.show_npc_announcement("INGENIERO", Color(1.0, 0.65, 0.20))

func _on_npc_died(npc: Node) -> void:
	if npc == _assault_npc:
		_assault_npc = null
	elif npc == _medic_npc:
		_medic_npc = null
	elif npc == _engineer_npc:
		_engineer_npc = null

func _on_build_card_selected(type: int) -> void:
	if not _build_phase:
		return
	_set_build_type(type as BuildType)

func _try_revive_nearby() -> void:
	if not is_instance_valid(_player):
		return
	for npc in _friendlies.get_children():
		if not is_instance_valid(npc) or not npc.get("down"):
			continue
		if _player.global_position.distance_to(npc.global_position) < 65.0:
			npc.revive(60)
			_hud.show_npc_announcement("RESCATADO", Color(0.3, 1.0, 0.6))
			return

func _on_upgrade_selected(type: int) -> void:
	if not _build_phase:
		return
	match type:
		0: _try_upgrade_speed()
		1: _try_upgrade_fire()
		2: _try_upgrade_armor()
		3: _try_heal()

# ── Spawn ─────────────────────────────────────────────────────────────────────

func _pick_spawn_pos() -> Vector2:
	var keys := SPAWN_POINTS.keys()
	var dir: String = keys[randi() % keys.size()]
	var base: Vector2 = SPAWN_POINTS[dir]
	var jitter := 80.0
	if dir == "N" or dir == "S":
		return base + Vector2(randf_range(-jitter, jitter), 0)
	elif dir == "E" or dir == "W":
		return base + Vector2(0, randf_range(-jitter, jitter))
	else:
		return base + Vector2(randf_range(-jitter*0.5, jitter*0.5), randf_range(-jitter*0.5, jitter*0.5))

# ── Events ────────────────────────────────────────────────────────────────────

func _on_enemy_died(e: Node) -> void:
	_kills  += 1
	_killed += 1
	_hud.update_kills(_kills)
	_spawn_death_effect(e.global_position, e.body_color)
	var raw    = e.get("max_hp")
	var scrap := clampi(int(float(int(raw)) / 10.0), 1, 5) if raw != null else 1
	_biomasa  += scrap
	_hud.update_biomasa(_biomasa)
	_spawn_scrap_text(e.global_position, scrap)

	if randf() < AMMO_DROP_CHANCE and is_instance_valid(_player):
		_player.add_ammo(AMMO_DROP_RIFLE, AMMO_DROP_SHOTGUN)
		_spawn_ammo_text(e.global_position)

	# Loot de enemigos grandes
	var hp_v: int = int(raw) if raw != null else 0
	if hp_v >= 300:
		_drop_crate(e.global_position, Crate.Type.MEDKIT)
		if randf() < 0.55:
			_drop_crate(e.global_position + Vector2(randf_range(-35,35), randf_range(-35,35)), Crate.Type.BOMB)
	elif hp_v >= 100:
		if randf() < 0.75:
			_drop_crate(e.global_position, Crate.Type.MEDKIT)
	elif hp_v >= 50:
		if randf() < 0.50:
			_drop_crate(e.global_position, Crate.Type.BIOMASA)

	SoundManager.play("death")
	shake(1.5)

func _spawn_death_effect(pos: Vector2, color: Color) -> void:
	var ef      = DeathEffect.new()
	ef.position = pos
	ef._color   = color
	add_child(ef)

func _spawn_scrap_text(pos: Vector2, amount: int) -> void:
	var st      = ScrapText.new()
	st.position = pos
	st.amount   = amount
	add_child(st)

func _spawn_ammo_text(pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = "+%d MUN" % AMMO_DROP_RIFLE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl.position = pos + Vector2(-20, -28)
	lbl.z_index  = 5
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 30, 0.9)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.tween_callback(lbl.queue_free)

func _on_player_died() -> void:
	_game_over      = true
	_mission_active = false
	_bomb_count     = 0
	_set_build_mode(false)
	_hud.hide_upgrades()
	_hud.hide_build_phase()
	_hud.set_minimap_threat(Vector2.ZERO)
	for c in _crates.get_children():
		if is_instance_valid(c): c.queue_free()
	for e in _enemies.get_children():
		e.queue_free()
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		var mtype = _mission_runtime.mission.type if _mission_runtime.mission != null else -1
		if mtype == _MissionData.MissionType.SURVIVAL:
			_mission_runtime.notify_failed_survival()
		else:
			_mission_runtime.notify_failed("player_died")
	else:
		_hud.show_game_over(_wave, _kills)

func _on_base_destroyed() -> void:
	_game_over      = true
	_mission_active = false
	_bomb_count     = 0
	_set_build_mode(false)
	_hud.hide_upgrades()
	_hud.hide_build_phase()
	_hud.set_minimap_threat(Vector2.ZERO)
	for c in _crates.get_children():
		if is_instance_valid(c): c.queue_free()
	for e in _enemies.get_children():
		e.queue_free()
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		var mtype = _mission_runtime.mission.type if _mission_runtime.mission != null else -1
		if mtype == _MissionData.MissionType.SURVIVAL:
			_mission_runtime.notify_failed_survival()
		else:
			_mission_runtime.notify_failed("base_destroyed")
	else:
		_hud.show_game_over(_wave, _kills, true)

func _on_hp_changed(v: int) -> void:
	_hud.update_hp(v)
	SoundManager.play("damage")
	shake(6.0)
