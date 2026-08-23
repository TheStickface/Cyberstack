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
	
	# Equip an augment to the fielded unit
	var aug = repo.get_augment("common_kinetic_accelerator")
	if aug:
		run_mgr.crew_mgr.fielded_units[0].equipped_augments[0] = aug
		
	# Add another augment to inventory
	var aug2 = repo.get_augment("common_thermal_core")
	if aug2:
		run_mgr.crew_mgr.augment_inventory.append(aug2)
		
	var saved = SaveManager.save_active_run(run_mgr, test_path)
	if not saved:
		return {"passed": false, "message": "Failed to save active run", "assertions": 1}
		
	var loaded_run = SaveManager.load_active_run(repo, test_path)
	if loaded_run == null:
		return {"passed": false, "message": "Failed to load active run", "assertions": 2}
		
	if loaded_run.current_district_index != 1:
		return {"passed": false, "message": "District index mismatch in loaded run", "assertions": 3}
		
	if loaded_run.shop_mgr.gold != 35:
		return {"passed": false, "message": "Gold mismatch in loaded run", "assertions": 4}
		
	if loaded_run.crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "Fielded units count mismatch", "assertions": 5}
		
	var equipped_aug = loaded_run.crew_mgr.fielded_units[0].equipped_augments[0]
	if equipped_aug == null or equipped_aug.id != "common_kinetic_accelerator":
		return {"passed": false, "message": "Equipped augment mismatch on loaded unit", "assertions": 6}
		
	if loaded_run.crew_mgr.augment_inventory.size() != 1:
		return {"passed": false, "message": "Augment inventory size mismatch in loaded run", "assertions": 7}
		
	# Cleanup
	SaveManager.delete_active_run(test_path)
	return {"passed": true, "assertions": 7}
