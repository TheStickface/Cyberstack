class_name TestBalanceSimulator
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const BalanceSimulatorScript = preload("res://src/tools/BalanceSimulator.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_single_battle_resolution() -> Dictionary:
	var player_templates = [
		{"unit": "runner_blitz", "augments": ["common_kinetic_accelerator"]},
		{"unit": "street_ghost", "augments": ["rare_kinetic_rail"]}
	]
	var enemy_templates = [
		{"unit": "runner_blitz", "augments": []}
	]
	
	var player_crew = BalanceSimulatorScript._instantiate_crew(player_templates, repo)
	var enemy_crew = BalanceSimulatorScript._instantiate_crew(enemy_templates, repo)
	
	var outcome = BalanceSimulatorScript.simulate_single_battle(player_crew, enemy_crew, repo)
	
	if not outcome.has("victory") or not outcome.has("duration") or not outcome.has("survivors"):
		return {"passed": false, "message": "Outcome dictionary missing expected keys", "assertions": 1}
	if outcome["duration"] <= 0.0:
		return {"passed": false, "message": "Battle duration should be > 0", "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_full_run_simulation() -> Dictionary:
	var result = BalanceSimulatorScript.simulate_full_run("runner_blitz", repo)
	
	if not result.has("victory") or not result.has("district_reached"):
		return {"passed": false, "message": "Full run result missing victory or district_reached", "assertions": 1}
	if result["district_reached"] < 1 or result["district_reached"] > 4:
		return {"passed": false, "message": "Invalid district reached: %d" % result["district_reached"], "assertions": 2}
	if not result.has("events_encountered") or not result.has("role_checks_passed"):
		return {"passed": false, "message": "Missing event metrics in full run result", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_report_generation() -> Dictionary:
	var mock_report_data = {
		"total_runs": 10,
		"total_victories": 8,
		"global_win_rate": 80.0,
		"starter_stats": [
			{
				"id": "runner_blitz",
				"name": "Street Runner (Blitz)",
				"runs": 10,
				"wins": 8,
				"win_rate": 80.0,
				"avg_events": 3.0,
				"role_check_rate": 66.7,
				"avg_event_gold": 12.0,
				"avg_event_augs": 1.2
			}
		],
		"deaths_by_district": {1: 0, 2: 1, 3: 1, 4: 0},
		"total_events_encountered": 30,
		"total_role_checks_passed": 20,
		"global_role_check_rate": 66.7,
		"avg_event_gold": 12.0,
		"avg_event_augs": 1.2
	}
	
	var report = BalanceSimulatorScript.generate_full_runs_markdown_report(mock_report_data)
	if not report.contains("Street Runner (Blitz)") or not report.contains("80.0%"):
		return {"passed": false, "message": "Report generation missing expected starter strings", "assertions": 1}
		
	return {"passed": true, "assertions": 1}
