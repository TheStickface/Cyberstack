class_name TestTacticalDragAndTethers
extends RefCounted

## Automated test suite for Drag-and-Drop Grid Placement, Positional Swapping & Holographic Tethers

var tests_passed: int = 0
var tests_failed: int = 0
var assertions_passed: int = 0
var assertions_failed: int = 0

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const OperativeCardScript = preload("res://src/ui/components/OperativeCard.gd")
const TetherOverlayScript = preload("res://src/ui/components/TacticalTetherOverlay.gd")

func _assert(condition: bool, message: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		printerr("  [FAIL] Assertion failed: %s" % message)

func run_all_tests() -> Dictionary:
	print("--- Running TestTacticalDragAndTethers ---")
	
	test_operative_card_drag_payload()
	test_operative_card_drop_validation()
	test_empty_slot_drop_validation()
	test_grid_and_bench_swapping_mechanics()
	test_tactical_tether_overlay()
	test_operative_card_formation_badges()
	
	print("TestTacticalDragAndTethers Complete. Passed: %d, Failed: %d (Assertions: %d passed, %d failed)" % [
		tests_passed, tests_failed, assertions_passed, assertions_failed
	])
	return {
		"suite_name": "TestTacticalDragAndTethers",
		"passed": tests_failed == 0 and assertions_failed == 0,
		"tests_passed": tests_passed,
		"tests_failed": tests_failed,
		"assertions_passed": assertions_passed,
		"assertions_failed": assertions_failed
	}

func test_operative_card_drag_payload() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var unit_res = repo.get_unit("runner_rampart")
	var unit_inst = UnitInstance.new(unit_res)
	unit_inst.grid_slot = 1
	
	var card = OperativeCard.new()
	card.unit_instance = unit_inst
	card.is_fielded = true
	
	var drag_data = card._get_drag_data(Vector2.ZERO)
	_assert(drag_data is Dictionary, "Drag data should be a Dictionary")
	if drag_data is Dictionary:
		_assert(drag_data.get("type") == "unit", "Drag type should be 'unit'")
		_assert(drag_data.get("unit") == unit_inst, "Drag unit should match unit_instance")
		_assert(drag_data.get("source_slot") == 1, "Drag source_slot should be 1")
		_assert(drag_data.get("is_fielded") == true, "Drag is_fielded should be true")
		
	card.free()
	tests_passed += 1

func test_operative_card_drop_validation() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var u1 = UnitInstance.new(repo.get_unit("runner_rampart"))
	var u2 = UnitInstance.new(repo.get_unit("runner_nexus"))
	
	var card = OperativeCard.new()
	card.unit_instance = u1
	card.is_fielded = true
	
	# Drop validation for other unit
	var valid_unit_drag = {
		"type": "unit",
		"unit": u2,
		"source_slot": 0,
		"is_fielded": true
	}
	_assert(card._can_drop_data(Vector2.ZERO, valid_unit_drag), "Card should accept drop of a different unit")
	
	# Reject drop of self
	var self_drag = {
		"type": "unit",
		"unit": u1,
		"source_slot": 1,
		"is_fielded": true
	}
	_assert(not card._can_drop_data(Vector2.ZERO, self_drag), "Card should reject drop of itself")
	
	# Drop validation for augment
	var aug_res = repo.get_augment("common_kinetic_plating")
	var aug_drag = {
		"type": "augment",
		"resource": aug_res
	}
	_assert(card._can_drop_data(Vector2.ZERO, aug_drag), "Card should accept compatible augment drop")
	
	card.free()
	tests_passed += 1

func test_empty_slot_drop_validation() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	# District 1: Max crew 2. Slots 0, 1 unlocked. Slot 2 locked.
	var crew_mgr = CrewManager.new(1, repo)
	var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
	var u2 = UnitInstance.new(repo.get_unit("corp_sentinel"))
	var u3 = UnitInstance.new(repo.get_unit("fixer_broker"))
	
	crew_mgr.place_unit_on_grid(u1, 0)
	crew_mgr.place_unit_on_grid(u2, 1)
	crew_mgr.benched_units.append(u3)
	
	var PrepScreenScript = preload("res://src/ui/screens/PrepScreen.gd")
	var slot0_btn = PrepScreenScript.TacticalEmptySlot.new()
	slot0_btn.slot_idx = 0
	slot0_btn.crew_mgr = crew_mgr
	
	var slot2_btn = PrepScreenScript.TacticalEmptySlot.new()
	slot2_btn.slot_idx = 2
	slot2_btn.crew_mgr = crew_mgr
	
	# 1. Dragging benched unit u3 to locked slot 2 should be rejected
	var benched_drag = {"type": "unit", "unit": u3, "is_fielded": false}
	_assert(not slot2_btn._can_drop_data(Vector2.ZERO, benched_drag), "Empty slot 2 (locked in D1) must reject drop")
	
	# 2. Dragging benched unit u3 when crew cap (2/2) reached should be rejected even on unlocked slots
	var slot1_btn = PrepScreenScript.TacticalEmptySlot.new()
	slot1_btn.slot_idx = 1
	slot1_btn.crew_mgr = crew_mgr
	_assert(not slot1_btn._can_drop_data(Vector2.ZERO, benched_drag), "Benched unit cannot drop to empty slot when crew max 2 is reached")
	
	# 3. Fielded unit moving/repositioning should be allowed on unlocked slots
	var fielded_drag = {"type": "unit", "unit": u1, "is_fielded": true, "source_slot": 0}
	var empty_unlocked_btn = PrepScreenScript.TacticalEmptySlot.new()
	empty_unlocked_btn.slot_idx = 1
	empty_unlocked_btn.crew_mgr = crew_mgr
	_assert(empty_unlocked_btn._can_drop_data(Vector2.ZERO, fielded_drag), "Fielded unit can move to unlocked empty slot")
	
	slot0_btn.free()
	slot2_btn.free()
	slot1_btn.free()
	empty_unlocked_btn.free()
	tests_passed += 1

func test_grid_and_bench_swapping_mechanics() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(4, repo)
	
	var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
	var u2 = UnitInstance.new(repo.get_unit("corp_sentinel"))
	var u3 = UnitInstance.new(repo.get_unit("fixer_broker"))
	
	# Place u1 and u2 on grid
	crew_mgr.place_unit_on_grid(u1, 0)
	crew_mgr.place_unit_on_grid(u2, 1)
	crew_mgr.benched_units.append(u3)
	
	# 1. Grid-to-Grid Swap (0 <-> 1)
	var swap_ok = crew_mgr.swap_grid_slots(0, 1)
	_assert(swap_ok, "Grid swap should succeed")
	_assert(crew_mgr.tactical_grid[0] == u2, "Slot 0 should now have u2")
	_assert(crew_mgr.tactical_grid[1] == u1, "Slot 1 should now have u1")
	
	# 2. Bench-to-Grid Deploy & Displacement (u3 to slot 1, displacing u1 to bench)
	var deploy_ok = crew_mgr.deploy_bench_to_grid(0, 1)
	_assert(deploy_ok, "Deploy bench to grid should succeed")
	_assert(crew_mgr.tactical_grid[1] == u3, "Slot 1 should now have u3")
	_assert(crew_mgr.benched_units.has(u1), "u1 should now be displaced to bench")
	
	tests_passed += 1

func test_tactical_tether_overlay() -> void:
	var overlay = TetherOverlayScript.new()
	_assert(overlay.active_tethers.is_empty(), "Overlay should start with no tethers")
	
	overlay.add_tether(Vector2(50, 50), Vector2(150, 50), TetherOverlayScript.COLOR_TANK_GUARD, "Guard")
	_assert(overlay.active_tethers.size() == 1, "Overlay should have 1 tether")
	_assert(overlay.active_tethers[0]["label"] == "Guard", "Tether label should match")
	_assert(overlay.active_tethers[0]["color"] == TetherOverlayScript.COLOR_TANK_GUARD, "Tether color should match")

	
	overlay.clear_tethers()
	_assert(overlay.active_tethers.is_empty(), "Overlay should be clear after clear_tethers()")
	
	overlay.free()
	tests_passed += 1

func test_operative_card_formation_badges() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var tank_res = repo.get_unit("runner_blitz")
	var slasher_res = repo.get_unit("runner_slasher")
	var aug_res = repo.get_augment("rare_kinetic_kinetic_overdrive")
	
	_assert(not tank_res.get_formation_badge_text().is_empty(), "Tank role should provide formation badge text")
	_assert(tank_res.get_formation_badge_text().contains("🛡️"), "Tank badge should have shield icon")
	
	_assert(slasher_res.has_directional(), "Slasher should have directional passive")
	_assert(slasher_res.get_formation_symbol() == "⮜", "Slasher symbol should be Left arrow")
	_assert(slasher_res.get_formation_badge_text().contains("⮜"), "Slasher badge text should contain left arrow")
	
	var card_scene = preload("res://src/ui/components/OperativeCard.tscn")
	var card = card_scene.instantiate()
	var slasher_inst = UnitInstance.new(slasher_res)
	card.setup(slasher_inst, true, ["🛡️ Guarded from Left (+120 S)"])
	
	var badge = card.get_node_or_null("Margin/VBox/FormationBadge")
	_assert(badge != null, "OperativeCard should have FormationBadge node")
	if badge:
		_assert(badge.visible == true, "FormationBadge should be visible")
		_assert(badge.text.contains("⮜"), "FormationBadge text should contain directional symbol")
		_assert(badge.text.contains("BUFFED"), "FormationBadge should show BUFFED when receiving buffs")
		
	card.free()
	tests_passed += 1
