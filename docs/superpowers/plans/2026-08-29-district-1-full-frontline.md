# District 1 Full Frontline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the player field 3 operatives across the full bottom row in District 1 while D1 enemy squads stay at 2.

**Architecture:** Raise `DISTRICT_CREW_LIMITS[1]` from 2 to 3, and decouple enemy squad size from that dict by introducing a parallel `DISTRICT_ENEMY_COUNTS` constant that `CombatBridge` reads instead. Sync the affected unit tests.

**Tech Stack:** Godot 4.6 / GDScript. Headless test runner at `tests/test_runner.gd`.

---

## Already done (do NOT redo)

Commit `78d9821` ("feat(tactical): unlock full 3-slot frontline in District 1") already landed:

- `CrewManager.is_slot_unlocked(2)` returns `true` unconditionally.
- `CrewManager.get_slot_unlock_district(2)` returns `1`.
- `CrewManager.gd:35-57` doc comments updated (frontline = slots 0,1,2 at D1).
- `tests/test_tactical_grid.gd` `test_district_slot_unlock_curve` updated to assert slot 2 unlocked at D1.

What remains is the **field-cap** and **enemy-count** half of the spec, plus the test fallout from raising the cap.

## Spec reference

`docs/superpowers/specs/2026-08-29-district-1-full-frontline-design.md`

## File structure

| File | Responsibility | Change |
|---|---|---|
| `src/core/Constants.gd` | Balance constants | `DISTRICT_CREW_LIMITS[1]` 2→3; add `DISTRICT_ENEMY_COUNTS` |
| `src/systems/CombatBridge.gd` | Enemy squad generation | Read `DISTRICT_ENEMY_COUNTS` instead of `DISTRICT_CREW_LIMITS` |
| `tests/test_data_integrity.gd` | Constant-sync guard | New `test_district_enemy_counts_vs_crew_limits` |
| `tests/test_run_manager.gd` | Run init | `get_max_field_units()` expectation 2→3 |
| `tests/test_crew_validator.gd` | Crew-size validation | D1 allows 3, rejects 4 |
| `tests/test_crew_manager.gd` | Deploy/recall/sell | Rework two D1-cap-of-2 scenarios for cap 3 |
| `tests/test_tactical_drag_and_tethers.gd` | Drop validation | Rework `test_empty_slot_drop_validation` for cap 3 + unlocked slot 2 |
| `tests/test_tactical_grid.gd` | Slot unlock curve | Comment fix "Max crew 2"→"Max crew 3" |

## Test command

Run the full suite (fast, ~seconds):

```bash
"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s tests/test_runner.gd
```

Expected baseline before changes: `Passed: 20 | Failed: 0`, `Assertions: 561 Passed | 0 Failed`.
Watch stderr for `[FAIL] Assertion failed:` lines — the void-returning tactical suites print those without failing the run count, so read them.

---

## Task 1: Add `DISTRICT_ENEMY_COUNTS`, raise D1 crew cap

**Files:**
- Modify: `src/core/Constants.gd:12-19`
- Test: `tests/test_data_integrity.gd`

- [ ] **Step 1: Write the failing test**

Add this method to `tests/test_data_integrity.gd` (anywhere among the other `test_` methods):

```gdscript
func test_district_enemy_counts_vs_crew_limits() -> Dictionary:
	# D1 is the intentional divergence: player fields 3, enemies stay 2.
	if Constants.DISTRICT_CREW_LIMITS.get(1, -1) != 3:
		return {"passed": false, "message": "D1 crew cap should be 3, got %d" % Constants.DISTRICT_CREW_LIMITS.get(1, -1), "assertions": 1}
	if Constants.DISTRICT_ENEMY_COUNTS.get(1, -1) != 2:
		return {"passed": false, "message": "D1 enemy count should be 2, got %d" % Constants.DISTRICT_ENEMY_COUNTS.get(1, -1), "assertions": 2}

	# Districts 2+ must stay in lockstep between the two dicts.
	for d in [2, 3, 4, 5]:
		var crew = Constants.DISTRICT_CREW_LIMITS.get(d, -1)
		var enemies = Constants.DISTRICT_ENEMY_COUNTS.get(d, -2)
		if crew != enemies:
			return {"passed": false, "message": "District %d: crew cap %d != enemy count %d (must match for d>=2)" % [d, crew, enemies], "assertions": 3}

	return {"passed": true, "assertions": 3}
```

- [ ] **Step 2: Run the suite, verify this test fails**

Run: `"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s tests/test_runner.gd`
Expected: `[FAIL] test_district_enemy_counts_vs_crew_limits` — "D1 crew cap should be 3, got 2" (and `DISTRICT_ENEMY_COUNTS` will also be undefined — a parse error is also acceptable proof it's not yet there).

- [ ] **Step 3: Implement the constant changes**

In `src/core/Constants.gd`, replace the `# District Crew Limits` block (lines 12-19):

```gdscript
# District Crew Limits (max operatives the PLAYER can field)
# NOTE: keep in lockstep with DISTRICT_ENEMY_COUNTS below for districts >= 2.
# District 1 intentionally diverges: player fields 3, enemy squads stay 2.
const DISTRICT_CREW_LIMITS: Dictionary = {
	1: 3,
	2: 4,
	3: 5,
	4: 6,
	5: 6
}

# District enemy squad size (non-boss minion count).
# Tracks DISTRICT_CREW_LIMITS for districts >= 2; D1 stays at 2 by design so the
# opening district is not made harder by the player's extra frontline slot.
const DISTRICT_ENEMY_COUNTS: Dictionary = {
	1: 2,
	2: 4,
	3: 5,
	4: 6,
	5: 6
}
```

- [ ] **Step 4: Run the suite, verify the new test passes**

Run: `"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s tests/test_runner.gd`
Expected: `[PASS] test_district_enemy_counts_vs_crew_limits`. Other tests will now fail (that is expected — Tasks 2-6 fix them).

- [ ] **Step 5: Commit**

```bash
git add src/core/Constants.gd tests/test_data_integrity.gd
git commit -m "feat(balance): raise D1 field cap to 3, add DISTRICT_ENEMY_COUNTS"
```

---

## Task 2: Point enemy generation at `DISTRICT_ENEMY_COUNTS`

**Files:**
- Modify: `src/systems/CombatBridge.gd:74`

- [ ] **Step 1: Confirm the current failing state**

Run the suite. `tests/test_game_manager.gd::test_*` that checks "District 2 enemy squad should have 4 units" still passes (D2 count unchanged), but with the raw `DISTRICT_CREW_LIMITS` read, D1 combats now generate 3 enemies. No test asserts D1 enemy count directly yet, so add the check first.

Add to `tests/test_game_manager.gd` a sibling of the existing D2 squad-size test — find the test around line 69-80 and add after it:

```gdscript
func test_district_1_enemy_squad_stays_two() -> Dictionary:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var synergies = SynergyReport.new()
	var payload = CombatBridge.package_combat_payload([blitz], synergies, 1, false, repo)
	var enemy_squad: Array = payload.get("enemy_squad", [])
	if enemy_squad.size() != 2:
		return {"passed": false, "message": "District 1 non-boss enemy squad should have 2 units, got %d" % enemy_squad.size(), "assertions": 1}
	return {"passed": true, "assertions": 1}
```

(Check the top of `tests/test_game_manager.gd` for the exact preload alias for `DataRepository` — reuse whatever the file already uses; it may be `DataRepoScript` or accessed via a member `repo`. If the file has an `_init` that sets `var repo`, use that instead of re-loading.)

- [ ] **Step 2: Run the suite, verify the new test fails**

Expected: `[FAIL] test_district_1_enemy_squad_stays_two` — "got 3".

- [ ] **Step 3: Implement**

`src/systems/CombatBridge.gd`, line 74, change:

```gdscript
	var enemy_count = Constants.DISTRICT_CREW_LIMITS.get(district_id, 2)
```

to:

```gdscript
	var enemy_count = Constants.DISTRICT_ENEMY_COUNTS.get(district_id, 2)
```

- [ ] **Step 4: Run the suite, verify the new test passes**

Expected: `[PASS] test_district_1_enemy_squad_stays_two`; `test_game_manager` D2 squad-size test still `[PASS]`.

- [ ] **Step 5: Commit**

```bash
git add src/systems/CombatBridge.gd tests/test_game_manager.gd
git commit -m "feat(combat): enemy squad size reads DISTRICT_ENEMY_COUNTS (D1 stays 2v3)"
```

---

## Task 3: Fix `test_run_manager.gd` crew-cap expectation

**Files:**
- Modify: `tests/test_run_manager.gd:22-23`

- [ ] **Step 1: Update the assertion**

Change:

```gdscript
	if run.crew_mgr.get_max_field_units() != 2:
		return {"passed": false, "message": "District 1 crew cap should be 2", "assertions": 4}
```

to:

```gdscript
	if run.crew_mgr.get_max_field_units() != 3:
		return {"passed": false, "message": "District 1 crew cap should be 3", "assertions": 4}
```

- [ ] **Step 2: Run the suite**

Expected: `test_run_manager` suite `[PASS]` for all its methods.

- [ ] **Step 3: Commit**

```bash
git add tests/test_run_manager.gd
git commit -m "test(run-manager): D1 crew cap is now 3"
```

---

## Task 4: Fix `test_crew_validator.gd` size limits

**Files:**
- Modify: `tests/test_crew_validator.gd:35-55`

- [ ] **Step 1: Rewrite `test_district_size_limits`**

Replace the whole method body (keep the signature) with:

```gdscript
func test_district_size_limits() -> Dictionary:
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	var sentinel = UnitInstance.new(repo.get_unit("corp_sentinel"))
	var dash = UnitInstance.new(repo.get_unit("runner_dash"))

	var crew_3: Array[UnitInstance] = [blitz, ghost, sentinel]
	var res_1 = CrewValidator.validate_crew_size(crew_3, 1)
	if not res_1.valid:
		return {"passed": false, "message": "District 1 should allow 3 units", "assertions": 1}

	var crew_4: Array[UnitInstance] = [blitz, ghost, sentinel, dash]
	var res_2 = CrewValidator.validate_crew_size(crew_4, 1)
	if res_2.valid:
		return {"passed": false, "message": "District 1 should reject 4 units", "assertions": 2}

	# District 2 should allow 4 units (limit is 4)
	var res_3 = CrewValidator.validate_crew_size(crew_4, 2)
	if not res_3.valid:
		return {"passed": false, "message": "District 2 should allow 4 units", "assertions": 3}

	return {"passed": true, "assertions": 3}
```

(If `repo.get_unit("runner_dash")` returns null, substitute any other recruitable unit id already used elsewhere in the tests, e.g. `fixer_broker`.)

- [ ] **Step 2: Run the suite**

Expected: `test_crew_validator` all `[PASS]`.

- [ ] **Step 3: Commit**

```bash
git add tests/test_crew_validator.gd
git commit -m "test(crew-validator): D1 allows 3, rejects 4"
```

---

## Task 5: Fix `test_crew_manager.gd` deploy/recall + sell scenarios

**Files:**
- Modify: `tests/test_crew_manager.gd:12-46` (`test_deploy_and_recall`)
- Modify: `tests/test_crew_manager.gd:150-187` (`test_sell_and_replace_starting_unit`)

- [ ] **Step 1: Rewrite `test_deploy_and_recall`**

Replace the whole method (keep signature). The intent is unchanged: fill to the D1 cap, prove the next deploy is rejected, then recall.

```gdscript
func test_deploy_and_recall() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo) # District 1: field cap 3

	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	var sentinel = UnitInstance.new(repo.get_unit("corp_sentinel"))
	var broker = UnitInstance.new(repo.get_unit("fixer_broker"))

	crew_mgr.add_unit_to_bench(blitz)
	crew_mgr.add_unit_to_bench(ghost)
	crew_mgr.add_unit_to_bench(sentinel)
	crew_mgr.add_unit_to_bench(broker)

	if crew_mgr.benched_units.size() != 4:
		return {"passed": false, "message": "Expected 4 benched units", "assertions": 1}

	# Deploy up to the D1 cap of 3
	if not crew_mgr.deploy_unit_to_field(0) or crew_mgr.fielded_units.size() != 1:
		return {"passed": false, "message": "Failed to deploy 1st unit", "assertions": 2}
	if not crew_mgr.deploy_unit_to_field(0) or crew_mgr.fielded_units.size() != 2:
		return {"passed": false, "message": "Failed to deploy 2nd unit", "assertions": 3}
	if not crew_mgr.deploy_unit_to_field(0) or crew_mgr.fielded_units.size() != 3:
		return {"passed": false, "message": "Failed to deploy 3rd unit", "assertions": 4}

	# Deploy 4th (Should FAIL because District 1 cap is 3)
	var d4_fail = crew_mgr.deploy_unit_to_field(0)
	if d4_fail or crew_mgr.fielded_units.size() != 3:
		return {"passed": false, "message": "Should not exceed District 1 limit of 3 units", "assertions": 5}

	# Recall 1st
	var r_ok = crew_mgr.recall_unit_to_bench(0)
	if not r_ok or crew_mgr.fielded_units.size() != 2 or crew_mgr.benched_units.size() != 2:
		return {"passed": false, "message": "Recall unit failed", "assertions": 6}

	return {"passed": true, "assertions": 6}
```

- [ ] **Step 2: Rewrite `test_sell_and_replace_starting_unit`**

Replace the whole method (keep signature). Intent unchanged: reach the field cap with one unit benched, sell a fielded unit, deploy the benched one into the freed slot.

```gdscript
func test_sell_and_replace_starting_unit() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo)
	var shop_mgr = ShopManager.new(20)

	var blitz = UnitInstance.new(repo.get_unit("runner_blitz"))
	var dash = UnitInstance.new(repo.get_unit("runner_dash"))
	var ghost = UnitInstance.new(repo.get_unit("street_ghost"))
	var sentinel = UnitInstance.new(repo.get_unit("corp_sentinel"))

	# Field 3 units (District 1 cap = 3), bench 1 unit
	crew_mgr.add_unit(blitz)
	crew_mgr.add_unit(dash)
	crew_mgr.add_unit(sentinel)
	crew_mgr.add_unit(ghost)

	if crew_mgr.fielded_units.size() != 3 or crew_mgr.benched_units.size() != 1:
		return {"passed": false, "message": "Expected 3 fielded, 1 benched", "assertions": 1}

	# Sell starting unit blitz
	var refund = shop_mgr.sell_unit(blitz, crew_mgr)
	if refund <= 0:
		return {"passed": false, "message": "Selling blitz should provide credit refund", "assertions": 2}
	if crew_mgr.fielded_units.size() != 2:
		return {"passed": false, "message": "Field size should be 2 after selling blitz", "assertions": 3}

	# Deploy benched ghost into the open slot
	var deploy_ok = crew_mgr.field_unit(ghost)
	if not deploy_ok:
		return {"passed": false, "message": "field_unit(ghost) should successfully deploy ghost from bench", "assertions": 4}
	if crew_mgr.fielded_units.size() != 3 or not crew_mgr.fielded_units.has(ghost):
		return {"passed": false, "message": "Ghost should now be in fielded_units", "assertions": 5}
	if not crew_mgr.benched_units.is_empty():
		return {"passed": false, "message": "Bench should now be empty", "assertions": 6}

	# Bench ghost
	var bench_ok = crew_mgr.bench_unit(ghost)
	if not bench_ok or crew_mgr.fielded_units.size() != 2 or crew_mgr.benched_units.size() != 1:
		return {"passed": false, "message": "bench_unit(ghost) should recall ghost to bench", "assertions": 7}

	return {"passed": true, "assertions": 7}
```

- [ ] **Step 3: Run the suite**

Expected: `test_crew_manager` all `[PASS]`. If `runner_dash` or `fixer_broker` is not a valid unit id, the run will error on a null `UnitInstance` — swap for an id confirmed present in `data/units/` (grep the dir).

- [ ] **Step 4: Commit**

```bash
git add tests/test_crew_manager.gd
git commit -m "test(crew-manager): rework D1 deploy/sell scenarios for field cap 3"
```

---

## Task 6: Fix `test_tactical_drag_and_tethers.gd` drop validation

**Files:**
- Modify: `tests/test_tactical_drag_and_tethers.gd:107-145` (`test_empty_slot_drop_validation`)

- [ ] **Step 1: Read the current method and the `_can_drop_data` implementation**

Read `tests/test_tactical_drag_and_tethers.gd:107-150` and `src/ui/screens/PrepScreen.gd` `TacticalEmptySlot._can_drop_data` so the rewrite matches real behavior. Key change: slot 2 is no longer locked in D1, and the cap is 3 not 2.

- [ ] **Step 2: Rewrite the method**

Replace `test_empty_slot_drop_validation` (keep signature). New intent: with the D1 field cap (3) reached, a benched unit cannot drop onto any empty slot (including the now-unlocked slot 2); a fielded unit may still reposition; the top row stays locked.

```gdscript
func test_empty_slot_drop_validation() -> void:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")

	# District 1: field cap 3. Full bottom row (0,1,2) unlocked. Top row (3,4,5) locked.
	var crew_mgr = CrewManager.new(1, repo)
	var u1 = UnitInstance.new(repo.get_unit("runner_blitz"))
	var u2 = UnitInstance.new(repo.get_unit("corp_sentinel"))
	var u3 = UnitInstance.new(repo.get_unit("fixer_broker"))
	var u4 = UnitInstance.new(repo.get_unit("street_ghost"))

	crew_mgr.place_unit_on_grid(u1, 0)
	crew_mgr.place_unit_on_grid(u2, 1)
	crew_mgr.place_unit_on_grid(u3, 2) # fills the D1 cap of 3
	crew_mgr.benched_units.append(u4)

	var PrepScreenScript = preload("res://src/ui/screens/PrepScreen.gd")

	# 1. Benched unit u4 cannot drop onto locked top-row slot 4
	var slot4_btn = PrepScreenScript.TacticalEmptySlot.new()
	slot4_btn.slot_idx = 4
	slot4_btn.crew_mgr = crew_mgr
	var benched_drag = {"type": "unit", "unit": u4, "is_fielded": false}
	_assert(not slot4_btn._can_drop_data(Vector2.ZERO, benched_drag), "Empty slot 4 (locked top row in D1) must reject drop")

	# 2. Benched unit u4 cannot drop even onto an unlocked bottom slot when the field cap (3/3) is reached.
	#    (Free a slot by recalling u3 first, then re-fill to prove the cap check, not the empty-slot check.)
	crew_mgr.recall_unit_to_bench(crew_mgr.benched_units.size()) # no-op guard; see step 1 for real API
	# -- if recall API differs, instead remove u3 from the grid directly, then:
	# crew_mgr.place_unit_on_grid(u3, 2) to restore, keeping 3 fielded.

	var slot_full_btn = PrepScreenScript.TacticalEmptySlot.new()
	slot_full_btn.slot_idx = 2
	slot_full_btn.crew_mgr = crew_mgr

	# 3. Fielded unit repositioning onto an unlocked empty slot is allowed
	crew_mgr.place_unit_on_grid(u3, 2) # ensure 3 fielded
	# move u1 (slot 0) -> slot ... there is no empty bottom slot at 3/3, so test reposition via swap target
	var fielded_drag = {"type": "unit", "unit": u1, "is_fielded": true, "source_slot": 0}
	var reposition_btn = PrepScreenScript.TacticalEmptySlot.new()
	reposition_btn.slot_idx = 0
	reposition_btn.crew_mgr = crew_mgr
	_assert(reposition_btn._can_drop_data(Vector2.ZERO, fielded_drag), "Fielded unit may drop back onto its own/unlocked slot")

	tests_passed += 1
```

**NOTE for the implementer:** the block above is a sketch — Step 1 requires reading the real `_can_drop_data` signature and `CrewManager` recall API (`recall_unit_to_bench(idx)` takes a *fielded* index, not a bench index). Write the method so it concretely proves: (a) locked top-row slot rejects a benched drop, (b) an unlocked bottom slot rejects a benched drop while 3/3 fielded, (c) a benched drop **succeeds** onto an unlocked bottom slot once a slot is freed (2/3 fielded). Do not leave placeholder comments in the committed test.

- [ ] **Step 3: Run the suite, watch stderr**

Run: `"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s tests/test_runner.gd`
Expected: no `[FAIL] Assertion failed:` lines from `test_tactical_drag_and_tethers`.

- [ ] **Step 4: Commit**

```bash
git add tests/test_tactical_drag_and_tethers.gd
git commit -m "test(tactical-drag): rework D1 empty-slot drop validation for cap 3 + unlocked slot 2"
```

---

## Task 7: Comment cleanup in `test_tactical_grid.gd`

**Files:**
- Modify: `tests/test_tactical_grid.gd:45`

- [ ] **Step 1: Fix the stale comment**

Change:

```gdscript
	# District 1: Full bottom row (0, 1, 2) unlocked (Max crew 2). Top row (3, 4, 5) locked.
```

to:

```gdscript
	# District 1: Full bottom row (0, 1, 2) unlocked (Max crew 3). Top row (3, 4, 5) locked.
```

- [ ] **Step 2: Run the full suite one final time**

Run: `"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s tests/test_runner.gd`
Expected: `Passed: 20 | Failed: 0`, `0 Assertions Failed`, no `[FAIL] Assertion failed:` on stderr.

- [ ] **Step 3: Commit**

```bash
git add tests/test_tactical_grid.gd
git commit -m "docs(test): correct D1 max-crew comment to 3"
```

---

## Task 8: Regenerate balance sims (validation gate)

**Files:**
- Regenerate: `data/balance_simulation_report.md`
- Regenerate: `data/community_analytics_report.md` (if the persona eval touches it)

- [ ] **Step 1: Run the Monte Carlo**

```bash
"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . -s src/tools/BalanceSimulator.gd -- --runs=10000
```

- [ ] **Step 2: Diff the report**

```bash
git diff data/balance_simulation_report.md
```

Compare against the `19f7c91` baseline. Check specifically:
- District 1 conditional clear probability — expect flat or slightly up, not down.
- Combat closeness / victory margin for D1 — expect wider player margins.
- Economy: avg gold on hand entering D2 — flag if it jumps materially.

- [ ] **Step 3: Run the persona eval**

```bash
"/c/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless -s src/tools/PeterPlayerEvaluator.gd
```

- [ ] **Step 4: Record findings + commit reports**

Write a 3-5 line summary of the D1 clear-rate / margin / economy deltas into the plan's Task 8 section or the commit body.

```bash
git add data/balance_simulation_report.md data/community_analytics_report.md
git commit -m "chore(balance): re-sim after D1 3-wide frontline (10k runs)"
```

- [ ] **Step 5: Decision checkpoint**

If D1 clear probability jumped hard (e.g. >8 points over baseline) or D2-entry gold inflated notably: STOP and report to the user. The spec's designated lever is dialing back commit `19f7c91`'s early synergy shop bias — that is a **separate** follow-up decision, not part of this plan.

---

## Self-review

**Spec coverage:**
- D1 crew cap 2→3 — Task 1 ✅
- `DISTRICT_ENEMY_COUNTS` constant — Task 1 ✅
- `is_slot_unlocked(2)` / `get_slot_unlock_district(2)` / comments — already done (`78d9821`) ✅
- `CombatBridge` reads new constant — Task 2 ✅
- `test_data_integrity` sync assertion — Task 1 ✅
- test fallout (crew_manager, crew_validator, run_manager, tactical_drag, tactical_grid) — Tasks 3-7 ✅
- Re-sim `BalanceSimulator` + `PeterPlayerEvaluator` — Task 8 ✅
- UI auto-updates (PrepScreen, DistrictMapScreen, CombatMockArena) — verified read-only in spec, no code change needed ✅

**Placeholder scan:** Task 6's method body is explicitly flagged as a sketch requiring the implementer to read the real API first; the "No Placeholders" rule is relaxed there because the drop-validation API was not read during planning. Every other task has concrete code.

**Type consistency:** `DISTRICT_ENEMY_COUNTS` name used identically in Constants, CombatBridge, and both new tests. `get_max_field_units()`, `deploy_unit_to_field(idx)`, `recall_unit_to_bench(idx)`, `field_unit(unit)`, `bench_unit(unit)`, `place_unit_on_grid(unit, idx)` all match existing `CrewManager` usage in the current tests.

**Known risk:** Concurrent session `78d9821` shows another agent is active in this feature area. Before each commit, re-check `git status` / `git log` — if the other session bumps `DISTRICT_CREW_LIMITS[1]` first, drop Task 1's crew-cap line and rebase the rest.
