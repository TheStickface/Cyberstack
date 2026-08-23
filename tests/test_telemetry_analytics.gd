class_name TestTelemetryAnalytics
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_telemetry_event_serialization() -> Dictionary:
	var event = TelemetryEvent.new()
	event.session_id = "test_user_01"
	event.victory = true
	event.district_index = 3
	event.gold_spent = 45
	event.fielded_unit_ids.append("runner_blitz")
	event.equipped_augment_ids.append("common_kinetic_accelerator")
	event.active_factions[Enums.Faction.STREET_RUNNERS] = 2
	
	var data = event.to_dict()
	var restored = TelemetryEvent.new()
	restored.from_dict(data)
	
	if restored.session_id != "test_user_01":
		return {"passed": false, "message": "Session ID serialization mismatch", "assertions": 1}
	if not restored.victory or restored.district_index != 3:
		return {"passed": false, "message": "Run outcome serialization mismatch", "assertions": 2}
	if not restored.fielded_unit_ids.has("runner_blitz"):
		return {"passed": false, "message": "Fielded unit serialization mismatch", "assertions": 3}
	if not restored.equipped_augment_ids.has("common_kinetic_accelerator"):
		return {"passed": false, "message": "Equipped augment serialization mismatch", "assertions": 4}
		
	return {"passed": true, "assertions": 4}

func test_sample_generation_and_storage() -> Dictionary:
	var test_path = "user://test_community_telemetry.json"
	
	var samples = TelemetryManager.generate_community_sample_data(25, repo, test_path)
	if samples.size() != 25:
		return {"passed": false, "message": "Expected 25 sample events generated, got %d" % samples.size(), "assertions": 1}
		
	var loaded = TelemetryManager.load_all_records(test_path)
	if loaded.size() != 25:
		return {"passed": false, "message": "Expected 25 loaded records from disk, got %d" % loaded.size(), "assertions": 2}
		
	# Cleanup
	SaveManager.delete_active_run(test_path)
	return {"passed": true, "assertions": 2}

func test_analytics_kpi_calculations() -> Dictionary:
	var records: Array[TelemetryEvent] = []
	
	# Event 1: Victory in D4 with Blitz
	var ev1 = TelemetryEvent.new()
	ev1.victory = true
	ev1.district_index = 4
	ev1.duration_seconds = 600.0
	ev1.gold_spent = 50
	ev1.fielded_unit_ids.append("runner_blitz")
	records.append(ev1)
	
	# Event 2: Defeat in D2 with Blitz and Sentinel
	var ev2 = TelemetryEvent.new()
	ev2.victory = false
	ev2.district_index = 2
	ev2.duration_seconds = 300.0
	ev2.gold_spent = 20
	ev2.fielded_unit_ids.append("runner_blitz")
	ev2.fielded_unit_ids.append("corp_sentinel")
	records.append(ev2)
	
	# Overview KPIs
	var overview = AnalyticsEngine.compute_overview(records)
	if overview.total_runs != 2 or overview.victories != 1 or overview.win_rate != 50.0:
		return {"passed": false, "message": "Overview KPI calculation mismatch", "assertions": 1}
	if overview.avg_duration != 450.0 or overview.avg_gold_spent != 35.0:
		return {"passed": false, "message": "Averages calculation mismatch", "assertions": 2}
		
	# Operative Meta
	var op_meta = AnalyticsEngine.compute_operative_meta(records, repo)
	var blitz_stat = null
	for op in op_meta:
		if op.id == "runner_blitz":
			blitz_stat = op
			break
			
	if blitz_stat == null or blitz_stat.picks != 2 or blitz_stat.win_rate != 50.0:
		return {"passed": false, "message": "Operative meta stats mismatch for Blitz", "assertions": 3}
		
	# Mortality Curve
	var mort = AnalyticsEngine.compute_mortality_curve(records)
	if mort.d2_deaths != 1 or mort.d2_rate != 50.0 or mort.victories != 1:
		return {"passed": false, "message": "Mortality curve mismatch", "assertions": 4}
		
	return {"passed": true, "assertions": 4}
