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
	test_grid_and_bench_swapping_mechanics()
	test_tactical_tether_overlay()
	
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
