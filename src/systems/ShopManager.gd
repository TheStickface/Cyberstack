class_name ShopManager
extends RefCounted

## Handles economy, gold transactions, shop generation, rerolls, and buy/sell operations

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var gold: int = Constants.DEFAULT_STARTING_GOLD
var current_district: int = 1
var shop_slots: Array[Dictionary] = [] # Array of {type, resource, cost, is_bought}

func _init(p_starting_gold: int = Constants.DEFAULT_STARTING_GOLD) -> void:
	gold = p_starting_gold

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	if Engine.has_singleton("EventBus") or ResourceLoader.exists("res://src/core/EventBus.gd"):
		# Safe emission if EventBus is active
		pass

func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	return true

func calculate_interest(_gold_amount: int = -1) -> int:
	# Interest mechanic removed: active spend economy
	return 0

func collect_round_income(base_income: int = 5, win_bonus: int = 0) -> Dictionary:
	var total_earned = base_income + win_bonus
	gold += total_earned
	return {
		"base": base_income,
		"interest": 0,
		"win_bonus": win_bonus,
		"total": total_earned,
		"new_balance": gold
	}

func generate_shop_offerings(district_id: int = 1, repo_instance: Object = null) -> Array[Dictionary]:
	current_district = district_id
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	
	var odds = Constants.DISTRICT_SHOP_ODDS.get(district_id, Constants.DISTRICT_SHOP_ODDS[1])
	shop_slots.clear()
	
	for i in range(Constants.SHOP_SLOTS_COUNT):
		var is_unit = (randf() < 0.5) # 50% chance unit, 50% chance augment
		var chosen_tier = _roll_tier(odds)
		
		if is_unit:
			var units_pool = repo.get_all_units()
			if not units_pool.is_empty():
				var unit_res: UnitResource = units_pool[randi() % units_pool.size()]
				shop_slots.append({
					"type": "unit",
					"resource": unit_res,
					"cost": unit_res.base_cost,
					"is_bought": false
				})
			else:
				# Fallback if no units
				shop_slots.append(_create_empty_slot())
		else:
			var aug_pool = repo.get_augments_by_tier(chosen_tier)
			if aug_pool.is_empty():
				aug_pool = repo.get_all_augments()
				
			if not aug_pool.is_empty():
				var aug_res: AugmentResource = aug_pool[randi() % aug_pool.size()]
				shop_slots.append({
					"type": "augment",
					"resource": aug_res,
					"cost": aug_res.base_cost,
					"is_bought": false
				})
			else:
				shop_slots.append(_create_empty_slot())
				
	return shop_slots

func reroll_shop(repo_instance: Object = null, free_reroll: bool = false) -> bool:
	if not free_reroll:
		if not spend_gold(Constants.BASE_REROLL_COST):
			return false
			
	generate_shop_offerings(current_district, repo_instance)
	return true

func buy_slot(slot_index: int, crew_mgr: Object) -> Dictionary:
	if slot_index < 0 or slot_index >= shop_slots.size():
		return {"success": false, "error": "Invalid slot index"}
		
	var slot = shop_slots[slot_index]
	if slot.get("is_bought", false):
		return {"success": false, "error": "Item already purchased"}
		
	var cost: int = slot.get("cost", 0)
	if gold < cost:
		return {"success": false, "error": "Not enough gold (Cost: %d, Current: %d)" % [cost, gold]}
		
	var item_type: String = slot.get("type", "")
	var res: Resource = slot.get("resource", null)
	if res == null:
		return {"success": false, "error": "Item resource is null"}
		
	if item_type == "unit":
		var unit_res = res as UnitResource
		var new_instance = UnitInstance.new(unit_res)
		var added = crew_mgr.add_unit_to_bench(new_instance)
		if not added:
			return {"success": false, "error": "Bench is full (Max %d units)" % Constants.MAX_BENCH_UNITS}
			
		spend_gold(cost)
		slot["is_bought"] = true
		return {"success": true, "item": new_instance, "type": "unit"}
		
	elif item_type == "augment":
		var aug_res = res as AugmentResource
		var added = crew_mgr.add_augment_to_inventory(aug_res)
		if not added:
			return {"success": false, "error": "Augment inventory is full (Max %d items)" % Constants.MAX_BENCH_AUGMENTS}
			
		spend_gold(cost)
		slot["is_bought"] = true
		return {"success": true, "item": aug_res, "type": "augment"}
		
	return {"success": false, "error": "Unknown item type"}

func sell_unit(unit: UnitInstance, crew_mgr: Object) -> int:
	if unit == null or unit.unit_resource == null:
		return 0
		
	var refund_gold = unit.unit_resource.base_cost
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
		
	var refund_gold: int = Constants.AUGMENT_SELL_VALUES.get(aug.tier, 1)
	add_gold(refund_gold)
	return refund_gold

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
