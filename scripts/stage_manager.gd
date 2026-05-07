extends Node

const SAVE_PATH := "user://progress.cfg"

# Meta-progresión: 8 mejoras permanentes (4×2 en la pantalla de hub)
const META_TREE := {
	"speed":    {"label": "VELOCIDAD",  "max": 3, "costs": [15, 25, 40], "color": Color(0.40, 0.85, 1.00)},
	"fire":     {"label": "CADENCIA",   "max": 3, "costs": [18, 28, 45], "color": Color(1.00, 0.75, 0.20)},
	"armor":    {"label": "BLINDAJE",   "max": 3, "costs": [20, 35, 55], "color": Color(0.60, 0.90, 0.60)},
	"ammo":     {"label": "MUNICIÓN",   "max": 3, "costs": [12, 22, 35], "color": Color(0.80, 0.80, 0.40)},
	"damage":   {"label": "DAÑO",       "max": 3, "costs": [22, 38, 60], "color": Color(1.00, 0.50, 0.30)},
	"rockets":  {"label": "COHETES",    "max": 3, "costs": [30, 50, 80], "color": Color(1.00, 0.35, 0.35)},
}

var is_multiplayer:      bool       = false
var selected_mission_id: String     = ""
var completed_missions:  Array      = []
var unlocked_rewards:    Array      = []
var current_stage_id:    String     = "stage1"
var _last_result:        Dictionary = {}
var chatarra_banked:     int        = 0
var meta_upgrades:       Dictionary = {}

func _ready() -> void:
	load_progress()

func get_mission_status(mission_id: String) -> String:
	if is_mission_completed(mission_id):
		return "completed"
	var mission = StageRegistry.get_mission(mission_id)
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
	var stage = StageRegistry.get_stage(stage_id)
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
	cfg.set_value("progress", "chatarra_banked",     chatarra_banked)
	cfg.set_value("progress", "meta_upgrades",       meta_upgrades)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	completed_missions = cfg.get_value("progress", "completed_missions", [])
	unlocked_rewards   = cfg.get_value("progress", "unlocked_rewards",   [])
	current_stage_id   = cfg.get_value("progress", "current_stage_id",   "stage1")
	chatarra_banked    = cfg.get_value("progress", "chatarra_banked",    0)
	meta_upgrades      = cfg.get_value("progress", "meta_upgrades",      {})


# ─────────────────────────────────────────────────────────────────────────────
# Meta-progresión
# ─────────────────────────────────────────────────────────────────────────────

func bank_chatarra(amount: int) -> void:
	chatarra_banked += amount
	save_progress()

func get_meta_level(key: String) -> int:
	return int(meta_upgrades.get(key, 0))

func get_meta_cost(key: String) -> int:
	var lv: int   = get_meta_level(key)
	var info: Dictionary = META_TREE.get(key, {})
	if info.is_empty() or lv >= int(info["max"]):
		return -1
	var costs: Array = info["costs"]
	return int(costs[lv])

func is_meta_maxed(key: String) -> bool:
	var info: Dictionary = META_TREE.get(key, {})
	if info.is_empty():
		return true
	return get_meta_level(key) >= int(info["max"])

func buy_meta(key: String) -> bool:
	if is_meta_maxed(key):
		return false
	var cost: int = get_meta_cost(key)
	if chatarra_banked < cost:
		return false
	chatarra_banked -= cost
	meta_upgrades[key] = get_meta_level(key) + 1
	save_progress()
	return true
