class_name TelemetryEvent
extends RefCounted

## Data container for individual player run telemetry events and summaries

var session_id: String = ""
var timestamp: int = 0
var event_type: String = "" # RUN_START, ENCOUNTER, RUN_END, RECRUIT, EQUIP
var district_index: int = 1
var node_index: int = 0
var victory: bool = false
var duration_seconds: float = 0.0
var gold_spent: int = 0

var fielded_unit_ids: Array[String] = []
var equipped_augment_ids: Array[String] = []
var active_factions: Dictionary = {} # Faction (int) -> count (int)
var active_tags: Dictionary = {}     # Tag (int) -> count (int)

func to_dict() -> Dictionary:
	var fac_dict: Dictionary = {}
	for f in active_factions.keys():
		fac_dict[str(f)] = active_factions[f]
		
	var tag_dict: Dictionary = {}
	for t in active_tags.keys():
		tag_dict[str(t)] = active_tags[t]
		
	return {
		"session_id": session_id,
		"timestamp": timestamp,
		"event_type": event_type,
		"district_index": district_index,
		"node_index": node_index,
		"victory": victory,
		"duration_seconds": duration_seconds,
		"gold_spent": gold_spent,
		"fielded_unit_ids": fielded_unit_ids,
		"equipped_augment_ids": equipped_augment_ids,
		"active_factions": fac_dict,
		"active_tags": tag_dict
	}

func from_dict(data: Dictionary) -> void:
	session_id = data.get("session_id", "")
	timestamp = data.get("timestamp", 0)
	event_type = data.get("event_type", "")
	district_index = data.get("district_index", 1)
	node_index = data.get("node_index", 0)
	victory = data.get("victory", false)
	duration_seconds = data.get("duration_seconds", 0.0)
	gold_spent = data.get("gold_spent", 0)
	
	fielded_unit_ids.clear()
	for u in data.get("fielded_unit_ids", []):
		fielded_unit_ids.append(str(u))
		
	equipped_augment_ids.clear()
	for a in data.get("equipped_augment_ids", []):
		equipped_augment_ids.append(str(a))
		
	active_factions.clear()
	var fac_dict = data.get("active_factions", {})
	for f_str in fac_dict.keys():
		active_factions[int(f_str)] = int(fac_dict[f_str])
		
	active_tags.clear()
	var tag_dict = data.get("active_tags", {})
	for t_str in tag_dict.keys():
		active_tags[int(t_str)] = int(tag_dict[t_str])
