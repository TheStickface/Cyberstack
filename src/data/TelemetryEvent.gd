class_name TelemetryEvent
extends RefCounted

## Data container for individual player run telemetry events and summaries

const SCHEMA_VERSION: int = 1

var schema_version: int = SCHEMA_VERSION
var is_synthetic: bool = false
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
		var fac_enum = f as int as Enums.Faction
		var fac_key = Enums.faction_to_string(fac_enum)
		fac_dict[fac_key] = active_factions[f]
		
	var tag_dict: Dictionary = {}
	for t in active_tags.keys():
		var tag_enum = t as int as Enums.AugmentTag
		var tag_key = Enums.tag_to_string(tag_enum)
		tag_dict[tag_key] = active_tags[t]
		
	return {
		"schema_version": schema_version,
		"is_synthetic": is_synthetic,
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
	schema_version = data.get("schema_version", SCHEMA_VERSION)
	is_synthetic = data.get("is_synthetic", false)
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
	for f_key in fac_dict.keys():
		var count = int(fac_dict[f_key])
		var f_str = str(f_key)
		if f_str.is_valid_int():
			active_factions[int(f_str)] = count
		else:
			var fac_enum = Enums.string_to_faction(f_str)
			if fac_enum != Enums.Faction.NONE:
				active_factions[int(fac_enum)] = count
		
	active_tags.clear()
	var tag_dict = data.get("active_tags", {})
	for t_key in tag_dict.keys():
		var count = int(tag_dict[t_key])
		var t_str = str(t_key)
		if t_str.is_valid_int():
			active_tags[int(t_str)] = count
		else:
			var tag_enum = Enums.string_to_tag(t_str)
			if tag_enum != Enums.AugmentTag.NONE:
				active_tags[int(tag_enum)] = count

