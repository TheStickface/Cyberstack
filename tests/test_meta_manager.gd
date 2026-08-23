class_name TestMetaManager
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_reputation_level_thresholds() -> Dictionary:
	if MetaManager.get_faction_level(0) != 1:
		return {"passed": false, "message": "0 pts should be Level 1", "assertions": 1}
	if MetaManager.get_faction_level(99) != 1:
		return {"passed": false, "message": "99 pts should be Level 1", "assertions": 2}
	if MetaManager.get_faction_level(100) != 2:
		return {"passed": false, "message": "100 pts should be Level 2", "assertions": 3}
	if MetaManager.get_faction_level(249) != 2:
		return {"passed": false, "message": "249 pts should be Level 2", "assertions": 4}
	if MetaManager.get_faction_level(250) != 3:
		return {"passed": false, "message": "250 pts should be Level 3", "assertions": 5}
	if MetaManager.get_faction_level(500) != 4:
		return {"passed": false, "message": "500 pts should be Level 4", "assertions": 6}
		
	return {"passed": true, "assertions": 6}

func test_run_end_meta_processing_and_unlocks() -> Dictionary:
	var profile = MetaProfile.new()
	profile.unlocked_operatives.clear() # Start blank
	profile.faction_reputation[Enums.Faction.STREET_RUNNERS] = 50
	
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz")) # Street Runners
	var aug = repo.get_augment("common_kinetic_accelerator")
	blitz.equipped_augments[0] = aug
	
	var summary = {
		"victory": true,
		"district": 2,
		"fights_won": 4,
		"bosses_defeated": 1,
		"gold_earned": 40
	}
	
	# Base rep = (2 * 25) + (4 * 10) + (1 * 50) + 100 = 50 + 40 + 50 + 100 = 240 pts
	var result = MetaManager.process_run_end(profile, summary, [blitz])
	
	if profile.total_runs_played != 1 or profile.total_victories != 1:
		return {"passed": false, "message": "Run counts not incremented properly", "assertions": 1}
		
	var street_rep = profile.faction_reputation.get(Enums.Faction.STREET_RUNNERS, 0)
	if street_rep != 290: # 50 initial + 240 earned
		return {"passed": false, "message": "Expected 290 Street Runner rep, got %d" % street_rep, "assertions": 2}
		
	# Level 2 crossing should unlock street_ghost
	if not profile.unlocked_operatives.has("street_ghost"):
		return {"passed": false, "message": "Level 2 unlock street_ghost missing from profile", "assertions": 3}
		
	# Discovered augments should include common_kinetic_accelerator
	if not profile.discovered_augments.has("common_kinetic_accelerator"):
		return {"passed": false, "message": "Equipped augment missing from codex discoveries", "assertions": 4}
		
	return {"passed": true, "assertions": 4}
