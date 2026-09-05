class_name TestCombatMockArena
extends RefCounted

## Regression coverage for CombatMockArena's armor/evasion parity fix.
##
## Previously CombatantState had no armor/evasion fields at all: they were
## never initialized in _create_combatant (base stats, faction/augment
## bonuses, and directional formation mods that grant Armor/Evasion did
## nothing), and applying a directional mod with an ARMOR or EVASION entry
## crashed with "Invalid access to property or key 'armor'/'evasion'" the
## first time a real equipped augment or formation passive granted one
## (uncovered by AutoplayDirector actually driving full runs headless).
## BalanceSimulator has always modeled both correctly; this pins the real
## combat screen to the same values so a Corp Enforcer/Bio-Synthetic/
## Net-Phantom actually gets their faction's armor/evasion identity in play.

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const CombatMockArenaScript = preload("res://src/ui/screens/CombatMockArena.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_create_combatant_initializes_armor_and_evasion_from_unit() -> Dictionary:
	var arena = CombatMockArenaScript.new()
	arena.combat_payload = {}

	var unit_res = repo.get_unit("corp_sentinel")
	if unit_res == null:
		return {"passed": false, "message": "Couldn't load corp_sentinel from repo", "assertions": 1}
	var unit = UnitInstance.new(unit_res)

	var state = arena._create_combatant(unit, true, 1)

	if not is_equal_approx(state.armor, unit.calculate_effective_stat(Enums.StatType.ARMOR)):
		return {"passed": false, "message": "state.armor (%f) doesn't match unit's effective Armor stat (%f)" % [state.armor, unit.calculate_effective_stat(Enums.StatType.ARMOR)], "assertions": 1}
	if not is_equal_approx(state.evasion, unit.calculate_effective_stat(Enums.StatType.EVASION)):
		return {"passed": false, "message": "state.evasion doesn't match unit's effective Evasion stat", "assertions": 2}

	arena.free()
	return {"passed": true, "assertions": 2}

func test_create_combatant_applies_formation_armor_and_evasion_bonus() -> Dictionary:
	var arena = CombatMockArenaScript.new()
	var unit_res = repo.get_unit("corp_sentinel")
	var unit = UnitInstance.new(unit_res)
	var base_armor = unit.calculate_effective_stat(Enums.StatType.ARMOR)
	var base_evasion = unit.calculate_effective_stat(Enums.StatType.EVASION)

	arena.combat_payload = {
		"formation_bonuses": {
			unit: {"armor_bonus": 35.0, "evasion_bonus": 0.20}
		}
	}
	var state = arena._create_combatant(unit, true, 1)

	if not is_equal_approx(state.armor, base_armor + 35.0):
		return {"passed": false, "message": "Formation armor_bonus wasn't applied: got %f, expected %f" % [state.armor, base_armor + 35.0], "assertions": 1}
	if not is_equal_approx(state.evasion, base_evasion + 0.20):
		return {"passed": false, "message": "Formation evasion_bonus wasn't applied: got %f, expected %f" % [state.evasion, base_evasion + 0.20], "assertions": 2}

	arena.free()
	return {"passed": true, "assertions": 2}

## The exact crash this fix resolves: a directional formation passive or
## augment granting Enums.StatType.ARMOR/EVASION used to throw "Invalid
## access to property or key" because CombatantState never declared those
## fields. This exercises the same code path (_apply_mods_to_combat_state)
## that BalanceSimulator._place_unit_tactically-driven live runs hit.
func test_directional_mod_with_armor_and_evasion_does_not_crash() -> Dictionary:
	var arena = CombatMockArenaScript.new()
	arena.combat_payload = {}
	var unit_res = repo.get_unit("corp_sentinel")
	var unit = UnitInstance.new(unit_res)
	var state = arena._create_combatant(unit, true, 1)
	var armor_before = state.armor
	var evasion_before = state.evasion

	arena._apply_mods_to_combat_state(state, {
		Enums.StatType.ARMOR: 15.0,
		Enums.StatType.EVASION: 0.10
	}, "")

	if not is_equal_approx(state.armor, armor_before + 15.0):
		return {"passed": false, "message": "Armor wasn't incremented by the directional mod", "assertions": 1}
	if not is_equal_approx(state.evasion, evasion_before + 0.10):
		return {"passed": false, "message": "Evasion wasn't incremented by the directional mod", "assertions": 2}

	arena.free()
	return {"passed": true, "assertions": 2}
