extends Node

const _StageData   = preload("res://scripts/stage_data.gd")
const _MissionData = preload("res://scripts/mission_data.gd")

var _stages:   Dictionary = {}
var _missions: Dictionary = {}

func _ready() -> void:
	_register_stage1()
	_register_stage2()

func get_stage(id: String):
	return _stages.get(id, null)

func get_mission(id: String):
	return _missions.get(id, null)

func get_stage_missions(stage_id: String) -> Array:
	var stage = get_stage(stage_id)
	if stage == null:
		return []
	return stage.missions

func _register_stage1() -> void:
	var s := _StageData.new()
	s.id           = "stage1"
	s.display_name = "Sector Alpha"
	s.biome        = "urban_ruins"

	var m1 := _MissionData.new()
	m1.id                   = "stage1_recon"
	m1.stage_id             = "stage1"
	m1.display_name         = "Reconocimiento"
	m1.description          = "Establecer perímetro. Sobrevivir 5 oleadas."
	m1.type                 = _MissionData.MissionType.INCURSION
	m1.objective_type       = _MissionData.ObjectiveType.SURVIVE_WAVES
	m1.max_waves            = 8
	m1.pre_populate_enemies = 22
	m1.required_missions    = []
	m1.is_optional          = false
	m1.reward_chatarra      = 30
	m1.reward_id            = ""

	var m2 := _MissionData.new()
	m2.id                   = "stage1_satellite"
	m2.stage_id             = "stage1"
	m2.display_name         = "Comunicaciones"
	m2.description          = "Activar 2 satélites de comunicaciones."
	m2.type                 = _MissionData.MissionType.INCURSION
	m2.objective_type       = _MissionData.ObjectiveType.ACTIVATE_BEACONS
	m2.objective_count      = 2
	m2.max_waves            = 0
	m2.pre_populate_enemies = 28
	m2.required_missions    = ["stage1_recon"]
	m2.is_optional          = true
	m2.reward_chatarra      = 20
	m2.reward_id            = "full_minimap"

	var m3 := _MissionData.new()
	m3.id                   = "stage1_research"
	m3.stage_id             = "stage1"
	m3.display_name         = "Investigación"
	m3.description          = "Recoger 3 cachés de investigación."
	m3.type                 = _MissionData.MissionType.INCURSION
	m3.objective_type       = _MissionData.ObjectiveType.COLLECT_CACHES
	m3.objective_count      = 3
	m3.max_waves            = 0
	m3.pre_populate_enemies = 22
	m3.required_missions    = ["stage1_recon"]
	m3.is_optional          = true
	m3.reward_chatarra      = 20
	m3.reward_id            = "antiserum"

	var m4 := _MissionData.new()
	m4.id                      = "stage1_extermination"
	m4.stage_id                = "stage1"
	m4.display_name            = "Exterminio"
	m4.description             = "Cerrar 4 madrigueras enemigas."
	m4.type                    = _MissionData.MissionType.INCURSION
	m4.objective_type          = _MissionData.ObjectiveType.CLOSE_BURROWS
	m4.objective_count         = 4
	m4.max_waves               = 0
	m4.pre_populate_enemies    = 38
	m4.required_missions       = ["stage1_recon"]
	m4.required_optional_group = ["stage1_satellite", "stage1_research"]
	m4.required_optional_count = 1
	m4.is_optional             = false
	m4.reward_chatarra         = 50
	m4.reward_id               = ""

	var m5 := _MissionData.new()
	m5.id                   = "stage1_engendro"
	m5.stage_id             = "stage1"
	m5.display_name         = "El Engendro"
	m5.description          = "Eliminar al líder de la horda."
	m5.type                 = _MissionData.MissionType.SURVIVAL
	m5.objective_type       = _MissionData.ObjectiveType.KILL_BOSS
	m5.objective_count      = 1
	m5.max_waves            = 6
	m5.pre_populate_enemies = 0
	m5.required_missions    = ["stage1_extermination"]
	m5.is_optional          = false
	m5.reward_chatarra      = 100
	m5.reward_id            = "stage1_complete"

	s.missions    = [m1, m2, m3, m4, m5]
	_stages[s.id] = s
	for m in s.missions:
		_missions[m.id] = m

func _register_stage2() -> void:
	var s := _StageData.new()
	s.id           = "stage2"
	s.display_name = "Sector Beta"
	s.biome        = "toxic_ruins"

	var m1 := _MissionData.new()
	m1.id                   = "stage2_advance"
	m1.stage_id             = "stage2"
	m1.display_name         = "Avanzada"
	m1.description          = "Establecer posición en Sector Beta. Enemigos más rápidos y numerosos."
	m1.type                 = _MissionData.MissionType.INCURSION
	m1.objective_type       = _MissionData.ObjectiveType.SURVIVE_WAVES
	m1.max_waves            = 10
	m1.pre_populate_enemies = 30
	m1.required_missions    = ["stage1_complete"]
	m1.is_optional          = false
	m1.reward_chatarra      = 60

	var m2 := _MissionData.new()
	m2.id                   = "stage2_infiltration"
	m2.stage_id             = "stage2"
	m2.display_name         = "Infiltración"
	m2.description          = "Recuperar 3 cachés en instalaciones comprometidas. Cuidado con los voladores."
	m2.type                 = _MissionData.MissionType.INCURSION
	m2.objective_type       = _MissionData.ObjectiveType.COLLECT_CACHES
	m2.objective_count      = 3
	m2.max_waves            = 0
	m2.pre_populate_enemies = 35
	m2.required_missions    = ["stage2_advance"]
	m2.is_optional          = true
	m2.reward_chatarra      = 45
	m2.reward_id            = ""

	var m3 := _MissionData.new()
	m3.id                   = "stage2_extermination"
	m3.stage_id             = "stage2"
	m3.display_name         = "Exterminio Beta"
	m3.description          = "Cerrar 5 madrigueras en Sector Beta. Los excavadores emergen desde adentro."
	m3.type                 = _MissionData.MissionType.INCURSION
	m3.objective_type       = _MissionData.ObjectiveType.CLOSE_BURROWS
	m3.objective_count      = 5
	m3.max_waves            = 0
	m3.pre_populate_enemies = 40
	m3.required_missions    = ["stage2_advance"]
	m3.is_optional          = true
	m3.reward_chatarra      = 45
	m3.reward_id            = ""

	var m4 := _MissionData.new()
	m4.id                      = "stage2_siege"
	m4.stage_id                = "stage2"
	m4.display_name            = "El Asedio"
	m4.description             = "Oleada masiva. Tanques, voladores y excavadores simultáneos. Sobrevivir 15 oleadas."
	m4.type                    = _MissionData.MissionType.SURVIVAL
	m4.objective_type          = _MissionData.ObjectiveType.SURVIVE_WAVES
	m4.max_waves               = 15
	m4.pre_populate_enemies    = 0
	m4.required_missions       = ["stage2_advance"]
	m4.required_optional_group = ["stage2_infiltration", "stage2_extermination"]
	m4.required_optional_count = 1
	m4.is_optional             = false
	m4.reward_chatarra         = 120

	var m5 := _MissionData.new()
	m5.id                   = "stage2_queen"
	m5.stage_id             = "stage2"
	m5.display_name         = "La Reina"
	m5.description          = "Eliminar a la Reina de la colmena. La amenaza final del Sector Beta."
	m5.type                 = _MissionData.MissionType.SURVIVAL
	m5.objective_type       = _MissionData.ObjectiveType.KILL_BOSS
	m5.objective_count      = 1
	m5.max_waves            = 6
	m5.pre_populate_enemies = 0
	m5.required_missions    = ["stage2_siege"]
	m5.is_optional          = false
	m5.reward_chatarra      = 200
	m5.reward_id            = "stage2_complete"

	s.missions    = [m1, m2, m3, m4, m5]
	_stages[s.id] = s
	for m in s.missions:
		_missions[m.id] = m
