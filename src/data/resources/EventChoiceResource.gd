class_name EventChoiceResource
extends Resource

## Data resource representing an actionable choice within a Narrative Event vignette

@export var text: String = ""
@export_multiline var outcome_description: String = ""

# Requirements to take this choice
@export_group("Requirements")
@export var required_gold: int = 0
@export var required_role: Enums.UnitRole = Enums.UnitRole.ANY
@export var required_faction: Enums.Faction = Enums.Faction.NONE

# Rewards & Consequences
@export_group("Outcome Payload")
@export var reward_type: Enums.EventRewardType = Enums.EventRewardType.GOLD
@export var reward_gold: int = 0
@export var reward_augment: AugmentResource = null
@export var reward_stat_modifiers: Dictionary = {}
@export var penalty_gold: int = 0
@export var penalty_health_cost: float = 0.0
@export var triggers_combat: bool = false
@export var combat_enemy_id: String = ""

func is_available(player_gold: int, crew: Array[UnitInstance]) -> bool:
	if required_gold > 0 and player_gold < required_gold:
		return false
		
	if required_role != Enums.UnitRole.ANY:
		var has_role = false
		for u in crew:
			if u and u.unit_resource and u.unit_resource.role == required_role:
				has_role = true
				break
		if not has_role:
			return false
			
	if required_faction != Enums.Faction.NONE:
		var has_faction = false
		for u in crew:
			if u and u.unit_resource and u.unit_resource.faction == required_faction:
				has_faction = true
				break
		if not has_faction:
			return false
			
	return true
