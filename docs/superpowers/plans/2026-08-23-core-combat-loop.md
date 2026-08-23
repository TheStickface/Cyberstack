# Core Combat Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the automated fight-resolution engine described in Section 3 ("Combat System") of `docs/superpowers/specs/2026-06-20-cyberstack-design.md` — two crews of units resolve a fight automatically, acting in speed order, using basic attacks and a single mana-gated signature ability, until one side is defeated.

**Architecture:** Pure GDScript simulation core with no scene-tree or rendering dependency, so it can run and be tested entirely headless. Three plain `RefCounted` classes — `Unit`, `Ability`, `CombatSimulator` — plus a hand-rolled test harness (no external addon) that discovers and runs `test_*.gd` files via `godot --headless --script`. A small demo script proves the loop end-to-end by simulating one fight and printing the log.

**Out of scope for this plan** (deferred to later plans, per the design spec's own sequencing): unit roles/augment slots, faction traits, augment tag chains, RNG/crit/dodge, the shop/economy layer, and any visual/scene representation of combat. This plan only builds the deterministic fight resolver.

**Tech Stack:** Godot 4.6.3 (GDScript), no external addons or plugins.

---

## Prerequisites

Godot 4.6.3 is installed at:

```
C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe
```

(The console build is used everywhere below so stdout/stderr are visible in the terminal — the non-console `Godot_v4.6.3-stable_win64.exe` works identically but suppresses console output on Windows.)

All commands below assume the current working directory is the repository root (`C:/Dev/Cyberstack`) and are given in Git Bash / POSIX-shell form. In PowerShell, the same command is:

```powershell
& "C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```

There is no project yet — Task 1 creates it.

---

### Task 1: Project scaffold

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `combat/entities/.gitkeep`
- Create: `combat/simulation/.gitkeep`
- Create: `combat/demo/.gitkeep`
- Create: `tests/.gitkeep`

- [ ] **Step 1: Create the Godot project file**

```
config_version=5

[application]

config/name="Cyberstack"
config/features=PackedStringArray("4.6")
```

Save as `project.godot` in the repository root.

- [ ] **Step 2: Create `.gitignore`**

```
# Godot 4+ engine-generated cache
.godot/
```

- [ ] **Step 3: Create the folder skeleton**

Create these empty placeholder files (Godot/git don't track empty directories, so each folder gets a `.gitkeep`):
- `combat/entities/.gitkeep`
- `combat/simulation/.gitkeep`
- `combat/demo/.gitkeep`
- `tests/.gitkeep`

- [ ] **Step 4: Verify the project loads headlessly**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --path . --quit
```
Expected: prints the Godot engine banner (`Godot Engine v4.6.3...`) and exits with code 0. No `SCRIPT ERROR` or `ERROR` lines.

- [ ] **Step 5: Commit**

```bash
git add project.godot .gitignore combat tests
git commit -m "chore: scaffold Godot project for core combat loop"
```

---

### Task 2: Test harness

**Files:**
- Create: `tests/test_case.gd`
- Create: `tests/test_runner.gd`
- Test (temporary, deleted at end of this task): `tests/test_smoke.gd`

- [ ] **Step 1: Create the test case base class**

`tests/test_case.gd`:
```gdscript
extends RefCounted

var _pass_count := 0
var _fail_count := 0
var _failures: Array[String] = []

func assert_eq(actual, expected, message := "") -> void:
	if actual == expected:
		_pass_count += 1
	else:
		_fail_count += 1
		var msg := message if message != "" else "expected %s, got %s" % [expected, actual]
		_failures.append(msg)

func get_results() -> Dictionary:
	return {"pass": _pass_count, "fail": _fail_count, "failures": _failures}
```

- [ ] **Step 2: Create the test runner**

`tests/test_runner.gd`:
```gdscript
extends SceneTree

func _initialize() -> void:
	var total_pass := 0
	var total_fail := 0
	var all_failures: Array[String] = []
	var test_files := _find_test_files("res://tests")

	for file_path in test_files:
		var script = load(file_path)
		if script == null or not (script is GDScript) or not script.can_instantiate():
			all_failures.append("%s: failed to load (parse/compile error, see output above)" % file_path)
			total_fail += 1
			continue

		var instance = script.new()
		if not instance.has_method("get_results"):
			continue

		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				instance.call(method_name)

		var results: Dictionary = instance.get_results()
		total_pass += results["pass"]
		total_fail += results["fail"]
		for failure in results["failures"]:
			all_failures.append("%s: %s" % [file_path, failure])

	print("Passed: %d, Failed: %d" % [total_pass, total_fail])
	for failure in all_failures:
		print("  FAIL - %s" % failure)

	quit(1 if total_fail > 0 else 0)

func _find_test_files(dir_path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				results.append_array(_find_test_files(dir_path + "/" + file_name))
		elif file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd" and file_name != "test_case.gd":
			results.append(dir_path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results
```

- [ ] **Step 3: Write a throwaway smoke test to prove the harness works**

`tests/test_smoke.gd`:
```gdscript
extends "res://tests/test_case.gd"

func test_true_is_true() -> void:
	assert_eq(true, true)
```

- [ ] **Step 4: Run it and confirm the harness reports a clean pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 1, Failed: 0` and exit code 0.

- [ ] **Step 5: Delete the smoke test**

It only existed to prove the harness works; the real suite starts in Task 3.
```bash
rm tests/test_smoke.gd
```

- [ ] **Step 6: Commit**

```bash
git add tests/test_case.gd tests/test_runner.gd
git commit -m "test: add hand-rolled GDScript test harness"
```

---

### Task 3: `Unit` entity

**Files:**
- Create: `combat/entities/unit.gd`
- Test: `tests/test_unit.gd`

A `Unit` is one crew member: health, basic-attack stats, and a mana bar that gates its (optional) signature ability. `id` and `team` (0 = player side, 1 = enemy side) are used later by `CombatSimulator` for targeting and turn order.

- [ ] **Step 1: Write the stub**

`combat/entities/unit.gd`:
```gdscript
extends RefCounted

var id: String = ""
var unit_name: String = ""
var max_health: int = 0
var current_health: int = 0
var attack_damage: int = 0
var attack_speed: float = 0.0
var max_mana: int = 0
var current_mana: int = 0
var mana_per_attack: int = 0
var team: int = 0
var ability = null

func _init(p_id: String, p_unit_name: String, p_max_health: int, p_attack_damage: int, p_attack_speed: float, p_max_mana: int, p_mana_per_attack: int, p_team: int) -> void:
	id = p_id
	unit_name = p_unit_name
	max_health = p_max_health
	current_health = p_max_health
	attack_damage = p_attack_damage
	attack_speed = p_attack_speed
	max_mana = p_max_mana
	current_mana = 0
	mana_per_attack = p_mana_per_attack
	team = p_team

func is_alive() -> bool:
	return false

func take_damage(amount: int) -> void:
	pass

func heal(amount: int) -> void:
	pass

func gain_mana(amount: int) -> void:
	pass

func reset_mana() -> void:
	pass

func is_mana_full() -> bool:
	return false
```

- [ ] **Step 2: Write the failing tests**

`tests/test_unit.gd`:
```gdscript
extends "res://tests/test_case.gd"

const Unit = preload("res://combat/entities/unit.gd")

func _make_unit(max_health := 100, attack_damage := 10, attack_speed := 1.0, max_mana := 100, mana_per_attack := 20) -> Object:
	return Unit.new("u1", "Test Unit", max_health, attack_damage, attack_speed, max_mana, mana_per_attack, 0)

func test_new_unit_starts_at_full_health() -> void:
	var u = _make_unit(100)
	assert_eq(u.current_health, 100)

func test_new_unit_starts_with_zero_mana() -> void:
	var u = _make_unit()
	assert_eq(u.current_mana, 0)

func test_take_damage_reduces_health() -> void:
	var u = _make_unit(100)
	u.take_damage(30)
	assert_eq(u.current_health, 70)

func test_take_damage_does_not_go_below_zero() -> void:
	var u = _make_unit(10)
	u.take_damage(999)
	assert_eq(u.current_health, 0)

func test_is_alive_true_when_health_positive() -> void:
	var u = _make_unit(10)
	assert_eq(u.is_alive(), true)

func test_is_alive_false_when_health_zero() -> void:
	var u = _make_unit(10)
	u.take_damage(10)
	assert_eq(u.is_alive(), false)

func test_heal_increases_health() -> void:
	var u = _make_unit(100)
	u.take_damage(50)
	u.heal(20)
	assert_eq(u.current_health, 70)

func test_heal_does_not_exceed_max_health() -> void:
	var u = _make_unit(100)
	u.take_damage(10)
	u.heal(999)
	assert_eq(u.current_health, 100)

func test_gain_mana_increases_mana() -> void:
	var u = _make_unit(100, 10, 1.0, 100, 20)
	u.gain_mana(20)
	assert_eq(u.current_mana, 20)

func test_gain_mana_does_not_exceed_max_mana() -> void:
	var u = _make_unit(100, 10, 1.0, 100, 20)
	u.gain_mana(999)
	assert_eq(u.current_mana, 100)

func test_is_mana_full_false_when_below_max() -> void:
	var u = _make_unit(100, 10, 1.0, 100, 20)
	u.gain_mana(50)
	assert_eq(u.is_mana_full(), false)

func test_is_mana_full_true_when_at_max() -> void:
	var u = _make_unit(100, 10, 1.0, 100, 20)
	u.gain_mana(100)
	assert_eq(u.is_mana_full(), true)

func test_reset_mana_sets_mana_to_zero() -> void:
	var u = _make_unit(100, 10, 1.0, 100, 20)
	u.gain_mana(100)
	u.reset_mana()
	assert_eq(u.current_mana, 0)
```

- [ ] **Step 3: Run and confirm failures**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 6, Failed: 7` (the constructor is already correct, so a few tests pass by coincidence against the stub; every test that depends on `take_damage`, `heal`, `gain_mana`, `is_mana_full`, or `is_alive` actually doing something fails). The exact split isn't the point — what matters is `Failed: 7` (i.e. > 0), confirming the harness catches real behavioral gaps.

- [ ] **Step 4: Implement `Unit` for real**

Replace the six stub method bodies in `combat/entities/unit.gd` with:
```gdscript
func is_alive() -> bool:
	return current_health > 0

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)

func gain_mana(amount: int) -> void:
	current_mana = min(current_mana + amount, max_mana)

func reset_mana() -> void:
	current_mana = 0

func is_mana_full() -> bool:
	return current_mana >= max_mana
```

- [ ] **Step 5: Run and confirm all pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 13, Failed: 0`, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add combat/entities/unit.gd tests/test_unit.gd
git commit -m "feat: add Unit entity with health and mana"
```

---

### Task 4: `Ability` entity

**Files:**
- Create: `combat/entities/ability.gd`
- Test: `tests/test_ability.gd`

An `Ability` is a unit's signature move: fixed damage dealt to one target when cast (triggered by `CombatSimulator` once mana is full — that wiring is Task 7).

- [ ] **Step 1: Write the stub**

`combat/entities/ability.gd`:
```gdscript
extends RefCounted

var ability_name: String = ""
var power: int = 0

func _init(p_ability_name: String, p_power: int) -> void:
	ability_name = p_ability_name
	power = p_power

func cast(target) -> void:
	pass
```

- [ ] **Step 2: Write the failing test**

`tests/test_ability.gd`:
```gdscript
extends "res://tests/test_case.gd"

const Ability = preload("res://combat/entities/ability.gd")
const Unit = preload("res://combat/entities/unit.gd")

func test_cast_deals_power_damage_to_target() -> void:
	var ability = Ability.new("Overload", 40)
	var target = Unit.new("t1", "Target", 100, 10, 1.0, 100, 20, 1)
	ability.cast(target)
	assert_eq(target.current_health, 60)
```

- [ ] **Step 3: Run and confirm it fails**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 13, Failed: 1` (the 13 `Unit` tests from Task 3 still pass; the new ability test fails because `cast` is a no-op).

- [ ] **Step 4: Implement `cast`**

Replace the stub body in `combat/entities/ability.gd`:
```gdscript
func cast(target) -> void:
	target.take_damage(power)
```

- [ ] **Step 5: Run and confirm all pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 14, Failed: 0`.

- [ ] **Step 6: Commit**

```bash
git add combat/entities/ability.gd tests/test_ability.gd
git commit -m "feat: add Ability entity"
```

---

### Task 5: `CombatSimulator` — alive counting and targeting

**Files:**
- Create: `combat/simulation/combat_simulator.gd`
- Test: `tests/test_combat_simulator.gd`

`CombatSimulator` orchestrates a fight. This task builds its two smallest, independently-testable pieces: counting how many units in a list are still alive, and picking a target (the spec doesn't define a targeting rule, so this MVP always targets the lowest-current-health alive enemy — the simplest deterministic rule that produces sensible fights).

- [ ] **Step 1: Write the stub (all five methods `CombatSimulator` will eventually have)**

`combat/simulation/combat_simulator.gd`:
```gdscript
extends RefCounted

const MAX_ACTIONS := 1000

func _count_alive(units: Array) -> int:
	return 0

func _select_target(candidates: Array):
	return null

func _next_actor(player_units: Array, enemy_units: Array, next_action_time: Dictionary):
	return null

func _resolve_action(actor, enemies: Array) -> Dictionary:
	return {}

func simulate_fight(player_units: Array, enemy_units: Array) -> Dictionary:
	return {"winner": "draw", "actions": 0, "log": []}
```

Only `_count_alive` and `_select_target` are implemented in this task; the other three stay stubbed until Tasks 6-8.

- [ ] **Step 2: Write the failing tests**

`tests/test_combat_simulator.gd`:
```gdscript
extends "res://tests/test_case.gd"

const CombatSimulator = preload("res://combat/simulation/combat_simulator.gd")
const Unit = preload("res://combat/entities/unit.gd")

func _make_unit(id: String, health: int) -> Object:
	return Unit.new(id, id, health, 10, 1.0, 100, 20, 1)

func test_count_alive_counts_only_units_with_positive_health() -> void:
	var sim = CombatSimulator.new()
	var a = _make_unit("a", 10)
	var b = _make_unit("b", 10)
	b.take_damage(10)
	assert_eq(sim._count_alive([a, b]), 1)

func test_count_alive_returns_zero_for_empty_array() -> void:
	var sim = CombatSimulator.new()
	assert_eq(sim._count_alive([]), 0)

func test_select_target_picks_lowest_health_among_alive() -> void:
	var sim = CombatSimulator.new()
	var e1 = _make_unit("e1", 50)
	var e2 = _make_unit("e2", 20)
	var e3 = _make_unit("e3", 10)
	e3.take_damage(10)
	var target = sim._select_target([e1, e2, e3])
	var target_id = target.id if target != null else "none"
	assert_eq(target_id, "e2")

func test_select_target_returns_null_when_all_dead() -> void:
	var sim = CombatSimulator.new()
	var e1 = _make_unit("e1", 10)
	e1.take_damage(10)
	var target = sim._select_target([e1])
	assert_eq(target, null)
```

(Note the `target_id = target.id if target != null else "none"` pattern — it avoids ever reading a property off a `null` result, which is important: a raw `target.id` on `null` throws a GDScript runtime error that the harness cannot cleanly catch as a failed assertion.  Use this same pattern in every later test that might get `null` back.)

- [ ] **Step 3: Run and confirm failures**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 16, Failed: 2` (`test_count_alive_counts_only_units_with_positive_health` and `test_select_target_picks_lowest_health_among_alive` fail against the stub; the other two pass by coincidence since the stub's constant `0`/`null` happen to match those particular expectations — that's fine, the meaningful signal is `Failed: 2`).

- [ ] **Step 4: Implement `_count_alive` and `_select_target`**

Replace the two stub bodies in `combat/simulation/combat_simulator.gd`:
```gdscript
func _count_alive(units: Array) -> int:
	var count := 0
	for u in units:
		if u.is_alive():
			count += 1
	return count

func _select_target(candidates: Array):
	var best = null
	var best_health := INF
	for u in candidates:
		if not u.is_alive():
			continue
		if float(u.current_health) < best_health:
			best_health = float(u.current_health)
			best = u
	return best
```

- [ ] **Step 5: Run and confirm all pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 18, Failed: 0`.

- [ ] **Step 6: Commit**

```bash
git add combat/simulation/combat_simulator.gd tests/test_combat_simulator.gd
git commit -m "feat: add CombatSimulator alive-counting and targeting"
```

---

### Task 6: `CombatSimulator` — turn order (`_next_actor`)

**Files:**
- Modify: `combat/simulation/combat_simulator.gd` (the `_next_actor` function)
- Modify: `tests/test_combat_simulator.gd`

Units act in speed order: each unit's next action happens after `1.0 / attack_speed` seconds, tracked externally in a `next_action_time` dictionary keyed by unit id. `_next_actor` picks whichever alive unit's next action time is smallest.

- [ ] **Step 1: Add the failing tests**

Append to `tests/test_combat_simulator.gd`:
```gdscript
func test_next_actor_picks_unit_with_smallest_next_action_time() -> void:
	var sim = CombatSimulator.new()
	var a = Unit.new("a", "A", 100, 5, 2.0, 100, 10, 0)
	var b = Unit.new("b", "B", 100, 5, 1.0, 100, 10, 1)
	var next_action_time = {"a": 0.5, "b": 1.0}
	var actor = sim._next_actor([a], [b], next_action_time)
	var actor_id = actor.id if actor != null else "none"
	assert_eq(actor_id, "a")

func test_next_actor_skips_dead_units() -> void:
	var sim = CombatSimulator.new()
	var a = Unit.new("a", "A", 10, 5, 2.0, 100, 10, 0)
	a.take_damage(10)
	var b = Unit.new("b", "B", 100, 5, 1.0, 100, 10, 1)
	var next_action_time = {"a": 0.1, "b": 1.0}
	var actor = sim._next_actor([a], [b], next_action_time)
	var actor_id = actor.id if actor != null else "none"
	assert_eq(actor_id, "b")

func test_next_actor_returns_null_when_all_units_dead() -> void:
	var sim = CombatSimulator.new()
	var a = Unit.new("a", "A", 10, 5, 1.0, 100, 10, 0)
	a.take_damage(10)
	var next_action_time = {"a": 1.0}
	var actor = sim._next_actor([a], [], next_action_time)
	assert_eq(actor, null)
```

- [ ] **Step 2: Run and confirm failures**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 19, Failed: 2` (the two tests expecting a real unit id back fail against the `null`-returning stub; the "all dead" test passes by coincidence).

- [ ] **Step 3: Implement `_next_actor`**

Replace the stub body in `combat/simulation/combat_simulator.gd`:
```gdscript
func _next_actor(player_units: Array, enemy_units: Array, next_action_time: Dictionary):
	var best = null
	var best_time := INF
	for u in player_units + enemy_units:
		if not u.is_alive():
			continue
		var t: float = next_action_time[u.id]
		if t < best_time:
			best_time = t
			best = u
	return best
```

- [ ] **Step 4: Run and confirm all pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 21, Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add combat/simulation/combat_simulator.gd tests/test_combat_simulator.gd
git commit -m "feat: add CombatSimulator speed-order turn selection"
```

---

### Task 7: `CombatSimulator` — resolving one action (`_resolve_action`)

**Files:**
- Modify: `combat/simulation/combat_simulator.gd` (the `_resolve_action` function)
- Modify: `tests/test_combat_simulator.gd`

`_resolve_action` is what happens when it's a unit's turn: if its mana is full and it has an ability, cast the ability and reset mana; otherwise do a basic attack and gain mana. Returns a log entry describing what happened (an empty dict if there was no alive enemy to act against).

- [ ] **Step 1: Add the failing tests**

Append to `tests/test_combat_simulator.gd`:
```gdscript
func test_resolve_action_basic_attack_damages_target_and_grants_mana() -> void:
	var sim = CombatSimulator.new()
	var actor = Unit.new("a", "A", 100, 15, 1.0, 100, 30, 0)
	var enemy = Unit.new("e", "E", 100, 5, 1.0, 100, 10, 1)
	var entry = sim._resolve_action(actor, [enemy])
	assert_eq(entry.get("action", ""), "attack")
	assert_eq(entry.get("target_id", ""), "e")
	assert_eq(enemy.current_health, 85)
	assert_eq(actor.current_mana, 30)

func test_resolve_action_targets_lowest_health_enemy() -> void:
	var sim = CombatSimulator.new()
	var actor = Unit.new("p1", "P1", 100, 10, 1.0, 100, 30, 0)
	var e1 = Unit.new("e1", "E1", 50, 5, 1.0, 100, 10, 1)
	var e2 = Unit.new("e2", "E2", 20, 5, 1.0, 100, 10, 1)
	var entry = sim._resolve_action(actor, [e1, e2])
	assert_eq(entry.get("target_id", ""), "e2")

func test_resolve_action_casts_ability_when_mana_full_and_resets_mana() -> void:
	var sim = CombatSimulator.new()
	var actor = Unit.new("a", "A", 100, 10, 1.0, 100, 30, 0)
	actor.ability = Ability.new("Overload", 50)
	actor.gain_mana(100)
	var enemy = Unit.new("e", "E", 100, 5, 1.0, 100, 10, 1)
	var entry = sim._resolve_action(actor, [enemy])
	assert_eq(entry.get("action", ""), "ability")
	assert_eq(enemy.current_health, 50)
	assert_eq(actor.current_mana, 0)

func test_resolve_action_returns_empty_dict_when_no_alive_enemies() -> void:
	var sim = CombatSimulator.new()
	var actor = Unit.new("p1", "P1", 100, 10, 1.0, 100, 30, 0)
	var dead_enemy = Unit.new("e1", "E1", 10, 5, 1.0, 100, 10, 1)
	dead_enemy.take_damage(10)
	var entry = sim._resolve_action(actor, [dead_enemy])
	assert_eq(entry, {})
```

Add the `Ability` preload near the top of `tests/test_combat_simulator.gd`, alongside the existing `CombatSimulator`/`Unit` preloads:
```gdscript
const Ability = preload("res://combat/entities/ability.gd")
```

- [ ] **Step 2: Run and confirm failures**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 22, Failed: 8` (every assertion in the first three new tests fails against the `{}`-returning stub; the fourth passes by coincidence since the stub always returns `{}`, which happens to be the "no target" case too).

- [ ] **Step 3: Implement `_resolve_action`**

Replace the stub body in `combat/simulation/combat_simulator.gd`:
```gdscript
func _resolve_action(actor, enemies: Array) -> Dictionary:
	var target = _select_target(enemies)
	if target == null:
		return {}

	if actor.is_mana_full() and actor.ability != null:
		actor.ability.cast(target)
		actor.reset_mana()
		return {"actor_id": actor.id, "action": "ability", "target_id": target.id, "target_health_after": target.current_health}
	else:
		target.take_damage(actor.attack_damage)
		actor.gain_mana(actor.mana_per_attack)
		return {"actor_id": actor.id, "action": "attack", "target_id": target.id, "target_health_after": target.current_health}
```

- [ ] **Step 4: Run and confirm all pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 30, Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add combat/simulation/combat_simulator.gd tests/test_combat_simulator.gd
git commit -m "feat: add CombatSimulator action resolution (attack + ability cast)"
```

---

### Task 8: `CombatSimulator` — full fight loop (`simulate_fight`)

**Files:**
- Modify: `combat/simulation/combat_simulator.gd` (the `simulate_fight` function)
- Modify: `tests/test_combat_simulator.gd`

`simulate_fight` ties everything together: initialize each unit's next-action time, repeatedly pick the next actor and resolve their action, and stop when one side has no unit left alive (or after `MAX_ACTIONS` as a safety cap against a stalemate, which also declares a draw).

- [ ] **Step 1: Add the failing tests**

Append to `tests/test_combat_simulator.gd`:
```gdscript
func test_simulate_fight_declares_player_winner_when_enemy_is_defeated() -> void:
	var sim = CombatSimulator.new()
	var player = [Unit.new("p1", "P1", 100, 50, 1.0, 100, 10, 0)]
	var enemy = [Unit.new("e1", "E1", 30, 5, 1.0, 100, 10, 1)]
	var result = sim.simulate_fight(player, enemy)
	assert_eq(result["winner"], "player")

func test_simulate_fight_declares_enemy_winner_when_player_is_defeated() -> void:
	var sim = CombatSimulator.new()
	var player = [Unit.new("p1", "P1", 30, 5, 1.0, 100, 10, 0)]
	var enemy = [Unit.new("e1", "E1", 100, 50, 1.0, 100, 10, 1)]
	var result = sim.simulate_fight(player, enemy)
	assert_eq(result["winner"], "enemy")

func test_simulate_fight_faster_unit_acts_first_in_log() -> void:
	var sim = CombatSimulator.new()
	var player = [Unit.new("p1", "P1", 100, 5, 2.0, 100, 10, 0)]
	var enemy = [Unit.new("e1", "E1", 100, 5, 1.0, 100, 10, 1)]
	var result = sim.simulate_fight(player, enemy)
	var log: Array = result["log"]
	var first_actor_id = log[0]["actor_id"] if log.size() > 0 else "none"
	assert_eq(first_actor_id, "p1")

func test_simulate_fight_returns_draw_when_neither_side_can_deal_damage() -> void:
	var sim = CombatSimulator.new()
	var player = [Unit.new("p1", "P1", 100, 0, 1.0, 100, 10, 0)]
	var enemy = [Unit.new("e1", "E1", 100, 0, 1.0, 100, 10, 1)]
	var result = sim.simulate_fight(player, enemy)
	assert_eq(result["winner"], "draw")
	assert_eq(result["actions"], 1000)
```

- [ ] **Step 2: Run and confirm failures**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 31, Failed: 4` (the first three new tests fail against the `{"winner": "draw", "actions": 0, "log": []}` stub; the fourth has one passing assertion — `winner` happens to already be `"draw"` — and one failing assertion on `actions`).

- [ ] **Step 3: Implement `simulate_fight`**

Replace the stub body in `combat/simulation/combat_simulator.gd`:
```gdscript
func simulate_fight(player_units: Array, enemy_units: Array) -> Dictionary:
	var log: Array = []
	var next_action_time: Dictionary = {}
	for u in player_units + enemy_units:
		next_action_time[u.id] = 1.0 / u.attack_speed

	var actions_taken := 0
	while actions_taken < MAX_ACTIONS:
		if _count_alive(player_units) == 0 or _count_alive(enemy_units) == 0:
			break

		var actor = _next_actor(player_units, enemy_units, next_action_time)
		if actor == null:
			break

		var enemies: Array = enemy_units if actor.team == 0 else player_units
		var entry: Dictionary = _resolve_action(actor, enemies)
		if not entry.is_empty():
			entry["time"] = next_action_time[actor.id]
			log.append(entry)

		next_action_time[actor.id] += 1.0 / actor.attack_speed
		actions_taken += 1

	var winner := "draw"
	if _count_alive(player_units) > 0 and _count_alive(enemy_units) == 0:
		winner = "player"
	elif _count_alive(enemy_units) > 0 and _count_alive(player_units) == 0:
		winner = "enemy"

	return {"winner": winner, "actions": actions_taken, "log": log}
```

- [ ] **Step 4: Run and confirm all pass**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```
Expected: `Passed: 35, Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add combat/simulation/combat_simulator.gd tests/test_combat_simulator.gd
git commit -m "feat: add CombatSimulator full fight loop"
```

---

### Task 9: Demo script and README update

**Files:**
- Create: `combat/demo/run_demo_fight.gd`
- Modify: `README.md`

A runnable, human-readable proof that the core loop works end to end: two made-up crews (named after spec factions — Street Runners vs. Corp Enforcers) fight, and the full action log plus the winner get printed.

- [ ] **Step 1: Write the demo script**

`combat/demo/run_demo_fight.gd`:
```gdscript
extends SceneTree

const CombatSimulator = preload("res://combat/simulation/combat_simulator.gd")
const Unit = preload("res://combat/entities/unit.gd")
const Ability = preload("res://combat/entities/ability.gd")

func _initialize() -> void:
	var runner = Unit.new("street_runner", "Street Runner", 120, 12, 1.4, 60, 20, 0)
	var fixer = Unit.new("fixer", "Fixer", 90, 8, 1.0, 80, 25, 0)
	fixer.ability = Ability.new("Overclock", 45)

	var enforcer = Unit.new("corp_enforcer", "Corp Enforcer", 150, 15, 0.9, 50, 25, 1)
	var drone = Unit.new("security_drone", "Security Drone", 80, 10, 1.6, 40, 15, 1)

	var sim = CombatSimulator.new()
	var result = sim.simulate_fight([runner, fixer], [enforcer, drone])

	print("=== Cyberstack Combat Demo ===")
	for entry in result["log"]:
		print("t=%.2f  %s -> %s: %s (target hp now %d)" % [entry["time"], entry["actor_id"], entry["target_id"], entry["action"], entry["target_health_after"]])
	print("Winner: %s (%d actions)" % [result["winner"], result["actions"]])

	quit(0)
```

- [ ] **Step 2: Run the demo**

Run:
```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://combat/demo/run_demo_fight.gd --path .
```
Expected: a printed sequence of `t=... actor -> target: action (target hp now N)` lines, ending with a `Winner: ...` line, exit code 0.

- [ ] **Step 3: Update the README**

Replace the contents of `README.md`:
```markdown
# Cyberstack

A singleplayer autobattler game inspired by Teamfight Tactics, The Bazaar, and Oaken Tower.

> Development in progress.

## Design

See `docs/superpowers/specs/2026-06-20-cyberstack-design.md` for the full game design spec.

## Status

- [x] Core combat loop — automated fight resolution (speed order, basic attacks, mana-gated abilities). See `combat/simulation/combat_simulator.gd`.
- [ ] Shop / gold economy
- [ ] Unit roles and augment slots
- [ ] Faction traits and augment tag chains
- [ ] Meta-layer
- [ ] Visual/scene layer

## Running tests

```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://tests/test_runner.gd --path .
```

## Running the combat demo

```bash
"C:/Tools/Godot/Godot_v4.6.3-stable_win64_console.exe" --headless --script res://combat/demo/run_demo_fight.gd --path .
```
```

- [ ] **Step 4: Commit**

```bash
git add combat/demo/run_demo_fight.gd README.md
git commit -m "feat: add combat demo script and update README status"
```

---

## Self-Review Notes

- **Spec coverage:** Implements Combat System (spec §3): speed order (`_next_actor`), basic attack + mana gain, single mana-gated signature ability (`Ability.cast` via `_resolve_action`), automated resolution with no mid-fight input. Deliberately does not implement roles/augment slots, faction traits, tag chains, or the shop/gold/district layer (spec §2, §4) — those are separate subsystems for future plans, as scoped in the Architecture section above and confirmed with the user (chose "core combat loop first").
- **Placeholder scan:** No TBD/TODO markers; every step has concrete, complete code.
- **Type consistency:** `Unit` fields (`id`, `team`, `current_health`, `current_mana`, `attack_speed`, `mana_per_attack`, `ability`) and `CombatSimulator` method names (`_count_alive`, `_select_target`, `_next_actor`, `_resolve_action`, `simulate_fight`) are used identically across all tasks that reference them.
