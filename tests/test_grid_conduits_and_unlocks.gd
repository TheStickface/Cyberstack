class_name TestGridConduitsAndUnlocks
extends RefCounted

## Unit test suite for Tactical Conduits and Player-Chosen Grid Unlocks with Intrinsic Attributes

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
	print("--- Running TestGridConduitsAndUnlocks ---")
	
	test_dynamic_slot_unlock_and_doctrines()
	test_tactical_conduit_installation_and_row_restrictions()
	test_conduit_duration_tick_and_burnout()
	test_shop_manager_conduit_flow()
	test_run_manager_encounter_victory_ticks_conduits()
	test_combat_bridge_packages_conduit_bonuses()
	test_new_conduits_and_vector_and_flux_resonator()
	
	print("TestGridConduitsAndUnlocks Complete. Passed: %d, Failed: %d (Assertions: %d passed, %d failed)" % [
		tests_passed, tests_failed, assertions_passed, assertions_failed
	])
	return {
		"suite_name": "TestGridConduitsAndUnlocks",
		"passed": tests_failed == 0 and assertions_failed == 0,
		"tests_passed": tests_passed,
		"tests_failed": tests_failed,
		"assertions_passed": assertions_passed,
		"assertions_failed": assertions_failed
	}

func test_dynamic_slot_unlock_and_doctrines() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(1, repo)
	
	_assert(crew_mgr.is_slot_unlocked(0), "Slot 0 unlocked in D1")
	_assert(not crew_mgr.unlocked_slots.has(3), "Slot 3 not explicitly unlocked yet")
	
	# Unlock Slot 3 with Overwatch Perch doctrine
	var unlocked = crew_mgr.unlock_slot(3, "overwatch_perch")
	_assert(unlocked, "unlock_slot(3) should succeed")
	_assert(crew_mgr.is_slot_unlocked(3), "Slot 3 should now be unlocked")
	
	var doc = crew_mgr.get_slot_specialization(3)
	_assert(doc.get("id") == "overwatch_perch", "Slot 3 doctrine should be overwatch_perch")
	
	# Place an operative on Slot 3
	var sniper = UnitInstance.new(repo.get_unit("corp_deadeye"))
	crew_mgr.place_unit_on_grid(sniper, 3)
	
	var report = crew_mgr.calculate_formation_bonuses()
	_assert(report.has(sniper), "Formation report should contain sniper")
	if report.has(sniper):
		var b = report[sniper]
		_assert(b["crit_bonus"] >= 0.20, "Sniper on Slot 3 should gain +20% crit from Overwatch Perch")
		_assert(b["attack_damage_bonus"] >= 25.0, "Sniper on Slot 3 should gain +25 AD from Overwatch Perch")
		
	tests_passed += 1

func test_tactical_conduit_installation_and_row_restrictions() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(2, repo)
	
	var bus = repo.get_conduit("conduit_overcharged_bus")
	var bastion = repo.get_conduit("conduit_kinetic_bastion") # Frontline only
	var overwatch = repo.get_conduit("conduit_overwatch_transmitter") # Backline only
	
	_assert(bus != null, "Overcharged Bus conduit should load")
	_assert(bastion != null, "Kinetic Bastion conduit should load")
	_assert(overwatch != null, "Overwatch Transmitter conduit should load")
	
	# Install Bus on Frontline Slot 1
	var inst_bus = crew_mgr.install_conduit(1, bus)
	_assert(inst_bus, "Installing any-row conduit on Slot 1 should succeed")
	
	# Install Bastion on Frontline Slot 0 (Row 1)
	var inst_bastion = crew_mgr.install_conduit(0, bastion)
	_assert(inst_bastion, "Installing frontline-only conduit on Slot 0 should succeed")
	
	# Attempt to install Bastion on Backline Slot 4 (Row 0) -> Should fail!
	var fail_bastion = crew_mgr.install_conduit(4, bastion)
	_assert(not fail_bastion, "Installing frontline conduit on Backline Slot 4 should fail")
	
	# Attempt to install Overwatch on Frontline Slot 2 (Row 1) -> Should fail!
	var fail_overwatch = crew_mgr.install_conduit(2, overwatch)
	_assert(not fail_overwatch, "Installing backline conduit on Frontline Slot 2 should fail")
	
	# Install Overwatch on Backline Slot 4 (Row 0) -> Should succeed!
	var succ_overwatch = crew_mgr.install_conduit(4, overwatch)
	_assert(succ_overwatch, "Installing backline conduit on Backline Slot 4 should succeed")
	
	tests_passed += 1

func test_conduit_duration_tick_and_burnout() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(2, repo)
	
	var bastion = repo.get_conduit("conduit_kinetic_bastion") # 2 charges
	crew_mgr.install_conduit(1, bastion)
	
	var tank = UnitInstance.new(repo.get_unit("runner_rampart"))
	crew_mgr.place_unit_on_grid(tank, 1)
	
	var b1 = crew_mgr.calculate_formation_bonuses()[tank]
	_assert(b1["shield_bonus"] >= 250.0, "Tank should get +250 shield from Bastion conduit")
	
	# Combat victory 1 -> tick durations
	var burned_1 = crew_mgr.tick_conduit_durations()
	_assert(burned_1.is_empty(), "Conduit with 2 charges should not burn out after 1 combat")
	var active = crew_mgr.get_active_conduit(1)
	_assert(active["remaining_charges"] == 1, "Remaining charges should be 1")
	
	# Combat victory 2 -> tick durations -> should burn out!
	var burned_2 = crew_mgr.tick_conduit_durations()
	_assert(burned_2.size() == 1, "Conduit should burn out after 2nd combat")
	_assert(burned_2[0]["slot"] == 1, "Burnout slot should be 1")
	_assert(crew_mgr.get_active_conduit(1).is_empty(), "Slot 1 conduit should be cleared after burnout")
	
	var b2 = crew_mgr.calculate_formation_bonuses()[tank]
	_assert(b2["shield_bonus"] < 250.0, "Shield bonus from conduit should be gone after burnout")
	
	tests_passed += 1

func test_shop_manager_conduit_flow() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var shop = ShopManager.new(20)
	shop.generate_shop_offerings(1, repo)
	
	_assert(shop.conduit_slots.size() == 1, "Shop should generate 1 conduit slot")
	var cond_slot = shop.conduit_slots[0]
	_assert(cond_slot.has("resource") and cond_slot["resource"] is ConduitResource, "Slot resource should be ConduitResource")
	
	var cost = cond_slot["cost"]
	var gold_before = shop.gold
	var bought = shop.buy_conduit(0)
	
	_assert(bought != null, "buy_conduit(0) should return the conduit")
	_assert(shop.gold == gold_before - cost, "Shop gold should be deducted by conduit cost")
	_assert(shop.conduit_slots[0]["is_bought"], "Conduit slot should be marked bought")
	
	# Buying again should fail
	var buy_again = shop.buy_conduit(0)
	_assert(buy_again == null, "Buying an already bought conduit should return null")
	
	tests_passed += 1

func test_run_manager_encounter_victory_ticks_conduits() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var run_mgr = RunManager.new(repo)
	run_mgr.start_new_run()
	
	var bus = repo.get_conduit("conduit_overcharged_bus") # 3 charges
	run_mgr.crew_mgr.install_conduit(0, bus)
	_assert(run_mgr.crew_mgr.get_active_conduit(0)["remaining_charges"] == 3, "Initial charges should be 3")
	
	# Complete a fight victory
	var res = run_mgr.complete_encounter(true)
	_assert(res.has("conduits_burned"), "Result should have conduits_burned list")
	_assert(run_mgr.crew_mgr.get_active_conduit(0)["remaining_charges"] == 2, "Charges should tick down to 2 after battle victory")
	
	tests_passed += 1

func test_combat_bridge_packages_conduit_bonuses() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(2, repo)
	
	var bus = repo.get_conduit("conduit_overcharged_bus")
	crew_mgr.install_conduit(1, bus)
	
	var unit = UnitInstance.new(repo.get_unit("runner_blitz"))
	crew_mgr.place_unit_on_grid(unit, 1)
	
	var formation_bonuses = crew_mgr.calculate_formation_bonuses()
	var payload = CombatBridge.package_combat_payload(
		crew_mgr.fielded_units,
		crew_mgr.active_synergy_report,
		2,
		false,
		repo,
		null,
		crew_mgr.tactical_grid,
		formation_bonuses
	)
	
	_assert(payload.has("formation_bonuses"), "Payload should contain formation_bonuses")
	var f_b = payload["formation_bonuses"]
	_assert(f_b.has(unit), "formation_bonuses should contain unit")
	if f_b.has(unit):
		_assert(f_b[unit]["starting_mana_bonus"] >= 35.0, "Unit should have starting mana bonus from conduit")
		
	tests_passed += 1

func test_new_conduits_and_vector_and_flux_resonator() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(2, repo)
	
	# 1. Arc Discharge Coil
	var arc = repo.get_conduit("conduit_arc_discharge")
	_assert(arc != null, "Arc Discharge Coil should exist in repository")
	_assert(arc.cost == 4, "Arc Discharge cost should be 4")
	_assert(arc.can_install_on_row(1), "Arc Discharge should install on frontline row 1")
	_assert(not arc.can_install_on_row(0), "Arc Discharge should not install on backline row 0")
	
	# 2. Hyper-Frequency Siphon
	var siphon = repo.get_conduit("conduit_overclock_siphon")
	_assert(siphon != null, "Hyper-Frequency Siphon should exist in repository")
	_assert(siphon.cost == 5, "Hyper-Frequency Siphon cost should be 5")
	_assert(siphon.can_install_on_row(0), "Hyper-Frequency Siphon should install on backline row 0")
	_assert(not siphon.can_install_on_row(1), "Hyper-Frequency Siphon should not install on frontline row 1")
	
	# 3. Vector (Operative)
	var vector = repo.get_unit("ai_vector")
	_assert(vector != null, "Vector should exist in repository")
	_assert(vector.role == Enums.UnitRole.TANK, "Vector should be a Tank")
	_assert(vector.faction == Enums.Faction.ROGUE_AIS, "Vector should be in Rogue AI faction")
	_assert(vector.directional_target == Enums.GridDirection.SAME_ROW, "Vector should have SAME_ROW directional target")
	
	# 4. Flux Resonator (Augment)
	var flux = repo.get_augment("rare_flux_resonator")
	_assert(flux != null, "Flux Resonator should exist in repository")
	_assert(flux.tier == Enums.AugmentTier.RARE, "Flux Resonator should be Rare")
	
	# Test Flux Resonator charge extension:
	var glitch = repo.get_unit("ai_glitch")
	var glitch_inst = UnitInstance.new(glitch)
	crew_mgr.place_unit_on_grid(glitch_inst, 1)
	var equip_ok = glitch_inst.equip_augment(1, flux)
	_assert(equip_ok, "Flux Resonator should equip in glitch's utility slot")
	
	var overcharge_bus = repo.get_conduit("conduit_overcharged_bus")
	crew_mgr.install_conduit(1, overcharge_bus)
	var active = crew_mgr.get_active_conduit(1)
	_assert(active["remaining_charges"] == 4, "Flux Resonator should grant +1 charge (3 -> 4)")
	
	# Test Flux Resonator haste on calibrated slot:
	var b = crew_mgr.calculate_formation_bonuses()[glitch_inst]
	_assert(b["attack_speed_bonus"] >= 0.25, "Flux Resonator should give +25% attack speed on active conduit slot")
	
	tests_passed += 1

