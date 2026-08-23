class_name SynergyEngine
extends RefCounted

## Pure functional evaluator that calculates faction synergies, tag chains, and cross-system bonuses for a given crew

static func evaluate_crew(
	crew: Array[UnitInstance],
	faction_registry: Dictionary = {},
	tag_registry: Dictionary = {}
) -> SynergyReport:
	var report = SynergyReport.new()
	
	# 1. Count Factions (tracking unique operative IDs per faction)
	var seen_unit_ids_per_faction: Dictionary = {}
	for unit in crew:
		if unit == null or unit.unit_resource == null:
			continue
		var faction = unit.unit_resource.faction
		if faction == Enums.Faction.NONE:
			continue
		
		if not seen_unit_ids_per_faction.has(faction):
			seen_unit_ids_per_faction[faction] = {}
		
		seen_unit_ids_per_faction[faction][unit.unit_resource.id] = true
	
	for faction in seen_unit_ids_per_faction.keys():
		report.faction_counts[faction] = seen_unit_ids_per_faction[faction].keys().size()

	# 2. Count Augment Tags across all equipped gear on all units
	for unit in crew:
		if unit == null:
			continue
		for tag in unit.get_all_tags():
			if tag == Enums.AugmentTag.NONE:
				continue
			var current_count = report.tag_counts.get(tag, 0)
			report.tag_counts[tag] = current_count + 1

	# 3. Evaluate Faction Threshold Bonuses (2 / 4 / 6)
	for faction_enum in report.faction_counts.keys():
		var count: int = report.faction_counts[faction_enum]
		var faction_res: FactionResource = faction_registry.get(faction_enum, null)
		if faction_res:
			var active_bonuses = faction_res.get_bonus_for_count(count)
			if not active_bonuses.is_empty():
				report.active_faction_bonuses[faction_enum] = active_bonuses
				for bonus in active_bonuses:
					_merge_bonus(report, bonus)

	# 4. Evaluate Tag Chain Bonuses (2 / 4 / 6)
	for tag_enum in report.tag_counts.keys():
		var count: int = report.tag_counts[tag_enum]
		var tag_res: TagResource = tag_registry.get(tag_enum, null)
		if tag_res:
			var active_bonuses = tag_res.get_active_chain_bonuses(count)
			if not active_bonuses.is_empty():
				report.active_tag_bonuses[tag_enum] = active_bonuses
				for bonus in active_bonuses:
					_merge_bonus(report, bonus)

	# 5. Evaluate Cross-System Combos (Faction x Tag Intersections)
	_evaluate_cross_system_combos(report)

	return report

static func _merge_bonus(report: SynergyReport, bonus: SynergyBonus) -> void:
	if bonus == null:
		return
	
	# Merge stat modifiers
	for stat_key in bonus.stat_modifiers.keys():
		var stat_type = stat_key as Enums.StatType
		var current_val: float = report.total_stat_modifiers.get(stat_type, 0.0)
		report.total_stat_modifiers[stat_type] = current_val + float(bonus.stat_modifiers[stat_key])
	
	# Register triggers
	if not bonus.trigger_effect_id.is_empty() and not report.registered_triggers.has(bonus.trigger_effect_id):
		report.registered_triggers.append(bonus.trigger_effect_id)

static func _evaluate_cross_system_combos(report: SynergyReport) -> void:
	# Combo 1: Rogue AIs (2+) + Neural (4+) -> "Neural Hivemind Overclock"
	if report.has_active_faction(Enums.Faction.ROGUE_AIS, 2) and report.has_active_tag(Enums.AugmentTag.NEURAL, 4):
		var combo = SynergyBonus.new(
			"combo_ai_neural",
			"Neural Hivemind Overclock",
			"Rogue AIs gain +25% Ability Power and share 20% mana generation with all crew members.",
			4,
			{Enums.StatType.ABILITY_POWER: 25.0},
			"rogue_ai_hivemind_overclock"
		)
		report.cross_system_bonuses.append(combo)
		_merge_bonus(report, combo)

	# Combo 2: Street Runners (2+) + Kinetic (4+) -> "Kinetic Momentum Drive"
	if report.has_active_faction(Enums.Faction.STREET_RUNNERS, 2) and report.has_active_tag(Enums.AugmentTag.KINETIC, 4):
		var combo = SynergyBonus.new(
			"combo_runners_kinetic",
			"Kinetic Momentum Drive",
			"Street Runners gain +20% Speed and +15% Critical Strike Chance.",
			4,
			{Enums.StatType.SPEED: 20.0, Enums.StatType.CRIT_CHANCE: 0.15},
			"kinetic_momentum_drive"
		)
		report.cross_system_bonuses.append(combo)
		_merge_bonus(report, combo)

	# Combo 3: Corp Enforcers (2+) + Thermal (4+) -> "Thermal Armor Lockdown"
	if report.has_active_faction(Enums.Faction.CORP_ENFORCERS, 2) and report.has_active_tag(Enums.AugmentTag.THERMAL, 4):
		var combo = SynergyBonus.new(
			"combo_corp_thermal",
			"Thermal Armor Lockdown",
			"Corp Enforcers gain +30 Armor and burn attackers for 15% damage over 3 seconds.",
			4,
			{Enums.StatType.ARMOR: 30.0},
			"thermal_armor_lockdown"
		)
		report.cross_system_bonuses.append(combo)
		_merge_bonus(report, combo)

	# Combo 4: Fixers (2+) + Viral (4+) -> "Viral Black-Market Contagion"
	if report.has_active_faction(Enums.Faction.FIXERS, 2) and report.has_active_tag(Enums.AugmentTag.VIRAL, 4):
		var combo = SynergyBonus.new(
			"combo_fixers_viral",
			"Viral Black-Market Contagion",
			"Viral triggers spread 50% faster and generate 1 bonus gold on enemy takedown.",
			4,
			{Enums.StatType.ATTACK_SPEED: 0.20},
			"viral_blackmarket_contagion"
		)
		report.cross_system_bonuses.append(combo)
		_merge_bonus(report, combo)

static func calculate_synergy_impact(
	current_crew: Array[UnitInstance],
	prospective_unit: UnitResource,
	faction_registry: Dictionary = {},
	tag_registry: Dictionary = {}
) -> Dictionary:
	var base_report = evaluate_crew(current_crew, faction_registry, tag_registry)
	
	var sim_crew: Array[UnitInstance] = []
	for u in current_crew:
		sim_crew.append(u)
	if prospective_unit:
		sim_crew.append(UnitInstance.new(prospective_unit))
		
	var new_report = evaluate_crew(sim_crew, faction_registry, tag_registry)
	
	var faction_enum = prospective_unit.faction if prospective_unit else Enums.Faction.NONE
	var prev_f_count = base_report.faction_counts.get(faction_enum, 0)
	var new_f_count = new_report.faction_counts.get(faction_enum, 0)
	
	var will_activate = (prev_f_count < 2 and new_f_count >= 2) or (prev_f_count < 4 and new_f_count >= 4) or (prev_f_count < 6 and new_f_count >= 6)
	
	var new_combos: Array[SynergyBonus] = []
	for c in new_report.cross_system_bonuses:
		var found = false
		for old_c in base_report.cross_system_bonuses:
			if old_c.id == c.id:
				found = true
				break
		if not found:
			new_combos.append(c)
			
	return {
		"faction": faction_enum,
		"faction_name": Enums.faction_to_string(faction_enum),
		"prev_count": prev_f_count,
		"new_count": new_f_count,
		"will_activate_threshold": will_activate,
		"new_combos": new_combos,
		"is_duplicate": (prev_f_count == new_f_count and prev_f_count > 0)
	}
