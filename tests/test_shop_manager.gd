class_name TestShopManager
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_gold_transactions() -> Dictionary:
	var shop = ShopManager.new(10)
	
	if shop.gold != 10:
		return {"passed": false, "message": "Expected starting gold 10, got %d" % shop.gold, "assertions": 1}
		
	shop.add_gold(5)
	if shop.gold != 15:
		return {"passed": false, "message": "Expected 15 gold after adding 5, got %d" % shop.gold, "assertions": 2}
		
	var spend_ok = shop.spend_gold(10)
	if not spend_ok or shop.gold != 5:
		return {"passed": false, "message": "Expected 5 gold after spending 10", "assertions": 3}
		
	var spend_fail = shop.spend_gold(20)
	if spend_fail or shop.gold != 5:
		return {"passed": false, "message": "Should not allow spending more gold than available", "assertions": 4}
		
	return {"passed": true, "assertions": 4}

func test_flat_encounter_income_and_no_interest() -> Dictionary:
	var shop = ShopManager.new(0)
	
	# Verify hoarding credits gives 0 interest
	if shop.calculate_interest(0) != 0:
		return {"passed": false, "message": "0 gold should yield 0 interest", "assertions": 1}
	if shop.calculate_interest(50) != 0:
		return {"passed": false, "message": "50 gold should yield 0 interest in active spend economy", "assertions": 2}
		
	# Verify flat income collection (base payout + win bonus)
	var income_0g = shop.collect_round_income(5, 1)
	if income_0g.total != 6 or income_0g.interest != 0:
		return {"passed": false, "message": "Income collection mismatch", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_shop_generation_and_reroll() -> Dictionary:
	var shop = ShopManager.new(10)
	var slots = shop.generate_shop_offerings(1, repo)
	
	if slots.size() != Constants.SHOP_SLOTS_COUNT:
		return {"passed": false, "message": "Expected %d shop slots, got %d" % [Constants.SHOP_SLOTS_COUNT, slots.size()], "assertions": 1}
		
	if shop.unit_slots.size() != Constants.DEFAULT_CREW_SHOP_SLOTS:
		return {"passed": false, "message": "Expected %d pure crew slots, got %d" % [Constants.DEFAULT_CREW_SHOP_SLOTS, shop.unit_slots.size()], "assertions": 2}
		
	if shop.augment_slots.size() != Constants.DEFAULT_AUGMENT_SHOP_SLOTS:
		return {"passed": false, "message": "Expected %d pure augment slots, got %d" % [Constants.DEFAULT_AUGMENT_SHOP_SLOTS, shop.augment_slots.size()], "assertions": 3}
		
	# In District 1, all augments should be Common
	for slot in shop.augment_slots:
		var aug: AugmentResource = slot.get("resource", null)
		if aug and aug.tier != Enums.AugmentTier.COMMON:
			return {"passed": false, "message": "District 1 should only produce Common augments", "assertions": 4}
				
	# Test Reroll
	var prev_gold = shop.gold
	var reroll_ok = shop.reroll_shop(repo)
	if not reroll_ok or shop.gold != (prev_gold - Constants.BASE_REROLL_COST):
		return {"passed": false, "message": "Reroll should cost %d gold" % Constants.BASE_REROLL_COST, "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_buy_and_sell_flow() -> Dictionary:
	var shop = ShopManager.new(20)
	var crew_mgr = CrewManager.new(1, repo)
	
	# Manually setup shop slots for deterministic testing
	var blitz_res = repo.get_unit("runner_blitz")
	var aug_res = repo.get_augment("common_viral_nanites")
	
	var custom_slots: Array[Dictionary] = [
		{"type": "unit", "resource": blitz_res, "cost": 2, "is_bought": false},
		{"type": "augment", "resource": aug_res, "cost": 2, "is_bought": false}
	]
	shop.shop_slots = custom_slots
	
	# Buy Unit
	var buy_unit_res = shop.buy_slot(0, crew_mgr)
	if not buy_unit_res.success:
		return {"passed": false, "message": "Failed to buy unit: %s" % buy_unit_res.get("error", ""), "assertions": 1}
	if (crew_mgr.fielded_units.size() + crew_mgr.benched_units.size()) != 1:
		return {"passed": false, "message": "Expected 1 unit in crew after purchase", "assertions": 2}
	if shop.gold != 18:
		return {"passed": false, "message": "Expected 18 gold after purchase, got %d" % shop.gold, "assertions": 3}
		
	# Buy Augment
	var buy_aug_res = shop.buy_slot(1, crew_mgr)
	if not buy_aug_res.success:
		return {"passed": false, "message": "Failed to buy augment: %s" % buy_aug_res.get("error", ""), "assertions": 4}
	if crew_mgr.augment_inventory.size() != 1:
		return {"passed": false, "message": "Expected 1 augment in inventory after purchase", "assertions": 5}
	if shop.gold != 16:
		return {"passed": false, "message": "Expected 16 gold after purchase, got %d" % shop.gold, "assertions": 6}
		
	# Equip Augment to unit, then sell unit
	var unit: UnitInstance = crew_mgr.fielded_units[0] if not crew_mgr.fielded_units.is_empty() else crew_mgr.benched_units[0]
	var equip_ok = crew_mgr.equip_augment_from_inventory(unit, 2, 0) # Slot 2: Passive
	if not equip_ok:
		return {"passed": false, "message": "Failed to equip augment in passive slot", "assertions": 7}
	if not crew_mgr.augment_inventory.is_empty():
		return {"passed": false, "message": "Inventory should be empty after equipping", "assertions": 8}
		
	# Sell Unit (should return equipped augment to inventory)
	var refund = shop.sell_unit(unit, crew_mgr)
	if refund != blitz_res.base_cost:
		return {"passed": false, "message": "Expected refund %d, got %d" % [blitz_res.base_cost, refund], "assertions": 9}
	if not crew_mgr.fielded_units.is_empty() or not crew_mgr.benched_units.is_empty():
		return {"passed": false, "message": "Crew should be empty after selling", "assertions": 10}
	if crew_mgr.augment_inventory.size() != 1:
		return {"passed": false, "message": "Equipped augment should have returned to inventory upon selling unit", "assertions": 11}
		
	# Sell Augment
	var aug_refund = shop.sell_augment(0, crew_mgr)
	if aug_refund != 1: # Common augment sell value is 1
		return {"passed": false, "message": "Expected 1 gold refund for common augment, got %d" % aug_refund, "assertions": 12}
	if not crew_mgr.augment_inventory.is_empty():
		return {"passed": false, "message": "Augment inventory should be empty after selling augment", "assertions": 13}
		
	return {"passed": true, "assertions": 13}

func test_shop_freeze_and_lock() -> Dictionary:
	var shop = ShopManager.new(20)
	shop.generate_shop_offerings(1, repo)
	
	var initial_unit_res = shop.unit_slots[0].get("resource", null)
	if initial_unit_res == null:
		return {"passed": false, "message": "Expected valid unit in slot 0", "assertions": 1}
		
	# 1. Toggle Lock ON
	var is_locked = shop.toggle_lock()
	if not is_locked or not shop.is_locked:
		return {"passed": false, "message": "Shop should be locked after toggle_lock", "assertions": 2}
		
	# 2. Simulate District round advancement (generate offerings with locked shop)
	var preserved_slots = shop.generate_shop_offerings(2, repo)
	var preserved_unit_res = shop.unit_slots[0].get("resource", null)
	if preserved_unit_res != initial_unit_res:
		return {"passed": false, "message": "Locked shop should preserve offerings across rounds", "assertions": 3}
		
	# 3. Verify lock is consumed/auto-unlocked for the subsequent round
	if shop.is_locked:
		return {"passed": false, "message": "Lock should be automatically consumed after round transition", "assertions": 4}
		
	# 4. Manual reroll should force new offerings even if locked
	shop.toggle_lock()
	var reroll_ok = shop.reroll_shop(repo)
	if not reroll_ok or shop.is_locked:
		return {"passed": false, "message": "Reroll should clear lock state and generate fresh offerings", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_tiered_district_shop_odds() -> Dictionary:
	var shop = ShopManager.new(50)
	
	# 1. Verify District 1 produces 100% Tier 1 units and Common augments
	shop.generate_shop_offerings(1, repo, 10, 10, true)
	for slot in shop.unit_slots:
		var u: UnitResource = slot.get("resource", null)
		if u and u.base_cost > 2:
			return {"passed": false, "message": "District 1 should only produce Tier 1 (<=2 cost) units, got %s (cost %d)" % [u.display_name, u.base_cost], "assertions": 1}
	for slot in shop.augment_slots:
		var a: AugmentResource = slot.get("resource", null)
		if a and a.tier != Enums.AugmentTier.COMMON:
			return {"passed": false, "message": "District 1 should only produce Common augments", "assertions": 2}
			
	# 2. Verify District 4 unit odds and augment odds accessors
	var d4_unit_odds = shop.get_current_unit_tier_odds()
	shop.generate_shop_offerings(4, repo, 10, 10, true)
	var d4_odds = shop.get_current_unit_tier_odds()
	if d4_odds.get(3, 0.0) != 0.40:
		return {"passed": false, "message": "District 4 expected Tier 3 odds 0.40, got %f" % d4_odds.get(3, 0.0), "assertions": 3}
		
	return {"passed": true, "assertions": 4}

func test_augment_resequencing() -> Dictionary:
	var shop = ShopManager.new(20)
	var unit_res = repo.get_unit("runner_blitz")
	var unit = UnitInstance.new(unit_res)
	var aug_res = repo.get_augment("rare_kinetic_rail")
	unit.equipped_augments[0] = aug_res
	
	# 1. In District 1, resequencing is disabled
	shop.current_district = 1
	if shop.can_resequence_augment(unit, 0):
		return {"passed": false, "message": "Resequencing should be locked before District 3", "assertions": 1}
		
	# 2. In District 3 with enough gold, resequencing is available
	shop.current_district = 3
	if not shop.can_resequence_augment(unit, 0):
		return {"passed": false, "message": "Resequencing should be available in District 3 with 20 gold", "assertions": 2}
		
	# 3. Perform resequence: credits debited, new augment assigned
	var old_id = aug_res.id
	var reseq_aug = shop.resequence_augment(unit, 0, repo)
	if reseq_aug == null or unit.equipped_augments[0] == null:
		return {"passed": false, "message": "Expected valid resequenced augment returned", "assertions": 3}
	if shop.gold != 15:
		return {"passed": false, "message": "Expected 15 gold after spending 5 on resequencing, got %d" % shop.gold, "assertions": 4}
	if unit.equipped_augments[0].tier != aug_res.tier:
		return {"passed": false, "message": "Resequenced augment must preserve tier", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

