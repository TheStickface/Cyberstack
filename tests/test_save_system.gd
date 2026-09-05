class_name TestSaveSystem
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_profile_save_and_load() -> Dictionary:
	var test_path = "user://test_profile.json"
	var profile = MetaProfile.new()
	profile.total_runs_played = 5
	profile.total_victories = 2
	profile.total_bosses_defeated = 4
	profile.total_credits_earned = 180
	profile.faction_reputation[Enums.Faction.STREET_RUNNERS] = 120
	profile.unlocked_operatives.append("custom_unlock")
	
	var saved = SaveManager.save_profile(profile, test_path)
	if not saved:
		return {"passed": false, "message": "Failed to save profile to disk", "assertions": 1}
		
	var loaded = SaveManager.load_profile(test_path)
	if loaded == null:
		return {"passed": false, "message": "Failed to load saved profile", "assertions": 2}
		
	if loaded.total_runs_played != 5 or loaded.total_victories != 2:
		return {"passed": false, "message": "Lifetime metrics mismatch", "assertions": 3}
		
	if loaded.faction_reputation.get(Enums.Faction.STREET_RUNNERS, 0) != 120:
		return {"passed": false, "message": "Faction reputation mismatch", "assertions": 4}
		
	if not loaded.unlocked_operatives.has("custom_unlock"):
		return {"passed": false, "message": "Unlocked operatives list mismatch", "assertions": 5}
		
	# Cleanup
	SaveManager.delete_active_run(test_path)
	return {"passed": true, "assertions": 5}

func test_active_run_save_and_load() -> Dictionary:
	var test_path = "user://test_active_run.json"
	var run_mgr = RunManager.new(repo)
	run_mgr.start_new_run("runner_blitz")
	run_mgr.shop_mgr.gold = 35
	run_mgr.shop_mgr.is_locked = true
	
	# Set star_level to 2 on fielded unit
	run_mgr.crew_mgr.fielded_units[0].star_level = 2
	run_mgr.crew_mgr.fielded_units[0].level = 2
	
	# Equip an augment to the fielded unit
	var aug = repo.get_augment("common_kinetic_accelerator")
	if aug:
		run_mgr.crew_mgr.fielded_units[0].equipped_augments[0] = aug
		
	# Add another augment to inventory
	var aug2 = repo.get_augment("common_thermal_core")
	if aug2:
		run_mgr.crew_mgr.augment_inventory.append(aug2)
		
	# Add a unit to bench
	var sentinel_res = repo.get_unit("corp_sentinel")
	if sentinel_res:
		var benched_unit = UnitInstance.new(sentinel_res)
		run_mgr.crew_mgr.benched_units.append(benched_unit)
		
	var saved = SaveManager.save_active_run(run_mgr, test_path)
	if not saved:
		return {"passed": false, "message": "Failed to save active run", "assertions": 1}
		
	var loaded_run = SaveManager.load_active_run(repo, test_path)
	if loaded_run == null:
		return {"passed": false, "message": "Failed to load active run", "assertions": 2}
		
	if loaded_run.current_district_index != 1 or loaded_run.current_subdistrict_index != 1:
		return {"passed": false, "message": "District / subdistrict index mismatch in loaded run", "assertions": 3}
		
	if loaded_run.shop_mgr.gold != 35:
		return {"passed": false, "message": "Gold mismatch in loaded run", "assertions": 4}
		
	if not loaded_run.shop_mgr.is_locked:
		return {"passed": false, "message": "Shop lock state not preserved", "assertions": 5}
		
	if loaded_run.crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "Fielded units count mismatch", "assertions": 6}
		
	if loaded_run.crew_mgr.benched_units.size() != 1:
		return {"passed": false, "message": "Benched units count mismatch (Expected 1, got %d)" % loaded_run.crew_mgr.benched_units.size(), "assertions": 7}
		
	var bu0 = loaded_run.crew_mgr.benched_units[0]
	if bu0.unit_resource == null or bu0.unit_resource.id != "corp_sentinel":
		return {"passed": false, "message": "Benched unit identity mismatch", "assertions": 8}
		
	var u0 = loaded_run.crew_mgr.fielded_units[0]
	if u0.star_level != 2:
		return {"passed": false, "message": "Unit star level was not preserved across save/load (Got %d, Expected 2)" % u0.star_level, "assertions": 9}
		
	if u0.grid_slot != 1 or loaded_run.crew_mgr.tactical_grid[1] != u0:
		return {"passed": false, "message": "Tactical grid slot assignment was not reconstructed properly", "assertions": 10}
		
	var equipped_aug = u0.equipped_augments[0]
	if equipped_aug == null or equipped_aug.id != "common_kinetic_accelerator":
		return {"passed": false, "message": "Equipped augment mismatch on loaded unit", "assertions": 11}
		
	if loaded_run.crew_mgr.augment_inventory.size() != 1:
		return {"passed": false, "message": "Augment inventory size mismatch in loaded run", "assertions": 12}
		
	if loaded_run.run_districts.is_empty():
		return {"passed": false, "message": "Run districts were not preserved in loaded run", "assertions": 13}
		
	# Cleanup
	SaveManager.delete_active_run(test_path)
	return {"passed": true, "assertions": 13}
