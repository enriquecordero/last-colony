class_name MissionData

enum MissionType   { DEFEND, INCURSION, SURVIVAL }
enum ObjectiveType { SURVIVE_WAVES, ACTIVATE_BEACONS, COLLECT_CACHES, CLOSE_BURROWS, KILL_BOSS }

var id:                      String        = ""
var stage_id:                String        = ""
var display_name:            String        = ""
var description:             String        = ""
var type:                    MissionType   = MissionType.INCURSION
var objective_type:          ObjectiveType = ObjectiveType.SURVIVE_WAVES
var objective_count:         int           = 0
var max_waves:               int           = 5
var pre_populate_enemies:    int           = 0
var required_missions:       Array         = []
var required_optional_group: Array         = []
var required_optional_count: int           = 1
var is_optional:             bool          = false
var reward_chatarra:         int           = 0
var reward_id:               String        = ""
