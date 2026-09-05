class_name BalanceSimulator
extends SceneTree

## Automated Monte Carlo Balance Simulator for Cyberstack
## Simulates thousands of full 4-district roguelite playthroughs including combat, shopping, and narrative events

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const CombatEngineScript = preload("res://src/systems/CombatEngine.gd")

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
		{"id": "fixer_broker", "name": "Fixer (Madame Vane)"},
		{"id": "bio_chimera", "name": "Bio-Synthetic (Bio-Chimera)"},
		{"id": "phantom_spectre", "name": "Net-Phantom (Phantom Spectre)"}
	]
	
	var runs_per_starter = total_runs / starters.size()
	var starter_stats: Array[Dictionary] = []
	
	var total_victories = 0
	var deaths_by_district = {1: 0, 2: 0, 3: 0, 4: 0}
	var total_events_encountered = 0
	var total_role_checks_passed = 0
	var total_event_gold_earned = 0
	var total_event_augments_gained = 0
	var total_fights_won = 0

	# Conditional clear: runs that reached (started) each district.
	var reached_district = {1: 0, 2: 0, 3: 0, 4: 0}

	# Economy / credit flow.
	var sum_gold_spent = 0
	var sum_gold_leftover = 0
	var idle_wealth_runs = 0  # runs ending with > 20 unspent credits
	var goh_sum = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
	var goh_count = {1: 0, 2: 0, 3: 0, 4: 0}

	# Combat closeness / victory margin (won battles only).
	var margin_hp_sum = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
	var margin_hp_count = {1: 0, 2: 0, 3: 0, 4: 0}
	var stomp_count = {1: 0, 2: 0, 3: 0, 4: 0}   # won with >= 80% crew HP
	var nail_count = {1: 0, 2: 0, 3: 0, 4: 0}    # won with <= 15% crew HP
	var boss_hp_sum = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
	var boss_hp_count = {1: 0, 2: 0, 3: 0, 4: 0}

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

			for dr in range(1, clampi(result["district_reached"], 1, 4) + 1):
				reached_district[dr] += 1

			total_fights_won += result["fights_won"]

			sum_gold_spent += result["gold_spent_total"]
			sum_gold_leftover += result["gold_leftover"]
			if result["gold_leftover"] > 20:
				idle_wealth_runs += 1
			for k in result["gold_on_hand_by_district"]:
				goh_sum[k] += float(result["gold_on_hand_by_district"][k])
				goh_count[k] += 1

			for m in result["battle_margins"]:
				if not m["victory"]:
					continue
				var md = clampi(m["district"], 1, 4)
				var frac: float = m["player_hp_frac"]
				margin_hp_sum[md] += frac
				margin_hp_count[md] += 1
				if frac >= 0.80:
					stomp_count[md] += 1
				if frac <= 0.15:
					nail_count[md] += 1
				if m["is_boss"]:
					boss_hp_sum[md] += frac
					boss_hp_count[md] += 1

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
		
	var conditional_clear: Dictionary = {}
	for d in [1, 2, 3, 4]:
		conditional_clear[d] = {
			"reached": reached_district[d],
			"clears": total_victories,
			"rate": (float(total_victories) / float(maxi(1, reached_district[d]))) * 100.0
		}

	var avg_goh: Dictionary = {}
	for d in [1, 2, 3, 4]:
		avg_goh[d] = goh_sum[d] / float(maxi(1, goh_count[d]))

	var combat_margin: Dictionary = {}
	for d in [1, 2, 3, 4]:
		combat_margin[d] = {
			"avg_win_hp_frac": margin_hp_sum[d] / float(maxi(1, margin_hp_count[d])),
			"stomp_pct": (float(stomp_count[d]) / float(maxi(1, margin_hp_count[d]))) * 100.0,
			"nail_pct": (float(nail_count[d]) / float(maxi(1, margin_hp_count[d]))) * 100.0,
			"boss_avg_hp_frac": boss_hp_sum[d] / float(maxi(1, boss_hp_count[d])),
			"wins_sampled": margin_hp_count[d]
		}

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
		"avg_event_augs": float(total_event_augments_gained) / float(total_runs),
		"total_fights_won": total_fights_won,
		"avg_fights_won": float(total_fights_won) / float(total_runs),
		"conditional_clear": conditional_clear,
		"economy": {
			"avg_gold_spent": float(sum_gold_spent) / float(total_runs),
			"avg_gold_leftover": float(sum_gold_leftover) / float(total_runs),
			"idle_wealth_pct": (float(idle_wealth_runs) / float(total_runs)) * 100.0,
			"avg_gold_on_hand": avg_goh
		},
		"combat_margin": combat_margin
	}

static func simulate_full_run(starter_id: String, repo: Object, strategy: Dictionary = {}) -> Dictionary:
	var drawn_districts = repo.draw_run_districts(3) # 3 normal + 1 final boss = 4 districts
	var starter_unit_res = repo.get_unit(starter_id)
	if starter_unit_res == null:
		starter_unit_res = repo.get_unit("runner_blitz")
		
	var crew_mgr = CrewManager.new(1, repo)
	var starter_inst = UnitInstance.new(starter_unit_res)
	crew_mgr.benched_units.append(starter_inst)
	_place_unit_tactically(crew_mgr, starter_inst, 1)
	
	var gold = Constants.DEFAULT_STARTING_GOLD

	# Accumulators live in a Dictionary (reference type) so the _finish_run helper
	# always sees current values — a lambda closure would freeze the ints at 0.
	var R := {
		"fights_won": 0,
		"events_encountered": 0,
		"role_checks_passed": 0,
		"event_gold_earned": 0,
		"event_augments_gained": 0,
		"gold_spent_total": 0,
		"gold_on_hand_by_district": {},
		"battle_margins": []
	}

	# Initial Shop / Prep Phase before First Fight
	R["gold_on_hand_by_district"][1] = gold
	var _g0 = gold
	gold = _simulate_shop_purchase(crew_mgr, gold, repo, strategy)
	R["gold_spent_total"] += _g0 - gold

	for d_idx in range(1, drawn_districts.size() + 1):
		crew_mgr.current_district = d_idx
		var district: DistrictResource = drawn_districts[d_idx - 1]

		# Prep Phase at start of each district
		if d_idx > 1:
			var slot_to_unlock = 4 if d_idx == 2 else (3 if d_idx == 3 else 5)
			var doctrine = _pick_best_doctrine_for_crew(crew_mgr, slot_to_unlock)
			crew_mgr.unlock_slot(slot_to_unlock, doctrine)

			R["gold_on_hand_by_district"][d_idx] = gold
			var _g1 = gold
			gold = _simulate_shop_purchase(crew_mgr, gold, repo, strategy)
			R["gold_spent_total"] += _g1 - gold

		for sub_idx in range(1, Constants.SUBDISTRICTS_PER_DISTRICT + 1):
			var seq = district.get_subdistrict_sequence(sub_idx)
			for enc_type in seq:
				match enc_type:
					Enums.EncounterType.FIGHT:
						var enemy_comp_templates = _build_minion_enemy_comp(repo, d_idx)
						var enemy_crew = _instantiate_crew(enemy_comp_templates, repo)

						var form_bonuses = crew_mgr.calculate_formation_bonuses()
						var battle_res = simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, false, district, crew_mgr.tactical_grid, crew_mgr.active_synergy_report, form_bonuses)
						R["battle_margins"].append(_margin_entry(battle_res, d_idx, false))
						if not battle_res["victory"]:
							return _finish_run(R, false, d_idx, gold)

						crew_mgr.tick_conduit_durations()
						R["fights_won"] += 1
						var payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4)
						gold += payout

					Enums.EncounterType.BOSS:
						var enemy_comp_templates = _build_boss_enemy_comp(repo, d_idx)
						var enemy_crew = _instantiate_crew(enemy_comp_templates, repo)

						var form_bonuses = crew_mgr.calculate_formation_bonuses()
						var battle_res = simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, true, district, crew_mgr.tactical_grid, crew_mgr.active_synergy_report, form_bonuses)
						R["battle_margins"].append(_margin_entry(battle_res, d_idx, true))
						if not battle_res["victory"]:
							return _finish_run(R, false, d_idx, gold)

						crew_mgr.tick_conduit_durations()
						R["fights_won"] += 1
						var payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4) + 4
						gold += payout

					Enums.EncounterType.EVENT:
						R["events_encountered"] += 1
						var ev_res = repo.get_random_event()
						if ev_res:
							var best_choice = _pick_best_event_choice(ev_res, gold, crew_mgr.fielded_units)
							if best_choice:
								if best_choice.required_role != Enums.UnitRole.ANY or best_choice.required_faction != Enums.Faction.NONE:
									R["role_checks_passed"] += 1

								gold = maxi(0, gold - best_choice.required_gold - best_choice.penalty_gold + best_choice.reward_gold)
								R["event_gold_earned"] += best_choice.reward_gold

								if best_choice.reward_augment != null:
									R["event_augments_gained"] += 1
									_try_equip_augment(crew_mgr.fielded_units, best_choice.reward_augment)

					Enums.EncounterType.SHOP:
						var _g2 = gold
						gold = _simulate_shop_purchase(crew_mgr, gold, repo, strategy)
						R["gold_spent_total"] += _g2 - gold

	# Completed all 4 districts
	return _finish_run(R, true, 4, gold)

## Stamps run outcome onto the accumulator dict and returns it. Kept separate from
## simulate_full_run so the early-exit paths and the success path share one shape.
static func _finish_run(R: Dictionary, victory: bool, district_reached: int, gold_left: int) -> Dictionary:
	R["victory"] = victory
	R["district_reached"] = district_reached
	R["gold_leftover"] = maxi(0, gold_left)
	return R

## Builds a compact victory-margin record for one battle result.
static func _margin_entry(battle_res: Dictionary, district_index: int, is_boss: bool) -> Dictionary:
	return {
		"district": district_index,
		"is_boss": is_boss,
		"victory": battle_res.get("victory", false),
		"player_hp_frac": battle_res.get("player_hp_frac", 0.0),
		"enemy_hp_frac": battle_res.get("enemy_hp_frac", 0.0)
	}

## Runs the greedy shop AI (star-ups, recruits, augment fills) against the given
## gold budget and returns the credits left afterwards. Callers MUST assign the
## result back so purchases actually debit the run's gold.
##
## `strategy` is an optional StrategyArchetypes archetype Dictionary (see that
## file). When empty, every choice below is exactly the original random
## heuristic (unchanged behavior — existing tests rely on this). When
## non-empty, step 2 (recruit) and step 3 (augment fill) pick the
## best-scoring candidate via StrategyArchetypes.score_unit/score_augment
## instead of a uniform-random pick, biasing this run toward that strategy
## while keeping the same tier odds / economy pacing. This is what lets
## StrategyMetricsSimulator measure a real winrate per named strategy, and
## what AutoplayDirector's live shop decisions are scored the same way as.
static func _simulate_shop_purchase(crew_mgr: CrewManager, gold: int, repo: Object, strategy: Dictionary = {}) -> int:
	var d_idx = crew_mgr.current_district
	var unit_odds = Constants.DISTRICT_UNIT_SHOP_ODDS.get(d_idx, Constants.DISTRICT_UNIT_SHOP_ODDS[1])
	var aug_odds = Constants.DISTRICT_SHOP_ODDS.get(d_idx, Constants.DISTRICT_SHOP_ODDS[1])
	
	# 1. Star Level Combinations / Duplicate Purchases
	for u in crew_mgr.fielded_units:
		if u.star_level < 3 and gold >= u.unit_resource.base_cost:
			if randf() < 0.35:
				gold -= u.unit_resource.base_cost
				u.star_level = min(3, u.star_level + 1)
				
	# 2. Recruit new units if crew cap allows (Tiered by District Odds)
	if crew_mgr.fielded_units.size() < crew_mgr.get_max_field_units() and gold >= 2:
		var unfielded = _get_unfielded_units(crew_mgr.fielded_units, repo)
		if not unfielded.is_empty():
			var roll = randf()
			var target_tier = 1
			var cum_p = 0.0
			for t in [1, 2, 3]:
				cum_p += unit_odds.get(t, 0.0)
				if roll <= cum_p:
					target_tier = t
					break
			
			var tiered_pool: Array[UnitResource] = []
			for u in unfielded:
				if target_tier == 1 and u.base_cost <= 2:
					tiered_pool.append(u)
				elif target_tier == 2 and (u.base_cost == 3 or u.base_cost == 4):
					tiered_pool.append(u)
				elif target_tier == 3 and u.base_cost >= 5:
					tiered_pool.append(u)
			if tiered_pool.is_empty():
				tiered_pool = unfielded

			var recruit_unit: UnitResource
			if strategy.is_empty():
				recruit_unit = tiered_pool[randi() % tiered_pool.size()]
			else:
				var existing_ids: Dictionary = {}
				for u2 in crew_mgr.fielded_units:
					if u2 and u2.unit_resource:
						existing_ids[u2.unit_resource.id] = true
				for u2 in crew_mgr.benched_units:
					if u2 and u2.unit_resource:
						existing_ids[u2.unit_resource.id] = true
				var best_u: UnitResource = tiered_pool[0]
				var best_u_score := -1.0
				for cand in tiered_pool:
					var sc = StrategyArchetypes.score_unit(cand, strategy, {"existing_ids": existing_ids})
					if sc > best_u_score:
						best_u_score = sc
						best_u = cand
				recruit_unit = best_u
			if gold >= recruit_unit.base_cost:
				gold -= recruit_unit.base_cost
				var new_inst = UnitInstance.new(recruit_unit)
				crew_mgr.benched_units.append(new_inst)
				_place_unit_tactically(crew_mgr, new_inst, crew_mgr.current_district)
				
	# 3. Buy augments for open slots (Tiered by District Odds)
	for u in crew_mgr.fielded_units:
		for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
			if u.equipped_augments[s_idx] == null and gold >= 2:
				var a_roll = randf()
				var chosen_a_tier = Enums.AugmentTier.COMMON
				var c_prob = aug_odds.get(Enums.AugmentTier.COMMON, 0.0)
				var r_prob = aug_odds.get(Enums.AugmentTier.RARE, 0.0)
				if a_roll <= c_prob:
					chosen_a_tier = Enums.AugmentTier.COMMON
				elif a_roll <= c_prob + r_prob:
					chosen_a_tier = Enums.AugmentTier.RARE
				else:
					chosen_a_tier = Enums.AugmentTier.LEGENDARY
					
				var aug_pool = repo.get_augments_by_tier(chosen_a_tier)
				if aug_pool.is_empty():
					aug_pool = repo.get_all_augments()

				if strategy.is_empty():
					for aug in aug_pool:
						if aug.base_cost <= gold and u.can_equip_augment(s_idx, aug):
							gold -= aug.base_cost
							u.equip_augment(s_idx, aug)
							break
				else:
					var best_aug: AugmentResource = null
					var best_aug_score := -1.0
					for aug in aug_pool:
						if aug.base_cost <= gold and u.can_equip_augment(s_idx, aug):
							var sc = StrategyArchetypes.score_augment(aug, strategy)
							if sc > best_aug_score:
								best_aug_score = sc
								best_aug = aug
					if best_aug != null:
						gold -= best_aug.base_cost
						u.equip_augment(s_idx, best_aug)

	# 4. Black Market Overdrive (Augment Synthesis) in District 3+ (Cost: 6 credits)
	if d_idx >= 3 and gold >= 6:
		for u in crew_mgr.fielded_units:
			for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
				var cur_aug = u.equipped_augments[s_idx]
				if cur_aug != null and cur_aug.tier < Enums.AugmentTier.LEGENDARY and gold >= 6:
					var target_tier = Enums.AugmentTier.RARE if cur_aug.tier == Enums.AugmentTier.COMMON else Enums.AugmentTier.LEGENDARY
					var pool = repo.get_augments_by_tier(target_tier)
					if pool.is_empty():
						pool = repo.get_all_augments()
					var candidates: Array[AugmentResource] = []
					for a in pool:
						if a.tier == target_tier and a.primary_tag == cur_aug.primary_tag:
							candidates.append(a)
					if candidates.is_empty():
						for a in pool:
							if a.tier == target_tier:
								candidates.append(a)
					if not candidates.is_empty():
						gold -= 6
						u.equipped_augments[s_idx] = candidates[randi() % candidates.size()]

	# 5. Tactical Conduit Installation (Dedicated Conduit Shop Slot)
	if repo and repo.has_method("get_all_conduits") and gold >= 3:
		var all_conduits: Array[ConduitResource] = repo.get_all_conduits()
		if not all_conduits.is_empty():
			var offered_cond: ConduitResource = all_conduits[randi() % all_conduits.size()]
			if gold >= offered_cond.cost:
				for s in range(6):
					if crew_mgr.is_slot_unlocked(s) and not crew_mgr.slot_conduits.has(s):
						var s_coords = UnitInstance.slot_to_coords(s)
						if offered_cond.can_install_on_row(s_coords.x):
							gold -= offered_cond.cost
							crew_mgr.install_conduit(s, offered_cond)
							break

	return maxi(0, gold)

static func _place_unit_tactically(crew_mgr: CrewManager, unit: UnitInstance, district: int) -> void:
	var role = unit.unit_resource.role if unit.unit_resource else Enums.UnitRole.TANK
	var b_idx = crew_mgr.benched_units.find(unit)
	if b_idx == -1: return
	
	if role == Enums.UnitRole.SNIPER or role == Enums.UnitRole.HACKER:
		# Prefer Backline slots (4 [D2], 3 [D3], 5 [D4])
		var backline_pref = [4, 3, 5]
		for s in backline_pref:
			if crew_mgr.is_slot_unlocked(s) and crew_mgr.tactical_grid[s] == null:
				crew_mgr.deploy_bench_to_grid(b_idx, s)
				return
				
	# Prefer Frontline slots (1 [Center], 0 [Left], 2 [Right])
	var frontline_pref = [1, 0, 2]
	for s in frontline_pref:
		if crew_mgr.is_slot_unlocked(s) and crew_mgr.tactical_grid[s] == null:
			crew_mgr.deploy_bench_to_grid(b_idx, s)
			return
			
	# Fallback to any open unlocked slot
	for s in range(6):
		if crew_mgr.is_slot_unlocked(s) and crew_mgr.tactical_grid[s] == null:
			crew_mgr.deploy_bench_to_grid(b_idx, s)
			return

static func _pick_best_doctrine_for_crew(crew_mgr: CrewManager, slot_to_unlock: int) -> String:
	var coords = UnitInstance.slot_to_coords(slot_to_unlock)
	var row = coords.x # Row 1 = Frontline, Row 0 = Backline
	if row == 0:
		var has_sniper = false
		var has_hacker = false
		for u in crew_mgr.fielded_units:
			if u and u.unit_resource:
				if u.unit_resource.role == Enums.UnitRole.SNIPER: has_sniper = true
				if u.unit_resource.role == Enums.UnitRole.HACKER: has_hacker = true
		if has_sniper:
			return "overwatch_perch"
		elif has_hacker:
			return "neural_relay"
		else:
			return "amplifier_matrix"
	else:
		return "fortified_aegis"

static func simulate_single_battle(
	player_crew: Array[UnitInstance],
	enemy_crew: Array[UnitInstance],
	repo: Object,
	district_index: int = 1,
	is_boss: bool = false,
	_district: DistrictResource = null,
	_player_grid: Array = [],
	synergy_report: SynergyReport = null,
	formation_bonuses: Dictionary = {}
) -> Dictionary:
	# Calculate active synergy bonuses for player squad
	var factions_dict = repo.factions if repo != null else {}
	var tags_dict = repo.tags if repo != null else {}
	var player_synergy_report = synergy_report if synergy_report != null else (SynergyEngine.evaluate_crew(player_crew, factions_dict, tags_dict) if repo != null else null)
	
	# Ensure grid slots are assigned for player units
	for i in range(player_crew.size()):
		var u = player_crew[i]
		if u != null and u.grid_slot < 0:
			u.grid_slot = _assign_tactical_slot(u, i, district_index)
			
	# Ensure grid slots are assigned for enemy units
	for i in range(enemy_crew.size()):
		var u = enemy_crew[i]
		if u != null and u.grid_slot < 0:
			u.grid_slot = _assign_tactical_slot(u, i, district_index)

	# Execute battle via CombatEngine with 60 FPS sub-frame precision (dt = 1.0 / 60.0)
	return CombatEngineScript.simulate_battle(
		player_crew,
		enemy_crew,
		district_index,
		is_boss,
		formation_bonuses,
		1.0 / 60.0,
		60.0,
		player_synergy_report
	)

## Aggregate remaining-HP fraction of a squad (0.0 = wiped, 1.0 = untouched).
## Shields are ignored; only raw HP pools count toward the margin.
static func _squad_hp_fraction(combatants: Array) -> float:
	var current := 0.0
	var maximum := 0.0
	for c in combatants:
		current += maxf(0.0, c["hp"])
		maximum += maxf(1.0, c["max_hp"])
	return clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0

static func _apply_district_environmental_hazards(player_combatants: Array, enemy_combatants: Array, district_index: int) -> void:
	match district_index:
		1:
			# District 1 (Slum Market): Corrosive sludge reduces healing effectiveness
			for c in player_combatants:
				c["healing_mult"] = 0.85
		2:
			# District 2 (Corp Arcology): High-security grid gives all enemies +120 initial barrier shields
			for c in enemy_combatants:
				c["shield"] += 120.0
		3:
			# District 3 (Server Vault): EMP firewall dampens initial starting mana by 20%
			for c in player_combatants:
				c["mana"] = maxf(0.0, c["mana"] - 15.0)
		4:
			# District 4 (Black Site Boss): Boss gains enrage phase flag
			for c in enemy_combatants:
				c["has_enrage"] = true

static func _create_combatant(unit: UnitInstance, repo: Object, is_player: bool, district_index: int = 1, is_boss: bool = false, synergy_report: SynergyReport = null) -> Dictionary:
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
	
	var tag_counts: Dictionary = {}
	for t in unit.get_all_tags():
		tag_counts[t] = tag_counts.get(t, 0) + 1
		
	var triggers: Array[String] = []
	
	# Apply active SynergyReport bonuses for player squad
	if is_player and synergy_report != null:
		var role = unit.unit_resource.role if unit.unit_resource else Enums.UnitRole.TANK
		var faction = unit.unit_resource.faction if unit.unit_resource else Enums.Faction.NONE
		
		# Faction threshold boosts
		for f_id in synergy_report.faction_counts:
			var count = synergy_report.faction_counts[f_id]
			match int(f_id):
				Enums.Faction.ROGUE_AIS:
					if count >= 2: ap *= 1.20
					if count >= 4: ap *= 1.35
				Enums.Faction.STREET_RUNNERS:
					if count >= 2: aspeed *= 1.15
					if count >= 4: aspeed *= 1.25
				Enums.Faction.CORP_ENFORCERS:
					if count >= 2: armor += 20.0; shield += 180.0
					if count >= 4: armor += 35.0; shield += 350.0
				Enums.Faction.FIXERS:
					if count >= 2: hp += 100.0; evasion += 0.05
					if count >= 4: hp += 200.0; evasion += 0.10
				Enums.Faction.BIO_HACKERS:
					if count >= 2: hp += 160.0; armor += 8.0
					if count >= 4: hp += 280.0; armor += 15.0
					if count >= 6: hp += 600.0; armor += 35.0; aspeed *= 1.20
				Enums.Faction.NET_PHANTOMS:
					if count >= 2: evasion += 0.20; ad += 10.0
					if count >= 4: evasion += 0.25; crit += 0.20; ad += 20.0
					if count >= 6: evasion += 0.40; crit += 0.35; ad += 40.0
					
	# Aggregate tag counts from entire squad synergy report
		for t_key in synergy_report.tag_counts:
			tag_counts[t_key] = synergy_report.tag_counts[t_key]
			
		for trig in synergy_report.registered_triggers:
			triggers.append(trig)
			
	# Register equipped augment triggers
	for aug in unit.equipped_augments:
		if aug != null and not aug.trigger_effect_id.is_empty() and not triggers.has(aug.trigger_effect_id):
			triggers.append(aug.trigger_effect_id)
					
	if not is_player:
		var scaling = Constants.DISTRICT_ENEMY_SCALING.get(district_index, {"hp_mult": 1.0, "dmg_mult": 1.0})
		hp *= scaling.get("hp_mult", 1.0)
		ad *= scaling.get("dmg_mult", 1.0)
		ap *= scaling.get("dmg_mult", 1.0)
		if is_boss:
			hp *= 1.35
			ad *= 1.20
	
	return {
		"id": unit.unit_resource.id if unit.unit_resource else "unit",
		"unit_instance": unit,
		"is_player": is_player,
		"is_boss": is_boss,
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
		"attack_timer": randf_range(0.05, 0.3),
		"enraged": false,
		"healing_mult": 1.0,
		"tags": tag_counts,
		"triggers": triggers,
		"active_dots": [],
		"active_conduit_id": "",
		"slot_doctrine_id": "",
		"retaliation_icd": 0.0
	}



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

static func _assign_tactical_slot(unit: UnitInstance, index: int, district_index: int) -> int:
	if unit.grid_slot >= 0:
		return unit.grid_slot

	var role = unit.unit_resource.role if unit.unit_resource else Enums.UnitRole.TANK
	if role == Enums.UnitRole.SNIPER or role == Enums.UnitRole.HACKER:
		if district_index >= 2:
			return 4 if index == 0 else (3 if index == 1 else 5)
	return clampi(index, 0, 2)

static func _apply_sim_formations(squad: Array[Dictionary]) -> void:
	for c in squad:
		var u = c["unit_instance"] as UnitInstance
		if not u or not u.unit_resource: continue
		var row = c["row"]
		var col = c["col"]
		var role = u.unit_resource.role
		
		# Base Tank Guard (+120 Shield to Left & Right)
		for other in squad:
			if other != c:
				var o_u = other["unit_instance"] as UnitInstance
				if o_u and o_u.unit_resource and o_u.unit_resource.role == Enums.UnitRole.TANK:
					if other["row"] == row and abs(other["col"] - col) == 1:
						c["shield"] += 120.0
						
		# Base Hacker Row Uplink (+15 Mana & +15% Speed)
		for other in squad:
			if other != c:
				var o_u = other["unit_instance"] as UnitInstance
				if o_u and o_u.unit_resource and o_u.unit_resource.role == Enums.UnitRole.HACKER:
					if other["row"] == row:
						c["mana"] = minf(c["max_mana"], c["mana"] + 15.0)
						c["attack_speed"] *= 1.15
						
		# Base Sniper Backline Spotter (+25% Crit in Row 0)
		if row == 0 and role == Enums.UnitRole.SNIPER:
			c["crit_chance"] += 0.25
			
		# Unit Directional Passives
		var u_res = u.unit_resource
		if u_res and u_res.directional_target != Enums.GridDirection.NONE:
			_apply_sim_directional_mods(c, squad, u_res.directional_target, u_res.directional_modifiers)
			
		# Augment Directional Modifiers
		for aug in u.equipped_augments:
			if aug and aug.directional_target != Enums.GridDirection.NONE:
				_apply_sim_directional_mods(c, squad, aug.directional_target, aug.directional_modifiers)

static func _apply_sim_directional_mods(source: Dictionary, squad: Array[Dictionary], dir: Enums.GridDirection, mods: Dictionary) -> void:
	var s_row = source["row"]
	var s_col = source["col"]
	
	if dir == Enums.GridDirection.FRONTLINE:
		if s_row == 1: _apply_sim_mods(source, mods)
		return
	elif dir == Enums.GridDirection.BACKLINE:
		if s_row == 0: _apply_sim_mods(source, mods)
		return
		
	for other in squad:
		if other["hp"] <= 0: continue
		var o_row = other["row"]
		var o_col = other["col"]
		var matches = false
		match dir:
			Enums.GridDirection.LEFT: matches = (o_row == s_row and o_col == s_col - 1)
			Enums.GridDirection.RIGHT: matches = (o_row == s_row and o_col == s_col + 1)
			Enums.GridDirection.ABOVE: matches = (o_row == s_row - 1 and o_col == s_col)
			Enums.GridDirection.BELOW: matches = (o_row == s_row + 1 and o_col == s_col)
			Enums.GridDirection.ADJACENT: matches = ((o_row == s_row and abs(o_col - s_col) == 1) or (o_col == s_col and abs(o_row - s_row) == 1))
			Enums.GridDirection.SAME_ROW: matches = (o_row == s_row and other != source)
			Enums.GridDirection.SAME_COLUMN: matches = (o_col == s_col and other != source)
			Enums.GridDirection.ALL_UNITS: matches = (other != source)
			
		if matches:
			_apply_sim_mods(other, mods)

static func _apply_sim_mods(target: Dictionary, mods: Dictionary) -> void:
	for k in mods:
		var v = mods[k]
		match int(k):
			Enums.StatType.MAX_HEALTH:
				target["max_hp"] += v
				target["hp"] += v
			Enums.StatType.ATTACK_DAMAGE: target["attack_damage"] += v
			Enums.StatType.ABILITY_POWER: target["ability_power"] += v
			Enums.StatType.ATTACK_SPEED: target["attack_speed"] += v
			Enums.StatType.ARMOR: target["armor"] += v
			Enums.StatType.SHIELD: target["shield"] += v
			Enums.StatType.STARTING_MANA: target["mana"] = minf(target["max_mana"], target["mana"] + v)
			Enums.StatType.CRIT_CHANCE: target["crit_chance"] += v
			Enums.StatType.EVASION: target["evasion"] += v

static func _step_combatant(c: Dictionary, opponents: Array[Dictionary], allies: Array[Dictionary], dt: float, district_index: int = 1) -> void:
	c["retaliation_icd"] = maxf(0.0, c.get("retaliation_icd", 0.0) - dt)
	# 1. Process active DoTs on this combatant
	if not c["active_dots"].is_empty():
		var remaining_dots: Array = []
		for dot in c["active_dots"]:
			dot["timer"] -= dt
			_apply_damage(c, dot["dps"] * dt)
			if dot["timer"] > 0.0 and c["hp"] > 0:
				remaining_dots.append(dot)
		c["active_dots"] = remaining_dots
		
	if c["hp"] <= 0:
		return

	# 2. Boss Enrage trigger below 50% HP in final district
	if c.get("has_enrage", false) and not c.get("enraged", false):
		if c["hp"] <= c["max_hp"] * 0.5:
			c["enraged"] = true
			c["attack_speed"] *= 1.35
			c["attack_damage"] *= 1.30
			c["shield"] += 200.0
			# Enrage Shockwave: hit all opponents in frontline
			for opp in opponents:
				if opp["hp"] > 0 and opp.get("row", 1) == 1:
					_apply_damage(opp, 120.0)
			
	c["attack_timer"] -= dt
	if c["attack_timer"] <= 0.0:
		c["attack_timer"] = 1.0 / maxf(0.2, c["attack_speed"])
		
		# Tactical Targeting: Prioritize Frontline (Row 1) defenders before Backline (Row 0)
		var target: Dictionary = {}
		for opp in opponents:
			if opp["hp"] > 0 and opp.get("row", 1) == 1:
				target = opp
				break
		if target.is_empty():
			for opp in opponents:
				if opp["hp"] > 0:
					target = opp
					break
				
		if target.is_empty():
			return
			
		if randf() < target["evasion"]:
			return
			
		var is_crit = randf() < c["crit_chance"]
		
		# Kinetic Momentum Drive Combo (+15% crit chance & +50 shield on crit)
		if is_crit and c["triggers"].has("kinetic_momentum_drive"):
			c["shield"] += 50.0
			
		# Legendary Kinetic Destroyer Ricochet: deals 50% damage to all enemies in same row on crit
		if is_crit and (c["triggers"].has("kinetic_destroyer_blast") or c["triggers"].has("kinetic_destroyer_ricochet")):
			var t_row = target.get("row", 1)
			for opp in opponents:
				if opp != target and opp["hp"] > 0 and opp.get("row", 1) == t_row:
					_apply_damage(opp, c["attack_damage"] * 0.75)
			
		var damage = c["attack_damage"] * (1.5 if is_crit else 1.0)
		
		# Thermal Tag: Burns target armor on basic attacks
		var thermal_tags = c["tags"].get(Enums.AugmentTag.THERMAL, 0)
		if thermal_tags >= 2:
			target["armor"] = maxf(-25.0, target["armor"] - 2.5 * thermal_tags)
			
		var damage_mult = 100.0 / (100.0 + maxf(0.0, target["armor"]))
		var final_damage = damage * damage_mult
		
		_apply_damage(target, final_damage)

		# Arc Discharge Coil: Frontline Retaliation when struck
		if target.get("active_conduit_id", "") == "conduit_arc_discharge" and target.get("retaliation_icd", 0.0) <= 0.0 and target["hp"] > 0:
			target["retaliation_icd"] = 1.5
			var retal_dmg = 35.0
			for opp in opponents:
				if opp["hp"] > 0 and opp.get("row", 1) == 1:
					_apply_damage(opp, retal_dmg)
		
		# Check if target died from attack for on-kill procs
		if target["hp"] <= 0:
			if c["triggers"].has("viral_pandemic"):
				for opp in opponents:
					if opp["hp"] > 0:
						opp["attack_speed"] *= 0.75
						opp["active_dots"].append({"timer": 3.0, "dps": 18.0})
		
		# Thermal Armor Lockdown Combo: Reflect 15% damage to attacker
		if target["triggers"].has("thermal_armor_lockdown"):
			_apply_damage(c, final_damage * 0.15)
			
		# Kinetic Tag: Stagger / delay target's attack timer on heavy hit
		var kinetic_tags = c["tags"].get(Enums.AugmentTag.KINETIC, 0)
		if kinetic_tags >= 2 and (is_crit or randf() < 0.35):
			target["attack_timer"] += 0.15 * kinetic_tags
			
		# Mana generation on attack
		var neural_tags = c["tags"].get(Enums.AugmentTag.NEURAL, 0)
		var mana_gain = 10.0 + (5.0 * neural_tags if is_crit else 0.0)
		c["mana"] = minf(c["max_mana"], c["mana"] + mana_gain)
		target["mana"] = minf(target["max_mana"], target["mana"] + 5.0)
		
		# Spellcast execution
		if c["mana"] >= c["max_mana"] and c["max_mana"] > 0:
			c["mana"] = 0.0

			# Hyper-Frequency Siphon: Refund 20 mana & grant +20% attack speed on cast
			if c.get("active_conduit_id", "") == "conduit_overclock_siphon":
				c["mana"] = minf(c["max_mana"], c["mana"] + 20.0)
				c["attack_speed"] *= 1.20

			# Vector (Conduit Sapper): Overload Pulse
			if c.get("id", "") == "ai_vector":
				var vector_dmg = 120.0 + (c["ability_power"] * 0.75)
				for opp in opponents:
					if opp["hp"] > 0:
						_apply_damage(opp, vector_dmg)
				if not c.get("slot_doctrine_id", "").is_empty() or not c.get("active_conduit_id", "").is_empty():
					for ally in allies:
						if ally["hp"] > 0 and ally.get("row", 1) == c.get("row", 1):
							ally["shield"] += 130.0
			
			# Legendary Supernova Core: Melts 40% target armor on cast and applies 30 dps burn
			if c["triggers"].has("thermal_supernova"):
				target["armor"] = maxf(-35.0, target["armor"] * 0.60)
				target["active_dots"].append({"timer": 3.0, "dps": 30.0 * (c["ability_power"] / 40.0)})
			
			var spell_dmg = c["ability_power"] * damage_mult
			
			# Boss AI Prime Overmind EMP drain
			if c.get("id", "") == "boss_ai_prime_overmind":
				for opp in opponents:
					if opp["hp"] > 0 and opp.get("row", 0) == 0:
						opp["mana"] = maxf(0.0, opp["mana"] - 25.0)
			
			# Boss Nemesis Synthetic team-wide Singularity Rupture
			if c.get("id", "") == "boss_nemesis_synthetic":
				for opp in opponents:
					if opp != target and opp["hp"] > 0:
						_apply_damage(opp, spell_dmg * 0.40)
			
			_apply_damage(target, spell_dmg)
			
			# Check target death on spellcast for viral pandemic
			if target["hp"] <= 0 and c["triggers"].has("viral_pandemic"):
				for opp in opponents:
					if opp["hp"] > 0:
						opp["attack_speed"] *= 0.75
						opp["active_dots"].append({"timer": 3.0, "dps": 18.0})
			
			# Neural Hivemind Overclock Combo / Legendary Neural Singularity: Share mana with living allies
			if c["triggers"].has("rogue_ai_hivemind_overclock") or c["triggers"].has("neural_singularity_synchronize"):
				var mana_share = 20.0 if c["triggers"].has("neural_singularity_synchronize") else 15.0
				for ally in allies:
					if ally != c and ally["hp"] > 0:
						ally["mana"] = minf(ally["max_mana"], ally["mana"] + mana_share)
						
			# Viral Tag: Inflict 3s damage-over-time debuff on spellcast
			var viral_tags = c["tags"].get(Enums.AugmentTag.VIRAL, 0)
			if viral_tags >= 2:
				var dot_dps = 12.0 * viral_tags * (c["ability_power"] / 40.0)
				target["active_dots"].append({"timer": 3.0, "dps": dot_dps})
				
				# Viral Black-Market Contagion Combo: Vampiric heal 25% of spell damage
				if c["triggers"].has("viral_blackmarket_contagion"):
					c["hp"] = minf(c["max_hp"], c["hp"] + (spell_dmg * 0.25) * c.get("healing_mult", 1.0))



static func _apply_damage(target: Dictionary, dmg: float) -> void:
	if target["shield"] > 0.0:
		if target["shield"] >= dmg:
			target["shield"] -= dmg
			return
		else:
			dmg -= target["shield"]
			target["shield"] = 0.0
	target["hp"] = maxf(0.0, target["hp"] - dmg)

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
				{"unit": "fixer_chemist", "augments": ["rare_viral_siphon"]},
				{"unit": "corp_operative", "augments": ["common_kinetic_accelerator"]}
			]
		4:
			return [
				{"unit": "corp_breacher", "augments": ["rare_thermal_exhaust"]},
				{"unit": "corp_deadeye", "augments": ["rare_kinetic_rail"]},
				{"unit": "ai_dreadnought", "augments": ["rare_neural_daemon"]},
				{"unit": "fixer_hitman", "augments": ["rare_viral_cascade"]},
				{"unit": "ai_singularity", "augments": ["rare_neural_daemon"]},
				{"unit": "runner_slasher", "augments": ["common_kinetic_plating"]}
			]
		_:
			return [{"unit": "runner_dash", "augments": []}]

static func _build_boss_enemy_comp(repo: Object, district_index: int) -> Array:
	match district_index:
		1:
			return [
				{"unit": "boss_slum_enforcer", "augments": []},
				{"unit": "runner_dash", "augments": ["common_kinetic_accelerator"]}
			]
		2:
			return [
				{"unit": "boss_corp_commander", "augments": ["rare_thermal_laser"]},
				{"unit": "street_ghost", "augments": ["rare_kinetic_rail"]},
				{"unit": "runner_dash", "augments": ["common_kinetic_accelerator"]},
				{"unit": "corp_sentinel", "augments": ["common_kinetic_plating"]}
			]
		3:
			return [
				{"unit": "boss_ai_prime_overmind", "augments": ["rare_neural_daemon", "legendary_neural_hive"]},
				{"unit": "ai_bastion", "augments": ["rare_thermal_exhaust"]},
				{"unit": "ai_cipher", "augments": ["rare_neural_synapse"]},
				{"unit": "runner_nexus", "augments": ["rare_neural_synapse"]},
				{"unit": "ai_glitch", "augments": ["common_neural_buffer"]}
			]
		4:
			return [
				{"unit": "boss_nemesis_synthetic", "augments": ["legendary_kinetic_destroyer"]},
				{"unit": "corp_director", "augments": ["rare_kinetic_rail"]},
				{"unit": "ai_singularity", "augments": ["rare_neural_daemon"]},
				{"unit": "fixer_kingpin", "augments": ["rare_viral_cascade"]},
				{"unit": "corp_breacher", "augments": ["rare_thermal_exhaust"]}
			]
		_:
			return [{"unit": "boss_slum_enforcer", "augments": []}]

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
	if report_data.has("avg_fights_won"):
		lines.append("- **Average Fights Won per Run:** %.2f (%d total across all runs)" % [
			report_data["avg_fights_won"], report_data["total_fights_won"]
		])
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

	# 4. Conditional Clear Probability (Decided-vs-Ended)
	if report_data.has("conditional_clear"):
		var cc: Dictionary = report_data["conditional_clear"]
		lines.append("## 4. Conditional Clear Probability (Decided-vs-Ended)")
		lines.append("_P(win the whole run | reached this milestone). A run is 'effectively decided' once this crosses 95%._")
		lines.append("")
		lines.append("| Milestone | Runs Reaching | Eventual Clears | Conditional Clear Rate |")
		lines.append("|---|---|---|---|")
		var cc_labels = {
			1: "Started run (reached District 1)",
			2: "Cleared District 1 (reached District 2)",
			3: "Cleared District 2 (reached District 3)",
			4: "Cleared District 3 (reached District 4)"
		}
		var decided_at := 0
		for d in [1, 2, 3, 4]:
			var cc_row: Dictionary = cc[d]
			lines.append("| %s | %d | %d | **%.2f%%** |" % [cc_labels[d], cc_row["reached"], cc_row["clears"], cc_row["rate"]])
			if decided_at == 0 and cc_row["rate"] >= 95.0:
				decided_at = d
		lines.append("")
		if decided_at > 0:
			var decided_labels = {1: "before District 1 even begins", 2: "clearing District 1", 3: "clearing District 2", 4: "clearing District 3"}
			lines.append("- **Run is effectively decided by: %s** (first milestone with ≥95%% conditional clear)." % decided_labels[decided_at])
		else:
			lines.append("- **Run stays in genuine doubt through the final district** (no milestone reaches 95% conditional clear).")
		lines.append("")

	# 5. Combat Closeness & Victory Margin
	if report_data.has("combat_margin"):
		var cm: Dictionary = report_data["combat_margin"]
		lines.append("## 5. Combat Closeness & Victory Margin")
		lines.append("_Crew HP remaining at the end of **won** battles. Stomp = won with ≥80% crew HP; Nailbiter = won with ≤15%._")
		lines.append("")
		lines.append("| District | Won Battles Sampled | Avg Crew HP Left | Stomps | Nailbiters | Boss: Avg Crew HP Left |")
		lines.append("|---|---|---|---|---|---|")
		var cm_names = {1: "District 1 (Slum Market)", 2: "District 2 (Corp Arcology)", 3: "District 3 (Server Vault)", 4: "District 4 (Black Site)"}
		for d in [1, 2, 3, 4]:
			var cm_row: Dictionary = cm[d]
			lines.append("| %s | %d | %.0f%% | %.1f%% | %.1f%% | %.0f%% |" % [
				cm_names[d], cm_row["wins_sampled"],
				cm_row["avg_win_hp_frac"] * 100.0, cm_row["stomp_pct"], cm_row["nail_pct"],
				cm_row["boss_avg_hp_frac"] * 100.0
			])
		lines.append("")

	# 6. Economy & Credit Flow
	if report_data.has("economy"):
		var eco: Dictionary = report_data["economy"]
		var goh: Dictionary = eco["avg_gold_on_hand"]
		lines.append("## 6. Economy & Credit Flow")
		lines.append("- **Average Credits Spent per Run:** %.1f" % eco["avg_gold_spent"])
		lines.append("- **Average Credits Unspent at Run End:** %.1f" % eco["avg_gold_leftover"])
		lines.append("- **Runs Ending With >20 Idle Credits:** %.1f%% (economy never bit)" % eco["idle_wealth_pct"])
		lines.append("")
		lines.append("| Entering Prep For | Avg Credits On Hand |")
		lines.append("|---|---|")
		var goh_names = {1: "District 1", 2: "District 2", 3: "District 3", 4: "District 4"}
		for d in [1, 2, 3, 4]:
			lines.append("| %s | %.1f |" % [goh_names[d], goh.get(d, 0.0)])
		lines.append("")

	return "\n".join(lines)
