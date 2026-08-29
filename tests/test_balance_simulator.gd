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

func test_simulation_tactical_grid_placement() -> Dictionary:
	var crew_mgr = CrewManager.new(2, repo) # District 2 unlocks Backline Center (Slot 4)
	var sniper_res = repo.get_unit("corp_deadeye")
	var tank_res = repo.get_unit("corp_sentinel")
	
	var sniper_inst = UnitInstance.new(sniper_res)
	var tank_inst = UnitInstance.new(tank_res)
	crew_mgr.benched_units.append(sniper_inst)
	crew_mgr.benched_units.append(tank_inst)
	
	BalanceSimulatorScript._place_unit_tactically(crew_mgr, sniper_inst, 2)
	BalanceSimulatorScript._place_unit_tactically(crew_mgr, tank_inst, 2)
	
	if sniper_inst.grid_slot != 4:
		return {"passed": false, "message": "Sniper should be placed in Backline slot 4, got: %d" % sniper_inst.grid_slot, "assertions": 1}
	if tank_inst.grid_slot != 1 and tank_inst.grid_slot != 0 and tank_inst.grid_slot != 2:
		return {"passed": false, "message": "Tank should be placed in Frontline (0, 1, or 2), got: %d" % tank_inst.grid_slot, "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_simulation_synergy_stat_integration() -> Dictionary:
	var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
	var u2 = UnitInstance.new(repo.get_unit("runner_nexus"))
	var report = SynergyEngine.evaluate_crew([u1, u2], repo.factions, repo.tags)
	
	var c_without = BalanceSimulatorScript._create_combatant(u1, repo, true, 1, false, null)
	var c_with = BalanceSimulatorScript._create_combatant(u1, repo, true, 1, false, report)
	
	# Street Runner 2-piece gives +15% attack speed
	if c_with["attack_speed"] <= c_without["attack_speed"]:
		return {"passed": false, "message": "Synergy report should boost attack speed for Street Runner 2-piece", "assertions": 1}
		
	return {"passed": true, "assertions": 1}

func test_simulation_district_hazards() -> Dictionary:
	var p_comb = [{"hp": 500.0, "mana": 30.0, "healing_mult": 1.0}]
	var e_comb = [{"shield": 0.0, "has_enrage": false}]
	
	BalanceSimulatorScript._apply_district_environmental_hazards(p_comb, e_comb, 2)
	if e_comb[0]["shield"] != 120.0:
		return {"passed": false, "message": "District 2 should grant enemies 120 barrier shield", "assertions": 1}
		
	BalanceSimulatorScript._apply_district_environmental_hazards(p_comb, e_comb, 3)
	if p_comb[0]["mana"] != 15.0: # 30 - 15 = 15
		return {"passed": false, "message": "District 3 should dampen player mana by 15", "assertions": 2}
		
	BalanceSimulatorScript._apply_district_environmental_hazards(p_comb, e_comb, 4)
	if not e_comb[0]["has_enrage"]:
		return {"passed": false, "message": "District 4 should set has_enrage on enemies", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_simulation_tag_chains_and_combos() -> Dictionary:
	# Test 1: Thermal armor reduction on attack
	var attacker = {
		"hp": 500.0,
		"max_hp": 500.0,
		"shield": 0.0,
		"armor": 0.0,
		"attack_damage": 50.0,
		"attack_speed": 1.0,
		"ability_power": 30.0,
		"mana": 0.0,
		"max_mana": 100.0,
		"crit_chance": 0.0,
		"evasion": 0.0,
		"attack_timer": 0.0,
		"tags": {Enums.AugmentTag.THERMAL: 3},
		"triggers": [],
		"active_dots": []
	}
	var defender = {
		"hp": 500.0,
		"max_hp": 500.0,
		"shield": 0.0,
		"armor": 30.0,
		"evasion": 0.0,
		"mana": 0.0,
		"max_mana": 100.0,
		"triggers": [],
		"active_dots": [],
		"row": 1
	}
	
	BalanceSimulatorScript._step_combatant(attacker, [defender], [attacker], 0.1, 1)
	
	# Defender armor should have burned down from 30
	if defender["armor"] >= 30.0:
		return {"passed": false, "message": "Thermal tags should reduce target armor on attack", "assertions": 1}
		
	# Test 2: Viral tag applies DoT on spellcast
	attacker["mana"] = 100.0 # Ready to cast
	attacker["tags"] = {Enums.AugmentTag.VIRAL: 2}
	attacker["attack_timer"] = 0.0
	
	BalanceSimulatorScript._step_combatant(attacker, [defender], [attacker], 0.1, 1)
	
	if defender["active_dots"].is_empty():
		return {"passed": false, "message": "Viral tag should apply active DoT on spellcast", "assertions": 2}

	return {"passed": true, "assertions": 2}

func test_single_battle_reports_victory_margin() -> Dictionary:
	var player_templates = [
		{"unit": "runner_blitz", "augments": ["common_kinetic_accelerator"]},
		{"unit": "street_ghost", "augments": ["rare_kinetic_rail"]}
	]
	var enemy_templates = [{"unit": "runner_blitz", "augments": []}]
	var player_crew = BalanceSimulatorScript._instantiate_crew(player_templates, repo)
	var enemy_crew = BalanceSimulatorScript._instantiate_crew(enemy_templates, repo)

	var outcome = BalanceSimulatorScript.simulate_single_battle(player_crew, enemy_crew, repo)

	if not outcome.has("player_hp_frac") or not outcome.has("enemy_hp_frac"):
		return {"passed": false, "message": "Battle outcome missing hp fraction keys", "assertions": 1}
	if outcome["player_hp_frac"] < 0.0 or outcome["player_hp_frac"] > 1.0:
		return {"passed": false, "message": "player_hp_frac out of range: %f" % outcome["player_hp_frac"], "assertions": 2}
	if outcome["enemy_hp_frac"] < 0.0 or outcome["enemy_hp_frac"] > 1.0:
		return {"passed": false, "message": "enemy_hp_frac out of range: %f" % outcome["enemy_hp_frac"], "assertions": 3}
	if outcome["victory"] and outcome["enemy_hp_frac"] > 0.01:
		return {"passed": false, "message": "Victory should wipe enemy hp fraction, got %f" % outcome["enemy_hp_frac"], "assertions": 4}
	return {"passed": true, "assertions": 4}

func test_shop_purchase_returns_remaining_gold() -> Dictionary:
	var crew_mgr = CrewManager.new(3, repo)
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	crew_mgr.benched_units.append(blitz)
	BalanceSimulatorScript._place_unit_tactically(crew_mgr, blitz, 3)

	var remaining = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, 40, repo)
	if typeof(remaining) != TYPE_INT:
		return {"passed": false, "message": "Shop purchase should return remaining gold as int", "assertions": 1}
	if remaining < 0 or remaining > 40:
		return {"passed": false, "message": "Remaining gold must be within [0, 40], got %d" % remaining, "assertions": 2}
	if remaining == 40:
		return {"passed": false, "message": "Expected sim to spend gold on an empty-slot crew", "assertions": 3}
	return {"passed": true, "assertions": 3}

func test_full_run_reports_economy_and_margins() -> Dictionary:
	var result = BalanceSimulatorScript.simulate_full_run("runner_blitz", repo)

	if not result.has("gold_spent_total") or not result.has("gold_leftover"):
		return {"passed": false, "message": "Full run result missing economy keys", "assertions": 1}
	if not result.has("gold_on_hand_by_district") or typeof(result["gold_on_hand_by_district"]) != TYPE_DICTIONARY:
		return {"passed": false, "message": "Full run result missing gold_on_hand_by_district dict", "assertions": 2}
	if not result.has("battle_margins") or typeof(result["battle_margins"]) != TYPE_ARRAY:
		return {"passed": false, "message": "Full run result missing battle_margins array", "assertions": 3}
	if result["battle_margins"].is_empty():
		return {"passed": false, "message": "Every run plays at least one battle", "assertions": 4}
	var first = result["battle_margins"][0]
	if not first.has("district") or not first.has("is_boss") or not first.has("player_hp_frac"):
		return {"passed": false, "message": "battle_margins entries missing expected keys", "assertions": 5}
	if result["gold_spent_total"] < 0:
		return {"passed": false, "message": "gold_spent_total should never be negative", "assertions": 6}
	return {"passed": true, "assertions": 6}

func test_matrix_reports_conditional_clear_and_economy() -> Dictionary:
	var report_data = BalanceSimulatorScript.run_10k_full_runs_matrix(repo, 60)

	for key in ["conditional_clear", "economy", "combat_margin", "total_fights_won", "avg_fights_won"]:
		if not report_data.has(key):
			return {"passed": false, "message": "Matrix report_data missing key: %s" % key, "assertions": 1}

	var cc: Dictionary = report_data["conditional_clear"]
	if not cc.has(1) or not cc[1].has("reached") or not cc[1].has("rate"):
		return {"passed": false, "message": "conditional_clear milestones malformed", "assertions": 2}
	if cc[1]["reached"] != 60:
		return {"passed": false, "message": "All 60 runs should reach District 1, got %d" % cc[1]["reached"], "assertions": 3}
	if cc[4]["rate"] < cc[1]["rate"] - 0.001:
		return {"passed": false, "message": "Conditional clear rate should not drop as run progresses", "assertions": 4}

	var eco: Dictionary = report_data["economy"]
	if not eco.has("avg_gold_leftover") or not eco.has("avg_gold_spent"):
		return {"passed": false, "message": "economy block missing averages", "assertions": 5}
	return {"passed": true, "assertions": 5}

func test_report_includes_new_metric_sections() -> Dictionary:
	var report_data = BalanceSimulatorScript.run_10k_full_runs_matrix(repo, 60)
	var report = BalanceSimulatorScript.generate_full_runs_markdown_report(report_data)

	for heading in ["Conditional Clear Probability", "Combat Closeness", "Economy & Credit Flow"]:
		if not report.contains(heading):
			return {"passed": false, "message": "Report missing section: %s" % heading, "assertions": 1}
	return {"passed": true, "assertions": 1}


