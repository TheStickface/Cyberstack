class_name UnitResource
extends Resource

## Static Data Template for an Operative / Unit

@export var id: String = ""
@export var display_name: String = ""
@export var title: String = ""
@export_multiline var bio: String = ""

@export var role: Enums.UnitRole = Enums.UnitRole.TANK
@export var faction: Enums.Faction = Enums.Faction.NONE
@export var base_cost: int = 3
@export var portrait: Texture2D = null

# Base Combat Stats
@export_group("Base Combat Stats")
@export var base_max_health: float = 650.0
@export var base_attack_damage: float = 45.0
@export var base_ability_power: float = 50.0
@export var base_attack_speed: float = 0.75 # Attacks per second
@export var base_armor: float = 20.0
@export var base_shield: float = 0.0
@export var base_starting_mana: float = 0.0
@export var base_max_mana: float = 100.0
@export var base_speed: float = 50.0       # Initiative order in real-time tick
@export var base_crit_chance: float = 0.05 # 5% default
@export var base_evasion: float = 0.0

# Signature Ability
@export_group("Signature Ability")
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""
@export var ability_effect_id: String = ""

# Directional & Positional Formation Passive
@export_group("Directional Formation Passive")
@export var directional_target: Enums.GridDirection = Enums.GridDirection.NONE
@export var directional_passive_description: String = ""
@export var directional_modifiers: Dictionary = {}


var slot_layout: Array[Enums.SlotType]:
	get:
		return get_slot_types()

func get_slot_types() -> Array[Enums.SlotType]:
	var schema = Constants.ROLE_SLOT_SCHEMAS.get(role, [])
	var result: Array[Enums.SlotType] = []
	for st in schema:
		result.append(st as Enums.SlotType)
	return result

func get_role_name() -> String:
	return Enums.role_to_string(role)

func get_faction_name() -> String:
	return Enums.faction_to_string(faction)

func has_directional() -> bool:
	return directional_target != Enums.GridDirection.NONE

## e.g. "RIGHT" / "ADJACENT" / "SAME COLUMN". Empty when this operative has no
## positional formation passive.
func get_directional_header() -> String:
	if not has_directional():
		return ""
	return Enums.grid_direction_to_string(directional_target).to_upper()

## Stat readout for the positional passive (directional_modifiers), same
## canonical ordering/formatting as AugmentResource.get_stat_lines().
func get_directional_stat_lines() -> Array[String]:
	if not has_directional():
		return []
	return Enums.format_stat_dict(directional_modifiers)

func get_formation_symbol() -> String:
	if has_directional():
		return Enums.grid_direction_to_symbol(directional_target)
	match role:
		Enums.UnitRole.TANK: return "🛡️⮂"
		Enums.UnitRole.HACKER: return "⚡⮂"
		Enums.UnitRole.SNIPER: return "🎯▲"
		_: return ""

## Short badge text for card display, e.g. "⮜ +12 AD", "🛡️ +120 SHD ⮂"
func get_formation_badge_text() -> String:
	if has_directional():
		var sym = get_formation_symbol()
		var compact_stats = ", ".join(Enums.format_stat_dict_compact(directional_modifiers))
		return ("%s %s" % [sym, compact_stats]).strip_edges()
	match role:
		Enums.UnitRole.TANK: return "🛡️ +120 SHD ⮂"
		Enums.UnitRole.HACKER: return "⚡ +15 MP ⮂"
		Enums.UnitRole.SNIPER: return "🎯 +25% CRIT ▲"
		_: return ""

## Full 1-line summary for shop cards and tooltips
func get_formation_full_summary() -> String:
	if has_directional():
		var sym = get_formation_symbol()
		var header = get_directional_header()
		var stats = ", ".join(get_directional_stat_lines())
		if not directional_passive_description.is_empty():
			return "%s %s" % [sym, directional_passive_description]
		return "%s %s: %s" % [sym, header, stats]
	match role:
		Enums.UnitRole.TANK: return "🛡️ GUARD ⮂: +120 Shield to Left & Right allies"
		Enums.UnitRole.HACKER: return "⚡ ROW UPLINK ⮂: +15 Mana & +15% Spd to Row"
		Enums.UnitRole.SNIPER: return "🎯 BACKLINE ▲: +25% Crit in Row 0"
		_: return ""
