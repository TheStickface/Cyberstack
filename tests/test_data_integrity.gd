class_name TestDataIntegrity
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_all_factions_loaded() -> Dictionary:
	if repo.factions.size() != 6:
		return {"passed": false, "message": "Expected 6 factions, got %d" % repo.factions.size(), "assertions": 1}
		
	var runners = repo.get_faction(Enums.Faction.STREET_RUNNERS)
	if runners == null or runners.threshold_bonuses.size() < 2:
		return {"passed": false, "message": "Street Runners faction missing or has insufficient thresholds", "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_all_tags_loaded() -> Dictionary:
	if repo.tags.size() != 4:
		return {"passed": false, "message": "Expected 4 tags, got %d" % repo.tags.size(), "assertions": 1}
		
	var viral = repo.get_tag(Enums.AugmentTag.VIRAL)
	if viral == null or viral.chain_bonuses.size() < 2:
		return {"passed": false, "message": "Viral tag missing or has insufficient chain bonuses", "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_unit_queries() -> Dictionary:
	var all_units = repo.get_all_units()
	if all_units.size() != 83:
		return {"passed": false, "message": "Expected 83 total units (60 recruitable + 23 bosses), got %d" % all_units.size(), "assertions": 1}
		
	var recruitable = repo.get_recruitable_units()
	if recruitable.size() != 60:
		return {"passed": false, "message": "Expected 60 recruitable units, got %d" % recruitable.size(), "assertions": 2}
		
	var bosses = repo.get_boss_units()
	if bosses.size() != 23:
		return {"passed": false, "message": "Expected 23 boss units, got %d" % bosses.size(), "assertions": 3}
		
	for f in [Enums.Faction.STREET_RUNNERS, Enums.Faction.CORP_ENFORCERS, Enums.Faction.ROGUE_AIS, Enums.Faction.FIXERS, Enums.Faction.BIO_HACKERS, Enums.Faction.NET_PHANTOMS]:
		var fac_recruitable = repo.get_recruitable_units().filter(func(u): return u.faction == f)
		if fac_recruitable.size() != 10:
			return {"passed": false, "message": "Expected 10 recruitable units for faction %d, got %d" % [f, fac_recruitable.size()], "assertions": 4}
		
	return {"passed": true, "assertions": 4}

func test_augment_queries() -> Dictionary:
	var all_augments = repo.get_all_augments()
	if all_augments.size() != 20:
		return {"passed": false, "message": "Expected 20 total augments, got %d" % all_augments.size(), "assertions": 1}
		
	for t in [Enums.AugmentTag.VIRAL, Enums.AugmentTag.THERMAL, Enums.AugmentTag.NEURAL, Enums.AugmentTag.KINETIC]:
		var tag_augs = repo.get_augments_by_tag(t)
		if tag_augs.size() != 5:
			return {"passed": false, "message": "Expected 5 augments for tag %d, got %d" % [t, tag_augs.size()], "assertions": 2}
		
	var legendaries = repo.get_augments_by_tier(Enums.AugmentTier.LEGENDARY)
	if legendaries.size() != 4:
		return {"passed": false, "message": "Expected 4 Legendary augments (1 per tag), got %d" % legendaries.size(), "assertions": 3}

	return {"passed": true, "assertions": 3}

func test_district_pool_composition() -> Dictionary:
	var all_districts = repo.get_all_districts()
	if all_districts.size() < 20:
		return {"passed": false, "message": "Expected at least 20 districts in the pool, got %d" % all_districts.size(), "assertions": 1}

	var finals = repo.get_final_boss_districts()
	if finals.is_empty():
		return {"passed": false, "message": "Expected at least 1 final-boss district", "assertions": 2}

	var normals = repo.get_normal_districts()
	if normals.size() != all_districts.size() - finals.size():
		return {"passed": false, "message": "Normal + final-boss counts should add up to the full pool", "assertions": 3}

	for d in normals:
		if (d as DistrictResource).is_final_boss:
			return {"passed": false, "message": "get_normal_districts() returned a final-boss district", "assertions": 4}

	return {"passed": true, "assertions": 4}

func test_draw_run_districts() -> Dictionary:
	var drawn = repo.draw_run_districts(Constants.NORMAL_DISTRICTS_PER_RUN)

	if drawn.size() != Constants.NORMAL_DISTRICTS_PER_RUN + 1:
		return {"passed": false, "message": "Expected %d drawn districts, got %d" % [Constants.NORMAL_DISTRICTS_PER_RUN + 1, drawn.size()], "assertions": 1}

	var seen_ids: Dictionary = {}
	for i in range(Constants.NORMAL_DISTRICTS_PER_RUN):
		var dist: DistrictResource = drawn[i]
		if dist.is_final_boss:
			return {"passed": false, "message": "Non-final run slot %d contained a final-boss district" % i, "assertions": 2}
		if seen_ids.has(dist.id):
			return {"passed": false, "message": "Duplicate district '%s' drawn within the same run" % dist.id, "assertions": 2}
		seen_ids[dist.id] = true

	var last: DistrictResource = drawn[drawn.size() - 1]
	if not last.is_final_boss:
		return {"passed": false, "message": "Final run slot did not contain a final-boss district", "assertions": 3}

	return {"passed": true, "assertions": 3}

func test_constants_limits_consistency() -> Dictionary:
	# District 1: 3 player slots vs 2 enemy minions
	if Constants.DISTRICT_CREW_LIMITS.get(1) != 3 or Constants.DISTRICT_ENEMY_COUNTS.get(1) != 2:
		return {"passed": false, "message": "District 1 should have 3 crew limit and 2 enemy minions", "assertions": 1}
		
	# District 2+: Enemy count must equal crew limit for matching symmetric scaling
	for d in [2, 3, 4, 5]:
		var crew_lim = Constants.DISTRICT_CREW_LIMITS.get(d)
		var enemy_lim = Constants.DISTRICT_ENEMY_COUNTS.get(d)
		if crew_lim != enemy_lim:
			return {"passed": false, "message": "District %d mismatch: crew %d vs enemy %d" % [d, crew_lim, enemy_lim], "assertions": 2}
			
	return {"passed": true, "assertions": 2}
