class_name TelemetryManager
extends RefCounted

## Telemetry recorder buffering player run summaries and community data

const TELEMETRY_PATH = "user://cyberstack_telemetry.json"
const SAMPLE_TELEMETRY_PATH = "user://cyberstack_sample_telemetry.json"

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var current_session_id: String = ""
var events_buffer: Array[TelemetryEvent] = []

func _init() -> void:
	current_session_id = _generate_uuid()

static func record_run_summary(
	summary: Dictionary,
	crew: Array[UnitInstance],
	path: String = TELEMETRY_PATH
) -> TelemetryEvent:
	var event = TelemetryEvent.new()
	event.session_id = summary.get("session_id", _generate_uuid())
	event.timestamp = Time.get_unix_time_from_system()
	event.event_type = "RUN_END"
	event.victory = summary.get("victory", false)
	event.district_index = summary.get("district", 1)
	event.duration_seconds = float(summary.get("duration", 0.0))
	event.gold_spent = int(summary.get("gold_spent", 0))
	event.is_synthetic = summary.get("is_synthetic", false)

	for unit in crew:
		if unit and unit.unit_resource:
			event.fielded_unit_ids.append(unit.unit_resource.id)
			var fac_id := int(unit.unit_resource.faction)
			event.active_factions[fac_id] = int(event.active_factions.get(fac_id, 0)) + 1
			for aug in unit.get_equipped_augments():
				if aug:
					event.equipped_augment_ids.append(aug.id)
			for tag in unit.get_all_tags():
				var tag_id := int(tag)
				event.active_tags[tag_id] = int(event.active_tags.get(tag_id, 0)) + 1

	var records = load_all_records(path)
	records.append(event)
	save_records(records, path)
	return event

static func save_records(records: Array[TelemetryEvent], path: String = TELEMETRY_PATH) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
		
	var data_list: Array[Dictionary] = []
	for r in records:
		if r:
			data_list.append(r.to_dict())
			
	var json_str = JSON.stringify(data_list, "\t")
	file.store_string(json_str)
	file.close()
	return true

static func load_all_records(path: String = TELEMETRY_PATH) -> Array[TelemetryEvent]:
	var result: Array[TelemetryEvent] = []
	if not FileAccess.file_exists(path):
		return result
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return result
		
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err == OK and json.data is Array:
		for item in json.data:
			if item is Dictionary:
				var ev = TelemetryEvent.new()
				ev.from_dict(item)
				result.append(ev)
				
	return result

## Generates realistic multi-user community sample data for analytics visualization
static func generate_community_sample_data(count: int = 50, repo_instance: Object = null, path: String = SAMPLE_TELEMETRY_PATH) -> Array[TelemetryEvent]:
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	var all_units = repo.get_all_units()
	var all_augs = repo.get_all_augments()
	
	var sample_records: Array[TelemetryEvent] = []
	
	for i in range(count):
		var ev = TelemetryEvent.new()
		ev.is_synthetic = true
		ev.session_id = "user_%04d_%s" % [randi() % 1000, _generate_uuid().substr(0, 4)]
		ev.timestamp = Time.get_unix_time_from_system() - (randi() % 604800) # Past 7 days
		ev.event_type = "RUN_END"
		
		# Simulated run outcome curve:
		# 20% die in D1, 35% die in D2, 25% die in D3, 10% die in D4, 10% Win run
		var roll = randf()
		if roll < 0.20:
			ev.district_index = 1
			ev.victory = false
		elif roll < 0.55:
			ev.district_index = 2
			ev.victory = false
		elif roll < 0.80:
			ev.district_index = 3
			ev.victory = false
		elif roll < 0.90:
			ev.district_index = 4
			ev.victory = false
		else:
			ev.district_index = 4
			ev.victory = true
			
		ev.duration_seconds = randf_range(120.0, 900.0)
		ev.gold_spent = ev.district_index * randi_range(15, 30)
		
		# Pick 2-5 random operatives for crew
		var crew_size = mini(all_units.size(), Constants.DISTRICT_CREW_LIMITS.get(ev.district_index, 2))
		var shuffled_units = all_units.duplicate()
		shuffled_units.shuffle()
		for u_idx in range(crew_size):
			var u: UnitResource = shuffled_units[u_idx]
			ev.fielded_unit_ids.append(u.id)
			var fac_id := int(u.faction)
			ev.active_factions[fac_id] = int(ev.active_factions.get(fac_id, 0)) + 1

			# Add random augments
			if not all_augs.is_empty() and randf() < 0.75:
				var a: AugmentResource = all_augs[randi() % all_augs.size()]
				ev.equipped_augment_ids.append(a.id)
				for tag in a.tags:
					var tag_id := int(tag)
					ev.active_tags[tag_id] = int(ev.active_tags.get(tag_id, 0)) + 1
				
		sample_records.append(ev)
		
	save_records(sample_records, path)
	return sample_records

static func _generate_uuid() -> String:
	return "%08x-%04x" % [randi(), randi() & 0xffff]

static func _get_default_repo() -> Object:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	return repo
