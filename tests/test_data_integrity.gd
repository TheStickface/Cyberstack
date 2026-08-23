class_name TestDataIntegrity
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_all_factions_loaded() -> Dictionary:
	if repo.factions.size() != 4:
		return {"passed": false, "message": "Expected 4 factions, got %d" % repo.factions.size(), "assertions": 1}
		
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
	if all_units.size() < 5:
		return {"passed": false, "message": "Expected at least 5 units, got %d" % all_units.size(), "assertions": 1}
		
	var runners = repo.get_units_by_faction(Enums.Faction.STREET_RUNNERS)
	if runners.size() < 2:
		return {"passed": false, "message": "Expected at least 2 Street Runners, got %d" % runners.size(), "assertions": 2}
		
	var tanks = repo.get_units_by_role(Enums.UnitRole.TANK)
	if tanks.size() < 2:
		return {"passed": false, "message": "Expected at least 2 Tanks, got %d" % tanks.size(), "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_augment_queries() -> Dictionary:
	var all_augments = repo.get_all_augments()
	if all_augments.size() < 7:
		return {"passed": false, "message": "Expected at least 7 augments, got %d" % all_augments.size(), "assertions": 1}
		
	var viral_augments = repo.get_augments_by_tag(Enums.AugmentTag.VIRAL)
	if viral_augments.size() < 2:
		return {"passed": false, "message": "Expected at least 2 Viral augments, got %d" % viral_augments.size(), "assertions": 2}
		
	var legendary = repo.get_augments_by_tier(Enums.AugmentTier.LEGENDARY)
	if legendary.is_empty():
		return {"passed": false, "message": "Expected at least 1 Legendary augment", "assertions": 3}

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
