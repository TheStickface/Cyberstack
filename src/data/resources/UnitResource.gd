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
