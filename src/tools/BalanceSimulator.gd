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
		
	var crew_mgr = CrewManager.new(1, repo)
	var starter_inst = UnitInstance.new(starter_unit_res)
	crew_mgr.benched_units.append(starter_inst)
	_place_unit_tactically(crew_mgr, starter_inst, 1)
	
	var gold = Constants.DEFAULT_STARTING_GOLD
	
	var events_encountered = 0
	var role_checks_passed = 0
	var event_gold_earned = 0
	var event_augments_gained = 0
	var fights_won = 0
	
	# Initial Shop / Prep Phase before First Fight
	_simulate_shop_purchase(crew_mgr, gold, repo)
	
	for d_idx in range(1, drawn_districts.size() + 1):
		crew_mgr.current_district = d_idx
		var district: DistrictResource = drawn_districts[d_idx - 1]
		
		# Prep Phase at start of each district
		if d_idx > 1:
			_simulate_shop_purchase(crew_mgr, gold, repo)
			
		for enc_type in district.node_sequence:
			match enc_type:
				Enums.EncounterType.FIGHT:
					var enemy_comp_templates = _build_minion_enemy_comp(repo, d_idx)
					var enemy_crew = _instantiate_crew(enemy_comp_templates, repo)
					
					var battle_res = simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, false, district)
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
					
					var battle_res = simulate_single_battle(crew_mgr.fielded_units, enemy_crew, repo, d_idx, true, district)
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
						var best_choice = _pick_best_event_choice(ev_res, gold, crew_mgr.fielded_units)
						if best_choice:
							if best_choice.required_role != Enums.UnitRole.ANY or best_choice.required_faction != Enums.Faction.NONE:
								role_checks_passed += 1
								
							gold = maxi(0, gold - best_choice.required_gold - best_choice.penalty_gold + best_choice.reward_gold)
							event_gold_earned += best_choice.reward_gold
							
							if best_choice.reward_augment != null:
								event_augments_gained += 1
								_try_equip_augment(crew_mgr.fielded_units, best_choice.reward_augment)
								
				Enums.EncounterType.SHOP:
					_simulate_shop_purchase(crew_mgr, gold, repo)
										
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

static func _simulate_shop_purchase(crew_mgr: CrewManager, gold: int, repo: Object) -> void:
	# 1. Star Level Combinations / Duplicate Purchases
	for u in crew_mgr.fielded_units:
		if u.star_level < 3 and gold >= u.unit_resource.base_cost:
			if randf() < 0.35:
				gold -= u.unit_resource.base_cost
				u.star_level = min(3, u.star_level + 1)
				
	# 2. Recruit new units if crew cap allows
	if crew_mgr.fielded_units.size() < crew_mgr.get_max_field_units() and gold >= 3:
		var unfielded = _get_unfielded_units(crew_mgr.fielded_units, repo)
		if not unfielded.is_empty():
			var recruit_unit: UnitResource = unfielded[randi() % unfielded.size()]
			if gold >= recruit_unit.base_cost:
				gold -= recruit_unit.base_cost
				var new_inst = UnitInstance.new(recruit_unit)
				crew_mgr.benched_units.append(new_inst)
				_place_unit_tactically(crew_mgr, new_inst, crew_mgr.current_district)
				
	# 3. Buy augments for open slots
	var all_augs = repo.get_all_augments()
	for u in crew_mgr.fielded_units:
		for s_idx in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
			if u.equipped_augments[s_idx] == null and gold >= 2:
				for aug in all_augs:
					if aug.base_cost <= gold and u.can_equip_augment(s_idx, aug):
						gold -= aug.base_cost
						u.equip_augment(s_idx, aug)
						break

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

static func simulate_single_battle(
	player_crew: Array[UnitInstance],
	enemy_crew: Array[UnitInstance],
	repo: Object,
	district_index: int = 1,
	is_boss: bool = false,
	district: DistrictResource = null
) -> Dictionary:
	# Calculate active synergy bonuses for player squad
	var factions_dict = repo.factions if repo != null else {}
	var tags_dict = repo.tags if repo != null else {}
	var player_synergy_report = SynergyEngine.evaluate_crew(player_crew, factions_dict, tags_dict)
	
	var player_combatants: Array[Dictionary] = []
	for i in range(player_crew.size()):
		var u = player_crew[i]
		var c = _create_combatant(u, repo, true, district_index, false, player_synergy_report)
		var slot = _assign_tactical_slot(u, i, district_index)
		c["slot"] = slot
		var coords = UnitInstance.slot_to_coords(slot)
		c["row"] = coords.x
		c["col"] = coords.y
		player_combatants.append(c)
		
	var enemy_combatants: Array[Dictionary] = []
	for i in range(enemy_crew.size()):
		var u = enemy_crew[i]
		var c = _create_combatant(u, repo, false, district_index, is_boss, null)
		var slot = _assign_tactical_slot(u, i, district_index)
		c["slot"] = slot
		var coords = UnitInstance.slot_to_coords(slot)
		c["row"] = coords.x
		c["col"] = coords.y
		enemy_combatants.append(c)
		
	# Apply start-of-battle formation buffs
	_apply_sim_formations(player_combatants)
	_apply_sim_formations(enemy_combatants)
	
	# Apply District-Thematic Environmental Hazards & Modifiers
	_apply_district_environmental_hazards(player_combatants, enemy_combatants, district_index)
		
	var time = 0.0
	var dt = 0.1
	var max_time = 60.0
	
	while time < max_time:
		time += dt
		
		# Step player combatants
		for c in player_combatants:
			if c["hp"] > 0:
				_step_combatant(c, enemy_combatants, player_combatants, dt, district_index)
				
		# Step enemy combatants
		for c in enemy_combatants:
			if c["hp"] > 0:
				_step_combatant(c, player_combatants, enemy_combatants, dt, district_index)
				
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
					if count >= 2: armor += 15.0
					if count >= 4: shield += 120.0
				Enums.Faction.FIXERS:
					if count >= 2: hp += 100.0; evasion += 0.05
					if count >= 4: hp += 200.0; evasion += 0.10
					
		# Aggregate tag counts from entire squad synergy report
		for t_key in synergy_report.tag_counts:
			tag_counts[t_key] = synergy_report.tag_counts[t_key]
			
		for trig in synergy_report.registered_triggers:
			triggers.append(trig)
					
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
		"active_dots": []
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
			c["attack_speed"] *= 1.25
			c["attack_damage"] *= 1.20
			
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
			
		var damage = c["attack_damage"] * (1.5 if is_crit else 1.0)
		
		# Thermal Tag: Burns target armor on basic attacks
		var thermal_tags = c["tags"].get(Enums.AugmentTag.THERMAL, 0)
		if thermal_tags >= 2:
			target["armor"] = maxf(-25.0, target["armor"] - 2.5 * thermal_tags)
			
		var damage_mult = 100.0 / (100.0 + maxf(0.0, target["armor"]))
		var final_damage = damage * damage_mult
		
		_apply_damage(target, final_damage)
		
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
			var spell_dmg = c["ability_power"] * damage_mult
			_apply_damage(target, spell_dmg)
			
			# Neural Hivemind Overclock Combo: Share mana generation with all living allies
			if c["triggers"].has("rogue_ai_hivemind_overclock"):
				for ally in allies:
					if ally != c and ally["hp"] > 0:
						ally["mana"] = minf(ally["max_mana"], ally["mana"] + 15.0)
						
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
				{"unit": "boss_slum_enforcer", "augments": []},
				{"unit": "runner_dash", "augments": ["common_kinetic_accelerator"]}
			]
		2:
			return [
				{"unit": "boss_corp_commander", "augments": ["rare_thermal_laser"]},
				{"unit": "street_ghost", "augments": ["rare_kinetic_rail"]},
				{"unit": "runner_dash", "augments": ["common_kinetic_accelerator"]}
			]
		3:
			return [
				{"unit": "boss_ai_prime_overmind", "augments": ["rare_neural_daemon", "legendary_neural_hive"]},
				{"unit": "ai_bastion", "augments": ["rare_thermal_exhaust"]},
				{"unit": "ai_cipher", "augments": ["rare_neural_synapse"]},
				{"unit": "runner_nexus", "augments": ["rare_neural_synapse"]}
			]
		4:
			return [
				{"unit": "boss_nemesis_synthetic", "augments": ["legendary_kinetic_destroyer", "legendary_viral_pandemic"]},
				{"unit": "corp_director", "augments": ["rare_kinetic_rail"]},
				{"unit": "ai_singularity", "augments": ["rare_neural_daemon"]},
				{"unit": "fixer_kingpin", "augments": ["rare_viral_cascade"]}
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
