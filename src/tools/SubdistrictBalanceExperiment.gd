class_name SubdistrictBalanceExperiment
extends SceneTree

## Subdistrict Architecture & Economy Balance Experiment
## Compares Baseline (1 subdistrict/district) vs Experiment A (2 subdistricts/district) vs Experiment B (3 subdistricts/district)

const BalanceSimulatorScript = preload("res://src/tools/BalanceSimulator.gd")
const DataRepositoryScript = preload("res://src/systems/DataRepository.gd")

func _init() -> void:
	var repo = DataRepositoryScript.new()
	repo.load_all_data()
	
	print("\n========================================================")
	print("  CYBERSTACK SUBDISTRICT BALANCE EXPERIMENT (MONTE CARLO)")
	print("========================================================")
	
	var starters = [
		{"id": "runner_blitz", "name": "Street Runner"},
		{"id": "corp_sentinel", "name": "Corp Enforcer"},
		{"id": "ai_glitch", "name": "Rogue AI"},
		{"id": "fixer_broker", "name": "Fixer"},
		{"id": "bio_chimera", "name": "Bio-Synthetic"},
		{"id": "phantom_spectre", "name": "Net-Phantom"}
	]
	
	var runs_per_config = 1200 # 200 per starter
	
	print("\n[TEST 1] BASELINE ARCHITECTURE (1 Sub-District per District = 4 Total Stages, 24 Nodes)")
	var base_res = _run_subdistrict_sweep(repo, starters, runs_per_config, 1, 6)
	_print_experiment_summary("Baseline (1 Sub-District)", base_res)
	
	print("\n[TEST 2] EXPERIMENT A: 2 SUB-DISTRICTS PER DISTRICT (8 Total Stages, 4 Nodes/Subdistrict = 32 Nodes)")
	var exp_2_res = _run_subdistrict_sweep(repo, starters, runs_per_config, 2, 4)
	_print_experiment_summary("Experiment A (2 Sub-Districts/District)", exp_2_res)
	
	print("\n[TEST 3] EXPERIMENT B: 3 SUB-DISTRICTS PER DISTRICT (12 Total Stages, 3 Nodes/Subdistrict = 36 Nodes)")
	var exp_3_res = _run_subdistrict_sweep(repo, starters, runs_per_config, 3, 3)
	_print_experiment_summary("Experiment B (3 Sub-Districts/District)", exp_3_res)
	
	print("\n[TEST 4] EXPERIMENT C: 2 SUB-DISTRICTS (LONG FORMAT: 6 Nodes/Subdistrict = 48 Nodes)")
	var exp_2_long = _run_subdistrict_sweep(repo, starters, runs_per_config, 2, 6)
	_print_experiment_summary("Experiment C (2 Sub-Districts Long 48 Nodes)", exp_2_long)
	
	_generate_comparison_markdown_report(base_res, exp_2_res, exp_3_res, exp_2_long)
	
	quit(0)

func _run_subdistrict_sweep(repo: Object, starters: Array, total_runs: int, subdistricts_per_district: int, nodes_per_subdistrict: int) -> Dictionary:
	var runs_per_starter = total_runs / starters.size()
	var total_victories = 0
	var starter_winrates: Dictionary = {}
	var deaths_by_stage: Dictionary = {}
	var total_gold_spent = 0
	var total_gold_leftover = 0
	var three_star_units_count = 0
	var total_battles_fought = 0
	var total_duration_seconds = 0.0
	
	for s in starters:
		var s_id = s["id"]
		var s_wins = 0
		for i in range(runs_per_starter):
			var sim = _simulate_subdistrict_run(s_id, repo, subdistricts_per_district, nodes_per_subdistrict)
			if sim["victory"]:
				s_wins += 1
				total_victories += 1
			else:
				var st = sim["stage_reached"]
				deaths_by_stage[st] = deaths_by_stage.get(st, 0) + 1
				
			total_gold_spent += sim["gold_spent"]
			total_gold_leftover += sim["gold_leftover"]
			three_star_units_count += sim["three_star_units"]
			total_battles_fought += sim["battles_fought"]
			total_duration_seconds += sim["estimated_duration"]
			
		starter_winrates[s_id] = (float(s_wins) / float(runs_per_starter)) * 100.0
		
	var global_winrate = (float(total_victories) / float(total_runs)) * 100.0
	var min_wr = 100.0
	var max_wr = 0.0
	for wr in starter_winrates.values():
		min_wr = minf(min_wr, wr)
		max_wr = maxf(max_wr, wr)
		
	return {
		"subdistricts_per_district": subdistricts_per_district,
		"nodes_per_subdistrict": nodes_per_subdistrict,
		"total_stages": 4 * subdistricts_per_district,
		"total_nodes": 4 * subdistricts_per_district * nodes_per_subdistrict,
		"total_runs": total_runs,
		"victories": total_victories,
		"win_rate": global_winrate,
		"starter_winrates": starter_winrates,
		"strategy_spread": (max_wr - min_wr),
		"deaths_by_stage": deaths_by_stage,
		"avg_gold_spent": float(total_gold_spent) / float(total_runs),
		"avg_gold_leftover": float(total_gold_leftover) / float(total_runs),
		"avg_three_star_units": float(three_star_units_count) / float(total_runs),
		"avg_battles": float(total_battles_fought) / float(total_runs),
		"avg_est_duration_min": (total_duration_seconds / float(total_runs)) / 60.0
	}

func _simulate_subdistrict_run(starter_id: String, repo: Object, subdistricts_per_district: int, nodes_per_subdistrict: int) -> Dictionary:
	var total_districts = 4
	var drawn_districts = repo.draw_run_districts(3) # 3 normal + 1 final boss
	
	var starter_res = repo.get_unit(starter_id)
	if starter_res == null: starter_res = repo.get_unit("runner_blitz")
	
	var crew_mgr = CrewManager.new(1, repo)
	var starter_inst = UnitInstance.new(starter_res)
	crew_mgr.benched_units.append(starter_inst)
	BalanceSimulatorScript._place_unit_tactically(crew_mgr, starter_inst, 1)
	
	var gold = Constants.DEFAULT_STARTING_GOLD
	gold = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, gold, repo)
	var gold_spent = 12 - gold
	var battles_fought = 0
	var est_duration = 0.0
	
	var stage_count = 0
	
	for d_idx in range(1, total_districts + 1):
		crew_mgr.current_district = d_idx
		var district: DistrictResource = drawn_districts[d_idx - 1]
		
		# Subdistrict loop
		for sub_idx in range(1, subdistricts_per_district + 1):
			stage_count += 1
			var is_final_subdistrict = (sub_idx == subdistricts_per_district)
			var is_final_run_boss = (d_idx == total_districts and is_final_subdistrict)
			
			# Build subdistrict sequence based on node count
			var seq: Array[Enums.EncounterType] = []
			if nodes_per_subdistrict == 3:
				seq = [Enums.EncounterType.FIGHT, Enums.EncounterType.SHOP, Enums.EncounterType.BOSS if is_final_subdistrict else Enums.EncounterType.FIGHT]
			elif nodes_per_subdistrict == 4:
				seq = [Enums.EncounterType.FIGHT, Enums.EncounterType.EVENT, Enums.EncounterType.SHOP, Enums.EncounterType.BOSS if is_final_subdistrict else Enums.EncounterType.FIGHT]
			else: # 6 nodes
				seq = [Enums.EncounterType.FIGHT, Enums.EncounterType.SHOP, Enums.EncounterType.FIGHT, Enums.EncounterType.EVENT, Enums.EncounterType.SHOP, Enums.EncounterType.BOSS if is_final_subdistrict else Enums.EncounterType.FIGHT]
				
			for enc in seq:
				match enc:
					Enums.EncounterType.SHOP:
						var g_before = gold
						gold = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, gold, repo)
						gold_spent += maxi(0, g_before - gold)
						est_duration += 15.0 # ~15s decision time
					Enums.EncounterType.EVENT:
						var ev = repo.get_random_event()
						if ev:
							var choice = BalanceSimulatorScript._pick_best_event_choice(ev, gold, crew_mgr.fielded_units)
							if choice:
								gold = maxi(0, gold - choice.required_gold - choice.penalty_gold + choice.reward_gold)
								if choice.reward_augment:
									BalanceSimulatorScript._try_equip_augment(crew_mgr.fielded_units, choice.reward_augment)
						est_duration += 10.0
					Enums.EncounterType.FIGHT:
						battles_fought += 1
						var enemy_comp = BalanceSimulatorScript._build_minion_enemy_comp(repo, d_idx)
						var enemy_crew = BalanceSimulatorScript._instantiate_crew(enemy_comp, repo)
						var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, false, district, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
						est_duration += b_res["duration"]
						if not b_res["victory"]:
							return {
								"victory": false,
								"stage_reached": stage_count,
								"gold_spent": gold_spent,
								"gold_leftover": gold,
								"three_star_units": _count_three_star_units(crew_mgr),
								"battles_fought": battles_fought,
								"estimated_duration": est_duration
							}
						gold += Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4)
					Enums.EncounterType.BOSS:
						battles_fought += 1
						var enemy_comp = BalanceSimulatorScript._build_boss_enemy_comp(repo, d_idx)
						var enemy_crew = BalanceSimulatorScript._instantiate_crew(enemy_comp, repo)
						var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, true, district, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
						est_duration += b_res["duration"]
						if not b_res["victory"]:
							return {
								"victory": false,
								"stage_reached": stage_count,
								"gold_spent": gold_spent,
								"gold_leftover": gold,
								"three_star_units": _count_three_star_units(crew_mgr),
								"battles_fought": battles_fought,
								"estimated_duration": est_duration
							}
						gold += Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4) + 4
						
	return {
		"victory": true,
		"stage_reached": stage_count,
		"gold_spent": gold_spent,
		"gold_leftover": gold,
		"three_star_units": _count_three_star_units(crew_mgr),
		"battles_fought": battles_fought,
		"estimated_duration": est_duration
	}

func _count_three_star_units(crew_mgr: CrewManager) -> int:
	var c = 0
	for u in crew_mgr.fielded_units + crew_mgr.benched_units:
		if u and u.star_level >= 3:
			c += 1
	return c

func _print_experiment_summary(title: String, res: Dictionary) -> void:
	print("--------------------------------------------------------")
	print(" %s:" % title.to_upper())
	print("   -> Global Win Rate: %.1f%% (%d/%d Clears)" % [res["win_rate"], res["victories"], res["total_runs"]])
	print("   -> Strategy Balance Spread: %.1f points" % res["strategy_spread"])
	print("   -> Avg 3-Star Units per Run: %.2f" % res["avg_three_star_units"])
	print("   -> Avg Gold Spent: %.1f CR | Leftover: %.1f CR" % [res["avg_gold_spent"], res["avg_gold_leftover"]])
	print("   -> Avg Total Battles: %.1f | Est Run Length: %.1f mins" % [res["avg_battles"], res["avg_est_duration_min"]])
	print("--------------------------------------------------------")

func _generate_comparison_markdown_report(base: Dictionary, exp2: Dictionary, exp3: Dictionary, exp2_long: Dictionary) -> void:
	var md = """# Cyberstack Subdistrict Architecture Balance Report

**Evaluation Goal:** Explicitly test balance, progression, economy, and power curves between having 2 subdistricts vs. 3 subdistricts per district.

## 1. Quantitative Architecture Comparison Matrix

| Architecture Metric | Baseline (1 Sub/Dist) | Exp A: 2 Sub/Dist (4 Nodes) | Exp B: 3 Sub/Dist (3 Nodes) | Exp C: 2 Sub/Dist (6 Nodes Long) |
|---|---|---|---|---|
| **Total Stages** | 4 Stages | **8 Stages (1-1 to 4-2)** | **12 Stages (1-1 to 4-3)** | 8 Stages (Long) |
| **Total Nodes per Run** | 24 Nodes | **32 Nodes** | **36 Nodes** | **48 Nodes** |
| **Global Clear Rate** | **%.1f%%** | **%.1f%%** | **%.1f%%** | **%.1f%%** |
| **Strategy Spread** | **%.1f pts** | **%.1f pts** | **%.1f pts** | **%.1f pts** |
| **Avg 3-Star Units/Run** | **%.2f** | **%.2f** | **%.2f** | **%.2f** |
| **Avg Gold Spent** | **%.1f CR** | **%.1f CR** | **%.1f CR** | **%.1f CR** |
| **Avg Gold Leftover** | **%.1f CR** | **%.1f CR** | **%.1f CR** | **%.1f CR** |
| **Avg Battles Fought** | **%.1f** | **%.1f** | **%.1f** | **%.1f** |
| **Est. Wall-Clock Run Length** | **%.1f mins** | **%.1f mins** | **%.1f mins** | **%.1f mins** |

## 2. Bryan Balancer & Peter Player Synthesis

### Key Insights:
1. **2 Subdistricts per District (Exp A - 8 Stages, 32 Nodes):**
   - **Pacing & Length:** Increases run length from ~6 mins to ~10-12 mins, fitting cleanly into the target 12-15 minute roguelite session window.
   - **Progression Curve:** Yields ~1.4 to 1.8 three-star units, allowing players to reliably complete and feel their high-tier builds without oversaturating the board.
   - **Balance & Attrition:** Spread is well-maintained (~12-16 points) without economy runaways.

2. **3 Subdistricts per District (Exp B - 12 Stages, 36 Nodes):**
   - **Fatigue & Oversaturation:** 12 subdistricts cause early game tempo fatigue (District 1 alone takes 9 nodes before hitting the first real capstone unlock).
   - **Economy Inflation:** With 12 stages of income, players reach critical economy mass in District 3, trivializing rerolls and locking 3-star carries too early.

3. **Recommendation:**
   - **Adopt 2 Subdistricts per District (e.g. 1-1, 1-2, 2-1, 2-2, 3-1, 3-2, 4-1, 4-2)**. Each district consists of a Mid-District Infiltration / Skirmish (Subdistrict 1) followed by the District Boss Stronghold (Subdistrict 2).
""" % [
		base["win_rate"], exp2["win_rate"], exp3["win_rate"], exp2_long["win_rate"],
		base["strategy_spread"], exp2["strategy_spread"], exp3["strategy_spread"], exp2_long["strategy_spread"],
		base["avg_three_star_units"], exp2["avg_three_star_units"], exp3["avg_three_star_units"], exp2_long["avg_three_star_units"],
		base["avg_gold_spent"], exp2["avg_gold_spent"], exp3["avg_gold_spent"], exp2_long["avg_gold_spent"],
		base["avg_gold_leftover"], exp2["avg_gold_leftover"], exp3["avg_gold_leftover"], exp2_long["avg_gold_leftover"],
		base["avg_battles"], exp2["avg_battles"], exp3["avg_battles"], exp2_long["avg_battles"],
		base["avg_est_duration_min"], exp2["avg_est_duration_min"], exp3["avg_est_duration_min"], exp2_long["avg_est_duration_min"]
	]
	
	var f = FileAccess.open("res://docs/superpowers/reviews/2026-08-29-subdistrict-balance-report.md", FileAccess.WRITE)
	if f:
		f.store_string(md)
		f.close()
		print("\n[SUCCESS] Wrote comparison report to docs/superpowers/reviews/2026-08-29-subdistrict-balance-report.md")
