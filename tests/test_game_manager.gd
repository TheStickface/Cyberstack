class_name TestGameManager
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const GameManagerScript = preload("res://src/core/GameManager.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_game_manager_state_flow() -> Dictionary:
	var gm = GameManagerScript.new()
	
	if gm.current_state != 0: # GameState.TITLE
		return {"passed": false, "message": "Initial state should be TITLE (0), got %d" % gm.current_state, "assertions": 1}
		
	# Start Game -> Routes to PREP for initial crew drafting & shop
	gm.start_new_game("runner_blitz", repo)
	if gm.current_state != 2: # GameState.PREP
		return {"passed": false, "message": "State after start_new_game should be PREP (2), got %d" % gm.current_state, "assertions": 2}
	if gm.active_run_manager == null:
		return {"passed": false, "message": "active_run_manager should be initialized", "assertions": 3}
		
	# Open Map after Prep
	gm.open_map()
	if gm.current_state != 1: # GameState.MAP
		return {"passed": false, "message": "State should be MAP (1), got %d" % gm.current_state, "assertions": 4}
		
	# Start Combat
	gm.start_combat_encounter(false, repo)
	if gm.current_state != 3: # GameState.COMBAT
		return {"passed": false, "message": "State should be COMBAT (3), got %d" % gm.current_state, "assertions": 5}
	if gm.active_combat_payload.is_empty():
		return {"passed": false, "message": "active_combat_payload should be populated", "assertions": 6}
		
	# Finish Combat with Victory -> Next node is SHOP, so routes to PREP (2)
	gm.finish_combat_encounter(true, {"duration": 10.0})
	if gm.current_state != 2: # GameState.PREP (SHOP node reached)
		return {"passed": false, "message": "Victory reaching SHOP node should route to PREP (2), got %d" % gm.current_state, "assertions": 7}
		
	# Lock in / Return to Map from Shop
	gm.open_map()
	if gm.current_state != 1: # GameState.MAP
		return {"passed": false, "message": "open_map should route to MAP (1), got %d" % gm.current_state, "assertions": 8}
		
	# Complete shop node to reach next FIGHT node
	gm.active_run_manager.complete_encounter(true)
	
	# Start Combat on second FIGHT node and trigger Defeat -> should route to RUN_END
	gm.start_combat_encounter(false, repo)
	gm.finish_combat_encounter(false, {"duration": 5.0})
	if gm.current_state != 4: # GameState.RUN_END
		return {"passed": false, "message": "Defeat should route to RUN_END (4), got %d" % gm.current_state, "assertions": 8}
		
	# Return to Title
	gm.return_to_title()
	if gm.current_state != 0: # GameState.TITLE
		return {"passed": false, "message": "State should reset to TITLE (0), got %d" % gm.current_state, "assertions": 9}
		
	return {"passed": true, "assertions": 9}

func test_combat_bridge_payload() -> Dictionary:
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var synergies = SynergyReport.new()
	
	var payload = CombatBridge.package_combat_payload([blitz], synergies, 2, false, repo)
	
	if payload.get("district_id", 0) != 2:
		return {"passed": false, "message": "District ID mismatch in payload", "assertions": 1}
		
	var player_crew: Array = payload.get("player_crew", [])
	if player_crew.size() != 1:
		return {"passed": false, "message": "Player crew size mismatch in payload", "assertions": 2}
		
	var enemy_squad: Array = payload.get("enemy_squad", [])
	if enemy_squad.size() != 4: # District 2 enemy squad size is 4
		return {"passed": false, "message": "District 2 enemy squad should have 4 units, got %d" % enemy_squad.size(), "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_abandon_run_records_telemetry() -> Dictionary:
	var test_path = "user://test_abandon_telemetry.json"
	SaveManager.delete_active_run(test_path)
	
	var gm = GameManagerScript.new()
	gm.start_new_game("runner_blitz", repo)
	
	# Abandon run
	gm.abandon_run()
	
	if gm.current_state != 4: # GameState.RUN_END
		return {"passed": false, "message": "abandon_run should route to RUN_END (4), got %d" % gm.current_state, "assertions": 1}
		
	if gm.last_run_summary.is_empty() or not gm.last_run_summary.get("abandoned", false):
		return {"passed": false, "message": "last_run_summary missing abandoned flag", "assertions": 2}
		
	if not gm.last_run_summary.has("duration"):
		return {"passed": false, "message": "last_run_summary should contain measured duration", "assertions": 3}
		
	return {"passed": true, "assertions": 3}
