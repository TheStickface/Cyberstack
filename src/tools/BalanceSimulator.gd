class_name BalanceSimulator
extends SceneTree

## Automated Monte Carlo Balance Simulator for Cyberstack
## Simulates thousands of full 4-district roguelite playthroughs including combat, shopping, and narrative events

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func _init() -> void:
	var total_runs = _parse_runs_from_args(10000)
	
	print("========================================================")
	print("    CYBERSTACK MONTE CARLO BALANCE SIMULATOR (%d RUNS)  " % total_runs)
	print("========================================================\n")
	
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var report_data = run_10k_full_runs_matrix(repo, total_runs)
	
	var md_report = generate_full_runs_markdown_report(report_data)
	var output_path = "res://data/balance_simulation_report.md"
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(md_report)
		file.close()
		print("\n[SUCCESS] Exported %d full-run simulation report to %s\n" % [total_runs, output_path])
		quit(0)
	else:
		printerr("\n[ERROR] Failed to save simulation report to %s\n" % output_path)
		quit(1)

func _parse_runs_from_args(default_runs: int = 10000) -> int:
	var all_args: Array[String] = []
	all_args.append_array(OS.get_cmdline_user_args())
	all_args.append_array(OS.get_cmdline_args())
	
	for i in range(all_args.size()):
		var arg = all_args[i]
		if arg.begins_with("--runs="):
			var val = arg.substr(7).to_int()
			if val > 0:
				return val
		elif arg.begins_with("-runs="):
			var val = arg.substr(6).to_int()
			if val > 0:
				return val
		elif arg.begins_with("-n="):
			var val = arg.substr(3).to_int()
			if val > 0:
				return val
		elif arg == "--runs" or arg == "-runs" or arg == "-n" or arg == "--n":
			if i + 1 < all_args.size():
				var val = all_args[i + 1].to_int()
				if val > 0:
					return val
	return default_runs

static func run_10k_full_runs_matrix(repo: Object, total_runs: int = 10000) -> Dictionary:
	var starters = [
		{"id": "runner_blitz", "name": "Street Runner (Blitz)"},
		{"id": "corp_sentinel", "name": "Corp Enforcer (Sentinel-09)"},
		{"id": "ai_glitch", "name": "Rogue AI (GLITCH.exe)"},
		{"id": "fixer_broker", "name": "Fixer (Madame Vane)"}
	]
	
	var runs_per_starter = total_runs / starters.size()
	var starter_stats: Array[Dictionary] = []
	
	var total_victories = 0
	var deaths_by_district = {1: 0, 2: 0, 3: 0, 4: 0}
	var total_events_encountered = 0
	var total_role_checks_passed = 0
	var total_event_gold_earned = 0
	var total_event_augments_gained = 0
	
	for s in starters:
		print(">> Simulating %d Full Runs with Starter: %s..." % [runs_per_starter, s["name"]])
		var wins = 0
		var s_events = 0
		var s_role_checks = 0
		var s_event_gold = 0
		var s_event_augs = 0
		
		for i in range(runs_per_starter):
			var result = simulate_full_run(s["id"], repo)
			if result["victory"]:
				wins += 1
				total_victories += 1
			else:
				var d = clampi(result["district_reached"], 1, 4)
				deaths_by_district[d] = deaths_by_district.get(d, 0) + 1
				
			s_events += result["events_encountered"]
			s_role_checks += result["role_checks_passed"]
			s_event_gold += result["event_gold_earned"]
			s_event_augs += result["event_augments_gained"]
			
			total_events_encountered += result["events_encountered"]
			total_role_checks_passed += result["role_checks_passed"]
			total_event_gold_earned += result["event_gold_earned"]
			total_event_augments_gained += result["event_augments_gained"]
			
		var win_rate = (float(wins) / float(runs_per_starter)) * 100.0
		var role_check_rate = (float(s_role_checks) / float(maxi(1, s_events))) * 100.0
		
		starter_stats.append({
			"id": s["id"],
			"name": s["name"],
			"runs": runs_per_starter,
			"wins": wins,
			"win_rate": win_rate,
			"avg_events": float(s_events) / float(runs_per_starter),
			"role_check_rate": role_check_rate,
			"avg_event_gold": float(s_event_gold) / float(runs_per_starter),
			"avg_event_augs": float(s_event_augs) / float(runs_per_starter)
		})
		
		print("   -> Win Rate: %.1f%% (%d/%d) | Role Checks: %.1f%% | Avg Event Gold: +%.1fg" % [
			win_rate,
			wins,
			runs_per_starter,
			role_check_rate,
			float(s_event_gold) / float(runs_per_starter)
		])
		
	return {
		"total_runs": total_runs,
		"total_victories": total_victories,
		"global_win_rate": (float(total_victories) / float(total_runs)) * 100.0,
		"starter_stats": starter_stats,
		"deaths_by_district": deaths_by_district,
		"total_events_encountered": total_events_encountered,
		"total_role_checks_passed": total_role_checks_passed,
		"global_role_check_rate": (float(total_role_checks_passed) / float(maxi(1, total_events_encountered))) * 100.0,
		"avg_event_gold": float(total_event_gold_earned) / float(total_runs),
		"avg_event_augs": float(total_event_augments_gained) / float(total_runs)
	}

static func simulate_full_run(starter_id: String, repo: Object) -> Dictionary:
	var drawn_districts = repo.draw_run_districts(3) # 3 normal + 1 final boss = 4 districts
	var starter_unit_res = repo.get_unit(starter_id)
	if starter_unit_res == null:
		starter_unit_res = repo.get_unit("runner_blitz")
		
	var crew: Array[UnitInstance] = [UnitInstance.new(starter_unit_res)]
	var gold = Constants.DEFAULT_STARTING_GOLD
	
	var events_encountered = 0
	var role_checks_passed = 0
	var event_gold_earned = 0
	var event_augments_gained = 0
	var fights_won = 0
	
	# Initial Shop / Prep Phase before First Fight
	_simulate_shop_purchase(crew, gold, Constants.DISTRICT_CREW_LIMITS.get(1, 2), repo)
	
	for d_idx in range(1, drawn_districts.size() + 1):
		var district: DistrictResource = drawn_districts[d_idx - 1]
		var crew_cap = Constants.DISTRICT_CREW_LIMITS.get(d_idx, 2)
		
		# Prep Phase at start of each district
		if d_idx > 1:
			_simulate_shop_purchase(crew, gold, crew_cap, repo)
			
		for enc_type in district.node_sequence:
			match enc_type:
				Enums.EncounterType.FIGHT:
					var enemy_comp_templates = _build_minion_enemy_comp(repo, d_idx)
					var enemy_crew = _instantiate_crew(enemy_comp_templates, repo)
					
					var battle_res = simulate_single_battle(crew, enemy_crew, repo, d_idx, false)
					if not battle_res["victory"]:
						return {
							"victory": false,
							"district_reached": d_idx,
							"fights_won": fights_won,
							"events_encountered": events_encountered,
							"role_checks_passed": role_checks_passed,
							"event_gold_earned": event_gold_earned,
							"event_augments_gained": event_augments_gained
						}
					
					fights_won += 1
					var payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4)
					gold += payout
					
				Enums.EncounterType.BOSS:
					var enemy_comp_templates = _build_boss_enemy_comp(repo, d_idx)
					var enemy_crew = _instantiate_crew(enemy_comp_templates, repo)
					
					var battle_res = simulate_single_battle(crew, enemy_crew, repo, d_idx, true)
					if not battle_res["victory"]:
						return {
							"victory": false,
							"district_reached": d_idx,
							"fights_won": fights_won,
							"events_encountered": events_encountered,
							"role_checks_passed": role_checks_passed,
							"event_gold_earned": event_gold_earned,
							"event_augments_gained": event_augments_gained
						}
					
					fights_won += 1
					var payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4) + 4
					gold += payout
					
				Enums.EncounterType.EVENT:
					events_encountered += 1
					var ev_res = repo.get_random_event()
					if ev_res:
						var best_choice = _pick_best_event_choice(ev_res, gold, crew)
						if best_choice:
							if best_choice.required_role != Enums.UnitRole.ANY or best_choice.required_faction != Enums.Faction.NONE:
								role_checks_passed += 1
								
							gold = maxi(0, gold - best_choice.required_gold - best_choice.penalty_gold + best_choice.reward_gold)
							event_gold_earned += best_choice.reward_gold
							
							if best_choice.reward_augment != null:
								event_augments_gained += 1
								_try_equip_augment(crew, best_choice.reward_augment)
								
				Enums.EncounterType.SHOP:
					_simulate_shop_purchase(crew, gold, crew_cap, repo)
										
	# Completed all 4 districts
	return {
		"victory": true,
		"district_reached": 4,
		"fights_won": fights_won,
		"events_encountered": events_encountered,
		"role_checks_passed": role_checks_passed,
		"event_gold_earned": event_gold_earned,
		"event_augments_gained": event_augments_gained
	}

static func _simulate_shop_purchase(crew: Array[UnitInstance], gold: int, crew_cap: int, repo: Object) -> void:
	# 1. Star Level Combinations / Duplicate Purchases
	for u in crew:
		if u.star_level < 3 and gold >= u.unit_resource.base_cost:
			if randf() < 0.35: # Chance player finds duplicate copy in shop
				gold -= u.unit_resource.base_cost
				u.star_level = min(3, u.star_level + 1)
				
	# 2. Recruit new units if crew cap allows
	if crew.size() < crew_cap and gold >= 3:
		var unfielded = _get_unfielded_units(crew, repo)
		if not unfielded.is_empty():
			var recruit_unit: UnitResource = unfielded[randi() % unfielded.size()]
			if gold >= recruit_unit.base_cost:
				gold -= recruit_unit.base_cost
				crew.append(UnitInstance.new(recruit_unit))
				
	# 3. Buy augments for open slots
	var all_augs = repo.get_all_augments()
	for u in crew:
		for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
			if u.equipped_augments[s_idx] == null and gold >= 2:
				for aug in all_augs:
					if aug.base_cost <= gold and u.can_equip_augment(s_idx, aug):
						gold -= aug.base_cost
						u.equip_augment(s_idx, aug)
						break

static func _pick_best_event_choice(ev_res: NarrativeEventResource, gold: int, crew: Array[UnitInstance]) -> EventChoiceResource:
	var available = ev_res.get_available_choices(gold, crew)
	if available.is_empty():
		return null
		
	# Prioritize role or faction checks first (highest value payoffs)
	for c in available:
		if c.required_role != Enums.UnitRole.ANY or c.required_faction != Enums.Faction.NONE:
			return c
			
	# Else pick augment rewards
	for c in available:
		if c.reward_augment != null and gold >= c.required_gold:
			return c
			
	# Else pick highest gold reward
	var best = available[0]
	for c in available:
		if c.reward_gold > best.reward_gold and gold >= c.required_gold:
			best = c
	return best

static func _try_equip_augment(crew: Array[UnitInstance], aug: AugmentResource) -> bool:
	if aug == null:
		return false
	for u in crew:
		for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
			if u.equipped_augments[s_idx] == null and u.can_equip_augment(s_idx, aug):
				u.equip_augment(s_idx, aug)
				return true
	return false

static func _get_unfielded_units(crew: Array[UnitInstance], repo: Object) -> Array[UnitResource]:
	var fielded_ids: Dictionary = {}
	for u in crew:
		if u and u.unit_resource:
			fielded_ids[u.unit_resource.id] = true
			
	var result: Array[UnitResource] = []
	for u in repo.get_all_units():
		if not fielded_ids.has(u.id):
			result.append(u)
	return result

static func simulate_single_battle(
	player_crew: Array[UnitInstance],
	enemy_crew: Array[UnitInstance],
	repo: Object,
	district_index: int = 1,
	is_boss: bool = false
) -> Dictionary:
	var player_combatants: Array[Dictionary] = []
	for u in player_crew:
		player_combatants.append(_create_combatant(u, repo, true, district_index, false))
		
	var enemy_combatants: Array[Dictionary] = []
	for u in enemy_crew:
		enemy_combatants.append(_create_combatant(u, repo, false, district_index, is_boss))
		
	var time = 0.0
	var dt = 0.1
	var max_time = 60.0
	
	while time < max_time:
		time += dt
		
		# Step player combatants
		for c in player_combatants:
			if c["hp"] > 0:
				_step_combatant(c, enemy_combatants, dt)
				
		# Step enemy combatants
		for c in enemy_combatants:
			if c["hp"] > 0:
				_step_combatant(c, player_combatants, dt)
				
		# Check victory
		var living_enemies = 0
		for c in enemy_combatants:
			if c["hp"] > 0:
				living_enemies += 1
				
		var living_players = 0
		for c in player_combatants:
			if c["hp"] > 0:
				living_players += 1
				
		if living_enemies == 0:
			return {"victory": true, "duration": time, "survivors": living_players}
		if living_players == 0:
			return {"victory": false, "duration": time, "survivors": 0}
			
	# Timeout
	var survivors = 0
	for c in player_combatants:
		if c["hp"] > 0:
			survivors += 1
	return {"victory": false, "duration": max_time, "survivors": survivors}

static func _step_combatant(c: Dictionary, opponents: Array[Dictionary], dt: float) -> void:
	c["attack_timer"] -= dt
	if c["attack_timer"] <= 0.0:
		c["attack_timer"] = 1.0 / maxf(0.2, c["attack_speed"])
		
		var target: Dictionary = {}
		for opp in opponents:
			if opp["hp"] > 0:
				target = opp
				break
				
		if target.is_empty():
			return
			
		if randf() < target["evasion"]:
			return
			
		var is_crit = randf() < c["crit_chance"]
		var damage = c["attack_damage"] * (1.5 if is_crit else 1.0)
		
		var damage_mult = 100.0 / (100.0 + target["armor"])
		var final_damage = damage * damage_mult
		
		_apply_damage(target, final_damage)
		
		c["mana"] = minf(c["max_mana"], c["mana"] + 10.0)
		target["mana"] = minf(target["max_mana"], target["mana"] + 5.0)
		
		if c["mana"] >= c["max_mana"] and c["max_mana"] > 0:
			c["mana"] = 0.0
			var spell_dmg = c["ability_power"] * damage_mult
			_apply_damage(target, spell_dmg)

static func _apply_damage(target: Dictionary, dmg: float) -> void:
	if target["shield"] > 0.0:
		if target["shield"] >= dmg:
			target["shield"] -= dmg
			return
		else:
			dmg -= target["shield"]
			target["shield"] = 0.0
	target["hp"] = maxf(0.0, target["hp"] - dmg)

static func _create_combatant(unit: UnitInstance, repo: Object, is_player: bool, district_index: int = 1, is_boss: bool = false) -> Dictionary:
	var hp = unit.calculate_effective_stat(Enums.StatType.MAX_HEALTH)
	var shield = unit.calculate_effective_stat(Enums.StatType.SHIELD)
	var armor = unit.calculate_effective_stat(Enums.StatType.ARMOR)
	var ad = unit.calculate_effective_stat(Enums.StatType.ATTACK_DAMAGE)
	var aspeed = unit.calculate_effective_stat(Enums.StatType.ATTACK_SPEED)
	var ap = unit.calculate_effective_stat(Enums.StatType.ABILITY_POWER)
	var mana = unit.calculate_effective_stat(Enums.StatType.STARTING_MANA)
	var max_mana = unit.calculate_effective_stat(Enums.StatType.MAX_MANA)
	var crit = unit.calculate_effective_stat(Enums.StatType.CRIT_CHANCE)
	var evasion = unit.calculate_effective_stat(Enums.StatType.EVASION)
	
	if not is_player:
		var scaling = Constants.DISTRICT_ENEMY_SCALING.get(district_index, {"hp_mult": 1.0, "dmg_mult": 1.0})
		hp *= scaling.get("hp_mult", 1.0)
		ad *= scaling.get("dmg_mult", 1.0)
		ap *= scaling.get("dmg_mult", 1.0)
		if is_boss:
			hp *= 1.15
			ad *= 1.10
	
	return {
		"id": unit.unit_resource.id if unit.unit_resource else "unit",
		"is_player": is_player,
		"hp": hp,
		"max_hp": hp,
		"shield": shield,
		"armor": armor,
		"attack_damage": ad,
		"attack_speed": maxf(0.2, aspeed),
		"ability_power": ap,
		"mana": mana,
		"max_mana": max_mana,
		"crit_chance": crit,
		"evasion": evasion,
		"attack_timer": randf_range(0.05, 0.3)
	}

static func _build_minion_enemy_comp(repo: Object, district_index: int) -> Array:
	match district_index:
		1:
			return [
				{"unit": "runner_dash", "augments": []},
				{"unit": "corp_patrol", "augments": []}
			]
		2:
			return [
				{"unit": "corp_sentinel", "augments": ["common_kinetic_accelerator"]},
				{"unit": "runner_slasher", "augments": []},
				{"unit": "corp_auditor", "augments": []}
			]
		3:
			return [
				{"unit": "ai_bastion", "augments": ["rare_thermal_exhaust"]},
				{"unit": "ai_cipher", "augments": ["rare_neural_synapse"]},
				{"unit": "runner_nexus", "augments": ["rare_neural_synapse"]},
				{"unit": "fixer_chemist", "augments": ["rare_viral_siphon"]}
			]
		4:
			return [
				{"unit": "corp_breacher", "augments": ["rare_thermal_exhaust"]},
				{"unit": "corp_deadeye", "augments": ["rare_kinetic_rail"]},
				{"unit": "ai_dreadnought", "augments": ["rare_neural_daemon"]},
				{"unit": "fixer_hitman", "augments": ["rare_viral_cascade"]}
			]
		_:
			return [{"unit": "runner_dash", "augments": []}]

static func _build_boss_enemy_comp(repo: Object, district_index: int) -> Array:
	match district_index:
		1:
			return [
				{"unit": "runner_blitz", "augments": []},
				{"unit": "runner_dash", "augments": ["common_kinetic_accelerator"]}
			]
		2:
			return [
				{"unit": "corp_sentinel", "augments": ["rare_thermal_exhaust"]},
				{"unit": "street_ghost", "augments": ["rare_kinetic_rail"]},
				{"unit": "runner_dash", "augments": ["common_kinetic_accelerator"]}
			]
		3:
			return [
				{"unit": "ai_null_construct", "augments": ["rare_thermal_exhaust"]},
				{"unit": "ai_cipher", "augments": ["rare_neural_synapse"]},
				{"unit": "corp_commander", "augments": ["rare_thermal_exhaust"]},
				{"unit": "fixer_wiretap", "augments": ["rare_viral_siphon"]}
			]
		4:
			return [
				{"unit": "fixer_kingpin", "augments": ["legendary_viral_pandemic", "rare_thermal_exhaust"]},
				{"unit": "corp_apex", "augments": ["legendary_kinetic_destroyer"]},
				{"unit": "ai_glitch", "augments": ["rare_neural_hive"]},
				{"unit": "corp_sentinel", "augments": ["rare_thermal_exhaust"]}
			]
		_:
			return [{"unit": "runner_blitz", "augments": []}]

static func _instantiate_crew(templates: Array, repo: Object) -> Array[UnitInstance]:
	var result: Array[UnitInstance] = []
	for t in templates:
		var u_res: UnitResource = repo.get_unit(t["unit"])
		if u_res:
			var inst = UnitInstance.new(u_res)
			for a_id in t.get("augments", []):
				var a_res: AugmentResource = repo.get_augment(a_id)
				if a_res:
					for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
						if inst.can_equip_augment(s_idx, a_res):
							inst.equip_augment(s_idx, a_res)
							break
			result.append(inst)
	return result

static func generate_full_runs_markdown_report(report_data: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# Cyberstack — %d Full-Run Monte Carlo Simulation Report" % report_data["total_runs"])
	lines.append("**Generated Date:** %s | **Total Complete Runs Simulated:** %d" % [
		Time.get_date_string_from_system(),
		report_data["total_runs"]
	])
	lines.append("")
	lines.append("---")
	lines.append("")
	
	# 1. Global Overview
	lines.append("## 1. Global Roguelite Run Performance")
	lines.append("- **Global 4-District Run Clear Rate:** **%.1f%%** (%d Victories / %d Runs)" % [
		report_data["global_win_rate"],
		report_data["total_victories"],
		report_data["total_runs"]
	])
	lines.append("- **Total Events Encountered:** %d (Avg %.1f per run)" % [
		report_data["total_events_encountered"],
		float(report_data["total_events_encountered"]) / float(report_data["total_runs"])
	])
	lines.append("- **Role-Check Activation Rate:** **%.1f%%** (%d special checks passed)" % [
		report_data["global_role_check_rate"],
		report_data["total_role_checks_passed"]
	])
	lines.append("- **Average Bonus Event Gold Earned:** +%.1f credits/run" % report_data["avg_event_gold"])
	lines.append("- **Average Bonus Event Augments Gained:** +%.2f augments/run" % report_data["avg_event_augs"])
	lines.append("")
	
	# 2. Starter Archetype Comparison
	lines.append("## 2. Starter Operative Clear Rates & Event Synergies")
	lines.append("| Starter Operative | Runs Simulated | Victories | Clear Rate | Role-Check Success | Avg Event Gold |")
	lines.append("|---|---|---|---|---|---|")
	for s in report_data["starter_stats"]:
		lines.append("| **%s** | %d | %d | **%.1f%%** | %.1f%% | +%.1f credits |" % [
			s["name"],
			s["runs"],
			s["wins"],
			s["win_rate"],
			s["role_check_rate"],
			s["avg_event_gold"]
		])
	lines.append("")
	
	# 3. Mortality Distribution
	var deaths: Dictionary = report_data["deaths_by_district"]
	var total_runs = float(report_data["total_runs"])
	lines.append("## 3. District Mortality Hotspot Distribution")
	lines.append("| District | Player Eliminations | % of Total Runs |")
	lines.append("|---|---|---|")
	lines.append("| District 1 (Slum Market) | %d | %.1f%% |" % [deaths.get(1, 0), (float(deaths.get(1, 0)) / total_runs) * 100.0])
	lines.append("| District 2 (Corp Arcology) | %d | %.1f%% |" % [deaths.get(2, 0), (float(deaths.get(2, 0)) / total_runs) * 100.0])
	lines.append("| District 3 (Server Vault) | %d | %.1f%% |" % [deaths.get(3, 0), (float(deaths.get(3, 0)) / total_runs) * 100.0])
	lines.append("| District 4 (Black Site Boss) | %d | %.1f%% |" % [deaths.get(4, 0), (float(deaths.get(4, 0)) / total_runs) * 100.0])
	lines.append("| **RUN VICTORY (Secured)** | **%d** | **%.1f%%** |" % [report_data["total_victories"], report_data["global_win_rate"]])
	lines.append("")
	
	return "\n".join(lines)
