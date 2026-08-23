class_name MetaProfile
extends RefCounted

## Lifetime player meta profile holding career stats, faction reputation, and codex unlocks

var total_runs_played: int = 0
var total_victories: int = 0
var total_bosses_defeated: int = 0
var total_credits_earned: int = 0

# Faction (int) -> reputation points (int)
var faction_reputation: Dictionary = {
	Enums.Faction.STREET_RUNNERS: 0,
	Enums.Faction.CORP_ENFORCERS: 0,
	Enums.Faction.ROGUE_AIS: 0,
	Enums.Faction.FIXERS: 0
}

# Unlocked starting operatives (IDs)
var unlocked_operatives: Array[String] = [
	"runner_blitz",
	"corp_sentinel",
	"ai_glitch",
	"fixer_broker"
]

# Discovered items in Codex
var discovered_augments: Array[String] = []
var discovered_combos: Array[String] = []

func to_dict() -> Dictionary:
	var rep_dict: Dictionary = {}
	for f in faction_reputation.keys():
		rep_dict[str(f)] = faction_reputation[f]
		
	return {
		"total_runs_played": total_runs_played,
		"total_victories": total_victories,
		"total_bosses_defeated": total_bosses_defeated,
		"total_credits_earned": total_credits_earned,
		"faction_reputation": rep_dict,
		"unlocked_operatives": unlocked_operatives,
		"discovered_augments": discovered_augments,
		"discovered_combos": discovered_combos
	}

func from_dict(data: Dictionary) -> void:
	total_runs_played = data.get("total_runs_played", 0)
	total_victories = data.get("total_victories", 0)
	total_bosses_defeated = data.get("total_bosses_defeated", 0)
	total_credits_earned = data.get("total_credits_earned", 0)
	
	var rep_dict = data.get("faction_reputation", {})
	for f_str in rep_dict.keys():
		var f_key = int(f_str) as Enums.Faction
		faction_reputation[f_key] = int(rep_dict[f_str])
		
	unlocked_operatives.clear()
	for u in data.get("unlocked_operatives", ["runner_blitz", "corp_sentinel", "ai_glitch", "fixer_broker"]):
		unlocked_operatives.append(str(u))
		
	discovered_augments.clear()
	for a in data.get("discovered_augments", []):
		discovered_augments.append(str(a))
		
	discovered_combos.clear()
	for c in data.get("discovered_combos", []):
		discovered_combos.append(str(c))
