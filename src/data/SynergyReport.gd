class_name SynergyReport
extends RefCounted

## Report containing the results of crew synergy evaluations

## Number of unique operatives per faction: Faction (int) -> count (int)
var faction_counts: Dictionary = {}

## Active SynergyBonus items per faction: Faction (int) -> Array[SynergyBonus]
var active_faction_bonuses: Dictionary = {}

## Total augment tag occurrences across all equipped gear: AugmentTag (int) -> count (int)
var tag_counts: Dictionary = {}

## Active SynergyBonus items per tag chain: AugmentTag (int) -> Array[SynergyBonus]
var active_tag_bonuses: Dictionary = {}

## Special Faction x Tag combo bonuses triggered
var cross_system_bonuses: Array[SynergyBonus] = []

## Aggregated stat modifiers to be applied to all crew members
## StatType (int) -> float
var total_stat_modifiers: Dictionary = {}

## All unique trigger effect IDs registered for combat
var registered_triggers: Array[String] = []

func has_active_faction(faction: Enums.Faction, min_count: int = 2) -> bool:
	return faction_counts.get(faction, 0) >= min_count

func has_active_tag(tag: Enums.AugmentTag, min_count: int = 2) -> bool:
	return tag_counts.get(tag, 0) >= min_count

func get_faction_bonus_count(faction: Enums.Faction) -> int:
	var bonuses = active_faction_bonuses.get(faction, [])
	return (bonuses as Array).size()

func get_tag_bonus_count(tag: Enums.AugmentTag) -> int:
	var bonuses = active_tag_bonuses.get(tag, [])
	return (bonuses as Array).size()

func get_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	for f in faction_counts.keys():
		var count = faction_counts[f]
		if count > 0:
			var f_name = Enums.faction_to_string(f as Enums.Faction)
			var b_count = get_faction_bonus_count(f as Enums.Faction)
			lines.append("Faction %s: %d units (%d active bonuses)" % [f_name, count, b_count])
			
	for t in tag_counts.keys():
		var count = tag_counts[t]
		if count > 0:
			var t_name = Enums.tag_to_string(t as Enums.AugmentTag)
			var b_count = get_tag_bonus_count(t as Enums.AugmentTag)
			lines.append("Tag %s: %d count (%d active chain bonuses)" % [t_name, count, b_count])
			
	if not cross_system_bonuses.is_empty():
		lines.append("Cross-System Combos: %d active" % cross_system_bonuses.size())
		
	return lines
