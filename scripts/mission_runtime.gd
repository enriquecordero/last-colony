class_name MissionRuntime
extends Node

const MissionData = preload("res://scripts/mission_data.gd")

signal completed(reward_chatarra: int, reward_id: String)
signal failed(reason: String)
signal progress_updated(current: int, total: int)

var mission: MissionData = null

var _waves_completed: int = 0
var _objectives_done: int = 0

func start() -> void:
	_waves_completed = 0
	_objectives_done = 0

func notify_wave_completed() -> void:
	if mission == null or mission.objective_type != MissionData.ObjectiveType.SURVIVE_WAVES:
		return
	_waves_completed += 1
	progress_updated.emit(_waves_completed, mission.max_waves)
	if _waves_completed >= mission.max_waves:
		_emit_completed()

func notify_satellite_activated() -> void:
	_notify_objective()

func notify_cache_collected() -> void:
	_notify_objective()

func notify_burrow_closed() -> void:
	_notify_objective()

func notify_boss_killed() -> void:
	_notify_objective()

func notify_failed(reason: String) -> void:
	failed.emit(reason)
	queue_free()

func notify_failed_survival() -> void:
	if mission != null:
		StageManager.lose_stage_progress(mission.stage_id)
	notify_failed("survival_failed")

func _notify_objective() -> void:
	if mission == null:
		return
	_objectives_done += 1
	progress_updated.emit(_objectives_done, mission.objective_count)
	if _objectives_done >= mission.objective_count:
		_emit_completed()

func _emit_completed() -> void:
	var chatarra := mission.reward_chatarra if mission != null else 0
	var rid      := mission.reward_id      if mission != null else ""
	if mission != null:
		StageManager.complete_mission(mission.id, rid)
	completed.emit(chatarra, rid)
	queue_free()
