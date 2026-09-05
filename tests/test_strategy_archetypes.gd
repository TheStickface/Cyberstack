class_name TestStrategyArchetypes
extends RefCounted

## Regression coverage for the strategy-archetype system backing the
## Autoplay spectator bot: StrategyArchetypes' data/scoring, and that
## BalanceSimulator's strategy-biased purchase path still produces a valid
## run without disturbing the existing unbiased (strategy={}) behavior.

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const BalanceSimulatorScript = preload("res://src/tools/BalanceSimulator.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_archetypes_well_formed() -> Dictionary:
	var seen_ids: Dictionary = {}
	if StrategyArchetypes.ARCHETYPES.is_empty():
		return {"passed": false, "message": "ARCHETYPES is empty", "assertions": 1}

	for a in StrategyArchetypes.ARCHETYPES:
		for key in ["id", "name", "description", "faction", "tag", "role_bias", "preferred_starters"]:
			if not a.has(key):
				return {"passed": false, "message": "Archetype missing key '%s': %s" % [key, a.get("id", "?")], "assertions": 1}
		if seen_ids.has(a["id"]):
			return {"passed": false, "message": "Duplicate archetype id: %s" % a["id"], "assertions": 2}
		seen_ids[a["id"]] = true

	return {"passed": true, "assertions": 2}

func test_get_by_id_roundtrip() -> Dictionary:
	var first = StrategyArchetypes.ARCHETYPES[0]
	var found = StrategyArchetypes.get_by_id(first["id"])
	if found.get("id", "") != first["id"]:
		return {"passed": false, "message": "get_by_id did not return the matching archetype", "assertions": 1}
	var missing = StrategyArchetypes.get_by_id("does_not_exist")
	if not missing.is_empty():
		return {"passed": false, "message": "get_by_id should return {} for an unknown id", "assertions": 2}
	return {"passed": true, "assertions": 2}

func test_score_unit_prefers_matching_faction_and_dupe() -> Dictionary:
	var strategy = {"faction": Enums.Faction.STREET_RUNNERS, "role_bias": Enums.UnitRole.ANY}
	var runner: UnitResource = repo.get_unit("runner_blitz")
	var other: UnitResource = null
	for u in repo.get_all_units():
		if u.faction != Enums.Faction.STREET_RUNNERS and not u.id.begins_with("boss_"):
			other = u
			break
	if runner == null or other == null:
		return {"passed": false, "message": "Couldn't find comparable units in repo data", "assertions": 1}

	var runner_score = StrategyArchetypes.score_unit(runner, strategy)
	var other_score = StrategyArchetypes.score_unit(other, strategy)
	if runner_score <= other_score:
		return {"passed": false, "message": "Matching-faction unit should score higher (%f vs %f)" % [runner_score, other_score], "assertions": 2}

	var dupe_score = StrategyArchetypes.score_unit(runner, strategy, {"existing_ids": {"runner_blitz": true}})
	if dupe_score <= runner_score:
		return {"passed": false, "message": "A duplicate-of-fielded unit should score even higher", "assertions": 3}

	return {"passed": true, "assertions": 3}

func test_score_augment_prefers_matching_tag() -> Dictionary:
	var strategy = {"tag": Enums.AugmentTag.KINETIC}
	var kinetic_aug: AugmentResource = null
	var other_aug: AugmentResource = null
	for a in repo.get_all_augments():
		if a.has_tag(Enums.AugmentTag.KINETIC) and kinetic_aug == null:
			kinetic_aug = a
		elif not a.has_tag(Enums.AugmentTag.KINETIC) and other_aug == null:
			other_aug = a
		if kinetic_aug != null and other_aug != null:
			break
	if kinetic_aug == null or other_aug == null:
		return {"passed": false, "message": "Couldn't find comparable augments in repo data", "assertions": 1}

	var kinetic_score = StrategyArchetypes.score_augment(kinetic_aug, strategy)
	var other_score = StrategyArchetypes.score_augment(other_aug, strategy)
	if kinetic_score <= other_score:
		return {"passed": false, "message": "Matching-tag augment should score higher (%f vs %f)" % [kinetic_score, other_score], "assertions": 2}

	return {"passed": true, "assertions": 2}

func test_describe_wants_returns_lines() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo)
	var strategy = StrategyArchetypes.get_by_id("street_runner_rush")
	var wants = StrategyArchetypes.describe_wants(strategy, crew_mgr)
	if wants.is_empty():
		return {"passed": false, "message": "describe_wants returned no lines", "assertions": 1}
	return {"passed": true, "assertions": 1}

## Unbiased behavior (strategy={}) must be untouched: existing callers pass
## no strategy argument at all, so this pins the default-parameter contract.
func test_simulate_full_run_unbiased_still_works() -> Dictionary:
	var result = BalanceSimulatorScript.simulate_full_run("runner_blitz", repo)
	if not result.has("victory") or not result.has("district_reached"):
		return {"passed": false, "message": "Unbiased full run result missing expected keys", "assertions": 1}
	return {"passed": true, "assertions": 1}

## Strategy-biased runs must still produce a well-formed, playable result —
## this is the same call path StrategyMetricsSimulator uses at scale.
func test_simulate_full_run_with_strategy_bias() -> Dictionary:
	var strategy = StrategyArchetypes.get_by_id("corp_tank_wall")
	var result = BalanceSimulatorScript.simulate_full_run("corp_sentinel", repo, strategy)
	if not result.has("victory") or not result.has("district_reached"):
		return {"passed": false, "message": "Biased full run result missing expected keys", "assertions": 1}
	if result["district_reached"] < 1 or result["district_reached"] > 4:
		return {"passed": false, "message": "Invalid district_reached: %d" % result["district_reached"], "assertions": 2}
	return {"passed": true, "assertions": 2}

func test_shop_purchase_with_strategy_bias_respects_gold() -> Dictionary:
	var crew_mgr = CrewManager.new(1, repo)
	var starter = repo.get_unit("runner_blitz")
	crew_mgr.place_unit_on_grid(UnitInstance.new(starter), 1)
	var strategy = StrategyArchetypes.get_by_id("street_runner_rush")
	var remaining = BalanceSimulatorScript._simulate_shop_purchase(crew_mgr, 40, repo, strategy)
	if remaining < 0 or remaining > 40:
		return {"passed": false, "message": "Strategy-biased shop purchase left invalid gold: %d" % remaining, "assertions": 1}
	return {"passed": true, "assertions": 1}
