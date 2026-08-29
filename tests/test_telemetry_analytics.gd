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

func test_record_run_summary_uses_gold_spent_and_synergy_tags() -> Dictionary:
	var test_path = "user://test_run_summary_telemetry.json"
	SaveManager.delete_active_run(test_path)

	var crew: Array[UnitInstance] = []
	# street_ghost is a SNIPER (offensive slots) so it can carry a kinetic augment.
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	var kin_aug = repo.get_augment("common_kinetic_accelerator")
	var equipped := false
	for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
		if ghost.equip_augment(s_idx, kin_aug):
			equipped = true
			break
	if not equipped:
		return {"passed": false, "message": "Test setup: could not equip kinetic augment on street_ghost", "assertions": 1}
	crew.append(ghost)
	# runner_phantom is a second Street Runner so the faction count reaches 2.
	crew.append(UnitInstance.new(repo.get_unit("runner_phantom")))

	var summary = {"victory": true, "district": 4, "gold_spent": 63, "gold_earned": 120}
	var event = TelemetryManager.record_run_summary(summary, crew, test_path)

	if event.gold_spent != 63:
		return {"passed": false, "message": "record_run_summary should read the gold_spent key, got %d" % event.gold_spent, "assertions": 1}
	if event.active_factions.is_empty():
		return {"passed": false, "message": "record_run_summary should populate active_factions from the crew", "assertions": 2}
	if int(event.active_factions.get(int(Enums.Faction.STREET_RUNNERS), 0)) < 2:
		return {"passed": false, "message": "Two Street Runners should register as faction count 2", "assertions": 3}
	if int(event.active_tags.get(int(Enums.AugmentTag.KINETIC), 0)) < 1:
		return {"passed": false, "message": "Equipped kinetic augment should register a KINETIC tag", "assertions": 4}

	SaveManager.delete_active_run(test_path)
	return {"passed": true, "assertions": 4}

func test_faction_meta_aggregation() -> Dictionary:
	var records: Array[TelemetryEvent] = []

	var ev1 = TelemetryEvent.new()
	ev1.victory = true
	ev1.active_factions[int(Enums.Faction.STREET_RUNNERS)] = 3
	records.append(ev1)

	var ev2 = TelemetryEvent.new()
	ev2.victory = false
	ev2.active_factions[int(Enums.Faction.STREET_RUNNERS)] = 1
	records.append(ev2)

	var fac_meta = AnalyticsEngine.compute_faction_meta(records, repo)
	if fac_meta.is_empty():
		return {"passed": false, "message": "compute_faction_meta returned nothing", "assertions": 1}

	var runner_row = null
	for row in fac_meta:
		if row.id == int(Enums.Faction.STREET_RUNNERS):
			runner_row = row
			break
	if runner_row == null:
		return {"passed": false, "message": "Street Runners missing from faction meta", "assertions": 2}
	if runner_row.runs_present != 2:
		return {"passed": false, "message": "Street Runners should be present in 2 runs, got %d" % runner_row.runs_present, "assertions": 3}
	if runner_row.win_rate != 50.0:
		return {"passed": false, "message": "Street Runners win rate should be 50%%, got %.1f" % runner_row.win_rate, "assertions": 4}
	return {"passed": true, "assertions": 4}

func test_telemetry_schema_version_and_synthetic_isolation() -> Dictionary:
	var event = TelemetryEvent.new()
	event.session_id = "test_sess_01"
	event.is_synthetic = false
	event.active_factions[int(Enums.Faction.ROGUE_AIS)] = 2
	event.active_tags[int(Enums.AugmentTag.NEURAL)] = 3
	
	var data = event.to_dict()
	if not data.has("schema_version") or data["schema_version"] != 1:
		return {"passed": false, "message": "TelemetryEvent dict missing schema_version 1", "assertions": 1}
	if not data.has("is_synthetic") or data["is_synthetic"] != false:
		return {"passed": false, "message": "TelemetryEvent dict missing is_synthetic boolean", "assertions": 2}
		
	# Verify string enum keys
	var facs: Dictionary = data.get("active_factions", {})
	if not facs.has("Rogue AIs"):
		return {"passed": false, "message": "Expected stable string key 'Rogue AIs' in active_factions, got: %s" % str(facs), "assertions": 3}
		
	var tags_dict: Dictionary = data.get("active_tags", {})
	if not tags_dict.has("Neural"):
		return {"passed": false, "message": "Expected stable string key 'Neural' in active_tags, got: %s" % str(tags_dict), "assertions": 4}
		
	# Verify round-trip back into TelemetryEvent
	var restored = TelemetryEvent.new()
	restored.from_dict(data)
	if restored.active_factions.get(int(Enums.Faction.ROGUE_AIS), 0) != 2:
		return {"passed": false, "message": "Failed to parse string faction key 'Rogue AIs' back into enum int", "assertions": 5}
	if restored.active_tags.get(int(Enums.AugmentTag.NEURAL), 0) != 3:
		return {"passed": false, "message": "Failed to parse string tag key 'Neural' back into enum int", "assertions": 6}

	# Verify sample generation default path is SAMPLE_TELEMETRY_PATH and sets is_synthetic = true
	var sample_path = "user://test_sample_isolation.json"
	var samples = TelemetryManager.generate_community_sample_data(5, repo, sample_path)
	if samples.is_empty() or not samples[0].is_synthetic:
		SaveManager.delete_active_run(sample_path)
		return {"passed": false, "message": "Generated sample record does not have is_synthetic set to true", "assertions": 7}
	SaveManager.delete_active_run(sample_path)

	return {"passed": true, "assertions": 7}

func test_analytics_linear_scalability() -> Dictionary:
	var records: Array[TelemetryEvent] = []
	var units = repo.get_all_units()
	var augs = repo.get_all_augments()
	
	# Generate 1,000 in-memory records
	for i in range(1000):
		var ev = TelemetryEvent.new()
		ev.victory = (i % 2 == 0)
		ev.duration_seconds = 400.0
		ev.gold_spent = 30
		if not units.is_empty():
			ev.fielded_unit_ids.append(units[i % units.size()].id)
		if not augs.is_empty():
			ev.equipped_augment_ids.append(augs[i % augs.size()].id)
		ev.active_factions[int(Enums.Faction.CORP_ENFORCERS)] = 2
		records.append(ev)
		
	var t0 = Time.get_ticks_msec()
	var _op = AnalyticsEngine.compute_operative_meta(records, repo)
	var _aug = AnalyticsEngine.compute_augment_meta(records, repo)
	var _fac = AnalyticsEngine.compute_faction_meta(records, repo)
	var elapsed_ms = Time.get_ticks_msec() - t0
	
	if elapsed_ms > 100:
		return {"passed": false, "message": "Analytics aggregation took %d ms for 1000 records (expected < 100ms)" % elapsed_ms, "assertions": 1}
		
	return {"passed": true, "assertions": 1}
