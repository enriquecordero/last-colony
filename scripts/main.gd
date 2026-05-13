extends Node2D

const PLAYER_SCENE    = preload("res://scenes/player.tscn")
const LARVA_SCENE     = preload("res://scenes/larva.tscn")
const SALTADORA_SCENE = preload("res://scenes/saltadora.tscn")
const BLINDADO_SCENE  = preload("res://scenes/blindado.tscn")
const ESCUPIDOR_SCENE = preload("res://scenes/escupidor.tscn")
const EXPLOSIVO_SCENE = preload("res://scenes/explosivo.tscn")
const VOLADOR_SCENE   = preload("res://scenes/volador.tscn")
const TANQUE_SCENE    = preload("res://scenes/tanque.tscn")
const EXCAVADOR_SCENE = preload("res://scenes/excavador.tscn")
const HUD_SCENE       = preload("res://scenes/hud.tscn")
const WALL_SCENE      = preload("res://scenes/wall.tscn")
const TURRET_SCENE    = preload("res://scenes/turret.tscn")
const DeathEffect     = preload("res://scripts/death_effect.gd")
const Background      = preload("res://scripts/background.gd")
const Terrain         = preload("res://scripts/terrain.gd")
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
const BossArena       = preload("res://scripts/boss_arena.gd")
const RuinsDecor      = preload("res://scripts/ruins_decor.gd")
const Barricada       = preload("res://scripts/barricada.gd")
const BarricadaPreview = preload("res://scripts/barricada_preview.gd")

const NPCAssault        = preload("res://scripts/npc_assault.gd")
const NPCMedic          = preload("res://scripts/npc_medic.gd")
const NPCEngineer       = preload("res://scripts/npc_engineer.gd")
const NPCFrancotirador  = preload("res://scripts/npc_francotirador.gd")
const NPCDemoliciones   = preload("res://scripts/npc_demoliciones.gd")
const FortressSkillTree        = preload("res://scripts/fortress_skill_tree.gd")
const FortressAmmoStation      = preload("res://scripts/fortress_ammo_station.gd")
const FortressGeneratorStation = preload("res://scripts/fortress_generator_station.gd")
const DESTRUCTOR_SCENE         = preload("res://scenes/destructor.tscn")
const CORRUPTOR_SCENE          = preload("res://scenes/corruptor.tscn")
const MenteColmena             = preload("res://scripts/mente_colmena.gd")
const Reina                    = preload("res://scripts/reina.gd")
const AcidPool                 = preload("res://scripts/acid_pool.gd")

const VIEW_W   := 1280.0
const VIEW_H   := 720.0
const MAP_W    := 2400.0
const MAP_H    := 1600.0
const BASE_POS := Vector2(MAP_W * 0.5, MAP_H * 0.5)
const BASE_R   := 160.0

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


const AMMO_DROP_CHANCE  := 0.18
const AMMO_DROP_RIFLE   := 22
const AMMO_DROP_SHOTGUN := 4

enum BuildType { WALL, TURRET, WALL_PLUS, MINE, BARRICADA }

const BUILD_PHASE_TIME := 14.0
const MAX_TURRETS      := 3

var _player:          CharacterBody2D
var _player2:         CharacterBody2D = null
var _enemies:         Node2D
var _friendlies:      Node2D
var _bullets:         Node2D
var _walls:           Node2D
var _hud:             CanvasLayer
var _camera:          Camera2D
var _fortress:        Node2D
var _wall_preview:       Node2D
var _turret_preview:     Node2D
var _mine_preview:       Node2D
var _barricada_preview:  Node2D
var _crates:           Node2D
var _mission_objects:  Node2D
var _title_ol:        CanvasLayer
var _title_bg:        ColorRect
var _title_blink:     Tween

var _assault_npc:  Node2D
var _medic_npc:    Node2D
var _engineer_npc: Node2D
var _sniper_npc:   Node2D
var _demo_npc:     Node2D
var _extra_grunts: Array  = []
const EXTRA_GRUNT_CAP := 8

# Player downed-revive state (active when medic is alive at moment of death)
var _player_down_active: bool  = false
var _player_down_t:      float = 0.0
const PLAYER_DOWN_TIMEOUT := 10.0
const PLAYER_REVIVE_RANGE := 60.0
const PLAYER_REVIVE_HP    := 60

var _wave:        int  = 0
var _kills:       int  = 0
var _killed:      int  = 0
var _wave_total:  int  = 0
var _game_over:   bool = false

var _mission_active:   bool = false
var _mission_runtime:  Node = null
var _mission_finished: bool = false
var _boss:             Node = null

var _base_hp:     int   = 1000
var _base_dmg_cd: float = 0.0
var _shake:       float = 0.0

var _bomb_count:    int  = 0
var _grenade_count: int  = 5
var _grenade_mode:  bool = false
var _sats_activated:   int = 0
var _caches_collected: int = 0
var _burrows_closed:   int = 0

var _biomasa:          int       = 0
var _build_phase:      bool      = false
var _build_phase_time: float     = 0.0
var _build_mode:       bool      = false
var _build_type:       BuildType = BuildType.WALL

var _upg_speed:         int  = 0
var _upg_fire:          int  = 0
var _upg_armor:         int  = 0
var _healed_this_phase: bool = false

var _pause_layer:    CanvasLayer = null
var _paused:         bool        = false
var _regen_t:        float       = 0.0
var _event_cd:       float       = 70.0
var _game_elapsed:   float       = 0.0

var _skill_tree:         CanvasLayer = null
var _ammo_station:       CanvasLayer = null
var _generator_station:  CanvasLayer = null

func _ready() -> void:
	_build_scene()
	if StageManager.selected_mission_id.is_empty():
		_show_title()
	else:
		_start_game()

func _build_scene() -> void:
	var bg := ColorRect.new()
	bg.size  = Vector2(MAP_W, MAP_H)
	bg.color = Color(0.10, 0.05, 0.02)
	add_child(bg)

	var grid := Background.new()
	grid.map_w = MAP_W
	grid.map_h = MAP_H
	add_child(grid)

	var terrain          := Terrain.new()
	terrain.map_w        = MAP_W
	terrain.map_h        = MAP_H
	terrain.base_pos     = BASE_POS
	add_child(terrain)

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

	_barricada_preview         = BarricadaPreview.new()
	_barricada_preview.z_index = 10
	_barricada_preview.visible = false
	add_child(_barricada_preview)

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

	_skill_tree = FortressSkillTree.new()
	_skill_tree.upgrade_bought.connect(_apply_meta_upgrades)
	add_child(_skill_tree)

	_ammo_station = FortressAmmoStation.new()
	_ammo_station.biomasa_spent.connect(_on_ammo_biomasa_spent)
	_ammo_station.grenade_added.connect(
		func(n: int): _grenade_count += n; _hud.update_grenade(_grenade_count, _grenade_mode))
	_ammo_station.bomb_added.connect(
		func(n: int): _bomb_count += n)
	_ammo_station.sniper_ammo_added.connect(
		func(n: int): if is_instance_valid(_player): _player.add_sniper_ammo(n))
	_ammo_station.flame_fuel_added.connect(
		func(n: int): if is_instance_valid(_player): _player.add_flame_fuel(n))
	add_child(_ammo_station)

	_generator_station = FortressGeneratorStation.new()
	_generator_station.biomasa_spent.connect(_on_generator_biomasa_spent)
	_generator_station.station_activated.connect(_on_generator_activated)
	add_child(_generator_station)

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

	_build_pause_menu()

func _build_pause_menu() -> void:
	_pause_layer        = CanvasLayer.new()
	_pause_layer.layer  = 50
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(280, 180)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "PAUSADO"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	vbox.add_child(title_lbl)

	var resume_btn := Button.new()
	resume_btn.text = "REANUDAR"
	resume_btn.custom_minimum_size = Vector2(220, 44)
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.pressed.connect(_unpause)
	vbox.add_child(resume_btn)

	var exit_btn := Button.new()
	exit_btn.text = "SALIR AL MENÚ"
	exit_btn.custom_minimum_size = Vector2(220, 44)
	exit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_btn.pressed.connect(_exit_to_menu)
	vbox.add_child(exit_btn)

	_pause_layer.visible = false

func _toggle_pause() -> void:
	if _paused:
		_unpause()
	else:
		_pause()

func _pause() -> void:
	_paused = true
	get_tree().paused = true
	_pause_layer.visible = true

func _unpause() -> void:
	_paused = false
	get_tree().paused = false
	_pause_layer.visible = false

func _exit_to_menu() -> void:
	_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")

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
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _build_phase:
				_repair_nearest()
				get_viewport().set_input_as_handled()
			elif _mission_active and not _build_mode:
				_throw_grenade(get_global_mouse_position())
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
			KEY_C:
				if _build_phase: _set_build_type(BuildType.BARRICADA)
			KEY_ESCAPE:
				if _build_mode:
					_set_build_mode(false)
				else:
					_toggle_pause()
			KEY_F:
				_try_interact_fortress()
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
	if _player.has_signal("rocket_fired"):
		_player.rocket_fired.connect(_on_rocket_fired)
	_apply_meta_upgrades()
	_spawn_fortress_turrets()

	if StageManager.is_multiplayer:
		_init_multiplayer_players()
		if not multiplayer.is_server():
			_mission_active = true
			return

	_setup_mission_runtime()
	_start_build_phase()

func _init_multiplayer_players() -> void:
	_player.set_multiplayer_authority(1)
	if multiplayer.is_server():
		var peers := multiplayer.get_peers()
		if peers.size() > 0:
			_rpc_init_player2.rpc(peers[0])

@rpc("authority", "call_local", "reliable")
func _rpc_init_player2(client_peer_id: int) -> void:
	_player2                  = PLAYER_SCENE.instantiate()
	_player2.name             = "Player2"
	_player2.position         = BASE_POS + Vector2(60, 0)
	_player2.bullet_container = _bullets
	if "fortress" in _player2:
		_player2.fortress = _fortress
	_player2.died.connect(_on_player_died)
	_player2.set_multiplayer_authority(client_peer_id)
	_player2.set_physics_process(true)
	_player2.set_process_unhandled_input(true)
	add_child(_player2)

	# On the client: rewire HUD to the LOCAL player (Player2) and apply meta
	if _player2.is_multiplayer_authority():
		# Snap camera to player2 immediately so it doesn't pan from player1 spawn
		_camera.position = _player2.global_position
		_camera.reset_smoothing()
		if _player.health_changed.is_connected(_on_hp_changed):
			_player.health_changed.disconnect(_on_hp_changed)
		_player2.health_changed.connect(_on_hp_changed)
		_player2.weapon_changed.connect(_hud.update_weapon)
		_player2.ammo_changed.connect(_hud.update_ammo)
		if _player2.has_signal("infection_changed"):
			_player2.infection_changed.connect(_on_infection_changed)
		if _player2.has_signal("elevation_changed"):
			_player2.elevation_changed.connect(_on_player_elevation_changed)
		if _player2.has_signal("stair_state_changed"):
			_player2.stair_state_changed.connect(_on_stair_state_changed)
		if _player2.has_signal("rocket_fired"):
			_player2.rocket_fired.connect(_on_rocket_fired)
		_apply_meta_upgrades_for(_player2)
		_hud.update_hp(_player2.hp)

@rpc("authority", "call_local", "reliable")
func _rpc_wave_start(wave_num: int) -> void:
	if multiplayer.get_unique_id() == 1:
		return  # server already handled this locally
	_wave          = wave_num
	_mission_active = true
	_hud.update_wave(_wave)
	_hud.announce_wave(_wave, "OLEADA %d" % _wave)

@rpc("authority", "call_local", "reliable")
func _rpc_build_phase_start(wave_num: int, grenade_count: int, biomasa: int,
		upg_speed: int, upg_fire: int, upg_armor: int) -> void:
	if multiplayer.get_unique_id() == 1:
		return
	_wave           = wave_num
	_mission_active = false
	_build_phase    = true
	_grenade_count  = grenade_count
	_biomasa        = biomasa
	_upg_speed      = upg_speed
	_upg_fire       = upg_fire
	_upg_armor      = upg_armor
	_hud.show_build_phase(int(BUILD_PHASE_TIME))
	_hud.show_upgrades(_upg_speed, _upg_fire, _upg_armor, false, _biomasa)
	_hud.update_grenade(_grenade_count, false)
	_hud.update_biomasa(_biomasa)
	if is_instance_valid(_player2):
		_player2.refill_ammo()

@rpc("authority", "call_local", "reliable")
func _rpc_wave_complete(reward: int) -> void:
	if multiplayer.get_unique_id() == 1:
		return
	_biomasa += reward
	_hud.update_biomasa(_biomasa)
	_hud.update_enemy_progress(0, 0)
	_hud.announce_wave(_wave, "OLEADA COMPLETADA  +%d CHATARRA" % reward)

func _get_local_player() -> Node2D:
	if StageManager.is_multiplayer and is_instance_valid(_player2) \
			and _player2.is_multiplayer_authority():
		return _player2
	return _player

func _setup_mission_runtime() -> void:
	var mid := StageManager.selected_mission_id
	if mid.is_empty():
		return
	var mission = StageRegistry.get_mission(mid)
	if mission == null:
		return

	if StageManager.is_reward_unlocked("antiserum") and is_instance_valid(_player):
		_player.serum = true

	_spawn_pre_populate(mission.pre_populate_enemies)
	_spawn_mission_objects(mission)
	_spawn_ruins_decor()

	_mission_runtime = _MissionRuntime.new()
	_mission_runtime.mission = mission
	add_child(_mission_runtime)
	_mission_runtime.completed.connect(_on_mission_completed)
	_mission_runtime.failed.connect(_on_mission_failed)
	_mission_runtime.start()

func _spawn_fortress_turrets() -> void:
	if not is_instance_valid(_fortress):
		return
	# Fortress off-map for incursion missions — skip
	if _fortress.get_core_pos().distance_to(BASE_POS) > 500.0:
		return
	var mids: Dictionary = _fortress.get_arm_midpoints()
	# Two flanking turrets in the N arm (main enemy entry)
	var n_mid: Vector2 = mids["N"]
	for offset in [Vector2(-20, 0), Vector2(20, 0)]:
		_place_fort_turret(n_mid + offset)
	# One covering turret in the W arm
	_place_fort_turret(mids["W"])

func _place_fort_turret(pos: Vector2) -> void:
	var t := TURRET_SCENE.instantiate()
	t.position         = pos
	t.hp               = 250
	t.max_hp           = 250
	t.bullet_container = _bullets
	t.enemies_node     = _enemies
	_walls.add_child(t)

func _spawn_pre_populate(count: int) -> void:
	if count <= 0:
		return
	for i in count:
		var e: CharacterBody2D
		var r := randf()
		if r < 0.20:
			e = SALTADORA_SCENE.instantiate()
			e.speed  = 110.0
			e.max_hp = 35
		elif r < 0.35:
			e = EXPLOSIVO_SCENE.instantiate()
			e.speed  = 65.0
			e.max_hp = 60
		else:
			e = LARVA_SCENE.instantiate()
			e.speed  = 75.0 + float(i) * 1.5
			e.max_hp = 25
		e.hp               = e.max_hp
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e:
			e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		e.position = _pick_far_spawn_pos()
		_enemies.add_child(e)

# Llena el mapa de aliens distribuidos uniformemente (fondo de la misión satélite)
func _spawn_map_fill(count: int) -> void:
	for _i in count:
		var e = LARVA_SCENE.instantiate()
		e.speed            = randf_range(60.0, 90.0)
		e.max_hp           = 12
		e.hp               = 12
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e: e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		for _j in 20:
			var p := Vector2(randf_range(150.0, MAP_W - 150.0),
				randf_range(150.0, MAP_H - 150.0))
			if p.distance_to(BASE_POS) > 350.0:
				e.position = p
				break
		_enemies.add_child(e)

# Spawn zona de dificultad alrededor de un satélite:
#   0–160px  → blindados + escupidores, 3× HP, rápidos
#   160–360px → mix variado, 2× HP
#   360–600px → larvas+saltadoras, 1.5× HP
func _spawn_satellite_zone(sat_pos: Vector2) -> void:
	var zones := [
		{"min_r": 0.0,   "max_r": 160.0, "count": 8,  "hp_m": 3.0, "spd_m": 1.4, "heavy": true},
		{"min_r": 160.0, "max_r": 360.0, "count": 18, "hp_m": 2.0, "spd_m": 1.2, "heavy": false},
		{"min_r": 360.0, "max_r": 620.0, "count": 25, "hp_m": 1.5, "spd_m": 1.0, "heavy": false},
	]
	for z in zones:
		for _i in int(z["count"]):
			var angle := randf() * TAU
			var dist  := randf_range(float(z["min_r"]), float(z["max_r"]))
			var pos   := sat_pos + Vector2(cos(angle), sin(angle)) * dist
			pos = pos.clamp(Vector2(150, 150), Vector2(MAP_W - 150, MAP_H - 150))
			if pos.distance_to(BASE_POS) < 300.0:
				continue
			var e: CharacterBody2D
			if z["heavy"]:
				if randf() < 0.5:
					e = BLINDADO_SCENE.instantiate()
				else:
					e = ESCUPIDOR_SCENE.instantiate()
			else:
				if randf() < 0.35:
					e = SALTADORA_SCENE.instantiate()
				elif randf() < 0.25:
					e = ESCUPIDOR_SCENE.instantiate()
				else:
					e = LARVA_SCENE.instantiate()
			e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * float(z["hp_m"])))
			e.hp               = e.max_hp
			e.speed           *= float(z["spd_m"])
			e.player           = _player
			e.base_pos         = BASE_POS
			e.bullet_container = _bullets
			if "fortress" in e: e.fortress = _fortress
			e.died.connect(_on_enemy_died)
			e.position = pos
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
			# Satélites en extremos opuestos del mapa, lejos de la base
			var sat_positions: Array[Vector2] = [
				Vector2(clamp(BASE_POS.x - 820.0, 200.0, MAP_W - 200.0),
					clamp(BASE_POS.y - 580.0, 200.0, MAP_H - 200.0)),  # NW
				Vector2(clamp(BASE_POS.x + 820.0, 200.0, MAP_W - 200.0),
					clamp(BASE_POS.y + 580.0, 200.0, MAP_H - 200.0)),  # SE
			]
			_sats_activated = 0
			_hud.set_minimap_visible(false)
			for sp in sat_positions:
				var sat := Satellite.new()
				sat.position = sp
				sat.activated.connect(_on_satellite_activated)
				_mission_objects.add_child(sat)
				_spawn_satellite_zone(sp)
			_spawn_map_fill(50)
		_MissionData.ObjectiveType.COLLECT_CACHES:
			_caches_collected = 0
			for _i in mission.objective_count:
				var pos := _pick_cache_pos(placed)
				placed.append(pos)
				var cache := ResearchCache.new()
				cache.position = pos
				cache.collected.connect(_on_cache_collected)
				_mission_objects.add_child(cache)
		_MissionData.ObjectiveType.CLOSE_BURROWS:
			_burrows_closed = 0
			for _i in mission.objective_count:
				var pos := _pick_cache_pos(placed)
				placed.append(pos)
				var burrow := Burrow.new()
				burrow.position         = pos
				burrow.player           = _player
				burrow.base_pos         = BASE_POS
				burrow.bullet_container = _bullets
				burrow.wave_num         = _wave
				burrow.escalation       = 0
				burrow.closed.connect(_on_burrow_closed)
				burrow.enemy_spawned.connect(_on_burrow_enemy_spawned)
				_mission_objects.add_child(burrow)
			_spawn_map_fill(40)

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

# Coloca cachés más juntos entre sí y más cercanos a la base que los objetos normales
func _pick_cache_pos(existing: Array) -> Vector2:
	for _i in 50:
		var pos := Vector2(
			randf_range(250.0, MAP_W - 250.0),
			randf_range(250.0, MAP_H - 250.0))
		var d := pos.distance_to(BASE_POS)
		if d < 300.0 or d > 680.0:
			continue
		var ok := true
		for ep in existing:
			if pos.distance_to(ep) < 180.0:
				ok = false
				break
		if ok:
			return pos
	return BASE_POS + Vector2(450.0, 0.0).rotated(randf() * TAU)

func _spawn_ruins_decor() -> void:
	const TYPES      := 3
	const COUNT      := 12
	const MIN_DIST   := 220.0
	var placed: Array = []
	for i in COUNT:
		for _j in 40:
			var pos := Vector2(
				randf_range(200.0, MAP_W - 200.0),
				randf_range(200.0, MAP_H - 200.0))
			if pos.distance_to(BASE_POS) < 380.0:
				continue
			var ok := true
			for ep in placed:
				if pos.distance_to(ep) < MIN_DIST:
					ok = false
					break
			if ok:
				placed.append(pos)
				var decor := RuinsDecor.new()
				decor.position  = pos
				decor.decor_type = i % TYPES
				_mission_objects.add_child(decor)
				break

func _on_satellite_activated(_sat: Node) -> void:
	_sats_activated += 1
	if _sats_activated >= 2:
		_hud.set_minimap_visible(true)
		_hud.set_satellite_revealed(true)
		_hud.announce_wave(_wave, "COMUNICACIONES RESTAURADAS")
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_satellite_activated()

func _on_cache_collected(_cache: Node) -> void:
	_caches_collected += 1
	_spawn_cache_ambush(_caches_collected)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_cache_collected()

func _spawn_cache_ambush(cache_num: int) -> void:
	const COUNTS := [0, 18, 38, 65]
	const HP_M   := [0.0, 1.3, 1.8, 2.8]
	const SPD_M  := [0.0, 1.1, 1.3, 1.6]
	var count: int   = COUNTS[mini(cache_num, 3)]
	var hp_m:  float = HP_M[mini(cache_num, 3)]
	var spd_m: float = SPD_M[mini(cache_num, 3)]
	match cache_num:
		1: _hud.announce_wave(_wave, "¡SEÑAL DETECTADA — HOSTILES EN CAMINO!")
		2: _hud.announce_wave(_wave, "¡MÚLTIPLES HOSTILES — PREPÁRENSE!")
		_: _hud.announce_wave(_wave, "¡OLEADA MASIVA — AGUANTEN!")
	shake(5.0 * cache_num)
	for i in count:
		await get_tree().create_timer(0.07 * i).timeout
		if not is_instance_valid(self) or not _mission_active:
			return
		var e: CharacterBody2D
		var r := randf()
		if cache_num >= 3:
			if   r < 0.30: e = BLINDADO_SCENE.instantiate()
			elif r < 0.58: e = ESCUPIDOR_SCENE.instantiate()
			elif r < 0.73: e = SALTADORA_SCENE.instantiate()
			else:          e = LARVA_SCENE.instantiate()
		elif cache_num >= 2:
			if   r < 0.15: e = BLINDADO_SCENE.instantiate()
			elif r < 0.38: e = ESCUPIDOR_SCENE.instantiate()
			elif r < 0.52: e = SALTADORA_SCENE.instantiate()
			else:          e = LARVA_SCENE.instantiate()
		else:
			if   r < 0.25: e = ESCUPIDOR_SCENE.instantiate()
			elif r < 0.42: e = SALTADORA_SCENE.instantiate()
			else:          e = LARVA_SCENE.instantiate()
		e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * hp_m))
		e.hp               = e.max_hp
		e.speed           *= spd_m
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e: e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		e.position         = _pick_spawn_pos()
		_enemies.add_child(e)

func _spawn_boss() -> void:
	var boss_pos := _pick_far_spawn_pos()
	var arena := BossArena.new()
	arena.position = boss_pos + Vector2(0, 30)
	_mission_objects.add_child(arena)

	var is_stage3 := StageManager.selected_mission_id.begins_with("stage3")
	if is_stage3:
		_boss                  = MenteColmena.new()
		_boss.position         = boss_pos
		_boss.player           = _player
		_boss.base_pos         = BASE_POS
		_boss.bullet_container = _bullets
		_boss.walls_node       = _walls
		if "fortress" in _boss:
			_boss.fortress = _fortress
		_boss.died.connect(_on_boss_died)
		_boss.summoned_larva.connect(_on_boss_summoned_larva)
		_boss.rugido_emitted.connect(_on_boss_rugido)
		_boss.phase2_entered.connect(_on_boss_phase2)
		_boss.corrosive_pulse_emitted.connect(_on_boss_corrosive_pulse)
		_enemies.add_child(_boss)
		MusicPlayer.set_mode(MusicPlayer.Mode.BOSS)
		_hud.show_npc_announcement("¡LA MENTE COLMENA DESPIERTA!", Color(0.85, 0.20, 1.0))
	elif StageManager.selected_mission_id.begins_with("stage2"):
		_boss                  = Reina.new()
		_boss.position         = boss_pos
		_boss.player           = _player
		_boss.base_pos         = BASE_POS
		_boss.bullet_container = _bullets
		_boss.walls_node       = _walls
		if "fortress" in _boss:
			_boss.fortress = _fortress
		if "_acid_node_parent" in _boss:
			_boss._acid_node_parent = self
		_boss.died.connect(_on_boss_died)
		_boss.summoned_larva.connect(_on_boss_summoned_larva)
		_boss.rugido_emitted.connect(_on_boss_rugido)
		_boss.phase2_entered.connect(_on_boss_phase2)
		_enemies.add_child(_boss)
		MusicPlayer.set_mode(MusicPlayer.Mode.BOSS)
		_hud.show_npc_announcement("¡LA REINA HA DESPERTADO!", Color(0.80, 0.15, 1.0))
	else:
		_boss                  = Engendro.new()
		_boss.position         = boss_pos
		_boss.player           = _player
		_boss.base_pos         = BASE_POS
		_boss.bullet_container = _bullets
		_boss.walls_node       = _walls
		if "fortress" in _boss:
			_boss.fortress = _fortress
		_boss.died.connect(_on_boss_died)
		_boss.summoned_larva.connect(_on_boss_summoned_larva)
		_boss.rugido_emitted.connect(_on_boss_rugido)
		_boss.phase2_entered.connect(_on_boss_phase2)
		_enemies.add_child(_boss)
		MusicPlayer.set_mode(MusicPlayer.Mode.BOSS)
		_hud.show_npc_announcement("¡EL ENGENDRO HA LLEGADO!", Color(1.0, 0.25, 0.1))

func _on_boss_died(e: Node) -> void:
	var boss_pos: Vector2 = e.global_position
	_boss = null
	_on_enemy_died(e)
	for i in 5:
		var ef := BombEffect.new()
		ef.position = boss_pos + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		add_child(ef)
	shake(30.0)
	SoundManager.play("boss_death")
	MusicPlayer.set_mode(MusicPlayer.Mode.BUILD)
	_hud.show_npc_announcement("¡ENEMIGO ELIMINADO!", Color(0.30, 1.00, 0.42))
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

func _on_boss_phase2() -> void:
	shake(18.0)
	if StageManager.selected_mission_id.begins_with("stage3"):
		var phase: int = int(_boss.get("_phase")) if is_instance_valid(_boss) else 2
		if phase == 3:
			_hud.show_npc_announcement("¡MENTE COLMENA — FASE 3! PULSO CORROSIVO CONSTANTE", Color(1.0, 0.15, 0.45))
		else:
			_hud.show_npc_announcement("¡MENTE COLMENA — FASE 2! PULSO CORROSIVO ACTIVO", Color(0.85, 0.20, 1.0))
	else:
		_hud.show_npc_announcement("¡EL ENGENDRO ENTRA EN FRENESÍ — FASE 2!", Color(1.0, 0.15, 0.05))

func _on_boss_corrosive_pulse(_pos: Vector2, _radius: float) -> void:
	shake(12.0)
	_hud.show_npc_announcement("¡PULSO CORROSIVO!", Color(0.60, 1.0, 0.15))

func _on_burrow_closed(_burrow: Node) -> void:
	_burrows_closed += 1
	var ef := BombEffect.new()
	ef.position = _burrow.global_position
	add_child(ef)
	SoundManager.play("explode")
	for obj in _mission_objects.get_children():
		if is_instance_valid(obj) and obj.get("escalation") != null:
			obj.escalation = _burrows_closed
	match _burrows_closed:
		1: _hud.announce_wave(_wave, "¡MADRIGUERA CERRADA — SE ENFURECEN!")
		2: _hud.announce_wave(_wave, "¡MADRIGUERA CERRADA — RESISTENCIA CRECIENTE!")
		3: _hud.announce_wave(_wave, "¡ÚLTIMA MADRIGUERA — RESISTENCIA MÁXIMA!")
	shake(8.0 * _burrows_closed)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_burrow_closed()

func _on_burrow_enemy_spawned(e: Node) -> void:
	if not is_instance_valid(e):
		return
	e.died.connect(_on_enemy_died)
	_enemies.add_child(e)

const FORTRESS_INTERACT_R := 80.0

func _try_interact_fortress() -> void:
	if _game_over or not is_instance_valid(_player) or not is_instance_valid(_fortress):
		return
	var pp := _player.global_position
	if pp.distance_to(_fortress.get_core_pos()) <= FORTRESS_INTERACT_R:
		_skill_tree.open()
		return
	if pp.distance_to(_fortress.get_east_arm_mid()) <= FORTRESS_INTERACT_R:
		_ammo_station.open(_biomasa)
		return
	var mids: Dictionary = _fortress.get_arm_midpoints()
	if pp.distance_to(mids["W"]) <= FORTRESS_INTERACT_R:
		_generator_station.open(_biomasa, _fortress.has_station(Fortress.StationType.GENERATOR))

func _on_ammo_biomasa_spent(amount: int) -> void:
	_biomasa = maxi(0, _biomasa - amount)
	_hud.update_biomasa(_biomasa)
	_ammo_station.refresh_biomasa(_biomasa)

func _on_generator_biomasa_spent(amount: int) -> void:
	_biomasa = maxi(0, _biomasa - amount)
	_hud.update_biomasa(_biomasa)
	_generator_station.refresh_biomasa(_biomasa)
	_ammo_station.refresh_biomasa(_biomasa)

func _on_generator_activated() -> void:
	if is_instance_valid(_fortress):
		_fortress.build_station(Fortress.StationType.GENERATOR)
		_hud.announce_wave(_wave, "GENERADOR ACTIVADO  — +15 ◈/OLEADA  +1 GRANADA/FASE")

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
		"time_sec":  int(_game_elapsed),
	})
	shake(12.0)
	_hud.announce_wave(_wave, "MISIÓN COMPLETADA")
	var _tree1 := get_tree()
	await _tree1.create_timer(2.5).timeout
	if is_instance_valid(self) and is_instance_valid(_tree1):
		_tree1.change_scene_to_file("res://scenes/mission_result.tscn")

func _on_mission_failed(reason: String) -> void:
	_game_over      = true
	_mission_active = false
	StageManager.set_last_result({
		"success":  false,
		"reason":   reason,
		"waves":    _wave,
		"kills":    _kills,
		"time_sec": int(_game_elapsed),
	})
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_hud.hide_upgrades()
	_hud.hide_build_phase()
	var _tree2 := get_tree()
	await _tree2.create_timer(2.5).timeout
	if is_instance_valid(self) and is_instance_valid(_tree2):
		_tree2.change_scene_to_file("res://scenes/mission_result.tscn")

# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _mission_active and not _game_over:
		_game_elapsed += delta
	_tick_camera()
	_tick_base_damage(delta)
	_tick_shake(delta)
	_tick_build_phase(delta)
	_tick_build_preview()
	_tick_mission(delta)
	_tick_regen(delta)
	_tick_events(delta)
	_tick_fortress_hints()
	_tick_player_down(delta)


func _tick_player_down(delta: float) -> void:
	if not _player_down_active:
		return
	_player_down_t -= delta
	# Revive if medic alive AND in range
	if is_instance_valid(_medic_npc) and not _medic_npc.get("down"):
		if _medic_npc.global_position.distance_to(_player.global_position) <= PLAYER_REVIVE_RANGE:
			_player_down_active = false
			_player.hp = PLAYER_REVIVE_HP
			_player.modulate = Color.WHITE
			_player.set_physics_process(true)
			if _player.has_signal("health_changed"):
				_player.health_changed.emit(PLAYER_REVIVE_HP)
			_hud.show_npc_announcement("REANIMADO", Color(0.3, 1.0, 0.55))
			return
	# Medic died or timer ran out → real game over
	if not is_instance_valid(_medic_npc) or _medic_npc.get("down") or _player_down_t <= 0.0:
		_finalize_player_death()

func _tick_fortress_hints() -> void:
	if not is_instance_valid(_fortress) or not is_instance_valid(_player):
		return
	_fortress.player_pos      = _player.global_position
	_fortress.show_zone_hints = not _game_over and not is_instance_valid(_title_ol)

	var any_available := false
	var all_maxed     := true
	for key in StageManager.META_TREE:
		var cost := StageManager.get_meta_cost(key)
		if cost < 0:
			continue   # this key is maxed
		all_maxed = false
		if StageManager.chatarra_banked >= cost:
			any_available = true
	_fortress.upgrade_available = any_available
	_fortress.upgrades_maxed    = all_maxed

func _tick_camera() -> void:
	if _game_over:
		return
	var p := _get_local_player()
	if is_instance_valid(p):
		_camera.position = p.global_position

func _tick_base_damage(delta: float) -> void:
	if _base_hp <= 0 or _game_over:
		return
	_base_dmg_cd -= delta
	if _base_dmg_cd > 0.0:
		return
	_base_dmg_cd = 0.35
	var dmg := 0
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.global_position.distance_to(BASE_POS) < BASE_R:
			dmg += 10
	if dmg == 0:
		return
	_base_hp = max(0, _base_hp - dmg)
	_hud.update_base_hp(_base_hp)
	_fortress.modulate = Color(1.6, 0.28, 0.28)
	_fortress.base_hp_pct = float(_base_hp) / 1000.0
	_fortress.on_damaged()
	var tw := create_tween()
	tw.tween_property(_fortress, "modulate", Color.WHITE, 0.25)
	shake(5.0 + (1.0 - float(_base_hp) / 1000.0) * 8.0)
	SoundManager.play("damage")
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
		round(mp.y / 40.0) * 40.0)
	var ok: bool = _can_place_at(preview.position)
	var tint: Color
	if not ok:
		tint = Color(1.4, 0.4, 0.4, 0.85)
	elif _build_type == BuildType.WALL_PLUS:
		tint = Color(0.6, 1.0, 0.6)
	else:
		tint = Color.WHITE
	preview.modulate = tint

func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

# ── Station effects ───────────────────────────────────────────────────────────

func _apply_station_buffs() -> void:
	if not is_instance_valid(_fortress):
		return
	var has_taller:     bool = _fortress.has_station(Fortress.StationType.TALLER)
	var has_generator:  bool = _fortress.has_station(Fortress.StationType.GENERATOR)
	var has_enfermeria: bool = _fortress.has_station(Fortress.StationType.ENFERMERIA)

	if is_instance_valid(_player):
		_player.taller_active = has_taller

	var turret_mult := 0.6 if has_taller else 1.0
	for s in _walls.get_children():
		if is_instance_valid(s) and s.get("fire_rate_mult") != null:
			s.fire_rate_mult = turret_mult

	var msgs: Array = []
	if has_taller:     msgs.append("TALLER: DAÑO +35%  TORRETAS ×1.7")
	if has_generator:  msgs.append("GENERADOR: +15 BIOMASA/OLEADA  +1 GRANADA")
	if has_enfermeria: msgs.append("ENFERMERÍA: REGENERACIÓN ACTIVA")
	for m in msgs:
		_hud.show_npc_announcement(m, Color(0.85, 0.65, 0.20))

func _tick_regen(delta: float) -> void:
	if not _mission_active or _game_over:
		return
	if not is_instance_valid(_fortress) or not _fortress.has_station(Fortress.StationType.ENFERMERIA):
		return
	if not is_instance_valid(_player) or _player.hp >= _player.max_hp:
		return
	_regen_t += delta
	if _regen_t >= 3.0:
		_regen_t = 0.0
		_player.hp = mini(_player.hp + 2, _player.max_hp)
		_hud.update_hp(_player.hp)

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
	var grenade_bonus := 1 if (is_instance_valid(_fortress) and _fortress.has_station(Fortress.StationType.GENERATOR)) else 0
	_grenade_count      = mini(_grenade_count + 3 + grenade_bonus, 10)
	_grenade_mode       = false
	MusicPlayer.set_mode(MusicPlayer.Mode.BUILD)
	_hud.show_build_phase(int(BUILD_PHASE_TIME))
	_hud.show_upgrades(_upg_speed, _upg_fire, _upg_armor, _healed_this_phase, _biomasa)
	_hud.update_grenade(_grenade_count, false)
	if StageManager.is_multiplayer and multiplayer.is_server():
		_rpc_build_phase_start.rpc(_wave, _grenade_count, _biomasa,
				_upg_speed, _upg_fire, _upg_armor)

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
	_apply_station_buffs()
	_start_mission()

func _set_build_type(type: BuildType) -> void:
	if _build_mode and _build_type == type:
		_set_build_mode(false)
	else:
		_build_type = type
		_set_build_mode(true)

func _set_build_mode(on: bool) -> void:
	_build_mode                = on
	_player.building           = on
	_wall_preview.visible      = on and (_build_type == BuildType.WALL or _build_type == BuildType.WALL_PLUS)
	_turret_preview.visible    = on and _build_type == BuildType.TURRET
	_mine_preview.visible      = on and _build_type == BuildType.MINE
	_barricada_preview.visible = on and _build_type == BuildType.BARRICADA
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
		BuildType.BARRICADA: return _barricada_preview
		_:                   return _wall_preview

func _build_cost() -> int:
	match _build_type:
		BuildType.TURRET:    return 18
		BuildType.WALL_PLUS: return 5
		BuildType.MINE:      return 3
		BuildType.BARRICADA: return 4
		_:                   return 3

func _build_type_name() -> String:
	match _build_type:
		BuildType.TURRET:    return "TORRETA"
		BuildType.WALL_PLUS: return "MURO +"
		BuildType.MINE:      return "MINA"
		BuildType.BARRICADA: return "BARRICADA"
		_:                   return "MURO"

func _place_structure() -> void:
	var cost := _build_cost()
	if _biomasa < cost:
		return
	var pos := _active_preview().position
	if not _can_place_at(pos):
		_hud.show_npc_announcement("NO PUEDE CONSTRUIR AHÍ", Color(1.0, 0.4, 0.2))
		return
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
		BuildType.BARRICADA:
			var b := Barricada.new()
			b.position = pos
			b.destroyed.connect(func(): pass)
			_walls.add_child(b)
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

func _can_place_at(pos: Vector2) -> bool:
	# Out of map
	if pos.x < 30.0 or pos.y < 30.0 or pos.x > MAP_W - 30.0 or pos.y > MAP_H - 30.0:
		return false
	# Don't overlap existing structures
	for s in _walls.get_children():
		if is_instance_valid(s) and s.global_position.distance_to(pos) < 32.0:
			return false
	# Respect fortress geometry — turrets allowed on platforms, walls only outside
	if is_instance_valid(_fortress):
		# Block: inside the octagon, arm corridors, south wall rect, towers
		if _fortress.is_inside_hex(pos):
			return false
		var arms: Dictionary = _fortress.arm_polygons
		for k in arms:
			var poly: Array = arms[k]
			if Geometry2D.is_point_in_polygon(pos, PackedVector2Array(poly)):
				return false
		var sw: Rect2 = _fortress.south_wall_rect
		if sw.has_point(pos):
			return false
		var t2: Rect2 = _fortress.tower_l2_rect
		if t2.has_point(pos) and _build_type != BuildType.TURRET:
			return false
		var t3: Rect2 = _fortress.tower_l3_rect
		if t3.has_point(pos) and _build_type != BuildType.TURRET:
			return false
	# Don't drop on top of player or NPCs
	if is_instance_valid(_player) and _player.global_position.distance_to(pos) < 28.0:
		return false
	for npc in _friendlies.get_children():
		if is_instance_valid(npc) and npc.global_position.distance_to(pos) < 24.0:
			return false
	return true


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
	if is_boss or randf() < 0.18:
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
	var center: Vector2 = _player.global_position if is_instance_valid(_player) else BASE_POS
	const BOMB_RADIUS := 480.0
	const BOMB_DMG    := 350
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.has_method("take_damage"):
			if e.global_position.distance_to(center) <= BOMB_RADIUS:
				e.take_damage(BOMB_DMG)
	var ef      := BombEffect.new()
	ef.position  = center
	ef.max_r     = BOMB_RADIUS * 0.85
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


# Public: NPCs (demolitions) can throw free grenades — no count cost.
func throw_npc_grenade(from_pos: Vector2, target_pos: Vector2) -> void:
	var g          := Grenade.new()
	g.target        = target_pos
	g.global_position = from_pos
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

func _is_beacon_mission() -> bool:
	return _mission_runtime != null and is_instance_valid(_mission_runtime) \
		and _mission_runtime.mission != null \
		and _mission_runtime.mission.objective_type == _MissionData.ObjectiveType.ACTIVATE_BEACONS

func _is_cache_mission() -> bool:
	return _mission_runtime != null and is_instance_valid(_mission_runtime) \
		and _mission_runtime.mission != null \
		and _mission_runtime.mission.objective_type == _MissionData.ObjectiveType.COLLECT_CACHES

func _is_burrow_mission() -> bool:
	return _mission_runtime != null and is_instance_valid(_mission_runtime) \
		and _mission_runtime.mission != null \
		and _mission_runtime.mission.objective_type == _MissionData.ObjectiveType.CLOSE_BURROWS

func _start_mission() -> void:
	_wave           += 1
	_mission_active  = true
	_killed          = 0
	_hud.update_wave(_wave)
	_check_npc_spawn()
	SoundManager.play_wave()
	shake(4.0)
	if _is_beacon_mission():
		_hud.announce_wave(_wave, "ACTIVA AMBOS SATÉLITES")
	elif _is_cache_mission():
		_hud.announce_wave(_wave, "RECOGE LAS CACHÉS DE INVESTIGACIÓN")
	elif _is_burrow_mission():
		_hud.announce_wave(_wave, "CIERRA LAS MADRIGUERAS — SE VUELVEN MÁS FUERTES")
	else:
		_hud.announce_wave(_wave, "OLEADA %d" % _wave)
		_spawn_wave()
	MusicPlayer.set_mode(MusicPlayer.Mode.WAVE)
	if StageManager.is_multiplayer and multiplayer.is_server():
		_rpc_wave_start.rpc(_wave)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		if _mission_runtime.mission != null:
			if _mission_runtime.mission.objective_type == _MissionData.ObjectiveType.KILL_BOSS and _wave == 4:
				_spawn_boss()

func _spawn_wave() -> void:
	var is_survival: bool  = _is_survival()
	var is_stage2:   bool  = StageManager.selected_mission_id.begins_with("stage2")
	var is_stage3:   bool  = StageManager.selected_mission_id.begins_with("stage3")

	var hp_mult:   float = 1.0 + (_wave - 1) * (0.32 if is_survival else 0.22)
	var base_spd:  float = (65.0 + (_wave - 1) * 8.0) if is_survival else (55.0 + (_wave - 1) * 6.0)
	var count:     int   = (8000 + _wave * 1500) if is_survival else (5000 + _wave * 1000)
	var interval:  float = 0.0015 if is_survival else 0.0025
	var max_live:  int   = 1000 if is_survival else 800
	if is_stage2:
		hp_mult  *= 1.20
		base_spd *= 1.10
		count     = int(count * 1.50)
		max_live  = int(max_live * 1.30)
	if is_stage3:
		hp_mult  *= 1.45
		base_spd *= 1.22
		count     = int(count * 1.80)
		max_live  = int(max_live * 1.60)
		interval  = maxf(interval * 0.70, 0.001)

	_wave_total = count
	_killed     = 0
	_hud.update_enemy_progress(0, count)

	# Cycle through all 8 spawn directions so every front is attacked at once
	var dir_keys: Array = SPAWN_POINTS.keys()
	dir_keys.shuffle()
	var dir_idx: int = 0

	for i in count:
		await get_tree().create_timer(interval).timeout
		if not _mission_active or not is_instance_valid(self):
			return
		# Cap: pause spawning when screen is already saturated (TAB carpet feel)
		while _enemies.get_child_count() >= max_live:
			await get_tree().create_timer(0.08).timeout
			if not _mission_active or not is_instance_valid(self):
				return
		# Re-shuffle after each full cycle so patterns don't repeat identically
		if dir_idx > 0 and dir_idx % dir_keys.size() == 0:
			dir_keys.shuffle()
		dir_idx += 1
		var e: CharacterBody2D
		var r := randf()
		if is_stage3:
			if _wave >= 2 and r < 0.08:
				e = TANQUE_SCENE.instantiate();     e.speed = base_spd * 0.28
			elif r < 0.16:
				e = CORRUPTOR_SCENE.instantiate();  e.speed = base_spd * 0.38
			elif r < 0.28:
				e = VOLADOR_SCENE.instantiate();    e.speed = base_spd * 1.55
			elif r < 0.40:
				e = EXCAVADOR_SCENE.instantiate();  e.speed = base_spd * 0.90
			elif r < 0.52:
				e = BLINDADO_SCENE.instantiate();   e.speed = base_spd * 0.55
			elif r < 0.62:
				e = ESCUPIDOR_SCENE.instantiate();  e.speed = base_spd * 0.88
			elif r < 0.74:
				e = SALTADORA_SCENE.instantiate();  e.speed = base_spd * 1.90
			else:
				e = LARVA_SCENE.instantiate();      e.speed = base_spd
		elif is_stage2:
			if _wave >= 3 and r < 0.06:
				e = TANQUE_SCENE.instantiate();     e.speed = base_spd * 0.30
			elif r < 0.20:
				e = VOLADOR_SCENE.instantiate();    e.speed = base_spd * 1.50
			elif _wave >= 2 and r < 0.35:
				e = EXCAVADOR_SCENE.instantiate();  e.speed = base_spd * 0.90
			elif r < 0.48:
				e = BLINDADO_SCENE.instantiate();   e.speed = base_spd * 0.55
			elif r < 0.60:
				e = ESCUPIDOR_SCENE.instantiate();  e.speed = base_spd * 0.85
			elif r < 0.72:
				e = SALTADORA_SCENE.instantiate();  e.speed = base_spd * 1.90
			else:
				e = LARVA_SCENE.instantiate();      e.speed = base_spd
		elif is_survival:
			if _wave >= 2 and r < 0.20:
				e = BLINDADO_SCENE.instantiate();   e.speed = base_spd * 0.55
			elif _wave >= 2 and r < 0.34:
				e = EXPLOSIVO_SCENE.instantiate();  e.speed = base_spd * 0.90
			elif r < 0.46:
				e = ESCUPIDOR_SCENE.instantiate();  e.speed = base_spd * 0.85
			elif r < 0.65:
				e = SALTADORA_SCENE.instantiate();  e.speed = base_spd * 1.9
			else:
				e = LARVA_SCENE.instantiate();      e.speed = base_spd
		else:
			if _wave >= 4 and r < 0.14:
				e = BLINDADO_SCENE.instantiate();   e.speed = base_spd * 0.55
			elif _wave >= 2 and r < 0.28:
				e = EXPLOSIVO_SCENE.instantiate();  e.speed = base_spd * 0.90
			elif _wave >= 2 and r < 0.42:
				e = ESCUPIDOR_SCENE.instantiate();  e.speed = base_spd * 0.85
			elif _wave >= 2 and r < 0.52:
				e = SALTADORA_SCENE.instantiate();  e.speed = base_spd * 1.9
			else:
				e = LARVA_SCENE.instantiate();      e.speed = base_spd
		e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * hp_mult))
		e.hp               = e.max_hp
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e:
			e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		if e.get("is_excavador"):
			e.position = _pick_interior_spawn_pos()
		else:
			var dkey: String  = dir_keys[(dir_idx - 1) % dir_keys.size()]
			var base_pt: Vector2 = SPAWN_POINTS[dkey]
			var jitter: float = 80.0
			if dkey == "N" or dkey == "S":
				e.position = base_pt + Vector2(randf_range(-jitter, jitter), 0)
			elif dkey == "E" or dkey == "W":
				e.position = base_pt + Vector2(0, randf_range(-jitter, jitter))
			else:
				e.position = base_pt + Vector2(randf_range(-jitter*0.5, jitter*0.5), randf_range(-jitter*0.5, jitter*0.5))
		_enemies.add_child(e)

	# Destructores — spawnean separados del conteo normal
	var destructor_count := 0
	if is_stage3:
		destructor_count = mini(_wave * 5 + 3, 30)
	elif is_stage2:
		destructor_count = mini(_wave * 4, 20)
	elif is_survival:
		destructor_count = mini(_wave * 3, 15)
	else:
		destructor_count = mini(_wave * 2 + 1, 10)

	for _di in destructor_count:
		await get_tree().create_timer(randf_range(0.5, 2.5)).timeout
		if not _mission_active or not is_instance_valid(self):
			return
		_spawn_destructor(hp_mult)

func _spawn_destructor(hp_mult: float) -> void:
	var d := DESTRUCTOR_SCENE.instantiate()
	d.max_hp           = int(float(d.max_hp) * hp_mult)
	d.hp               = d.max_hp
	d.player           = _player
	d.base_pos         = BASE_POS
	d.bullet_container = _bullets
	if "fortress" in d:
		d.fortress = _fortress
	if "walls_node" in d:
		d.walls_node = _walls
	d.died.connect(_on_enemy_died)
	d.position = _pick_spawn_pos()
	_enemies.add_child(d)
	_wave_total += 1
	_hud.update_enemy_progress(_killed, _wave_total)

func _tick_mission(_delta: float) -> void:
	if not _mission_active or _game_over:
		return
	if _is_beacon_mission() or _is_cache_mission() or _is_burrow_mission():
		return
	if _killed > 0 and _enemies.get_child_count() == 0:
		_on_wave_complete()

func _on_wave_complete() -> void:
	if not _mission_active:
		return
	_mission_active = false
	_grenade_mode   = false
	_hud.update_grenade(_grenade_count, false)
	_hud.update_enemy_progress(0, 0)
	shake(8.0)
	var reward := 8 + _wave * 2
	var gen_bonus := 15 if (is_instance_valid(_fortress) and _fortress.has_station(Fortress.StationType.GENERATOR)) else 0
	reward    += gen_bonus
	_biomasa  += reward
	_hud.update_biomasa(_biomasa)
	_spawn_scrap_text(BASE_POS + Vector2(0, -80), reward)
	_hud.announce_wave(_wave, "OLEADA COMPLETADA  +%d CHATARRA" % reward)
	if StageManager.is_multiplayer and multiplayer.is_server():
		_rpc_wave_complete.rpc(reward)
	if _mission_runtime != null and is_instance_valid(_mission_runtime):
		_mission_runtime.notify_wave_completed()
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(self) and not _game_over and not _mission_finished:
		_start_build_phase()

# ── NPC squad ─────────────────────────────────────────────────────────────────

func _check_npc_spawn() -> void:
	if _wave == 1:
		if not is_instance_valid(_assault_npc):  _spawn_assault_npc()
		if not is_instance_valid(_medic_npc):    _spawn_medic_npc()
		if not is_instance_valid(_engineer_npc): _spawn_engineer_npc()
	if _wave == 3:
		if not is_instance_valid(_sniper_npc):   _spawn_sniper_npc()
	if _wave == 5:
		if not is_instance_valid(_demo_npc):     _spawn_demo_npc()
	# Extra grunts scale with wave: 3 at w1, +1 per wave up to cap
	_extra_grunts = _extra_grunts.filter(func(n): return is_instance_valid(n))
	var desired: int = mini(2 + _wave, EXTRA_GRUNT_CAP)
	while _extra_grunts.size() < desired:
		_spawn_extra_grunt(_extra_grunts.size())


func _spawn_extra_grunt(idx: int) -> void:
	var g := NPCAssault.new()
	var angle: float = TAU * float(idx) / float(EXTRA_GRUNT_CAP) + randf_range(-0.2, 0.2)
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	var spawn: Vector2 = _npc_spawn_pos(dir)
	g.position         = spawn
	g.player           = _player
	g.base_pos         = BASE_POS
	g.post_pos         = spawn
	g.bullet_container = _bullets
	g.enemies_node     = _enemies
	g.died.connect(_on_npc_died)
	_friendlies.add_child(g)
	_extra_grunts.append(g)
	if idx == 0:
		_hud.show_npc_announcement("REFUERZOS DESPLEGADOS", Color(0.45, 0.95, 0.75))

func _npc_spawn_pos(offset_normal: Vector2) -> Vector2:
	# APO ≈ 111 + ARM_LEN/2 = 60 → midpoint of arm corridor ≈ 170
	return BASE_POS + offset_normal * 170.0

func _spawn_assault_npc() -> void:
	_assault_npc                  = NPCAssault.new()
	_assault_npc.position         = _npc_spawn_pos(Vector2(1, 0.25).normalized())
	_assault_npc.player           = _player
	_assault_npc.base_pos         = BASE_POS
	_assault_npc.post_pos         = _npc_spawn_pos(Vector2(1, 0.25).normalized())
	_assault_npc.bullet_container = _bullets
	_assault_npc.enemies_node     = _enemies
	_assault_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_assault_npc)
	_hud.show_npc_announcement("ASALTO", Color(0.45, 0.75, 1.0))

func _spawn_medic_npc() -> void:
	_medic_npc                  = NPCMedic.new()
	_medic_npc.position         = BASE_POS + Vector2(0, 35)
	_medic_npc.player           = _player
	_medic_npc.base_pos         = BASE_POS
	_medic_npc.bullet_container = _bullets
	_medic_npc.enemies_node     = _enemies
	_medic_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_medic_npc)
	_hud.show_npc_announcement("MÉDICO", Color(0.30, 1.0, 0.55))

func _spawn_engineer_npc() -> void:
	_engineer_npc                  = NPCEngineer.new()
	_engineer_npc.position         = _npc_spawn_pos(Vector2(-0.25, -1).normalized())
	_engineer_npc.player           = _player
	_engineer_npc.base_pos         = BASE_POS
	_engineer_npc.post_pos         = _npc_spawn_pos(Vector2(-0.25, -1).normalized())
	_engineer_npc.bullet_container = _bullets
	_engineer_npc.enemies_node     = _enemies
	_engineer_npc.walls_node       = _walls
	_engineer_npc.fortress         = _fortress
	_engineer_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_engineer_npc)
	_hud.show_npc_announcement("INGENIERO", Color(1.0, 0.65, 0.20))

func _spawn_sniper_npc() -> void:
	_sniper_npc                  = NPCFrancotirador.new()
	_sniper_npc.position         = _npc_spawn_pos(Vector2(-1, 0.25).normalized())
	_sniper_npc.player           = _player
	_sniper_npc.base_pos         = BASE_POS
	_sniper_npc.post_pos         = _npc_spawn_pos(Vector2(-1, 0.25).normalized())
	_sniper_npc.bullet_container = _bullets
	_sniper_npc.enemies_node     = _enemies
	_sniper_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_sniper_npc)
	_hud.show_npc_announcement("FRANCOTIRADOR", Color(0.55, 0.90, 1.0))

func _spawn_demo_npc() -> void:
	_demo_npc                  = NPCDemoliciones.new()
	_demo_npc.position         = _npc_spawn_pos(Vector2(0.5, 1.0).normalized())
	_demo_npc.player           = _player
	_demo_npc.base_pos         = BASE_POS
	_demo_npc.post_pos         = _npc_spawn_pos(Vector2(0.5, 1.0).normalized())
	_demo_npc.bullet_container = _bullets
	_demo_npc.enemies_node     = _enemies
	_demo_npc.walls_node       = _walls
	_demo_npc.main_ref         = self
	_demo_npc.died.connect(_on_npc_died)
	_friendlies.add_child(_demo_npc)
	_hud.show_npc_announcement("DEMOLICIONES", Color(1.0, 0.55, 0.15))

func _is_survival() -> bool:
	return _mission_runtime != null and is_instance_valid(_mission_runtime) \
		and _mission_runtime.mission != null \
		and _mission_runtime.mission.type == _MissionData.MissionType.SURVIVAL

func _on_npc_died(npc: Node) -> void:
	if npc == _assault_npc:
		_assault_npc = null
		_hud.show_npc_announcement("¡ASALTO CAÍDO!", Color(1.0, 0.45, 0.25))
	elif npc == _medic_npc:
		_medic_npc = null
		_hud.show_npc_announcement("¡MÉDICO CAÍDO! sin reanimación", Color(1.0, 0.30, 0.20))
	elif npc == _engineer_npc:
		_engineer_npc = null
		_hud.show_npc_announcement("¡INGENIERO CAÍDO! muros sin reparar", Color(1.0, 0.50, 0.10))
	elif npc == _sniper_npc:
		_sniper_npc = null
		_hud.show_npc_announcement("¡FRANCOTIRADOR CAÍDO! elites libres", Color(0.95, 0.55, 0.35))
	elif npc == _demo_npc:
		_demo_npc = null
		_hud.show_npc_announcement("¡DEMOLICIONES CAÍDO! sin explosivos", Color(1.0, 0.40, 0.15))
	else:
		_extra_grunts.erase(npc)

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

func _pick_interior_spawn_pos() -> Vector2:
	for _i in 25:
		var pos := Vector2(
			randf_range(250.0, MAP_W - 250.0),
			randf_range(250.0, MAP_H - 250.0))
		if pos.distance_to(BASE_POS) > 350.0:
			return pos
	return BASE_POS + Vector2(randf_range(-700, 700), randf_range(-700, 700))

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
	_hud.update_enemy_progress(_killed, _wave_total)

	if e.get("spawns_acid") == true:
		var pool := AcidPool.new()
		pool.global_position = e.global_position
		pool.player          = _get_local_player()
		if is_instance_valid(_assault_npc):  pool._allies.append(_assault_npc)
		if is_instance_valid(_medic_npc):    pool._allies.append(_medic_npc)
		add_child(pool)

	var mhp: int = int(e.get("max_hp") if e.get("max_hp") != null else 10)
	var ef_scale := 1.0
	var shk      := 1.2
	if   mhp >= 400: ef_scale = 3.0; shk = 5.0
	elif mhp >= 120: ef_scale = 2.0; shk = 2.8
	elif mhp >= 40:  ef_scale = 1.4; shk = 1.8
	shake(shk)
	_spawn_death_effect(e.global_position, e.body_color, ef_scale)
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

	if hp_v >= 120 and randf() < 0.05 and is_instance_valid(_player) and _player.has_method("add_rockets"):
		_player.add_rockets(1)
	if hp_v >= 300:
		if randf() < 0.45:
			_drop_crate(e.global_position, Crate.Type.MEDKIT)
		if randf() < 0.14:
			_drop_crate(e.global_position + Vector2(randf_range(-35,35), randf_range(-35,35)), Crate.Type.BOMB)
	elif hp_v >= 100:
		if randf() < 0.22:
			_drop_crate(e.global_position, Crate.Type.MEDKIT)
	elif hp_v >= 50:
		if randf() < 0.18:
			_drop_crate(e.global_position, Crate.Type.BIOMASA)

	SoundManager.play("death")
	shake(1.5)

func _spawn_death_effect(pos: Vector2, color: Color, scale_f: float = 1.0) -> void:
	var ef         = DeathEffect.new()
	ef.position    = pos
	ef._color      = color
	ef._scale_f    = scale_f
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
	# If the medic is alive, the player goes "down" with a revive timer
	# instead of game-over. Medic auto-targets downed player.
	if is_instance_valid(_medic_npc) and not _medic_npc.get("down"):
		_start_player_downed()
		return
	_finalize_player_death()


func _start_player_downed() -> void:
	if _player_down_active:
		return
	_player_down_active = true
	_player_down_t      = PLAYER_DOWN_TIMEOUT
	_player.set_physics_process(false)
	_player.modulate = Color(0.4, 0.4, 0.4)
	_hud.show_npc_announcement("¡CAÍSTE! MÉDICO EN CAMINO", Color(1.0, 0.55, 0.10))


func _finalize_player_death() -> void:
	_game_over      = true
	_mission_active = false
	_bomb_count     = 0
	_player_down_active = false
	MusicPlayer.set_mode(MusicPlayer.Mode.SILENT)
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
	MusicPlayer.set_mode(MusicPlayer.Mode.SILENT)
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


# ── Meta-progresión ───────────────────────────────────────────────────────────

func _apply_meta_upgrades() -> void:
	if not is_instance_valid(_player):
		return
	var speed_lv:  int = StageManager.get_meta_level("speed")
	var fire_lv:   int = StageManager.get_meta_level("fire")
	var armor_lv:  int = StageManager.get_meta_level("armor")
	var ammo_lv:   int = StageManager.get_meta_level("ammo")
	var damage_lv: int = StageManager.get_meta_level("damage")
	var rocket_lv: int = StageManager.get_meta_level("rockets")
	if speed_lv  > 0 and _player.has_method("apply_meta_speed"):  _player.apply_meta_speed(speed_lv)
	if fire_lv   > 0 and _player.has_method("apply_meta_fire"):   _player.apply_meta_fire(fire_lv)
	if ammo_lv   > 0 and _player.has_method("apply_meta_ammo"):   _player.apply_meta_ammo(ammo_lv)
	if damage_lv > 0 and _player.has_method("apply_meta_damage"): _player.apply_meta_damage(damage_lv)
	if armor_lv  > 0 and _player.has_method("apply_meta_armor"):
		const ARMOR_BONUS := [0, 25, 50, 80]
		_player.apply_meta_armor(ARMOR_BONUS[clamp(armor_lv, 0, 3)])
		_hud.update_max_hp(_player.max_hp)
		_hud.update_hp(_player.hp)
	if rocket_lv > 0 and _player.has_method("add_rockets"):
		const ROCKET_BONUS := [0, 1, 2, 4]
		_player.add_rockets(ROCKET_BONUS[clamp(rocket_lv, 0, 3)])


func _apply_meta_upgrades_for(p: Node2D) -> void:
	if not is_instance_valid(p):
		return
	var speed_lv:  int = StageManager.get_meta_level("speed")
	var fire_lv:   int = StageManager.get_meta_level("fire")
	var armor_lv:  int = StageManager.get_meta_level("armor")
	var ammo_lv:   int = StageManager.get_meta_level("ammo")
	var damage_lv: int = StageManager.get_meta_level("damage")
	var rocket_lv: int = StageManager.get_meta_level("rockets")
	if speed_lv  > 0 and p.has_method("apply_meta_speed"):  p.apply_meta_speed(speed_lv)
	if fire_lv   > 0 and p.has_method("apply_meta_fire"):   p.apply_meta_fire(fire_lv)
	if ammo_lv   > 0 and p.has_method("apply_meta_ammo"):   p.apply_meta_ammo(ammo_lv)
	if damage_lv > 0 and p.has_method("apply_meta_damage"): p.apply_meta_damage(damage_lv)
	if armor_lv  > 0 and p.has_method("apply_meta_armor"):
		const ARMOR_BONUS := [0, 25, 50, 80]
		p.apply_meta_armor(ARMOR_BONUS[clamp(armor_lv, 0, 3)])
		_hud.update_max_hp(p.max_hp)
		_hud.update_hp(p.hp)
	if rocket_lv > 0 and p.has_method("add_rockets"):
		const ROCKET_BONUS := [0, 1, 2, 4]
		p.add_rockets(ROCKET_BONUS[clamp(rocket_lv, 0, 3)])


# ── Rocket handling ───────────────────────────────────────────────────────────

func _on_rocket_fired(rocket: Node) -> void:
	if is_instance_valid(rocket) and rocket.has_signal("exploded"):
		rocket.exploded.connect(_on_rocket_exploded)

func _on_rocket_exploded(pos: Vector2) -> void:
	const ROCKET_RADIUS := 120.0
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.has_method("take_damage"):
			if e.global_position.distance_to(pos) <= ROCKET_RADIUS:
				e.take_damage(150)
	for s in _walls.get_children():
		if is_instance_valid(s) and s.has_method("take_damage"):
			if s.global_position.distance_to(pos) <= ROCKET_RADIUS * 0.5:
				s.take_damage(40)
	var ef     := BombEffect.new()
	ef.position = pos
	ef.max_r    = 140.0
	ef.tint     = Color(1.0, 0.55, 0.15)
	add_child(ef)
	shake(14.0)
	SoundManager.play("explode")


# ── Dynamic mid-mission events ────────────────────────────────────────────────

func _tick_events(delta: float) -> void:
	if not _mission_active or _game_over or _build_phase:
		return
	if _is_beacon_mission() or _is_cache_mission() or _is_burrow_mission():
		return
	_event_cd -= delta
	if _event_cd <= 0.0:
		_event_cd = randf_range(55.0, 90.0)
		_fire_random_event()

func _fire_random_event() -> void:
	var r := randf()
	if   r < 0.22: _event_horda()
	elif r < 0.40: _event_kit()
	elif r < 0.55: _event_interferencia()
	elif r < 0.68: _event_frenesi()
	elif r < 0.80: _event_lluvia_meteoros()
	elif r < 0.90: _event_tormenta_acida()
	else:          _event_infeccion_masiva()

func _event_horda() -> void:
	_hud.show_npc_announcement("¡REFUERZOS ENEMIGOS!", Color(1.0, 0.25, 0.2))
	shake(6.0)
	var count: int = 12 + _wave * 4
	for i in count:
		await get_tree().create_timer(0.12 * i).timeout
		if not is_instance_valid(self) or not _mission_active:
			return
		var e: CharacterBody2D
		var r := randf()
		if   r < 0.20: e = BLINDADO_SCENE.instantiate()
		elif r < 0.45: e = ESCUPIDOR_SCENE.instantiate()
		elif r < 0.65: e = SALTADORA_SCENE.instantiate()
		else:          e = LARVA_SCENE.instantiate()
		e.max_hp           = maxi(e.max_hp, int(float(e.max_hp) * (1.0 + _wave * 0.2)))
		e.hp               = e.max_hp
		e.player           = _player
		e.base_pos         = BASE_POS
		e.bullet_container = _bullets
		if "fortress" in e: e.fortress = _fortress
		e.died.connect(_on_enemy_died)
		e.position         = _pick_spawn_pos()
		_enemies.add_child(e)

func _event_kit() -> void:
	_hud.show_npc_announcement("¡KIT DE CAMPO DISPONIBLE!", Color(0.3, 1.0, 0.55))
	_spawn_crates()

func _event_interferencia() -> void:
	_hud.show_npc_announcement("¡INTERFERENCIA — TORRETAS FUERA 8s!", Color(1.0, 0.75, 0.15))
	for s in _walls.get_children():
		if is_instance_valid(s) and s.get("_fire_cd") != null:
			s.set("_fire_cd", 8.0)

func _event_frenesi() -> void:
	_hud.show_npc_announcement("¡FRENESÍ! ENEMIGOS ACELERADOS 12s", Color(1.0, 0.35, 0.80))
	shake(5.0)
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.get("speed") != null:
			e.speed = float(e.speed) * 1.45
	await get_tree().create_timer(12.0).timeout
	if not is_instance_valid(self):
		return
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.get("speed") != null:
			e.speed = float(e.speed) / 1.45

func _event_lluvia_meteoros() -> void:
	_hud.show_npc_announcement("¡LLUVIA DE METEOROS — A CUBIERTA!", Color(1.0, 0.55, 0.15))
	shake(6.0)
	var count := 5 + randi() % 4
	for i in count:
		await get_tree().create_timer(0.85 * i + randf_range(0.0, 0.4)).timeout
		if not is_instance_valid(self) or not _mission_active:
			return
		var pos := Vector2(
			randf_range(350.0, MAP_W - 350.0),
			randf_range(350.0, MAP_H - 350.0))
		_spawn_meteor(pos)

func _spawn_meteor(pos: Vector2) -> void:
	const METEOR_R   := 90.0
	const METEOR_DMG := 55
	for e in _enemies.get_children():
		if is_instance_valid(e) and e.has_method("take_damage"):
			if e.global_position.distance_to(pos) <= METEOR_R:
				e.take_damage(METEOR_DMG)
	if is_instance_valid(_player) and _player.global_position.distance_to(pos) <= METEOR_R * 0.6:
		_player.take_damage(22)
	var ef := BombEffect.new()
	ef.position = pos
	ef.max_r    = METEOR_R
	ef.tint     = Color(0.95, 0.45, 0.10)
	add_child(ef)
	SoundManager.play("explode")
	shake(7.0)

func _event_tormenta_acida() -> void:
	_hud.show_npc_announcement("¡TORMENTA ÁCIDA — VELOCIDAD REDUCIDA 15s!", Color(0.55, 0.88, 0.15))
	if is_instance_valid(_player) and _player.has_method("set_acid_storm"):
		_player.set_acid_storm(true)
	await get_tree().create_timer(15.0).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(_player) and _player.has_method("set_acid_storm"):
		_player.set_acid_storm(false)
	_hud.show_npc_announcement("TORMENTA ÁCIDA DISIPADA", Color(0.55, 0.88, 0.15))

func _event_infeccion_masiva() -> void:
	_hud.show_npc_announcement("¡ESPORA BIOORGÁNICA — INFECCIÓN MASIVA 20s!", Color(0.65, 0.10, 0.90))
	if is_instance_valid(_player) and not _player.serum \
			and _player.has_method("force_infect"):
		_player.force_infect(true)
		await get_tree().create_timer(20.0).timeout
		if not is_instance_valid(self):
			return
		if is_instance_valid(_player) and _player.infected:
			_player.force_infect(false)
			_hud.show_npc_announcement("INFECCIÓN NEUTRALIZADA", Color(0.30, 1.0, 0.55))
