class_name Enums
extends RefCounted

## Global enumeration definitions for Cyberstack

enum Faction {
	NONE,
	STREET_RUNNERS,
	CORP_ENFORCERS,
	ROGUE_AIS,
	FIXERS
}

enum AugmentTag {
	NONE,
	VIRAL,
	THERMAL,
	NEURAL,
	KINETIC
}

enum AugmentTier {
	COMMON,     # Blue: Single stat boost + tag carrier
	RARE,       # Purple: Tag + conditional trigger effect
	LEGENDARY   # Red: Tag + powerful activated/cross-unit effect
}

enum SlotType {
	DEFENSIVE,
	UTILITY,
	OFFENSIVE,
	PASSIVE,
	FLEX
}

enum UnitRole {
	TANK,       # 2 defensive slots, 1 passive
	HACKER,     # 2 utility slots, 1 passive
	SNIPER,     # 2 offensive slots, 1 passive
	FIXER,      # 1 offensive, 1 utility, 1 passive
	ANY
}

enum StatType {
	MAX_HEALTH,
	ATTACK_DAMAGE,
	ABILITY_POWER,
	ATTACK_SPEED,
	ARMOR,
	SHIELD,
	STARTING_MANA,
	MAX_MANA,
	CRIT_CHANCE,
	SPEED,
	EVASION
}

enum TriggerType {
	PASSIVE_STAT,
	ON_COMBAT_START,
	ON_ATTACK,
	ON_HIT,
	ON_KILL,
	ON_ABILITY_CAST,
	ON_ALLY_TAG_TRIGGER,
	ON_DAMAGE_TAKEN,
	ON_HEALTH_BELOW_THRESHOLD
}

enum EncounterType {
	FIGHT,
	SHOP,
	EVENT,
	BOSS
}

enum EventRewardType {
	GOLD,
	AUGMENT,
	STAT_BUFF,
	REPAIR_HEALTH,
	COMBAT_ENCOUNTER
}

static func faction_to_string(faction: Faction) -> String:
	match faction:
		Faction.STREET_RUNNERS: return "Street Runners"
		Faction.CORP_ENFORCERS: return "Corp Enforcers"
		Faction.ROGUE_AIS: return "Rogue AIs"
		Faction.FIXERS: return "Fixers"
		_: return "None"

static func string_to_faction(str_val: String) -> Faction:
	var clean = str_val.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match clean:
		"street_runners", "runners": return Faction.STREET_RUNNERS
		"corp_enforcers", "enforcers", "corp": return Faction.CORP_ENFORCERS
		"rogue_ais", "rogue_ai", "ais", "ai": return Faction.ROGUE_AIS
		"fixers", "fixer": return Faction.FIXERS
		_: return Faction.NONE

static func tag_to_string(tag: AugmentTag) -> String:
	match tag:
		AugmentTag.VIRAL: return "Viral"
		AugmentTag.THERMAL: return "Thermal"
		AugmentTag.NEURAL: return "Neural"
		AugmentTag.KINETIC: return "Kinetic"
		_: return "None"

static func string_to_tag(str_val: String) -> AugmentTag:
	var clean = str_val.strip_edges().to_lower()
	match clean:
		"viral": return AugmentTag.VIRAL
		"thermal": return AugmentTag.THERMAL
		"neural": return AugmentTag.NEURAL
		"kinetic": return AugmentTag.KINETIC
		_: return AugmentTag.NONE

static func role_to_string(role: UnitRole) -> String:
	match role:
		UnitRole.TANK: return "Tank"
		UnitRole.HACKER: return "Hacker"
		UnitRole.SNIPER: return "Sniper"
		UnitRole.FIXER: return "Fixer"
		_: return "Any"

static func slot_type_to_string(st: SlotType) -> String:
	match st:
		SlotType.DEFENSIVE: return "Defensive"
		SlotType.UTILITY: return "Utility"
		SlotType.OFFENSIVE: return "Offensive"
		SlotType.PASSIVE: return "Passive"
		SlotType.FLEX: return "Flex"
		_: return "Flex"

static func tier_to_string(tier: AugmentTier) -> String:
	match tier:
		AugmentTier.COMMON: return "Common"
		AugmentTier.RARE: return "Rare"
		AugmentTier.LEGENDARY: return "Legendary"
		_: return "Common"

static func tier_to_color_hex(tier: AugmentTier) -> String:
	match tier:
		AugmentTier.COMMON: return "#00b4d8"    # Electric Blue
		AugmentTier.RARE: return "#8338ec"      # Electric Purple
		AugmentTier.LEGENDARY: return "#ff006e" # Neon Red / Hot Pink
		_: return "#ffffff"

static func encounter_to_string(enc: EncounterType) -> String:
	match enc:
		EncounterType.FIGHT: return "Fight"
		EncounterType.SHOP: return "Shop"
		EncounterType.EVENT: return "Event"
		EncounterType.BOSS: return "Boss"
		_: return "Unknown"

static func stat_to_string(stat: StatType) -> String:
	match stat:
		StatType.MAX_HEALTH: return "Max Health"
		StatType.ATTACK_DAMAGE: return "Attack Damage"
		StatType.ABILITY_POWER: return "Ability Power"
		StatType.ATTACK_SPEED: return "Attack Speed"
		StatType.ARMOR: return "Armor"
		StatType.SHIELD: return "Shield"
		StatType.STARTING_MANA: return "Starting Mana"
		StatType.MAX_MANA: return "Max Mana"
		StatType.CRIT_CHANCE: return "Crit Chance"
		StatType.SPEED: return "Speed"
		StatType.EVASION: return "Evasion"
		_: return "Stat"

static func trigger_to_string(trigger: TriggerType) -> String:
	match trigger:
		TriggerType.PASSIVE_STAT: return "Passive Stat"
		TriggerType.ON_COMBAT_START: return "On Combat Start"
		TriggerType.ON_ATTACK: return "On Attack"
		TriggerType.ON_HIT: return "On Hit"
		TriggerType.ON_KILL: return "On Kill"
		TriggerType.ON_ABILITY_CAST: return "On Ability Cast"
		TriggerType.ON_ALLY_TAG_TRIGGER: return "On Ally Tag Trigger"
		TriggerType.ON_DAMAGE_TAKEN: return "On Damage Taken"
		TriggerType.ON_HEALTH_BELOW_THRESHOLD: return "On Health Below Threshold"
		_: return "None"
