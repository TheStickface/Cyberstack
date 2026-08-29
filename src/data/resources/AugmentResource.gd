class_name AugmentResource
extends Resource

## Data Resource for an Augment Item that can be slotted into an operative

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var tier: Enums.AugmentTier = Enums.AugmentTier.COMMON
@export var slot_type: Enums.SlotType = Enums.SlotType.PASSIVE
@export var tags: Array[Enums.AugmentTag] = []
@export var base_cost: int = 3
@export var icon: Texture2D = null

## Stat boosts provided by this augment directly to the equipped unit
## Dictionary of Enums.StatType (int) -> float
@export var stat_modifiers: Dictionary = {}

## Directional formation synergy (e.g. grants buffs to adjacent units, same row, or backline)
@export var directional_target: Enums.GridDirection = Enums.GridDirection.NONE
@export var directional_modifiers: Dictionary = {}

## Trigger configuration for Rare and Legendary augments
@export var trigger_type: Enums.TriggerType = Enums.TriggerType.PASSIVE_STAT
@export var trigger_effect_id: String = ""
@export var trigger_params: Dictionary = {}


func has_tag(tag: Enums.AugmentTag) -> bool:
	return tags.has(tag)

func can_equip_in_slot(target_slot_type: Enums.SlotType) -> bool:
	if slot_type == Enums.SlotType.FLEX or target_slot_type == Enums.SlotType.FLEX:
		return true
	return slot_type == target_slot_type

func get_tier_color_hex() -> String:
	return Enums.tier_to_color_hex(tier)

func get_tier_name() -> String:
	return Enums.tier_to_string(tier)
