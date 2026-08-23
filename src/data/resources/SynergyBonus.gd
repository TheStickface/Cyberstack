class_name SynergyBonus
extends Resource

## Structured bonus container for Faction thresholds, Tag chains, and Cross-system combos

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var required_count: int = 2

## Dictionary of StatType (int) -> modifier (float)
## Positive values add flat or percentage modifiers (e.g. {Enums.StatType.ATTACK_SPEED: 0.15})
@export var stat_modifiers: Dictionary = {}

## Custom trigger identifier (e.g. "viral_chain_overload", "rogue_ai_overclock")
@export var trigger_effect_id: String = ""

## Optional custom script path implementing specific trigger behavior
@export var custom_effect_script: Script = null

func _init(p_id: String = "", p_name: String = "", p_desc: String = "", p_req: int = 2, p_stats: Dictionary = {}, p_trigger: String = "") -> void:
	id = p_id
	name = p_name
	description = p_desc
	required_count = p_req
	stat_modifiers = p_stats
	trigger_effect_id = p_trigger
