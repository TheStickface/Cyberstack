class_name ShopManager
extends RefCounted

## Handles economy, gold transactions, shop generation, rerolls, and buy/sell operations

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var gold: int = Constants.DEFAULT_STARTING_GOLD
var total_spent: int = 0  ## Cumulative credits spent this run (buys + rerolls)
var current_district: int = 1
var is_locked: bool = false
var active_district_res: DistrictResource = null
var active_crew_mgr: Object = null
var unit_slots: Array[Dictionary] = [] # Array of 4 (expandable to 6) pure operative slots
var augment_slots: Array[Dictionary] = [] # Array of 2 (expandable to 5) pure augment slots
var shop_slots: Array[Dictionary] = [] # Unified array [unit_slots + augment_slots]

func _init(p_starting_gold: int = Constants.DEFAULT_STARTING_GOLD) -> void:
	gold = p_starting_gold

func toggle_lock() -> bool:
	is_locked = !is_locked
	return is_locked

func set_locked(locked: bool) -> void:
	is_locked = locked

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount

func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	total_spent += amount
	return true

func calculate_interest(_gold_amount: int = -1) -> int:
	# Interest mechanic removed: active spend economy
	return 0

func collect_round_income(base_income: int = 5, win_bonus: int = 0) -> Dictionary:
	var payout_boost = active_district_res.payout_bonus if active_district_res else 0
	var total_earned = base_income + win_bonus + payout_boost
	gold += total_earned
	return {
		"base": base_income,
		"interest": 0,
		"win_bonus": win_bonus,
		"payout_bonus": payout_boost,
		"total": total_earned,
		"new_balance": gold
	}

func get_reroll_cost() -> int:
	if active_district_res and active_district_res.reroll_cost_override >= 0:
		return active_district_res.reroll_cost_override
	return Constants.BASE_REROLL_COST

func get_current_unit_tier_odds() -> Dictionary:
	return Constants.DISTRICT_UNIT_SHOP_ODDS.get(current_district, Constants.DISTRICT_UNIT_SHOP_ODDS[1])

func get_current_augment_tier_odds() -> Dictionary:
	return Constants.DISTRICT_SHOP_ODDS.get(current_district, Constants.DISTRICT_SHOP_ODDS[1])

func generate_shop_offerings(district_id: int = 1, repo_instance: Object = null, num_crew: int = Constants.DEFAULT_CREW_SHOP_SLOTS, num_augments: int = Constants.DEFAULT_AUGMENT_SHOP_SLOTS, force_refresh: bool = false, district_res: DistrictResource = null) -> Array[Dictionary]:
	if district_res != null:
		active_district_res = district_res
		
	if active_district_res != null:
		num_crew = clampi(num_crew + active_district_res.bonus_crew_slots, 1, Constants.MAX_CREW_SHOP_SLOTS)
		num_augments = clampi(num_augments + active_district_res.bonus_augment_slots, 1, Constants.MAX_AUGMENT_SHOP_SLOTS)

	if is_locked and not force_refresh and not unit_slots.is_empty():
		current_district = district_id
		is_locked = false # Consumed for this round transition
		return shop_slots
		
	current_district = district_id
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	var aug_odds = Constants.DISTRICT_SHOP_ODDS.get(district_id, Constants.DISTRICT_SHOP_ODDS[1])
	var unit_odds = Constants.DISTRICT_UNIT_SHOP_ODDS.get(district_id, Constants.DISTRICT_UNIT_SHOP_ODDS[1])
	
	unit_slots.clear()
	augment_slots.clear()
	shop_slots.clear()
	
	# 1. Generate Pure Operative / Crew Slots (Tiered by District Odds, excluding boss units)
	var raw_units = repo.get_all_units()
	var all_units: Array[UnitResource] = []
	for u in raw_units:
		if not u.id.begins_with("boss_"):
			all_units.append(u)
			
	for i in range(num_crew):
		var target_tier = _roll_unit_tier(unit_odds)
		var filtered_units: Array[UnitResource] = []
		for u in all_units:
			if target_tier == 1 and u.base_cost <= 2:
				filtered_units.append(u)
			elif target_tier == 2 and (u.base_cost == 3 or u.base_cost == 4):
				filtered_units.append(u)
			elif target_tier == 3 and u.base_cost >= 5:
				filtered_units.append(u)
				
		if filtered_units.is_empty():
			filtered_units = all_units
			
		# Early synergy discovery bias: In District 1, 50% chance on the first slot to offer a unit matching player's starter/fielded faction
		if district_id == 1 and i == 0 and active_crew_mgr != null:
			var player_crew = active_crew_mgr.fielded_units
			if not player_crew.is_empty() and player_crew[0].unit_resource != null:
				var starter_fac = player_crew[0].unit_resource.faction
				var syn_units: Array[UnitResource] = []
				for u in filtered_units:
					if u.faction == starter_fac:
						syn_units.append(u)
				if not syn_units.is_empty() and randf() < 0.50:
					filtered_units = syn_units
			
		if not filtered_units.is_empty():
			var unit_res: UnitResource = filtered_units[randi() % filtered_units.size()]
			var slot_data = {
				"type": "unit",
				"resource": unit_res,
				"cost": unit_res.base_cost,
				"is_bought": false
			}
			unit_slots.append(slot_data)
			shop_slots.append(slot_data)
		else:
			var empty_slot = _create_empty_slot()
			unit_slots.append(empty_slot)
			shop_slots.append(empty_slot)
			
	# 2. Generate Pure Augment Slots (Tiered by District Odds & Preferred Tag Bias)
	var pref_tag = active_district_res.preferred_tag if active_district_res else Enums.AugmentTag.NONE
	for i in range(num_augments):
		var chosen_tier = _roll_tier(aug_odds)
		var aug_pool = repo.get_augments_by_tier(chosen_tier)
		if aug_pool.is_empty():
			aug_pool = repo.get_all_augments()
			
		# Apply thematic tag bias (65% chance if district has preferred tag)
		if pref_tag != Enums.AugmentTag.NONE and randf() < 0.65:
			var biased_pool: Array[AugmentResource] = []
			for a in aug_pool:
				if a.tags.has(pref_tag):
					biased_pool.append(a)
			if not biased_pool.is_empty():
				aug_pool = biased_pool
			
		if not aug_pool.is_empty():
			var aug_res: AugmentResource = aug_pool[randi() % aug_pool.size()]
			var slot_data = {
				"type": "augment",
				"resource": aug_res,
				"cost": aug_res.base_cost,
				"is_bought": false
			}
			augment_slots.append(slot_data)
			shop_slots.append(slot_data)
		else:
			var empty_slot = _create_empty_slot()
			augment_slots.append(empty_slot)
			shop_slots.append(empty_slot)
			
	return shop_slots

func _roll_unit_tier(odds: Dictionary) -> int:
	var roll = randf()
	var cum_prob = 0.0
	for tier in [1, 2, 3]:
		cum_prob += odds.get(tier, 0.0)
		if roll <= cum_prob:
			return tier
	return 1

func reroll_shop(repo_instance: Object = null, free_reroll: bool = false) -> bool:
	if not free_reroll:
		if not spend_gold(get_reroll_cost()):
			return false
			
	is_locked = false
	var crew_count = Constants.DEFAULT_CREW_SHOP_SLOTS + (active_district_res.bonus_crew_slots if active_district_res else 0)
	var aug_count = Constants.DEFAULT_AUGMENT_SHOP_SLOTS + (active_district_res.bonus_augment_slots if active_district_res else 0)
	generate_shop_offerings(current_district, repo_instance, crew_count, aug_count, true, active_district_res)
	return true

func buy_unit_slot(slot_index: int, crew_mgr: Object) -> Dictionary:
	if slot_index < 0 or slot_index >= unit_slots.size():
		return {"success": false, "error": "Invalid unit slot index"}
	return _execute_purchase(unit_slots[slot_index], crew_mgr)

func buy_augment_slot(slot_index: int, crew_mgr: Object) -> Dictionary:
	if slot_index < 0 or slot_index >= augment_slots.size():
		return {"success": false, "error": "Invalid augment slot index"}
	return _execute_purchase(augment_slots[slot_index], crew_mgr)

func buy_slot(slot_index: int, crew_mgr: Object) -> Dictionary:
	if slot_index < 0 or slot_index >= shop_slots.size():
		return {"success": false, "error": "Invalid slot index"}
	return _execute_purchase(shop_slots[slot_index], crew_mgr)

func _execute_purchase(slot: Dictionary, crew_mgr: Object) -> Dictionary:
	if slot.get("is_bought", false):
		return {"success": false, "error": "Item already purchased"}
		
	var cost: int = slot.get("cost", 0)
	if gold < cost:
		return {"success": false, "error": "Not enough credits (Cost: %d, Current: %d)" % [cost, gold]}
		
	var item_type: String = slot.get("type", "")
	var res: Resource = slot.get("resource", null)
	if res == null:
		return {"success": false, "error": "Item resource is null"}
		
	if item_type == "unit":
		var unit_res = res as UnitResource
		var new_instance = UnitInstance.new(unit_res)
		var added = false
		if crew_mgr.has_method("add_unit"):
			added = crew_mgr.add_unit(new_instance)
		else:
			added = crew_mgr.add_unit_to_bench(new_instance)
			
		if not added:
			return {"success": false, "error": "Crew field and bench are full"}
			
		spend_gold(cost)
		slot["is_bought"] = true
		return {"success": true, "item": new_instance, "type": "unit"}
		
	elif item_type == "augment":
		var aug_res = res as AugmentResource
		var added = crew_mgr.add_augment_to_inventory(aug_res)
		if not added:
			return {"success": false, "error": "Augment bag is full (Max %d items)" % Constants.MAX_BENCH_AUGMENTS}
			
		spend_gold(cost)
		slot["is_bought"] = true
		return {"success": true, "item": aug_res, "type": "augment"}
		
	return {"success": false, "error": "Unknown item type"}

func sell_unit(unit: UnitInstance, crew_mgr: Object) -> int:
	if unit == null or unit.unit_resource == null:
		return 0
		
	var mult = 2 if unit.star_level == 2 else (4 if unit.star_level >= 3 else 1)
	var refund_gold = unit.unit_resource.base_cost * mult
	# Return equipped augments to inventory if space allows
	for i in range(unit.equipped_augments.size()):
		var aug = unit.unequip_augment(i)
		if aug != null:
			crew_mgr.add_augment_to_inventory(aug)
			
	# Remove from field or bench
	crew_mgr.remove_unit(unit)
	add_gold(refund_gold)
	return refund_gold

func sell_augment(inventory_index: int, crew_mgr: Object) -> int:
	var aug = crew_mgr.remove_augment_from_inventory(inventory_index)
	if aug == null:
		return 0
		
	var base_refund: int = Constants.AUGMENT_SELL_VALUES.get(aug.tier, 1)
	var bonus = active_district_res.scrap_refund_bonus if active_district_res else 0
	var refund_gold = base_refund + bonus
	add_gold(refund_gold)
	return refund_gold

# --- Black Market Overdrive (Augment Synthesis) ---
const OVERDRIVE_COST: int = 6

func get_overdrive_cost() -> int:
	return OVERDRIVE_COST

func can_overdrive_augment(unit: UnitInstance, slot_idx: int) -> bool:
	if current_district < 3:
		return false
	if gold < OVERDRIVE_COST:
		return false
	if unit == null or slot_idx < 0 or slot_idx >= unit.equipped_augments.size():
		return false
	var current_aug = unit.equipped_augments[slot_idx]
	if current_aug == null:
		return false
	return current_aug.tier < Enums.AugmentTier.LEGENDARY

func overdrive_augment(unit: UnitInstance, slot_idx: int, repo_instance: Object = null) -> AugmentResource:
	if not can_overdrive_augment(unit, slot_idx):
		return null
	var current_aug = unit.equipped_augments[slot_idx]
	var target_tier = Enums.AugmentTier.RARE if current_aug.tier == Enums.AugmentTier.COMMON else Enums.AugmentTier.LEGENDARY
	var primary_tag = current_aug.primary_tag
	
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	var all_augs = repo.get_all_augments()
	
	# Prefer an augment of the same primary tag at target_tier
	var candidate_pool: Array[AugmentResource] = []
	for aug in all_augs:
		if aug.tier == target_tier and aug.primary_tag == primary_tag:
			candidate_pool.append(aug)
			
	# Fallback to any augment of target_tier if no same-tag found
	if candidate_pool.is_empty():
		for aug in all_augs:
			if aug.tier == target_tier:
				candidate_pool.append(aug)
				
	if candidate_pool.is_empty():
		return null
		
	var upgraded_aug = candidate_pool[randi() % candidate_pool.size()]
	if spend_gold(OVERDRIVE_COST):
		unit.equipped_augments[slot_idx] = upgraded_aug
		return upgraded_aug
	return null

const RESEQUENCE_COST: int = 5

func get_resequence_cost() -> int:
	return RESEQUENCE_COST

func can_resequence_augment(unit: UnitInstance, slot_idx: int) -> bool:
	if current_district < 3:
		return false
	if gold < RESEQUENCE_COST:
		return false
	if unit == null or slot_idx < 0 or slot_idx >= unit.equipped_augments.size():
		return false
	return unit.equipped_augments[slot_idx] != null

func resequence_augment(unit: UnitInstance, slot_idx: int, repo_instance: Object = null) -> AugmentResource:
	if not can_resequence_augment(unit, slot_idx):
		return null
	var current_aug = unit.equipped_augments[slot_idx]
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	var all_augs = repo.get_all_augments()
	
	# Find augments of same slot type and same tier, but different augment
	var candidate_pool: Array[AugmentResource] = []
	for aug in all_augs:
		if aug.id != current_aug.id and aug.slot_type == current_aug.slot_type and aug.tier == current_aug.tier:
			candidate_pool.append(aug)
			
	if candidate_pool.is_empty():
		for aug in all_augs:
			if aug.id != current_aug.id and aug.tier == current_aug.tier:
				candidate_pool.append(aug)
				
	if candidate_pool.is_empty():
		return null
		
	var resequenced = candidate_pool[randi() % candidate_pool.size()]
	if spend_gold(RESEQUENCE_COST):
		unit.equipped_augments[slot_idx] = resequenced
		return resequenced
	return null

func _roll_tier(odds: Dictionary) -> Enums.AugmentTier:
	var roll = randf()
	var cum_prob = 0.0
	
	var common_prob = odds.get(Enums.AugmentTier.COMMON, 0.0)
	var rare_prob = odds.get(Enums.AugmentTier.RARE, 0.0)
	var legend_prob = odds.get(Enums.AugmentTier.LEGENDARY, 0.0)
	
	cum_prob += common_prob
	if roll <= cum_prob:
		return Enums.AugmentTier.COMMON
		
	cum_prob += rare_prob
	if roll <= cum_prob:
		return Enums.AugmentTier.RARE
		
	return Enums.AugmentTier.LEGENDARY

func _create_empty_slot() -> Dictionary:
	return {
		"type": "none",
		"resource": null,
		"cost": 0,
		"is_bought": true
	}

func _get_default_repo() -> Object:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	return repo
