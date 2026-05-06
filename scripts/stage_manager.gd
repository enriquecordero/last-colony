extends Node

const SAVE_PATH := "user://progress.cfg"

var selected_mission_id: String     = ""
var completed_missions:  Array      = []
var unlocked_rewards:    Array      = []
var current_stage_id:    String     = "stage1"
var _last_result:        Dictionary = {}

func _ready() -> void:
	load_progress()

func get_mission_status(mission_id: String) -> String:
	if is_mission_completed(mission_id):
		return "completed"
	var mission: MissionData = StageRegistry.get_mission(mission_id)
	if mission == null:
		return "locked"
	for req in mission.required_missions:
		if not is_mission_completed(req):
			return "locked"
	if mission.required_optional_group.size() > 0:
		var count := 0
		for req in mission.required_optional_group:
			if is_mission_completed(req):
				count += 1
		if count < mission.required_optional_count:
			return "locked"
	return "available"

func is_mission_completed(id: String) -> bool:
	return id in completed_missions

func complete_mission(mission_id: String, reward_id: String = "") -> void:
	if not is_mission_completed(mission_id):
		completed_missions.append(mission_id)
	if reward_id != "" and not is_reward_unlocked(reward_id):
		unlocked_rewards.append(reward_id)
	save_progress()

func is_reward_unlocked(reward_id: String) -> bool:
	return reward_id in unlocked_rewards

func lose_stage_progress(stage_id: String) -> void:
	var stage: StageData = StageRegistry.get_stage(stage_id)
	if stage == null:
		return
	for mission in stage.missions:
		completed_missions.erase(mission.id)
	save_progress()

func reset_progress() -> void:
	completed_missions.clear()
	current_stage_id    = "stage1"
	selected_mission_id = ""
	save_progress()

func set_last_result(result: Dictionary) -> void:
	_last_result = result

func get_last_result() -> Dictionary:
	return _last_result

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed_missions", completed_missions)
	cfg.set_value("progress", "unlocked_rewards",   unlocked_rewards)
	cfg.set_value("progress", "current_stage_id",   current_stage_id)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	completed_missions = cfg.get_value("progress", "completed_missions", [])
	unlocked_rewards   = cfg.get_value("progress", "unlocked_rewards",   [])
	current_stage_id   = cfg.get_value("progress", "current_stage_id",   "stage1")
