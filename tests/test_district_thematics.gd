class_name TestDistrictThematics
extends RefCounted

## Test suite validating District Bosses, Thematic Modifiers, and Balance Scaling

var tests_passed: int = 0
var tests_failed: int = 0
var assertions_passed: int = 0
var assertions_failed: int = 0

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func _assert(condition: bool, message: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		printerr("  [FAIL] Assertion failed: %s" % message)

func run_all_tests() -> Dictionary:
	print("--- Running TestDistrictThematics ---")
	
	test_all_districts_and_bosses_exist()
	test_district_thematic_modifiers()
	test_shop_manager_thematic_integration()
	test_combat_bridge_boss_packaging()
	
	print("TestDistrictThematics Complete. Passed: %d, Failed: %d (Assertions: %d passed, %d failed)" % [
		tests_passed, tests_failed, assertions_passed, assertions_failed
	])
	return {
		"suite_name": "TestDistrictThematics",
		"passed": tests_failed == 0 and assertions_failed == 0,
		"tests_passed": tests_passed,
		"tests_failed": tests_failed,
		"assertions_passed": assertions_passed,
		"assertions_failed": assertions_failed
	}

func test_all_districts_and_bosses_exist() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var districts = repo.get_all_districts()
	_assert(districts.size() >= 23, "Expected at least 23 districts in data repository, got %d" % districts.size())
	
	var boss_count = 0
	for dist in districts:
		_assert(not dist.boss_unit_id.is_empty(), "District '%s' must have a non-empty boss_unit_id" % dist.id)
		var boss_unit = repo.get_unit(dist.boss_unit_id)
		_assert(boss_unit != null, "District '%s' boss '%s' must resolve to a valid UnitResource" % [dist.id, dist.boss_unit_id])
		if boss_unit:
			boss_count += 1
			_assert(boss_unit.id.begins_with("boss_"), "Boss unit id '%s' must begin with 'boss_'" % boss_unit.id)
			_assert(boss_unit.base_cost == 5, "Boss unit '%s' must have base_cost = 5" % boss_unit.id)
			_assert(boss_unit.portrait != null, "Boss unit '%s' must have a valid portrait texture" % boss_unit.id)
			_assert(not boss_unit.ability_name.is_empty(), "Boss unit '%s' must have an ability name" % boss_unit.id)
			
	_assert(boss_count >= 23, "Expected at least 23 resolved boss units, got %d" % boss_count)
	tests_passed += 1

func test_district_thematic_modifiers() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	# Test Skyline Casino reroll discount
	var casino = repo.get_district("skyline_casino")
	_assert(casino != null, "Skyline Casino district must exist")
	if casino:
		_assert(casino.reroll_cost_override == 1, "Skyline Casino reroll override must be 1 CR")
		_assert("1 CR Rerolls" in casino.get_perk_description(), "Perk description should mention reroll discount")
		
	# Test Kinetic Yards scrap refund bonus
	var kinetic = repo.get_district("kinetic_yards")
	_assert(kinetic != null, "Kinetic Yards district must exist")
	if kinetic:
		_assert(kinetic.scrap_refund_bonus == 1, "Kinetic Yards scrap refund bonus must be +1 CR")
		_assert(kinetic.preferred_tag == Enums.AugmentTag.KINETIC, "Kinetic Yards preferred tag must be KINETIC")
		
	# Test Slum Market bonus crew slot
	var slum = repo.get_district("district_1_slum_market")
	_assert(slum != null, "Slum Market district must exist")
	if slum:
		_assert(slum.bonus_crew_slots == 1, "Slum Market must have +1 bonus crew slot")
		
	# Test Corp Arcology bonus payout
	var corp = repo.get_district("district_2_corp_arcology")
	_assert(corp != null, "Corp Arcology district must exist")
	if corp:
		_assert(corp.payout_bonus == 2, "Corp Arcology must have +2 CR payout bonus")
		
	tests_passed += 1

func test_shop_manager_thematic_integration() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(1, repo)
	var shop_mgr = ShopManager.new(20)
	
	# 1. Test Casino Reroll Discount
	var casino = repo.get_district("skyline_casino")
	shop_mgr.generate_shop_offerings(1, repo, 4, 2, true, casino)
	_assert(shop_mgr.get_reroll_cost() == 1, "ShopManager reroll cost should be 1 CR in Skyline Casino")
	var pre_gold = shop_mgr.gold
	var success = shop_mgr.reroll_shop(repo)
	_assert(success, "Reroll in casino should succeed")
	_assert(shop_mgr.gold == pre_gold - 1, "Reroll in casino should deduct only 1 CR")
	
	# 2. Test Slum Market Bonus Crew Slots
	var slum = repo.get_district("district_1_slum_market")
	shop_mgr.generate_shop_offerings(1, repo, 4, 2, true, slum)
	_assert(shop_mgr.unit_slots.size() == 5, "Slum Market should generate 5 crew slots (4 base + 1 bonus)")
	
	# 3. Test Scrap Refund Bonus in Kinetic Yards
	var kinetic = repo.get_district("kinetic_yards")
	shop_mgr.generate_shop_offerings(2, repo, 4, 2, true, kinetic)
	var test_aug = repo.get_augment("common_kinetic_plating")
	_assert(test_aug != null, "common_kinetic_plating must exist")
	if test_aug:
		crew_mgr.add_augment_to_inventory(test_aug)
		var start_gold = shop_mgr.gold
		var refund = shop_mgr.sell_augment(0, crew_mgr)
		_assert(refund == 2, "Expected 2 CR refund for Common augment in Kinetic Yards (1 base + 1 bonus)")
		_assert(shop_mgr.gold == start_gold + 2, "Shop gold should increase by 2 CR")
		
	tests_passed += 1

func test_combat_bridge_boss_packaging() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(1, repo)
	var unit_res = repo.get_unit("runner_blitz")
	_assert(unit_res != null, "runner_blitz must exist")
	if unit_res:
		crew_mgr.add_unit(UnitInstance.new(unit_res))
	
	var thermal_foundry = repo.get_district("thermal_foundry")
	_assert(thermal_foundry != null, "Thermal Foundry district must exist")
	
	var payload = CombatBridge.package_combat_payload(
		crew_mgr.fielded_units,
		crew_mgr.active_synergy_report,
		2,
		true,
		repo,
		thermal_foundry
	)
	
	_assert(payload.get("is_boss", false) == true, "Payload is_boss should be true")
	_assert(payload.get("district_name", "") == "Thermal Foundry", "Payload district_name should be 'Thermal Foundry'")
	
	var enemy_squad: Array = payload.get("enemy_squad", [])
	_assert(not enemy_squad.is_empty(), "Enemy squad must not be empty")
	if not enemy_squad.is_empty():
		var boss: UnitInstance = enemy_squad[0]
		_assert(boss.unit_resource.id == "boss_foundry_overseer", "Expected boss unit 'boss_foundry_overseer', got '%s'" % boss.unit_resource.id)
		_assert(boss.star_level >= 2, "Boss unit should be at least 2 stars")
		_assert(boss.equipped_augments[0] != null, "Boss unit should have an equipped augment")
		
	tests_passed += 1
