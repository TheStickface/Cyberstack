class_name TestDebugConsole
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const GameManagerScript = preload("res://src/core/GameManager.gd")

var repo: Object
var console: DebugConsole

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	console = DebugConsole.new(repo)

func test_help_and_unknown_commands() -> Dictionary:
	var help_res = console.execute_command("/help")
	if not help_res.success or not help_res.message.contains("AVAILABLE DEBUG COMMANDS"):
		return {"passed": false, "message": "/help command failed", "assertions": 1}
		
	var unknown_res = console.execute_command("/invalid_command_xyz")
	if unknown_res.success or not unknown_res.message.contains("Unknown command"):
		return {"passed": false, "message": "Unknown command should fail with error message", "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_gold_and_district_commands() -> Dictionary:
	var gm = GameManagerScript.new()
	gm.start_new_game("runner_blitz", repo)
	
	# Test /gold command
	var initial_gold = gm.active_run_manager.shop_mgr.gold
	var gold_res = console.execute_command("/gold 30", gm)
	if not gold_res.success:
		return {"passed": false, "message": "/gold command execution failed: %s" % gold_res.message, "assertions": 1}
	if gm.active_run_manager.shop_mgr.gold != (initial_gold + 30):
		return {"passed": false, "message": "Gold mismatch after /gold command", "assertions": 2}
		
	# Test /district command
	var dist_res = console.execute_command("/district 3", gm)
	if not dist_res.success:
		return {"passed": false, "message": "/district command execution failed: %s" % dist_res.message, "assertions": 3}
	if gm.active_run_manager.current_district_index != 3:
		return {"passed": false, "message": "District mismatch after /district command", "assertions": 4}
	if gm.active_run_manager.crew_mgr.get_max_field_units() != 5:
		return {"passed": false, "message": "Crew cap should scale to 5 in District 3", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_spawn_and_grant_commands() -> Dictionary:
	var gm = GameManagerScript.new()
	gm.start_new_game("runner_blitz", repo)
	
	# Test /spawn command
	var spawn_res = console.execute_command("/spawn ai_glitch", gm)
	if not spawn_res.success:
		return {"passed": false, "message": "/spawn command failed: %s" % spawn_res.message, "assertions": 1}
	if gm.active_run_manager.crew_mgr.benched_units.is_empty():
		return {"passed": false, "message": "Spawned unit should be on bench", "assertions": 2}
		
	# Test /grant command
	var grant_res = console.execute_command("/grant common_kinetic_accelerator", gm)
	if not grant_res.success:
		return {"passed": false, "message": "/grant command failed: %s" % grant_res.message, "assertions": 3}
	if gm.active_run_manager.crew_mgr.augment_inventory.is_empty():
		return {"passed": false, "message": "Granted augment should be in inventory", "assertions": 4}
		
	return {"passed": true, "assertions": 4}

func test_loadout_and_fight_commands() -> Dictionary:
	var gm = GameManagerScript.new()
	gm.start_new_game("runner_blitz", repo)
	
	# Test /loadout command
	var loadout_res = console.execute_command("/loadout runner", gm)
	if not loadout_res.success:
		return {"passed": false, "message": "/loadout runner failed: %s" % loadout_res.message, "assertions": 1}
	if gm.active_run_manager.crew_mgr.fielded_units.size() != 4:
		return {"passed": false, "message": "Loadout should populate 4 fielded units, got %d" % gm.active_run_manager.crew_mgr.fielded_units.size(), "assertions": 2}
		
	# Test /fight command
	var fight_res = console.execute_command("/fight boss 2", gm)
	if not fight_res.success:
		return {"passed": false, "message": "/fight boss 2 failed: %s" % fight_res.message, "assertions": 3}
	if gm.current_state != GameManagerScript.GameState.COMBAT:
		return {"passed": false, "message": "State should be COMBAT after /fight, got %d" % gm.current_state, "assertions": 4}
		
	return {"passed": true, "assertions": 4}

