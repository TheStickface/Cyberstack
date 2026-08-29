class_name ExportTelemetryReport
extends SceneTree

## Headless CLI script exporting community telemetry metrics to markdown report

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func _init() -> void:
	print("========================================")
	print("   CYBERSTACK COMMUNITY METRICS REPORT  ")
	print("========================================")
	
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	var records = TelemetryManager.load_all_records()
	if records.size() < 10:
		print("[INFO] Generating 50 community player run simulations into sample storage...")
		records = TelemetryManager.generate_community_sample_data(50, repo, TelemetryManager.SAMPLE_TELEMETRY_PATH)
		
	var md = generate_markdown_report(records, repo)
	var output_path = "res://data/community_analytics_report.md"
	
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(md)
		file.close()
		print("[SUCCESS] Exported telemetry analytics report to %s\n" % output_path)
		quit(0)
	else:
		printerr("[ERROR] Failed to write report to %s\n" % output_path)
		quit(1)

static func generate_markdown_report(records: Array[TelemetryEvent], repo: Object) -> String:
	var lines: Array[String] = []
	lines.append("# Cyberstack — Community Telemetry & Meta Analytics Report")
	lines.append("**Generated Date:** %s | **Total Player Runs Analyzed:** %d" % [Time.get_date_string_from_system(), records.size()])
	lines.append("")
	lines.append("---")
	lines.append("")
	
	# 1. Executive Summary
	var overview = AnalyticsEngine.compute_overview(records)
	lines.append("## 1. Executive Overview")
	lines.append("- **Total Community Runs Executed:** %d" % overview.total_runs)
	lines.append("- **Global Run Victory Rate:** %.1f%% (%d Wins / %d Losses)" % [overview.win_rate, overview.victories, overview.defeats])
	lines.append("- **Average Run Length:** %.1f minutes" % (overview.avg_duration / 60.0))
	lines.append("- **Average Credits Spent per Run:** %.0f credits" % overview.avg_gold_spent)
	lines.append("")
	
	# 2. Operative Meta Rankings
	var op_meta = AnalyticsEngine.compute_operative_meta(records, repo)
	lines.append("## 2. Operative Meta & Pick/Win Rates")
	lines.append("| Operative | Role | Faction | Times Fielded | Pick Rate | Wins With Unit | Win Rate |")
	lines.append("|---|---|---|---|---|---|---|")
	for op in op_meta:
		lines.append("| **%s** | %s | %s | %d | %.1f%% | %d | **%.1f%%** |" % [
			op.name,
			op.role,
			op.faction,
			op.picks,
			op.pick_rate,
			op.wins,
			op.win_rate
		])
	lines.append("")
	
	# 3. Augment Popularity
	var aug_meta = AnalyticsEngine.compute_augment_meta(records, repo)
	lines.append("## 3. Augment Popularity & Win Rate Contribution")
	lines.append("| Augment | Tier | Slot | Times Equipped | Equip Rate | Win Rate |")
	lines.append("|---|---|---|---|---|---|")
	for aug in aug_meta:
		lines.append("| **%s** | %s | %s | %d | %.1f%% | **%.1f%%** |" % [
			aug.name,
			aug.tier,
			aug.slot,
			aug.equips,
			aug.equip_rate,
			aug.win_rate
		])
	lines.append("")
	
	# 4. Mortality Curve
	var mort = AnalyticsEngine.compute_mortality_curve(records)
	lines.append("## 4. District Mortality Curve (Where Players Die)")
	lines.append("| District | Eliminating Factor | Player Deaths | % of All Runs |")
	lines.append("|---|---|---|---|")
	lines.append("| District 1 (Slum Market) | Early Gang Patrols | %d | %.1f%% |" % [mort.d1_deaths, mort.d1_rate])
	lines.append("| District 2 (Corp Arcology) | Enforcer Strike Teams | %d | %.1f%% |" % [mort.d2_deaths, mort.d2_rate])
	lines.append("| District 3 (Server Vault) | Rogue AI Subroutines | %d | %.1f%% |" % [mort.d3_deaths, mort.d3_rate])
	lines.append("| District 4 (Black Site) | Final Boss Security | %d | %.1f%% |" % [mort.d4_deaths, mort.d4_rate])
	lines.append("| **VICTORY** | **Run Successfully Secured** | **%d** | **%.1f%%** |" % [mort.victories, mort.victory_rate])
	lines.append("")

	# 5. Faction Meta
	var fac_meta = AnalyticsEngine.compute_faction_meta(records, repo)
	lines.append("## 5. Faction Meta & Synergy Adoption")
	lines.append("| Faction | Runs Fielding It | Field Rate | Ran 2+ (Threshold) | Win Rate |")
	lines.append("|---|---|---|---|---|")
	for fac in fac_meta:
		lines.append("| **%s** | %d | %.1f%% | %.1f%% | **%.1f%%** |" % [
			fac.name,
			fac.runs_present,
			fac.present_rate,
			fac.threshold_rate,
			fac.win_rate
		])
	lines.append("")

	return "\n".join(lines)
