class_name TestRunManager
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_run_initialization() -> Dictionary:
	var run = RunManager.new(repo)
	run.start_new_run("runner_blitz")
	
	if not run.run_active:
		return {"passed": false, "message": "Run should be active", "assertions": 1}
	if run.current_district_index != 1:
		return {"passed": false, "message": "Run should start in District 1", "assertions": 2}
	if run.crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "Expected 1 starter unit fielded", "assertions": 3}
	if run.crew_mgr.get_max_field_units() != 2:
		return {"passed": false, "message": "District 1 crew cap should be 2", "assertions": 4}
	if run.district_nodes.is_empty():
		return {"passed": false, "message": "District nodes should be populated", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_node_traversal() -> Dictionary:
	var run = RunManager.new(repo)
	run.start_new_run("runner_blitz")
	
	var initial_gold = run.shop_mgr.gold
	var result = run.complete_encounter(true)
	
	if result.get("status", "") != "node_advanced":
		return {"passed": false, "message": "Expected node_advanced status", "assertions": 1}
	if run.current_node_index != 1:
		return {"passed": false, "message": "Expected node index 1, got %d" % run.current_node_index, "assertions": 2}
	if run.shop_mgr.gold <= initial_gold:
		return {"passed": false, "message": "Victory should grant gold income", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_district_advancement_and_crew_scaling() -> Dictionary:
	var run = RunManager.new(repo)
	run.start_new_run("runner_blitz")
	
	# Complete Subdistrict 1-1
	var total_nodes_1_1 = run.district_nodes.size()
	for i in range(total_nodes_1_1):
		run.complete_encounter(true)
		
	if run.current_district_index != 1 or run.current_subdistrict_index != 2:
		return {"passed": false, "message": "Expected Stage 1-2 after completing 1-1, got %s" % run.get_stage_string(), "assertions": 1}
		
	# Complete Subdistrict 1-2 -> Advances to District 2 (Stage 2-1)
	var total_nodes_1_2 = run.district_nodes.size()
	for i in range(total_nodes_1_2):
		run.complete_encounter(true)
		
	if run.current_district_index != 2 or run.current_subdistrict_index != 1:
		return {"passed": false, "message": "Expected Stage 2-1 after completing 1-2, got %s" % run.get_stage_string(), "assertions": 2}
	if run.crew_mgr.get_max_field_units() != 4:
		return {"passed": false, "message": "District 2 crew cap should scale to 4, got %d" % run.crew_mgr.get_max_field_units(), "assertions": 3}
		
	# Complete District 2 (2-1 and 2-2)
	for sub in range(2):
		var nodes = run.district_nodes.size()
		for i in range(nodes):
			run.complete_encounter(true)
		
	if run.current_district_index != 3 or run.current_subdistrict_index != 1:
		return {"passed": false, "message": "Expected Stage 3-1 after completing D2, got %s" % run.get_stage_string(), "assertions": 4}
	if run.crew_mgr.get_max_field_units() != 5:
		return {"passed": false, "message": "District 3 crew cap should scale to 5, got %d" % run.crew_mgr.get_max_field_units(), "assertions": 5}
		
	# Complete District 3 (3-1 and 3-2)
	for sub in range(2):
		var nodes = run.district_nodes.size()
		for i in range(nodes):
			run.complete_encounter(true)
		
	if run.current_district_index != 4 or run.current_subdistrict_index != 1:
		return {"passed": false, "message": "Expected Stage 4-1 after completing D3, got %s" % run.get_stage_string(), "assertions": 6}
	if run.crew_mgr.get_max_field_units() != 6:
		return {"passed": false, "message": "District 4 crew cap should scale to 6, got %d" % run.crew_mgr.get_max_field_units(), "assertions": 7}
		
	return {"passed": true, "assertions": 7}

func test_game_over_state() -> Dictionary:
	var run = RunManager.new(repo)
	run.start_new_run("runner_blitz")
	
	var loss_result = run.complete_encounter(false)
	if loss_result.get("status", "") != "game_over":
		return {"passed": false, "message": "Defeat on combat should trigger game_over", "assertions": 1}
	if run.run_active:
		return {"passed": false, "message": "Run should become inactive on loss", "assertions": 2}
		
	return {"passed": true, "assertions": 2}
