class_name TestTacticalGrid
extends RefCounted

## Unit test suite for 2x3 Strategic Deployment Grid and Directional Adjacency Synergies

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
	print("--- Running TestTacticalGrid ---")
	
	test_district_slot_unlock_curve()
	test_grid_placement_and_swapping()
	test_directional_adjacency_queries()
	test_formation_synergy_calculations()
	test_combat_bridge_grid_packaging()
	
	print("TestTacticalGrid Complete. Passed: %d, Failed: %d (Assertions: %d passed, %d failed)" % [
		tests_passed, tests_failed, assertions_passed, assertions_failed
	])
	return {
		"suite_name": "TestTacticalGrid",
		"passed": tests_failed == 0 and assertions_failed == 0,
		"tests_passed": tests_passed,
		"tests_failed": tests_failed,
		"assertions_passed": assertions_passed,
		"assertions_failed": assertions_failed
	}

func test_district_slot_unlock_curve() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	# District 1: Full bottom row (0, 1, 2) unlocked (Max crew 3). Top row (3, 4, 5) locked.
	var crew_d1 = CrewManager.new(1, repo)
	_assert(crew_d1.is_slot_unlocked(0), "D1: Slot 0 (Bottom Left) should be unlocked")
	_assert(crew_d1.is_slot_unlocked(1), "D1: Slot 1 (Bottom Center) should be unlocked")
	_assert(crew_d1.is_slot_unlocked(2), "D1: Slot 2 (Bottom Right) should be unlocked for positioning diversity")
	_assert(not crew_d1.is_slot_unlocked(4), "D1: Slot 4 (Top Center) should be locked")
	_assert(not crew_d1.is_slot_unlocked(3), "D1: Slot 3 (Top Left) should be locked")
	_assert(not crew_d1.is_slot_unlocked(5), "D1: Slot 5 (Top Right) should be locked")
	
	# District 2: Top Center (Slot 4) unlocks in D2 (Max crew 4)
	var crew_d2 = CrewManager.new(2, repo)
	_assert(crew_d2.is_slot_unlocked(0) and crew_d2.is_slot_unlocked(1) and crew_d2.is_slot_unlocked(2), "D2: Bottom row should be unlocked")
	_assert(crew_d2.is_slot_unlocked(4), "D2: Slot 4 (Top Center) must be unlocked")
	_assert(not crew_d2.is_slot_unlocked(3), "D2: Slot 3 (Top Left) should be locked")
	_assert(not crew_d2.is_slot_unlocked(5), "D2: Slot 5 (Top Right) should be locked")
	
	# District 3: Top Left (Slot 3) unlocks second past D1
	var crew_d3 = CrewManager.new(3, repo)
	_assert(crew_d3.is_slot_unlocked(4), "D3: Slot 4 (Top Center) must be unlocked")
	_assert(crew_d3.is_slot_unlocked(3), "D3: Slot 3 (Top Left) must be unlocked")
	_assert(not crew_d3.is_slot_unlocked(5), "D3: Slot 5 (Top Right) should be locked")
	
	# District 4: Top Right (Slot 5) unlocks third past D1 -> all 6 unlocked
	var crew_d4 = CrewManager.new(4, repo)
	for i in range(6):
		_assert(crew_d4.is_slot_unlocked(i), "D4: Slot %d should be unlocked" % i)
		
	tests_passed += 1

func test_grid_placement_and_swapping() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(4, repo)
	
	var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
	var u2 = UnitInstance.new(repo.get_unit("runner_rampart"))
	
	# Place u1 on Bottom Left (0) and u2 on Top Center (4)
	var p1 = crew_mgr.place_unit_on_grid(u1, 0)
	var p2 = crew_mgr.place_unit_on_grid(u2, 4)
	
	_assert(p1, "Placing u1 on slot 0 should succeed")
	_assert(p2, "Placing u2 on slot 4 should succeed")
	_assert(crew_mgr.tactical_grid[0] == u1, "Slot 0 should hold u1")
	_assert(crew_mgr.tactical_grid[4] == u2, "Slot 4 should hold u2")
	_assert(u1.grid_slot == 0, "u1 grid_slot should be 0")
	_assert(u2.grid_slot == 4, "u2 grid_slot should be 4")
	_assert(u1.is_frontline(), "u1 on slot 0 should be frontline")
	_assert(u2.is_backline(), "u2 on slot 4 should be backline")
	
	# Swap slots 0 and 4
	var swapped = crew_mgr.swap_grid_slots(0, 4)
	_assert(swapped, "Swapping slots 0 and 4 should succeed")
	_assert(crew_mgr.tactical_grid[0] == u2, "Slot 0 should now hold u2")
	_assert(crew_mgr.tactical_grid[4] == u1, "Slot 4 should now hold u1")
	_assert(u2.grid_slot == 0, "u2 grid_slot should be 0")
	_assert(u1.grid_slot == 4, "u1 grid_slot should be 4")
	
	# Recall slot 0 to bench
	var recalled = crew_mgr.recall_grid_slot_to_bench(0)
	_assert(recalled, "Recalling slot 0 should succeed")
	_assert(crew_mgr.tactical_grid[0] == null, "Slot 0 should now be empty")
	_assert(crew_mgr.benched_units.has(u2), "u2 should now be on bench")
	_assert(u2.grid_slot == -1, "u2 grid_slot should be -1 after recall")
	
	tests_passed += 1

func test_directional_adjacency_queries() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(4, repo)
	
	var tank = UnitInstance.new(repo.get_unit("runner_rampart"))
	var hacker = UnitInstance.new(repo.get_unit("runner_nexus"))
	var sniper = UnitInstance.new(repo.get_unit("corp_deadeye"))
	
	# Frontline: slot 0 (Left: tank), slot 1 (Center: hacker), slot 2 (Right: sniper)
	crew_mgr.place_unit_on_grid(tank, 0)
	crew_mgr.place_unit_on_grid(hacker, 1)
	crew_mgr.place_unit_on_grid(sniper, 2)
	
	# Query from slot 1 (Row 1, Col 1 - Bottom Center):
	var left = crew_mgr.get_adjacent_units(1, 1, Enums.GridDirection.LEFT)
	var right = crew_mgr.get_adjacent_units(1, 1, Enums.GridDirection.RIGHT)
	var same_row = crew_mgr.get_adjacent_units(1, 1, Enums.GridDirection.SAME_ROW)
	var adj = crew_mgr.get_adjacent_units(1, 1, Enums.GridDirection.ADJACENT)
	
	_assert(left.size() == 1 and left[0] == tank, "Unit to left of Center should be Tank")
	_assert(right.size() == 1 and right[0] == sniper, "Unit to right of Center should be Sniper")
	_assert(same_row.size() == 2, "Same row query should return 2 other units")
	_assert(adj.has(tank) and adj.has(sniper), "Adjacent query should contain left Tank and right Sniper")
	
	tests_passed += 1

func test_formation_synergy_calculations() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(4, repo)
	
	var tank = UnitInstance.new(repo.get_unit("runner_rampart"))   # Tank
	var hacker = UnitInstance.new(repo.get_unit("runner_nexus"))   # Hacker
	var sniper = UnitInstance.new(repo.get_unit("corp_deadeye"))   # Sniper
	
	# Place Tank on slot 0 (Row 1, Col 0 - Bottom Left)
	# Place Hacker on slot 1 (Row 1, Col 1 - Bottom Center) -> adjacent to Tank!
	# Place Sniper on slot 4 (Row 0, Col 1 - Top Center) -> Backline!
	crew_mgr.place_unit_on_grid(tank, 0)
	crew_mgr.place_unit_on_grid(hacker, 1)
	crew_mgr.place_unit_on_grid(sniper, 4)
	
	var bonuses = crew_mgr.calculate_formation_bonuses()
	_assert(bonuses.has(hacker), "Bonuses report should include Hacker")
	_assert(bonuses.has(sniper), "Bonuses report should include Sniper")
	
	if bonuses.has(hacker):
		var h_bonus = bonuses[hacker]
		_assert(h_bonus["shield_bonus"] >= 120.0, "Hacker adjacent to Tank should receive at least 120 shield bonus")
		
	if bonuses.has(sniper):
		var s_bonus = bonuses[sniper]
		_assert(s_bonus["crit_bonus"] >= 0.25, "Sniper in Backline (Row 0) should receive +25% Crit bonus")
		
	tests_passed += 1

func test_combat_bridge_grid_packaging() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var crew_mgr = CrewManager.new(2, repo)
	
	var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
	var u2 = UnitInstance.new(repo.get_unit("runner_rampart"))
	crew_mgr.place_unit_on_grid(u1, 0)
	crew_mgr.place_unit_on_grid(u2, 1)
	
	var payload = CombatBridge.package_combat_payload(
		crew_mgr.fielded_units,
		crew_mgr.active_synergy_report,
		2,
		false,
		repo,
		null,
		crew_mgr.tactical_grid
	)
	
	_assert(payload.has("player_grid"), "Combat payload should contain player_grid")
	_assert(payload.has("enemy_grid"), "Combat payload should contain enemy_grid")
	
	var p_grid: Array = payload["player_grid"]
	var e_grid: Array = payload["enemy_grid"]
	_assert(p_grid.size() == 6, "Player grid should have size 6")
	_assert(e_grid.size() == 6, "Enemy grid should have size 6")
	_assert(p_grid[0] == u1, "Player grid slot 0 should contain u1")
	_assert(p_grid[1] == u2, "Player grid slot 1 should contain u2")
	
	tests_passed += 1
