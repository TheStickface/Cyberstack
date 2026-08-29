class_name DebugConsole
extends RefCounted

## Command parser and state manipulation engine for in-game debugging

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object = null

func _init(p_repo: Object = null) -> void:
	if p_repo != null:
		repo = p_repo
	else:
		repo = DataRepoScript.new()
		repo.load_all_data("res://data")

func execute_command(cmd_string: String, gm: Object = null, main_node: Object = null) -> Dictionary:
	var trimmed = cmd_string.strip_edges()
	if trimmed.is_empty():
		return {"success": true, "message": ""}
		
	var parts = trimmed.split(" ", false)
	var command = parts[0].to_lower()
	if command.begins_with("/"):
		command = command.substr(1)
		
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(parts[i])
		
	match command:
		"help", "?":
			return {
				"success": true,
				"message": """[b]AVAILABLE DEBUG COMMANDS:[/b]
  /help — Show this command reference
  /loadout <ai|runner|corp|fixer> — Equip 4-man max synergy team preset
  /fight [boss|patrol|<boss_id>] [district] — Instant combat encounter jump
  /hud (or F3) — Toggle real-time Combat Telemetry & DPS Inspector
  /gold <amount> — Add or modify credits
  /district <1-4> — Jump to district
  /spawn <unit_id> — Add operative to bench/field
  /grant <aug_id> — Add augment to inventory
  /win — Force immediate combat victory
  /defeat — Force immediate combat defeat
  /unlock_all — Unlock all starter operatives
  /wipe_save — Reset profile and delete active run
  /crt — Toggle CRT scanline shader
  /metrics — Open Community Telemetry & Analytics Dashboard
  /inspect — Print current crew synergy breakdown"""
			}
			
		"loadout", "preset":
			if args.is_empty():
				return {"success": false, "message": "Usage: /loadout <ai|runner|corp|fixer>"}
			var preset = args[0].to_lower()
			if gm and gm.active_run_manager and gm.active_run_manager.crew_mgr:
				var cm: CrewManager = gm.active_run_manager.crew_mgr
				cm.current_district = 4 # Unlock slots for test squad
				cm.tactical_grid = [null, null, null, null, null, null]
				cm.benched_units.clear()
				cm.augment_inventory.clear()
				
				var u_ids: Array[String] = []
				var aug_ids: Array[String] = []
				match preset:
					"ai", "ai_overclock":
						u_ids = ["ai_bastion", "ai_cipher", "ai_siphon", "ai_bastion"]
						aug_ids = ["rare_neural_synapse", "common_neural_link", "rare_neural_synapse"]
					"runner", "runner_kinetic":
						u_ids = ["runner_blitz", "runner_rampart", "runner_nexus", "runner_phantom"]
						aug_ids = ["common_kinetic_plating", "rare_kinetic_rail", "legendary_kinetic_destroyer"]
					"corp", "corp_phalanx":
						u_ids = ["corp_sentinel", "corp_breacher", "corp_deadeye", "corp_operative"]
						aug_ids = ["rare_thermal_exhaust", "common_kinetic_plating", "rare_thermal_exhaust"]
					"fixer", "fixer_vamp":
						u_ids = ["fixer_broker", "fixer_bouncer", "fixer_doc", "street_ghost"]
						aug_ids = ["rare_viral_siphon", "rare_viral_cascade", "rare_viral_siphon"]
					_:
						return {"success": false, "message": "Unknown preset '%s'. Options: ai, runner, corp, fixer" % preset}
						
				for i in range(u_ids.size()):
					var u_res = repo.get_unit(u_ids[i])
					if u_res:
						var inst = UnitInstance.new(u_res)
						inst.star_level = 2
						if i < aug_ids.size():
							var a_res = repo.get_augment(aug_ids[i])
							if a_res and inst.can_equip_augment(0, a_res):
								inst.equip_augment(0, a_res)
						cm.place_unit_on_grid(inst, i)
						
				cm.recalculate_synergies()
				if main_node and main_node.has_node("ScreenContainer"):
					var sc = main_node.get_node("ScreenContainer")
					for ch in sc.get_children():
						if ch is PrepScreen: ch._refresh_all()
				return {"success": true, "message": "Equipped archetype loadout '%s' (4 units, Tier-2, slotted)." % preset}
			return {"success": false, "message": "No active run available."}
			
		"fight", "battle":
			if gm and gm.active_run_manager:
				var target_type = args[0] if not args.is_empty() else "patrol"
				var dist_num = int(args[1]) if args.size() > 1 else gm.active_run_manager.current_district_index
				var is_boss = target_type.begins_with("boss") or target_type == "boss"
				gm.active_run_manager.current_district_index = dist_num
				gm.start_combat_encounter(is_boss, repo)
				return {"success": true, "message": "Instantly launched combat encounter (%s, District %d)!" % [target_type, dist_num]}
			return {"success": false, "message": "No active GameManager available."}
			
		"hud", "dps":
			if main_node and main_node.has_node("ScreenContainer"):
				var sc = main_node.get_node("ScreenContainer")
				for ch in sc.get_children():
					if ch is CombatMockArena and ch.telemetry_hud:
						var st = ch.telemetry_hud.toggle_visibility()
						return {"success": true, "message": "Combat Telemetry HUD: %s" % ("ENABLED" if st else "DISABLED")}
			return {"success": false, "message": "Combat arena is not currently active (Press F3 during combat)."}

			
		"metrics", "analytics", "telemetry":
			if gm:
				gm.open_metrics()
				return {"success": true, "message": "Opening Community Telemetry Dashboard..."}
			return {"success": false, "message": "GameManager not found."}
			
		"gold", "credits", "money":
			if args.is_empty():
				return {"success": false, "message": "Usage: /gold <amount> (e.g. /gold 25)"}
			var amt = int(args[0])
			if gm and gm.active_run_manager and gm.active_run_manager.shop_mgr:
				gm.active_run_manager.shop_mgr.add_gold(amt)
				return {"success": true, "message": "Added %d credits. New balance: %d" % [amt, gm.active_run_manager.shop_mgr.gold]}
			return {"success": false, "message": "No active run or ShopManager available."}
			
		"district", "dist":
			if args.is_empty():
				return {"success": false, "message": "Usage: /district <1-4>"}
			var dist_idx = int(args[0])
			if dist_idx < 1 or dist_idx > 4:
				return {"success": false, "message": "District must be between 1 and 4"}
			if gm and gm.active_run_manager:
				gm.active_run_manager._load_district(dist_idx)
				gm.open_map()
				return {"success": true, "message": "Jumped to District %d: %s" % [dist_idx, gm.active_run_manager.current_district.display_name]}
			return {"success": false, "message": "No active run available."}
			
		"spawn", "spawn_unit", "unit":
			if args.is_empty():
				return {"success": false, "message": "Usage: /spawn <unit_id> (e.g. /spawn runner_blitz)"}
			var u_id = args[0]
			var unit_res = repo.get_unit(u_id)
			if unit_res == null:
				return {"success": false, "message": "Unit '%s' not found in repository." % u_id}
			if gm and gm.active_run_manager and gm.active_run_manager.crew_mgr:
				var instance = UnitInstance.new(unit_res)
				var added = gm.active_run_manager.crew_mgr.add_unit_to_bench(instance)
				if not added:
					gm.active_run_manager.crew_mgr.fielded_units.append(instance)
				gm.active_run_manager.crew_mgr.recalculate_synergies()
				return {"success": true, "message": "Spawned %s into crew." % unit_res.display_name}
			return {"success": false, "message": "No active crew manager available."}
			
		"grant", "grant_aug", "aug":
			if args.is_empty():
				return {"success": false, "message": "Usage: /grant <aug_id> (e.g. /grant common_kinetic_accelerator)"}
			var a_id = args[0]
			var aug_res = repo.get_augment(a_id)
			if aug_res == null:
				return {"success": false, "message": "Augment '%s' not found in repository." % a_id}
			if gm and gm.active_run_manager and gm.active_run_manager.crew_mgr:
				var added = gm.active_run_manager.crew_mgr.add_augment_to_inventory(aug_res)
				if added:
					return {"success": true, "message": "Added %s to augment inventory." % aug_res.display_name}
				return {"success": false, "message": "Augment inventory is full."}
			return {"success": false, "message": "No active crew manager available."}
			
		"win", "victory":
			if gm:
				var res = gm.finish_combat_encounter(true, {"duration": 5.0, "damage_dealt": 9999})
				return {"success": true, "message": "Combat Victory resolved: %s" % res.get("status", "")}
			return {"success": false, "message": "GameManager not found."}
			
		"defeat", "lose":
			if gm:
				var res = gm.finish_combat_encounter(false, {"duration": 3.0, "damage_dealt": 0})
				return {"success": true, "message": "Combat Defeat resolved: %s" % res.get("status", "")}
			return {"success": false, "message": "GameManager not found."}
			
		"unlock_all":
			if gm:
				var profile = gm.active_profile if gm.active_profile else SaveManager.load_profile()
				for u in repo.get_all_units():
					if not profile.unlocked_operatives.has(u.id):
						profile.unlocked_operatives.append(u.id)
				for a in repo.get_all_augments():
					if not profile.discovered_augments.has(a.id):
						profile.discovered_augments.append(a.id)
				SaveManager.save_profile(profile)
				return {"success": true, "message": "All operatives and augments unlocked in Codex."}
			return {"success": false, "message": "GameManager not found."}
			
		"wipe_save", "reset":
			SaveManager.delete_active_run()
			var fresh_profile = MetaProfile.new()
			SaveManager.save_profile(fresh_profile)
			if gm:
				gm.active_profile = fresh_profile
				gm.return_to_title()
			return {"success": true, "message": "Profile reset and active run deleted."}
			
		"crt":
			if main_node and main_node.has_node("CRTOverlay"):
				var crt = main_node.get_node("CRTOverlay")
				var state = crt.toggle_crt()
				return {"success": true, "message": "CRT Overlay toggled: %s" % ("ENABLED" if state else "DISABLED")}
			return {"success": false, "message": "CRTOverlay node not found in scene tree."}
			
		"inspect":
			if gm and gm.active_run_manager and gm.active_run_manager.crew_mgr:
				var rep: SynergyReport = gm.active_run_manager.crew_mgr.active_synergy_report
				var lines: Array[String] = ["[b]ACTIVE SYNERGIES & CREW STATS:[/b]"]
				for fac in rep.active_faction_thresholds.keys():
					lines.append("  - Faction %s: Threshold %d" % [Enums.faction_to_string(fac), rep.active_faction_thresholds[fac]])
				for tag in rep.active_tag_chains.keys():
					lines.append("  - Tag %s: Chain %d" % [Enums.tag_to_string(tag), rep.active_tag_chains[tag]])
				for combo in rep.active_cross_combos:
					lines.append("  - Combo: %s" % combo)
				return {"success": true, "message": "\n".join(lines)}
			return {"success": false, "message": "No active crew to inspect."}
			
		"hover", "hoverdebug":
			if main_node and main_node.has_node("ScreenContainer"):
				var screen_container = main_node.get_node("ScreenContainer")
				for child in screen_container.get_children():
					if "synergy_tooltip" in child and child.synergy_tooltip:
						child.synergy_tooltip.toggle_debug_hud()
						return {"success": true, "message": "Toggled Hover Debug HUD."}
			return {"success": false, "message": "PrepScreen with hover tooltip not currently active."}
			
		_:
			return {"success": false, "message": "Unknown command '/%s'. Type /help for a list of commands." % command}
