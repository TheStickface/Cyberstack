class_name TestCrewManager
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_deploy_and_recall() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo) # District 1: limit 2
	
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	var sentinel = UnitInstance.new(repo.get_unit("corp_sentinel"))
	
	crew_mgr.add_unit_to_bench(blitz)
	crew_mgr.add_unit_to_bench(ghost)
	crew_mgr.add_unit_to_bench(sentinel)
	
	if crew_mgr.benched_units.size() != 3:
		return {"passed": false, "message": "Expected 3 benched units", "assertions": 1}
		
	# Deploy 1st
	var d1_ok = crew_mgr.deploy_unit_to_field(0)
	if not d1_ok or crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "Failed to deploy 1st unit", "assertions": 2}
		
	# Deploy 2nd
	var d2_ok = crew_mgr.deploy_unit_to_field(0)
	if not d2_ok or crew_mgr.fielded_units.size() != 2:
		return {"passed": false, "message": "Failed to deploy 2nd unit", "assertions": 3}
		
	# Deploy 3rd (Should FAIL because District 1 cap is 2)
	var d3_fail = crew_mgr.deploy_unit_to_field(0)
	if d3_fail or crew_mgr.fielded_units.size() != 2:
		return {"passed": false, "message": "Should not exceed District 1 limit of 2 units", "assertions": 4}
		
	# Recall 1st
	var r_ok = crew_mgr.recall_unit_to_bench(0)
	if not r_ok or crew_mgr.fielded_units.size() != 1 or crew_mgr.benched_units.size() != 2:
		return {"passed": false, "message": "Recall unit failed", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_augment_inventory_and_swapping() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo)
	var sentinel = UnitInstance.new(repo.get_unit("corp_sentinel")) # Tank: Def, Def, Pass
	
	var def_aug = repo.get_augment("common_thermal_core") # Defensive
	var pass_aug = repo.get_augment("common_viral_nanites") # Passive
	var off_aug = repo.get_augment("common_kinetic_accelerator") # Offensive
	
	crew_mgr.add_augment_to_inventory(def_aug)
	crew_mgr.add_augment_to_inventory(off_aug)
	crew_mgr.add_augment_to_inventory(pass_aug)
	
	# Slot 0 is Defensive: Try equipping Offensive (off_aug is index 1) -> MUST FAIL
	var wrong_equip = crew_mgr.equip_augment_from_inventory(sentinel, 0, 1)
	if wrong_equip:
		return {"passed": false, "message": "Should reject offensive augment in defensive slot", "assertions": 1}
	if crew_mgr.augment_inventory.size() != 3:
		return {"passed": false, "message": "Failed equip should not consume augment from inventory", "assertions": 2}
		
	# Slot 0 is Defensive: Equip def_aug (index 0) -> MUST SUCCEED
	var right_equip = crew_mgr.equip_augment_from_inventory(sentinel, 0, 0)
	if not right_equip:
		return {"passed": false, "message": "Failed to equip valid defensive augment", "assertions": 3}
	if crew_mgr.augment_inventory.size() != 2:
		return {"passed": false, "message": "Equipping should remove item from inventory", "assertions": 4}
		
	# Unequip back to inventory
	var unequip_ok = crew_mgr.unequip_augment_to_inventory(sentinel, 0)
	if not unequip_ok or crew_mgr.augment_inventory.size() != 3:
		return {"passed": false, "message": "Unequip should return item to inventory", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_auto_synergies_and_lock_in() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo)
	
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	
	crew_mgr.add_unit_to_bench(blitz)
	crew_mgr.add_unit_to_bench(ghost)
	
	# Initial synergies should be empty
	if not crew_mgr.active_synergy_report.faction_counts.is_empty():
		return {"passed": false, "message": "Initial synergies should be empty", "assertions": 1}
		
	# Deploy Blitz (1 runner)
	crew_mgr.deploy_unit_to_field(0)
	if crew_mgr.active_synergy_report.faction_counts.get(Enums.Faction.STREET_RUNNERS, 0) != 1:
		return {"passed": false, "message": "Expected 1 Street Runner count", "assertions": 2}
	if crew_mgr.active_synergy_report.has_active_faction(Enums.Faction.STREET_RUNNERS, 2):
		return {"passed": false, "message": "Synergy should not be active with 1 runner", "assertions": 3}
		
	# Deploy Ghost (2 runners)
	crew_mgr.deploy_unit_to_field(0)
	if not crew_mgr.active_synergy_report.has_active_faction(Enums.Faction.STREET_RUNNERS, 2):
		return {"passed": false, "message": "Synergy should be ACTIVE with 2 distinct runners", "assertions": 4}
		
	# Lock-in
	var lock_result = crew_mgr.lock_in_crew()
	if not lock_result.valid:
		return {"passed": false, "message": "Valid crew failed lock-in", "assertions": 5}
	if (lock_result.crew as Array).size() != 2:
		return {"passed": false, "message": "Expected 2 units in locked payload", "assertions": 6}
		
	return {"passed": true, "assertions": 6}

func test_unit_star_combination() -> Dictionary:
	var crew_mgr = CrewManager.new(2, repo) # District 2: max 4 units
	var dash_res = repo.get_unit("runner_blitz")
	
	var copy1 = UnitInstance.new(dash_res)
	var copy2 = UnitInstance.new(dash_res)
	
	crew_mgr.add_unit(copy1)
	if crew_mgr.fielded_units.size() != 1 or copy1.star_level != 1:
		return {"passed": false, "message": "First unit should be 1-star", "assertions": 1}
		
	# Add 2nd copy -> MUST COMBINE into Tier 2 (★2)
	crew_mgr.add_unit(copy2)
	if crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "2 copies should combine into 1 unit, got %d" % crew_mgr.fielded_units.size(), "assertions": 2}
		
	var upgraded = crew_mgr.fielded_units[0]
	if upgraded.star_level != 2:
		return {"passed": false, "message": "Unit should be star_level 2, got %d" % upgraded.star_level, "assertions": 3}
	if upgraded.calculate_effective_stat(Enums.StatType.MAX_HEALTH) <= dash_res.base_max_health:
		return {"passed": false, "message": "Tier 2 unit should have boosted effective max health", "assertions": 4}
		
	# Now add 2 more copies to create a 2nd Tier 2 -> which immediately combines into 1 Tier 3 (★3)
	crew_mgr.add_unit(UnitInstance.new(dash_res))
	crew_mgr.add_unit(UnitInstance.new(dash_res))
		
	if crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "2 Tier 2 copies should combine into 1 Tier 3 unit, got %d" % crew_mgr.fielded_units.size(), "assertions": 5}
		
	var tier3_unit = crew_mgr.fielded_units[0]
	if tier3_unit.star_level != 3:
		return {"passed": false, "message": "Unit should be star_level 3, got %d" % tier3_unit.star_level, "assertions": 6}
		
	return {"passed": true, "assertions": 6}
