class_name StrategyMetricsSimulator
extends SceneTree

## Measures a real Monte Carlo clear-rate for every named strategy archetype
## in StrategyArchetypes.ARCHETYPES, then writes the ranked results to
## data/strategy_metrics.json. AutoplayDirector (the live spectator bot)
## reads that file and picks a strategy at random from the top 5 by winrate.
##
## Each archetype's runs use BalanceSimulator.simulate_full_run with the
## archetype Dictionary passed as the `strategy` bias — the exact same
## scoring functions (StrategyArchetypes.score_unit/score_augment) that
## AutoplayDirector uses to drive the real live shop, so a measured winrate
## here is an honest prediction of what the live bot will actually do.
##
## Usage:
##   godot --headless -s res://src/tools/StrategyMetricsSimulator.gd --runs-per-archetype=2000

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func _init() -> void:
	var runs_per_archetype = _parse_int_arg("--runs-per-archetype=", 2000)

	print("================================================================")
	print("  CYBERSTACK STRATEGY METRICS SIMULATOR (%d runs/archetype)   " % runs_per_archetype)
	print("================================================================\n")

	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")

	var results: Array[Dictionary] = []

	for strategy in StrategyArchetypes.ARCHETYPES:
		var starters: Array = strategy.get("preferred_starters", [])
		if starters.is_empty():
			starters = StrategyArchetypes.ALL_STARTER_IDS

		print(">> Measuring '%s' (%d runs)..." % [strategy["name"], runs_per_archetype])
		var wins := 0
		for i in range(runs_per_archetype):
			var starter_id: String = starters[randi() % starters.size()]
			var result = BalanceSimulator.simulate_full_run(starter_id, repo, strategy)
			if result.get("victory", false):
				wins += 1

		var winrate = float(wins) / float(maxi(1, runs_per_archetype))
		results.append({
			"id": strategy["id"],
			"name": strategy["name"],
			"description": strategy["description"],
			"faction": strategy.get("faction", Enums.Faction.NONE),
			"tag": strategy.get("tag", Enums.AugmentTag.NONE),
			"role_bias": strategy.get("role_bias", Enums.UnitRole.ANY),
			"prioritize_duplicates": strategy.get("prioritize_duplicates", false),
			"preferred_starters": strategy.get("preferred_starters", []),
			"runs": runs_per_archetype,
			"wins": wins,
			"winrate": winrate
		})
		print("   -> %.1f%% clear rate (%d/%d)" % [winrate * 100.0, wins, runs_per_archetype])

	results.sort_custom(func(a, b): return a["winrate"] > b["winrate"])

	var output_path = "res://data/strategy_metrics.json"
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		var payload = {
			"generated_runs_per_archetype": runs_per_archetype,
			"archetypes": results
		}
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()
		print("\n[SUCCESS] Wrote %d ranked strategy archetypes to %s\n" % [results.size(), output_path])
		_print_leaderboard(results)
		quit(0)
	else:
		printerr("\n[ERROR] Failed to save strategy metrics to %s\n" % output_path)
		quit(1)

func _print_leaderboard(results: Array[Dictionary]) -> void:
	print("Rank  Winrate   Strategy")
	print("----  -------   --------")
	for i in range(results.size()):
		var r = results[i]
		print("#%-3d  %5.1f%%    %s" % [i + 1, r["winrate"] * 100.0, r["name"]])
	print("")
	print("Top %d (what AutoplayDirector picks from):" % mini(5, results.size()))
	for i in range(mini(5, results.size())):
		print("  - %s" % results[i]["name"])

func _parse_int_arg(prefix: String, default_val: int) -> int:
	var all_args: Array[String] = []
	all_args.append_array(OS.get_cmdline_user_args())
	all_args.append_array(OS.get_cmdline_args())
	for arg in all_args:
		if arg.begins_with(prefix):
			var val = arg.substr(prefix.length()).to_int()
			if val > 0:
				return val
	return default_val
