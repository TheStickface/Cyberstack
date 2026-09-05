class_name StrategyArchetypes
extends RefCounted

## Named "strategy archetype" definitions shared by StrategyMetricsSimulator
## (measures each archetype's real clear-rate via BalanceSimulator) and
## AutoplayDirector (the live spectator bot, which biases its real shop
## decisions with the same scoring functions). Keeping one scoring
## implementation shared by both is what makes a measured winrate an honest
## prediction of what the live bot will actually do — see
## BalanceSimulator._simulate_shop_purchase's strategy parameter.
##
## Each archetype is a plain Dictionary (not a Resource) because this is
## internal dev-tooling data, not shipped game content:
##   id                 String, unique, snake_case
##   name               String, display name for the overlay
##   description         String, one line for the overlay
##   faction            Enums.Faction (NONE = no faction bias)
##   tag                Enums.AugmentTag (NONE = no tag bias)
##   role_bias          Enums.UnitRole (ANY = no role bias)
##   prioritize_duplicates  bool, true = weight star-up dupes even higher
##   preferred_starters  Array[String] unit ids; empty = any of ALL_STARTER_IDS

const ALL_STARTER_IDS: Array[String] = [
	"runner_blitz", "corp_sentinel", "ai_glitch",
	"fixer_broker", "bio_chimera", "phantom_spectre"
]

const ARCHETYPES: Array[Dictionary] = [
	{
		"id": "street_runner_rush",
		"name": "Street Runner Rush",
		"description": "Mono Street Runner velocity — Adrenaline Surge attack-speed/evasion stacking with Kinetic burst augments.",
		"faction": Enums.Faction.STREET_RUNNERS,
		"tag": Enums.AugmentTag.KINETIC,
		"role_bias": Enums.UnitRole.ANY,
		"prioritize_duplicates": false,
		"preferred_starters": ["runner_blitz"]
	},
	{
		"id": "corp_tank_wall",
		"name": "Corp Enforcer Tank Wall",
		"description": "Mono Corp Enforcer shield wall — Aegis Protocol shield/armor/reflect stacking behind a frontline Tank core.",
		"faction": Enums.Faction.CORP_ENFORCERS,
		"tag": Enums.AugmentTag.NONE,
		"role_bias": Enums.UnitRole.TANK,
		"prioritize_duplicates": false,
		"preferred_starters": ["corp_sentinel"]
	},
	{
		"id": "rogue_ai_neural_control",
		"name": "Rogue AI Neural Control",
		"description": "Mono Rogue AI mana/control — Subnet Sync AP and mana-battery stacking with a Neural-tag chain.",
		"faction": Enums.Faction.ROGUE_AIS,
		"tag": Enums.AugmentTag.NEURAL,
		"role_bias": Enums.UnitRole.HACKER,
		"prioritize_duplicates": false,
		"preferred_starters": ["ai_glitch"]
	},
	{
		"id": "fixer_econ_splash",
		"name": "Fixer Econ Splash",
		"description": "Fixer economy splash — Underworld Network gold/attack-damage stacking, banking free rerolls into a late greedy spike.",
		"faction": Enums.Faction.FIXERS,
		"tag": Enums.AugmentTag.NONE,
		"role_bias": Enums.UnitRole.FIXER,
		"prioritize_duplicates": false,
		"preferred_starters": ["fixer_broker"]
	},
	{
		"id": "bio_hacker_sustain",
		"name": "Bio-Synthetic Sustain",
		"description": "Mono Bio-Synthetic health-stack sustain — Cellular Grafting/Apex Mutation HP and armor stacking with Viral-tag spread.",
		"faction": Enums.Faction.BIO_HACKERS,
		"tag": Enums.AugmentTag.VIRAL,
		"role_bias": Enums.UnitRole.TANK,
		"prioritize_duplicates": false,
		"preferred_starters": ["bio_chimera"]
	},
	{
		"id": "net_phantom_crit_evasion",
		"name": "Net-Phantom Crit/Evasion",
		"description": "Mono Net-Phantom skirmishers — Cloak/Phase Infiltration speed-evasion-crit stacking with Kinetic burst on backline Snipers.",
		"faction": Enums.Faction.NET_PHANTOMS,
		"tag": Enums.AugmentTag.KINETIC,
		"role_bias": Enums.UnitRole.SNIPER,
		"prioritize_duplicates": false,
		"preferred_starters": ["phantom_spectre"]
	},
	{
		"id": "thermal_burn_chain",
		"name": "Thermal Burn Chain",
		"description": "Cross-faction Thermal tag chain — pure burn/DOT payoff stacking regardless of faction identity.",
		"faction": Enums.Faction.NONE,
		"tag": Enums.AugmentTag.THERMAL,
		"role_bias": Enums.UnitRole.ANY,
		"prioritize_duplicates": false,
		"preferred_starters": []
	},
	{
		"id": "viral_spread_chain",
		"name": "Viral Spread Chain",
		"description": "Cross-faction Viral tag chain — attack-speed/spread payoff stacking regardless of faction identity.",
		"faction": Enums.Faction.NONE,
		"tag": Enums.AugmentTag.VIRAL,
		"role_bias": Enums.UnitRole.ANY,
		"prioritize_duplicates": false,
		"preferred_starters": []
	},
	{
		"id": "sniper_backline_turtle",
		"name": "Sniper Backline Turtle",
		"description": "Placement-first — backline Snipers behind whatever frontline is available; role fit and grid position over faction/tag purity.",
		"faction": Enums.Faction.NONE,
		"tag": Enums.AugmentTag.NONE,
		"role_bias": Enums.UnitRole.SNIPER,
		"prioritize_duplicates": false,
		"preferred_starters": []
	},
	{
		"id": "greedy_star_up_econ",
		"name": "Greedy Star-Up Econ",
		"description": "Econ-greedy 3-star rush — prioritizes duplicating and star-upping whatever's already fielded over widening the roster.",
		"faction": Enums.Faction.NONE,
		"tag": Enums.AugmentTag.NONE,
		"role_bias": Enums.UnitRole.ANY,
		"prioritize_duplicates": true,
		"preferred_starters": []
	}
]

static func get_by_id(id: String) -> Dictionary:
	for a in ARCHETYPES:
		if a["id"] == id:
			return a
	return {}

## Scores how well a shop-offered (or repo-pool) unit fits a strategy.
## crew_context may carry "existing_ids" (Dictionary of unit_resource.id ->
## true for units already fielded/benched) so a duplicate — a star-up
## opportunity — scores higher than a fresh recruit.
static func score_unit(unit_res: UnitResource, strategy: Dictionary, crew_context: Dictionary = {}) -> float:
	if unit_res == null:
		return 0.0
	var score := 1.0
	var want_faction = strategy.get("faction", Enums.Faction.NONE)
	var want_role = strategy.get("role_bias", Enums.UnitRole.ANY)
	if want_faction != Enums.Faction.NONE and unit_res.faction == want_faction:
		score += 3.0
	if want_role != Enums.UnitRole.ANY and unit_res.role == want_role:
		score += 1.5
	var existing_ids: Dictionary = crew_context.get("existing_ids", {})
	if existing_ids.has(unit_res.id):
		var dupe_bonus = 6.0 if strategy.get("prioritize_duplicates", false) else 4.0
		score += dupe_bonus
	return score

## Scores how well a shop-offered (or repo-pool) augment fits a strategy.
static func score_augment(aug_res: AugmentResource, strategy: Dictionary) -> float:
	if aug_res == null:
		return 0.0
	var score := 1.0
	var want_tag = strategy.get("tag", Enums.AugmentTag.NONE)
	if want_tag != Enums.AugmentTag.NONE and aug_res.has_tag(want_tag):
		score += 3.0
	if aug_res.tier == Enums.AugmentTier.LEGENDARY:
		score += 1.0
	elif aug_res.tier == Enums.AugmentTier.RARE:
		score += 0.5
	return score

## Computes a short, human-readable "what this strategy wants next" readout
## against the crew's current state — the live bot's secondary overlay so a
## viewer can confirm its logic against what it actually buys.
static func describe_wants(strategy: Dictionary, crew_mgr: Object) -> Array[String]:
	var wants: Array[String] = []
	var want_faction = strategy.get("faction", Enums.Faction.NONE)
	var want_tag = strategy.get("tag", Enums.AugmentTag.NONE)
	var want_role = strategy.get("role_bias", Enums.UnitRole.ANY)

	if want_faction != Enums.Faction.NONE:
		var count := 0
		for u in crew_mgr.fielded_units:
			if u and u.unit_resource and u.unit_resource.faction == want_faction:
				count += 1
		var next_threshold := 2
		if count >= 4:
			next_threshold = 6
		elif count >= 2:
			next_threshold = 4
		wants.append("Another %s operative (%d/%d toward next threshold)" % [
			Enums.faction_to_string(want_faction), count, next_threshold
		])

	if want_tag != Enums.AugmentTag.NONE:
		var tag_count := 0
		for u in crew_mgr.fielded_units:
			for a in u.equipped_augments:
				if a and a.has_tag(want_tag):
					tag_count += 1
		wants.append("A %s-tagged augment (has %d equipped)" % [Enums.tag_to_string(want_tag), tag_count])

	if want_role != Enums.UnitRole.ANY:
		var has_role := false
		for u in crew_mgr.fielded_units:
			if u and u.unit_resource and u.unit_resource.role == want_role:
				has_role = true
				break
		if not has_role:
			wants.append("A %s-role operative for the core plan" % Enums.role_to_string(want_role))

	if strategy.get("prioritize_duplicates", false):
		wants.append("A duplicate of an already-fielded unit to star it up")

	if wants.is_empty():
		wants.append("Whatever scores best this shop (no strict faction/tag lock)")

	return wants
