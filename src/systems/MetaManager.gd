class_name MetaManager
extends RefCounted

## Manages lifetime Faction Reputation progression, operative unlocks, and Codex archives

const LEVEL_THRESHOLDS: Dictionary = {
	1: 0,
	2: 100,
	3: 250,
	4: 500
}

# Unlocks granted when reaching Level 2 for each faction
const FACTION_LEVEL_2_OPERATIVES: Dictionary = {
	Enums.Faction.STREET_RUNNERS: "street_ghost",
	Enums.Faction.CORP_ENFORCERS: "corp_sentinel",
	Enums.Faction.ROGUE_AIS: "ai_glitch",
	Enums.Faction.FIXERS: "fixer_broker",
	Enums.Faction.BIO_HACKERS: "bio_chimera",
	Enums.Faction.NET_PHANTOMS: "phantom_spectre"
}

static func get_faction_level(points: int) -> int:
	if points >= LEVEL_THRESHOLDS[4]:
		return 4
	elif points >= LEVEL_THRESHOLDS[3]:
		return 3
	elif points >= LEVEL_THRESHOLDS[2]:
		return 2
	return 1

static func get_points_for_next_level(points: int) -> int:
	var cur_lvl = get_faction_level(points)
	if cur_lvl >= 4:
		return LEVEL_THRESHOLDS[4]
	return LEVEL_THRESHOLDS[cur_lvl + 1]

static func process_run_end(profile: MetaProfile, run_summary: Dictionary, crew: Array[UnitInstance]) -> Dictionary:
	if profile == null:
		return {}
		
	profile.total_runs_played += 1
	var victory = run_summary.get("victory", false)
	if victory:
		profile.total_victories += 1
		
	var district = run_summary.get("district", 1)
	var fights = run_summary.get("fights_won", 0)
	var bosses = run_summary.get("bosses_defeated", 0)
	var gold = run_summary.get("gold_earned", 0)
	
	profile.total_bosses_defeated += bosses
	profile.total_credits_earned += gold
	
	# Calculate Reputation Points
	var base_rep = (district * 25) + (fights * 10) + (bosses * 50) + (100 if victory else 0)
	
	# Determine fielded factions
	var active_factions: Array[Enums.Faction] = []
	for unit in crew:
		if unit and unit.unit_resource and unit.unit_resource.faction != Enums.Faction.NONE:
			if not active_factions.has(unit.unit_resource.faction):
				active_factions.append(unit.unit_resource.faction)
				
	# If no specific faction fielded, distribute to Street Runners
	if active_factions.is_empty():
		active_factions.append(Enums.Faction.STREET_RUNNERS)
		
	var points_per_faction = int(base_rep / active_factions.size())
	var newly_unlocked_units: Array[String] = []
	var reputation_gains: Dictionary = {}
	
	for faction in active_factions:
		var current_pts = profile.faction_reputation.get(faction, 0)
		var new_pts = current_pts + points_per_faction
		profile.faction_reputation[faction] = new_pts
		reputation_gains[faction] = points_per_faction
		
		# Check if level 2 unlock triggered
		var prev_lvl = get_faction_level(current_pts)
		var new_lvl = get_faction_level(new_pts)
		
		if new_lvl >= 2 and prev_lvl < 2:
			var unlock_unit = FACTION_LEVEL_2_OPERATIVES.get(faction, "")
			if not unlock_unit.is_empty() and not profile.unlocked_operatives.has(unlock_unit):
				profile.unlocked_operatives.append(unlock_unit)
				newly_unlocked_units.append(unlock_unit)
				
	# Record equipped augments into Codex
	for unit in crew:
		if unit:
			for aug in unit.get_equipped_augments():
				if aug and not profile.discovered_augments.has(aug.id):
					profile.discovered_augments.append(aug.id)
					
	SaveManager.save_profile(profile)
	SaveManager.delete_active_run()
	
	return {
		"total_rep_earned": base_rep,
		"reputation_gains": reputation_gains,
		"new_unlocks": newly_unlocked_units
	}

static func is_operative_unlocked(profile: MetaProfile, unit_id: String) -> bool:
	if profile == null:
		return false
	return profile.unlocked_operatives.has(unit_id)
