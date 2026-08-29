class_name Constants
extends RefCounted

## Global balance and system constants for Cyberstack

# Crew & Slot Configuration
const MAX_AUGMENT_SLOTS_PER_UNIT: int = 3
const MAX_BENCH_UNITS: int = 8
const MAX_BENCH_AUGMENTS: int = 10
const MAX_INVENTORY_AUGMENTS: int = 10

# District Crew Limits
const DISTRICT_CREW_LIMITS: Dictionary = {
	1: 2,
	2: 4,
	3: 5,
	4: 6,
	5: 6
}

# Number of non-final districts drawn from the pool per run, before the final-boss district.
const NORMAL_DISTRICTS_PER_RUN: int = 3

# Faction & Tag Synergies
const FACTION_THRESHOLDS: Array[int] = [2, 4, 6]
const TAG_CHAIN_THRESHOLDS: Array[int] = [2, 4, 6]

# Role Slot Schemas (Defines the 3 slot types for each role)
const ROLE_SLOT_SCHEMAS: Dictionary = {
	Enums.UnitRole.TANK: [
		Enums.SlotType.DEFENSIVE,
		Enums.SlotType.DEFENSIVE,
		Enums.SlotType.PASSIVE
	],
	Enums.UnitRole.HACKER: [
		Enums.SlotType.UTILITY,
		Enums.SlotType.UTILITY,
		Enums.SlotType.PASSIVE
	],
	Enums.UnitRole.SNIPER: [
		Enums.SlotType.OFFENSIVE,
		Enums.SlotType.OFFENSIVE,
		Enums.SlotType.PASSIVE
	],
	Enums.UnitRole.FIXER: [
		Enums.SlotType.OFFENSIVE,
		Enums.SlotType.UTILITY,
		Enums.SlotType.PASSIVE
	]
}

# Economy & Shop Settings
const CURRENCY_NAME: String = "Credits"
const CURRENCY_NAME_SHORT: String = "CR"
const CURRENCY_SYMBOL: String = "¢"

static func format_currency(amount: int, short: bool = false) -> String:
	if short:
		return "%d %s" % [amount, CURRENCY_NAME_SHORT]
	return "%d %s" % [amount, CURRENCY_NAME]

static func format_cost(amount: int) -> String:
	return "%d %s" % [amount, CURRENCY_NAME.to_upper()]

const DEFAULT_STARTING_GOLD: int = 12
const BASE_REROLL_COST: int = 2
const DEFAULT_CREW_SHOP_SLOTS: int = 5
const MAX_CREW_SHOP_SLOTS: int = 7
const DEFAULT_AUGMENT_SHOP_SLOTS: int = 2
const MAX_AUGMENT_SHOP_SLOTS: int = 5
const SHOP_SLOTS_COUNT: int = 7

# Base Encounter Credit Payouts per District (Active Spend Economy - No Interest)
const DISTRICT_ENCOUNTER_PAYOUTS: Dictionary = {
	1: 4,
	2: 6,
	3: 8,
	4: 10,
	5: 12
}

# District Shop Rarity Probabilities (Common, Rare, Legendary)
const DISTRICT_SHOP_ODDS: Dictionary = {
	1: {
		Enums.AugmentTier.COMMON: 1.00,
		Enums.AugmentTier.RARE: 0.00,
		Enums.AugmentTier.LEGENDARY: 0.00
	},
	2: {
		Enums.AugmentTier.COMMON: 0.70,
		Enums.AugmentTier.RARE: 0.30,
		Enums.AugmentTier.LEGENDARY: 0.00
	},
	3: {
		Enums.AugmentTier.COMMON: 0.35,
		Enums.AugmentTier.RARE: 0.45,
		Enums.AugmentTier.LEGENDARY: 0.20
	},
	4: {
		Enums.AugmentTier.COMMON: 0.10,
		Enums.AugmentTier.RARE: 0.50,
		Enums.AugmentTier.LEGENDARY: 0.40
	},
	5: {
		Enums.AugmentTier.COMMON: 0.05,
		Enums.AugmentTier.RARE: 0.40,
		Enums.AugmentTier.LEGENDARY: 0.55
	}
}

# District Unit Shop Odds (Cost 1-2 CR: Tier 1, Cost 3-4 CR: Tier 2, Cost 5 CR: Tier 3)
const DISTRICT_UNIT_SHOP_ODDS: Dictionary = {
	1: { 1: 1.00, 2: 0.00, 3: 0.00 },
	2: { 1: 0.60, 2: 0.35, 3: 0.05 },
	3: { 1: 0.30, 2: 0.45, 3: 0.25 },
	4: { 1: 0.15, 2: 0.45, 3: 0.40 },
	5: { 1: 0.05, 2: 0.35, 3: 0.60 }
}

# Enemy Stat Scaling Multipliers per District (HP, Damage)
const DISTRICT_ENEMY_SCALING: Dictionary = {
	1: { "hp_mult": 1.00, "dmg_mult": 1.00 },
	2: { "hp_mult": 1.20, "dmg_mult": 1.15 },
	3: { "hp_mult": 1.75, "dmg_mult": 1.45 },
	4: { "hp_mult": 2.25, "dmg_mult": 1.70 },
	5: { "hp_mult": 2.50, "dmg_mult": 1.85 }
}

# Sell Refund Values
const AUGMENT_SELL_VALUES: Dictionary = {
	Enums.AugmentTier.COMMON: 1,
	Enums.AugmentTier.RARE: 2,
	Enums.AugmentTier.LEGENDARY: 4
}

# Visual Colors (Cyberpunk Palette)
const COLOR_CYBER_BG: Color = Color("#05040f")
const COLOR_NEON_PURPLE: Color = Color("#6e00ff")
const COLOR_ELECTRIC_BLUE: Color = Color("#00b4d8")
const COLOR_HOT_PINK: Color = Color("#ff006e")
const COLOR_CYAN_ACCENT: Color = Color("#00f5d4")
