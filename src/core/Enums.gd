class_name Enums
extends RefCounted

## Global enumeration definitions for Cyberstack

enum Faction {
	NONE,
	STREET_RUNNERS,
	CORP_ENFORCERS,
	ROGUE_AIS,
	FIXERS,
	BIO_HACKERS,
	NET_PHANTOMS
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
	MEATSHIELD, # 1 offensive, 1 defensive, 1 passive
	COMMANDER,  # 1 defensive, 1 utility, 1 passive
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
		Faction.BIO_HACKERS: return "Bio-Synthetics"
		Faction.NET_PHANTOMS: return "Net-Phantoms"
		_: return "None"

static func string_to_faction(str_val: String) -> Faction:
	var clean = str_val.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match clean:
		"street_runners", "runners": return Faction.STREET_RUNNERS
		"corp_enforcers", "enforcers", "corp": return Faction.CORP_ENFORCERS
		"rogue_ais", "rogue_ai", "ais", "ai": return Faction.ROGUE_AIS
		"fixers", "fixer": return Faction.FIXERS
		"bio_hackers", "bio_synthetics", "bio", "synthetics": return Faction.BIO_HACKERS
		"net_phantoms", "phantoms", "phantom", "ghosts": return Faction.NET_PHANTOMS
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
		UnitRole.MEATSHIELD: return "Meatshield"
		UnitRole.COMMANDER: return "Commander"
		_: return "Any"

static func string_to_role(str_val: String) -> UnitRole:
	var clean = str_val.strip_edges().to_lower().replace(" ", "_").replace("-", "_")
	match clean:
		"tank": return UnitRole.TANK
		"hacker": return UnitRole.HACKER
		"sniper": return UnitRole.SNIPER
		"fixer": return UnitRole.FIXER
		"meatshield", "meat_shield", "brawler": return UnitRole.MEATSHIELD
		"commander", "commanders", "warden": return UnitRole.COMMANDER
		_: return UnitRole.ANY

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

## Stats stored as a 0-1 fraction (e.g. 0.20 = 20%) rather than a flat value.
static func is_percent_stat(stat: StatType) -> bool:
	return stat == StatType.ATTACK_SPEED or stat == StatType.CRIT_CHANCE or stat == StatType.EVASION

## Formats a stat_modifiers value into a signed display string, e.g. "+12" or "+20%".
static func format_stat_value(stat: StatType, value: float) -> String:
	var sign_str := "+" if value >= 0.0 else "-"
	if is_percent_stat(stat):
		return "%s%d%%" % [sign_str, roundi(abs(value) * 100.0)]
	return "%s%d" % [sign_str, roundi(abs(value))]

## Formats a StatType(int)->float dict (stat_modifiers / directional_modifiers
## shape) into display lines in canonical StatType-ordinal order, e.g.
## ["+12 Attack Damage", "+15% Crit Chance"]. Shared by AugmentResource and
## UnitResource so every surface lists a given stat dict identically.
static func format_stat_dict(mods: Dictionary) -> Array[String]:
	var keys = mods.keys()
	keys.sort()
	var lines: Array[String] = []
	for k in keys:
		var stat: StatType = k as int as StatType
		lines.append("%s %s" % [format_stat_value(stat, float(mods[k])), stat_to_string(stat)])
	return lines

static func trigger_to_string(trigger: TriggerType) -> String:
	match trigger:
		TriggerType.PASSIVE_STAT: return ""
		TriggerType.ON_COMBAT_START: return "On Combat Start"
		TriggerType.ON_ATTACK: return "On Attack"
		TriggerType.ON_HIT: return "On Hit"
		TriggerType.ON_KILL: return "On Kill"
		TriggerType.ON_ABILITY_CAST: return "On Ability Cast"
		TriggerType.ON_ALLY_TAG_TRIGGER: return "On Ally Tag Trigger"
		TriggerType.ON_DAMAGE_TAKEN: return "On Damage Taken"
		TriggerType.ON_HEALTH_BELOW_THRESHOLD: return "On Health Below Threshold"
		_: return "Trigger"

enum GridDirection {
	NONE,
	LEFT,
	RIGHT,
	ABOVE,
	BELOW,
	ADJACENT,
	SAME_ROW,
	SAME_COLUMN,
	ALL_UNITS,
	FRONTLINE,
	BACKLINE
}

static func grid_direction_to_string(dir: GridDirection) -> String:
	match dir:
		GridDirection.LEFT: return "Left"
		GridDirection.RIGHT: return "Right"
		GridDirection.ABOVE: return "Above"
		GridDirection.BELOW: return "Below"
		GridDirection.ADJACENT: return "Adjacent"
		GridDirection.SAME_ROW: return "Same Row"
		GridDirection.SAME_COLUMN: return "Same Column"
		GridDirection.ALL_UNITS: return "All Units"
		GridDirection.FRONTLINE: return "Frontline"
		GridDirection.BACKLINE: return "Backline"
		_: return "None"

static func grid_direction_to_symbol(dir: GridDirection) -> String:
	match dir:
		GridDirection.LEFT: return "⮜"
		GridDirection.RIGHT: return "⮞"
		GridDirection.ABOVE: return "▲"
		GridDirection.BELOW: return "▼"
		GridDirection.ADJACENT: return "⯎"
		GridDirection.SAME_ROW: return "⮂"
		GridDirection.SAME_COLUMN: return "⯯"
		GridDirection.ALL_UNITS: return "★"
		GridDirection.FRONTLINE: return "▼"
		GridDirection.BACKLINE: return "▲"
		_: return ""

static func stat_to_short_string(stat: StatType) -> String:
	match stat:
		StatType.MAX_HEALTH: return "HP"
		StatType.ATTACK_DAMAGE: return "AD"
		StatType.ABILITY_POWER: return "AP"
		StatType.ATTACK_SPEED: return "AS"
		StatType.ARMOR: return "ARM"
		StatType.SHIELD: return "SHD"
		StatType.STARTING_MANA: return "MP"
		StatType.MAX_MANA: return "Max MP"
		StatType.CRIT_CHANCE: return "Crit"
		StatType.SPEED: return "SPD"
		StatType.EVASION: return "EVA"
		_: return "Stat"

## Formats stat modifiers dict compactly e.g. ["+12 AD", "+15% Crit"]
static func format_stat_dict_compact(mods: Dictionary) -> Array[String]:
	var keys = mods.keys()
	keys.sort()
	var lines: Array[String] = []
	for k in keys:
		var stat: StatType = k as int as StatType
		var val = float(mods[k])
		var sign_str := "+" if val >= 0.0 else "-"
		if is_percent_stat(stat):
			lines.append("%s%d%% %s" % [sign_str, roundi(abs(val) * 100.0), stat_to_short_string(stat)])
		else:
			lines.append("%s%d %s" % [sign_str, roundi(abs(val)), stat_to_short_string(stat)])
	return lines

