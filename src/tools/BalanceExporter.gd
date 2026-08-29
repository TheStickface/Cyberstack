class_name BalanceExporter
extends SceneTree

## Headless CLI tool that scans all game data and generates data/balance_matrix.md

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func _init() -> void:
	print("========================================")
	print("   CYBERSTACK BALANCE MATRIX EXPORTER   ")
	print("========================================")
	
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var md_content = generate_markdown_matrix(repo)
	var output_path = "res://data/balance_matrix.md"
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(md_content)
		file.close()
		print("[SUCCESS] Exported balance matrix to %s\n" % output_path)
		quit(0)
	else:
		printerr("[ERROR] Failed to write to %s\n" % output_path)
		quit(1)

static func generate_markdown_matrix(repo: Object) -> String:
	var lines: Array[String] = []
	lines.append("# Cyberstack — Unified Balance Matrix & Data Manifest")
	lines.append("**Generated Date:** %s" % Time.get_date_string_from_system())
	lines.append("")
	lines.append("---")
	lines.append("")
	
	# 1. Operatives Table
	lines.append("## 1. Operative Roster")
	lines.append("| ID | Name | Role | Faction | Base HP | Attack DMG | Mana (Start/Max) | Cost |")
	lines.append("|---|---|---|---|---|---|---|---|")
	for unit in repo.get_all_units():
		lines.append("| `%s` | **%s** | %s | %s | %.0f | %.0f | %.0f / %.0f | %dg |" % [
			unit.id,
			unit.display_name,
			unit.get_role_name(),
			unit.get_faction_name(),
			unit.base_max_health,
			unit.base_attack_damage,
			unit.base_starting_mana,
			unit.base_max_mana,
			unit.base_cost
		])
	lines.append("")
	
	# 2. Augments Table
	lines.append("## 2. Augment Gear Catalog")
	lines.append("| ID | Name | Tier | Slot Type | Tags | Stat Modifiers | Base Cost | Sell Value |")
	lines.append("|---|---|---|---|---|---|---|---|")
	for aug in repo.get_all_augments():
		var tag_names: Array[String] = []
		for t in aug.tags:
			tag_names.append(Enums.tag_to_string(t))
			
		var stat_desc: Array[String] = []
		for s_type in aug.stat_modifiers.keys():
			stat_desc.append(Enums.format_stat_value(s_type as int as Enums.StatType, float(aug.stat_modifiers[s_type])) + " " + Enums.stat_to_string(s_type as int as Enums.StatType))
			
		var sell_val = Constants.AUGMENT_SELL_VALUES.get(aug.tier, 1)
		lines.append("| `%s` | **%s** | %s | %s | %s | %s | %dg | %dg |" % [
			aug.id,
			aug.display_name,
			aug.get_tier_name(),
			Enums.slot_type_to_string(aug.slot_type),
			", ".join(tag_names),
			", ".join(stat_desc) if not stat_desc.is_empty() else "None",
			aug.base_cost,
			sell_val
		])
	lines.append("")
	
	# 3. District Run Scaling Curve
	lines.append("## 3. District Progression & Scaling Curve")
	lines.append("| District Index | Crew Capacity | Total Augment Slots | Base Encounter Payout | Common Shop Odds | Rare Shop Odds | Legendary Shop Odds |")
	lines.append("|---|---|---|---|---|---|---|")
	for d_idx in [1, 2, 3, 4]:
		var crew_cap = Constants.DISTRICT_CREW_LIMITS.get(d_idx, 2)
		var payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(d_idx, 4)
		var odds = Constants.DISTRICT_SHOP_ODDS.get(d_idx, {})
		var c_odds = odds.get(Enums.AugmentTier.COMMON, 0.0) * 100.0
		var r_odds = odds.get(Enums.AugmentTier.RARE, 0.0) * 100.0
		var l_odds = odds.get(Enums.AugmentTier.LEGENDARY, 0.0) * 100.0
		lines.append("| District %d | **%d Units** | %d Slots | %dg | %.0f%% | %.0f%% | %.0f%% |" % [
			d_idx,
			crew_cap,
			crew_cap * Constants.MAX_AUGMENT_SLOTS_PER_UNIT,
			payout,
			c_odds,
			r_odds,
			l_odds
		])
	lines.append("")
	
	# 4. District Theme Pool
	lines.append("## 4. District Theme Pool")
	lines.append("| ID | Display Name | Nodes | Final Boss Only |")
	lines.append("|---|---|---|---|")
	for dist in repo.get_all_districts():
		lines.append("| `%s` | **%s** | %d nodes | %s |" % [
			dist.id,
			dist.display_name,
			dist.get_node_count(),
			"YES" if dist.is_final_boss else "No"
		])
	lines.append("")
	
	# 5. Factions & Thresholds
	lines.append("## 5. Faction Trait Thresholds (2 / 4 / 6)")
	for f_key in repo.factions.keys():
		var fac: FactionResource = repo.factions[f_key]
		lines.append("### %s" % fac.display_name)
		lines.append("%s" % fac.description)
		lines.append("")
		lines.append("| Threshold | Stat Modifiers | Trigger Effect |")
		lines.append("|---|---|---|")
		for bonus in fac.threshold_bonuses:
			var mod_strs: Array[String] = []
			for st in bonus.stat_modifiers.keys():
				mod_strs.append(Enums.format_stat_value(st as int as Enums.StatType, float(bonus.stat_modifiers[st])) + " " + Enums.stat_to_string(st as int as Enums.StatType))
			lines.append("| **%d Units** | %s | %s |" % [
				bonus.required_count,
				", ".join(mod_strs) if not mod_strs.is_empty() else "None",
				bonus.trigger_effect_id if not bonus.trigger_effect_id.is_empty() else "None"
			])
		lines.append("")
		
	return "\n".join(lines)
