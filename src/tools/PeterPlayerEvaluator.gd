class_name PeterPlayerEvaluator
extends SceneTree

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const BalanceSimulatorScript = preload("res://src/tools/BalanceSimulator.gd")

func _init() -> void:
	print("========================================================")
	print("       PETER PLAYER ENDGAME EVALUATION SUITE            ")
	print("========================================================\n")
	
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	run_evaluation(repo)
	quit(0)

func run_evaluation(repo: Object) -> void:
	print(">> 1. Running Highroll Delta & TTK Analysis on D4 Boss vs D1 Minion...")
	var d1_ttks: Array[float] = []
	var d4_ttks: Array[float] = []
	var d4_survivors: Array[int] = []
	var d4_boss_margins: Array[float] = []
	
	var N = 1000
	var comp_signatures: Dictionary = {}
	var top_decile_signatures: Dictionary = {}
	var runs_data: Array[Dictionary] = []
	
	var starters = ["runner_blitz", "corp_sentinel", "ai_glitch", "fixer_broker", "bio_chimera", "phantom_spectre"]
	var starter_end_comps: Dictionary = {
		"runner_blitz": {},
		"corp_sentinel": {},
		"ai_glitch": {},
		"fixer_broker": {},
		"bio_chimera": {},
		"phantom_spectre": {}
	}
	
	for i in range(N):
		var starter_id = starters[i % starters.size()]
		var starter_res = repo.get_unit(starter_id)
		var crew_mgr = CrewManager.new(1, repo)
		var starter_inst = UnitInstance.new(starter_res)
		crew_mgr.benched_units.append(starter_inst)
		BalanceSimulatorScript._place_unit_tactically(crew_mgr, starter_inst, 1)
		
		var gold = Constants.DEFAULT_STARTING_GOLD
		var drawn_districts = repo.draw_run_districts(3)
		gold = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, gold, repo)
		
		var run_won = true
		var d4_boss_res = {}
		var d1_minion_time = 0.0
		
		for d_idx in range(1, drawn_districts.size() + 1):
			crew_mgr.current_district = d_idx
			var district: DistrictResource = drawn_districts[d_idx - 1]
			if d_idx > 1:
				gold = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, gold, repo)
				
			for sub_idx in range(1, Constants.SUBDISTRICTS_PER_DISTRICT + 1):
				var seq = district.get_subdistrict_sequence(sub_idx)
				for enc_type in seq:
					match enc_type:
						Enums.EncounterType.FIGHT:
							var enemy_comp_templates = BalanceSimulatorScript._build_minion_enemy_comp(repo, d_idx)
							var enemy_crew = BalanceSimulatorScript._instantiate_crew(enemy_comp_templates, repo)
							var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, false, district)
							if d_idx == 1 and d1_minion_time == 0.0:
								d1_minion_time = b_res["duration"]
							if not b_res["victory"]:
								run_won = false
								break
							gold += Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4)
						Enums.EncounterType.BOSS:
							var enemy_comp_templates = BalanceSimulatorScript._build_boss_enemy_comp(repo, d_idx)
							var enemy_crew = BalanceSimulatorScript._instantiate_crew(enemy_comp_templates, repo)
							var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, true, district)
							if d_idx == 4 and sub_idx == Constants.SUBDISTRICTS_PER_DISTRICT:
								d4_boss_res = b_res
							if not b_res["victory"]:
								run_won = false
								break
							gold += Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4) + 4
						Enums.EncounterType.EVENT:
							var ev_res = repo.get_random_event()
							if ev_res:
								var choice = BalanceSimulatorScript._pick_best_event_choice(ev_res, gold, crew_mgr.fielded_units)
								if choice:
									gold = maxi(0, gold - choice.required_gold - choice.penalty_gold + choice.reward_gold)
									if choice.reward_augment:
										BalanceSimulatorScript._try_equip_augment(crew_mgr.fielded_units, choice.reward_augment)
						Enums.EncounterType.SHOP:
							gold = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, gold, repo)
					if not run_won:
						break
				if not run_won:
					break
			if not run_won:
				break
				
		if d1_minion_time > 0.0:
			d1_ttks.append(d1_minion_time)
			
		if run_won and not d4_boss_res.is_empty():
			var ttk = d4_boss_res.get("duration", 60.0)
			var surv = d4_boss_res.get("survivors", 0)
			d4_ttks.append(ttk)
			d4_survivors.append(surv)
			
			var unit_names: Array[String] = []
			for u in crew_mgr.fielded_units:
				if u and u.unit_resource:
					unit_names.append(u.unit_resource.id)
			unit_names.sort()
			var sig = "+".join(unit_names)
			comp_signatures[sig] = comp_signatures.get(sig, 0) + 1
			starter_end_comps[starter_id][sig] = starter_end_comps[starter_id].get(sig, 0) + 1
			
			runs_data.append({
				"starter": starter_id,
				"ttk": ttk,
				"survivors": surv,
				"sig": sig,
				"crew": crew_mgr.fielded_units
			})

	d1_ttks.sort()
	d4_ttks.sort()
	runs_data.sort_custom(func(a, b): return a["ttk"] < b["ttk"])
	
	var d1_median = d1_ttks[int(d1_ttks.size() * 0.50)] if not d1_ttks.is_empty() else 0.0
	var d4_p50 = d4_ttks[int(d4_ttks.size() * 0.50)] if not d4_ttks.is_empty() else 0.0
	var d4_p95 = d4_ttks[int(d4_ttks.size() * 0.05)] if not d4_ttks.is_empty() else 0.0 # fastest 5%
	var d4_p05 = d4_ttks[int(d4_ttks.size() * 0.95)] if not d4_ttks.is_empty() else 0.0 # slowest 5%
	
	print("   -> D1 Minion Median TTK: %.2fs" % d1_median)
	print("   -> D4 Boss P50 TTK: %.2fs | P95 TTK: %.2fs | Highroll Delta: %.2fs" % [d4_p50, d4_p95, (d4_p50 - d4_p95)])
	print("   -> Combat Pacing Gap (D1 Minion vs D4 Boss): D1=%.2fs vs D4=%.2fs (Ratio: %.2fx)" % [d1_median, d4_p50, (d4_p50 / maxf(0.1, d1_median))])
	
	var top_10_count = int(runs_data.size() * 0.10)
	for idx in range(top_10_count):
		var sig = runs_data[idx]["sig"]
		top_decile_signatures[sig] = top_decile_signatures.get(sig, 0) + 1
		
	print("   -> Distinct End Builds in All Clears: %d" % comp_signatures.keys().size())
	print("   -> Distinct End Builds in Top 10%% Clears: %d" % top_decile_signatures.keys().size())
	
	print("\n>> 2. Starter End-Game Composition Divergence:")
	for s_id in starters:
		var distinct = starter_end_comps[s_id].keys().size()
		print("   -> Starter %s: %d distinct final comps" % [s_id, distinct])

	print("\n>> 3. Running Personas...")
	_run_personas(repo)

func _run_personas(repo: Object) -> void:
	_eval_forcer(repo)
	_eval_bio_mutators(repo)
	_eval_phantom_assassins(repo)
	_eval_meatshield_bruisers(repo)
	_eval_flexer(repo)
	_eval_econ_merchant(repo)
	_eval_highroll_hunter(repo)
	_eval_placement_surgeon(repo)
	_eval_tourist(repo)
	_eval_degenerate(repo)

func _deploy_units_directly(crew_mgr: CrewManager, units: Array[UnitInstance], slots: Array[int]) -> void:
	for i in range(units.size()):
		var u = units[i]
		var s = slots[i]
		crew_mgr.tactical_grid[s] = u
		u.grid_slot = s
	crew_mgr._sync_fielded_units()
	crew_mgr.recalculate_synergies()

func _eval_forcer(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("ai_glitch"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("ai_null_construct"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("ai_cipher"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("ai_bastion"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("ai_singularity"))
		u5.star_level = 2
		
		var aug1 = repo.get_augment("common_neural_link")
		if aug1: u1.equip_augment(0, aug1)
		var aug2 = repo.get_augment("rare_neural_daemon")
		if aug2: u1.equip_augment(1, aug2)
		var aug3 = repo.get_augment("rare_neural_synapse")
		if aug3: u3.equip_augment(0, aug3)
		var aug4 = repo.get_augment("legendary_neural_hive")
		if aug4: u5.equip_augment(0, aug4)
		
		_deploy_units_directly(crew_mgr, [u4, u2, u1, u3, u5], [0, 1, 3, 4, 5])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 4, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Forcer (Mono Rogue AI): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])

func _eval_bio_mutators(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("bio_gorgon"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("bio_chimera"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("bio_hydra"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("bio_fleshweaver"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("bio_manticore"))
		u5.star_level = 2
		
		var a1 = repo.get_augment("common_viral_spores")
		if a1: u1.equip_augment(0, a1)
		var a2 = repo.get_augment("rare_viral_cascade")
		if a2: u4.equip_augment(0, a2)
		var a3 = repo.get_augment("rare_viral_siphon")
		if a3: u5.equip_augment(0, a3)
		var a4 = repo.get_augment("legendary_viral_pandemic")
		if a4: u3.equip_augment(0, a4)
		
		_deploy_units_directly(crew_mgr, [u1, u2, u3, u4, u5], [0, 1, 2, 3, 4])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 4, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Bio Mutator (Bio-Synthetics 4 / Viral): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])

func _eval_phantom_assassins(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("phantom_bulwark"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("phantom_aegis"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("phantom_nightshade"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("phantom_assassin"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("phantom_spectre"))
		u5.star_level = 2
		
		var a1 = repo.get_augment("rare_kinetic_overdrive")
		if a1: u1.equip_augment(0, a1)
		var a2 = repo.get_augment("rare_kinetic_rail")
		if a2: u5.equip_augment(0, a2)
		var a3 = repo.get_augment("legendary_kinetic_destroyer")
		if a3: u3.equip_augment(0, a3)
		
		_deploy_units_directly(crew_mgr, [u1, u2, u3, u4, u5], [0, 1, 3, 4, 5])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 4, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Phantom Assassin (Net-Phantoms 4 / Ambush Crit): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])

func _eval_meatshield_bruisers(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("bio_chimera"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("phantom_nightshade"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("bio_hydra"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("phantom_aegis"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("bio_fleshweaver"))
		u5.star_level = 2
		
		var a1 = repo.get_augment("common_kinetic_plating")
		if a1: u1.equip_augment(0, a1)
		var a2 = repo.get_augment("rare_thermal_exhaust")
		if a2: u4.equip_augment(0, a2)
		var a3 = repo.get_augment("legendary_thermal_supernova")
		if a3: u2.equip_augment(0, a3)
		
		_deploy_units_directly(crew_mgr, [u1, u3, u2, u4, u5], [0, 1, 2, 3, 4])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 4, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Meatshield Bruiser (Frontline Meatshield & Commander Dive): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])

func _eval_flexer(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("corp_apex"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("corp_commander"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("fixer_bruiser"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("runner_dash"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("runner_blitz"))
		u5.star_level = 2
		
		var a1 = repo.get_augment("common_kinetic_accelerator")
		if a1: u1.equip_augment(0, a1)
		var a2 = repo.get_augment("common_thermal_blaster")
		if a2: u2.equip_augment(0, a2)
		var a3 = repo.get_augment("common_viral_nanites")
		if a3: u4.equip_augment(0, a3)
		var a4 = repo.get_augment("common_kinetic_plating")
		if a4: u5.equip_augment(0, a4)
		
		_deploy_units_directly(crew_mgr, [u3, u5, u2, u1, u4], [1, 0, 2, 4, 3])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 4, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Flexer (Good-Stuff Rainbow): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])

func _eval_econ_merchant(repo: Object) -> void:
	var wins = 0
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(2, repo)
		var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
		u1.star_level = 1
		_deploy_units_directly(crew_mgr, [u1], [1])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 2), repo)
		var d = repo.get_district("district_2_corp_arcology")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 2, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
	print("[PERSONA] The Econ Merchant (Greed/Hoard into D2 Boss): D2 Boss Survival=%.1f%%" % [(float(wins)/float(N))*100.0])

func _eval_highroll_hunter(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var crew_mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("street_ghost"))
		u1.star_level = 3
		var u2 = UnitInstance.new(repo.get_unit("runner_blitz"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("runner_dash"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("corp_apex"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("corp_sentinel"))
		u5.star_level = 2
		
		var leg = repo.get_augment("legendary_kinetic_destroyer")
		if leg: u1.equip_augment(0, leg)
		var r1 = repo.get_augment("rare_kinetic_rail")
		if r1: u1.equip_augment(1, r1)
		var r2 = repo.get_augment("rare_kinetic_overdrive")
		if r2: u2.equip_augment(0, r2)
		var leg2 = repo.get_augment("legendary_thermal_supernova")
		if leg2: u4.equip_augment(0, leg2)
		var p1 = repo.get_augment("common_kinetic_plating")
		if p1: u5.equip_augment(0, p1)
		
		_deploy_units_directly(crew_mgr, [u2, u5, u1, u3, u4], [1, 0, 4, 3, 5])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, 4, true, d, crew_mgr.tactical_grid, crew_mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Highroll Hunter (Double Legendary Kinetic/Thermal): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])

func _eval_placement_surgeon(repo: Object) -> void:
	var opt_wins = 0
	var inv_wins = 0
	var N = 200
	for i in range(N):
		var u_tank = UnitInstance.new(repo.get_unit("corp_sentinel"))
		u_tank.star_level = 2
		var u_sniper = UnitInstance.new(repo.get_unit("corp_apex"))
		u_sniper.star_level = 2
		var u_hacker = UnitInstance.new(repo.get_unit("fixer_wiretap"))
		u_hacker.star_level = 2
		var u_tank2 = UnitInstance.new(repo.get_unit("runner_blitz"))
		u_tank2.star_level = 2
		
		var mgr1 = CrewManager.new(3, repo)
		_deploy_units_directly(mgr1, [u_tank, u_tank2, u_sniper, u_hacker], [1, 0, 4, 3])
		
		var enemy_crew1 = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 3), repo)
		var d = repo.get_district("district_3_server_vault")
		var res1 = BalanceSimulatorScript.simulate_single_battle(mgr1.fielded_units, enemy_crew1, repo, 3, true, d, mgr1.tactical_grid, mgr1.active_synergy_report)
		if res1["victory"]: opt_wins += 1
		
		var mgr2 = CrewManager.new(3, repo)
		var u_t1 = UnitInstance.new(repo.get_unit("corp_sentinel"))
		u_t1.star_level = 2
		var u_s1 = UnitInstance.new(repo.get_unit("corp_apex"))
		u_s1.star_level = 2
		var u_h1 = UnitInstance.new(repo.get_unit("fixer_wiretap"))
		u_h1.star_level = 2
		var u_t2 = UnitInstance.new(repo.get_unit("runner_blitz"))
		u_t2.star_level = 2
		_deploy_units_directly(mgr2, [u_s1, u_h1, u_t1, u_t2], [1, 0, 4, 3])
		
		var enemy_crew2 = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 3), repo)
		var res2 = BalanceSimulatorScript.simulate_single_battle(mgr2.fielded_units, enemy_crew2, repo, 3, true, d, mgr2.tactical_grid, mgr2.active_synergy_report)
		if res2["victory"]: inv_wins += 1
		
	print("[PERSONA] The Placement Surgeon: Optimal Grid D3 Boss=%.1f%% vs Inverted Grid D3 Boss=%.1f%% (Placement Delta: %.1f%%)" % [
		(float(opt_wins)/float(N))*100.0,
		(float(inv_wins)/float(N))*100.0,
		(float(opt_wins - inv_wins)/float(N))*100.0
	])

func _eval_tourist(repo: Object) -> void:
	var wins = 0
	var N = 200
	for i in range(N):
		var mgr = CrewManager.new(3, repo)
		var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("corp_sentinel"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("ai_null_construct"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("fixer_bruiser"))
		u4.star_level = 2
		_deploy_units_directly(mgr, [u1, u2, u3, u4], [0, 1, 2, 4])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 3), repo)
		var d = repo.get_district("district_3_server_vault")
		var res = BalanceSimulatorScript.simulate_single_battle(mgr.fielded_units, enemy_crew, repo, 3, true, d, mgr.tactical_grid, mgr.active_synergy_report)
		if res["victory"]: wins += 1
	print("[PERSONA] The Tourist (4 Tanks, Zero Synergy): D3 Boss Winrate=%.1f%%" % [(float(wins)/float(N))*100.0])

func _eval_degenerate(repo: Object) -> void:
	var wins = 0
	var ttks: Array[float] = []
	var survivors_list: Array[int] = []
	var N = 200
	for i in range(N):
		var mgr = CrewManager.new(4, repo)
		var u1 = UnitInstance.new(repo.get_unit("ai_glitch"))
		u1.star_level = 2
		var u2 = UnitInstance.new(repo.get_unit("ai_cipher"))
		u2.star_level = 2
		var u3 = UnitInstance.new(repo.get_unit("ai_null_construct"))
		u3.star_level = 2
		var u4 = UnitInstance.new(repo.get_unit("runner_dash"))
		u4.star_level = 2
		var u5 = UnitInstance.new(repo.get_unit("street_ghost"))
		u5.star_level = 2
		
		var hive = repo.get_augment("legendary_neural_hive")
		if hive: u1.equip_augment(0, hive)
		var syn = repo.get_augment("rare_neural_synapse")
		if syn: u1.equip_augment(1, syn)
		var d_aug = repo.get_augment("rare_neural_daemon")
		if d_aug: u2.equip_augment(0, d_aug)
		var d_aug2 = repo.get_augment("rare_neural_daemon")
		if d_aug2: u4.equip_augment(0, d_aug2)
		
		_deploy_units_directly(mgr, [u3, u1, u2, u4, u5], [1, 4, 3, 5, 0])
		
		var enemy_crew = BalanceSimulatorScript._instantiate_crew(BalanceSimulatorScript._build_boss_enemy_comp(repo, 4), repo)
		var d = repo.get_district("district_4_black_site")
		var b_res = BalanceSimulatorScript.simulate_single_battle(mgr.fielded_units, enemy_crew, repo, 4, true, d, mgr.tactical_grid, mgr.active_synergy_report)
		if b_res["victory"]:
			wins += 1
			ttks.append(b_res["duration"])
			survivors_list.append(b_res["survivors"])
	ttks.sort()
	var p50 = ttks[int(ttks.size() * 0.5)] if not ttks.is_empty() else 60.0
	var p95 = ttks[int(ttks.size() * 0.05)] if not ttks.is_empty() else 60.0
	var avg_surv = 0.0
	for s in survivors_list: avg_surv += s
	if not survivors_list.is_empty(): avg_surv /= survivors_list.size()
	print("[PERSONA] The Degenerate (Infinite AI Mana Loop): Clear=%.1f%% | P50 TTK=%.2fs | P95 TTK=%.2fs | Avg Survivors=%.1f/5" % [(float(wins)/float(N))*100.0, p50, p95, avg_surv])
