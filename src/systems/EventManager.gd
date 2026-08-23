class_name EventManager
extends RefCounted

## Resolves narrative event choices, checks requirements, and applies rewards/penalties

static func execute_choice(
	choice: EventChoiceResource,
	shop_mgr: ShopManager,
	crew_mgr: CrewManager
) -> Dictionary:
	if choice == null:
		return {"success": false, "description": "Invalid choice."}
		
	# Check requirements
	var player_gold = shop_mgr.gold if shop_mgr else 0
	var crew = crew_mgr.fielded_units if crew_mgr else []
	
	if not choice.is_available(player_gold, crew):
		return {"success": false, "description": "Requirements not met."}
		
	# Apply Gold cost/penalty
	if choice.required_gold > 0 and shop_mgr:
		shop_mgr.spend_gold(choice.required_gold)
	if choice.penalty_gold > 0 and shop_mgr:
		shop_mgr.spend_gold(choice.penalty_gold)
		
	# Apply Rewards
	var gold_earned = 0
	var augment_awarded: AugmentResource = null
	
	if choice.reward_gold > 0 and shop_mgr:
		shop_mgr.add_gold(choice.reward_gold)
		gold_earned = choice.reward_gold
		
	if choice.reward_augment != null and crew_mgr:
		crew_mgr.add_augment_to_inventory(choice.reward_augment)
		augment_awarded = choice.reward_augment
			
	var outcome = {
		"success": true,
		"description": choice.outcome_description,
		"gold_delta": gold_earned - choice.required_gold - choice.penalty_gold,
		"augment_awarded": augment_awarded,
		"combat_triggered": choice.triggers_combat,
		"combat_enemy_id": choice.combat_enemy_id
	}
	
	return outcome
