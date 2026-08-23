class_name Constants
extends RefCounted

## Global balance and system constants for Cyberstack

# Crew & Slot Configuration
const MAX_AUGMENT_SLOTS_PER_UNIT: int = 3
const MAX_BENCH_UNITS: int = 8
const MAX_BENCH_AUGMENTS: int = 10

# District Crew Limits
const DISTRICT_CREW_LIMITS: Dictionary = {
	1: 2,
	2: 4,
	3: 5,
	4: 6
}

# Number of non-final districts drawn from the pool per run, before the final-boss district.
# Total run length stays at 4 (matching DISTRICT_CREW_LIMITS / DISTRICT_SHOP_ODDS) until
# 3-vs-4-district run-length variance gets its own scaling curve designed.
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
const DEFAULT_STARTING_GOLD: int = 10
const BASE_REROLL_COST: int = 2
const SHOP_SLOTS_COUNT: int = 4

# Base Encounter Credit Payouts per District (Active Spend Economy - No Interest)
const DISTRICT_ENCOUNTER_PAYOUTS: Dictionary = {
	1: 4,
	2: 6,
	3: 8,
	4: 10
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
		Enums.AugmentTier.COMMON: 0.50,
		Enums.AugmentTier.RARE: 0.40,
		Enums.AugmentTier.LEGENDARY: 0.10
	},
	4: {
		Enums.AugmentTier.COMMON: 0.00,
		Enums.AugmentTier.RARE: 0.65,
		Enums.AugmentTier.LEGENDARY: 0.35
	}
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
