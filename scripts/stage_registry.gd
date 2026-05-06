extends Node

const _StageData   = preload("res://scripts/stage_data.gd")
const _MissionData = preload("res://scripts/mission_data.gd")

var _stages:   Dictionary = {}
var _missions: Dictionary = {}

func _ready() -> void:
	_register_stage1()

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
	m1.max_waves            = 5
	m1.pre_populate_enemies = 10
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
	m2.pre_populate_enemies = 15
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
	m3.pre_populate_enemies = 12
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
	m4.pre_populate_enemies    = 25
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
