class_name MetricsDashboard
extends Control

## In-game Community Telemetry & Meta Analytics Dashboard

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object = null
var records: Array[TelemetryEvent] = []

@onready var overview_label: Label = $VBox/TabContainer/Overview/VBox/OverviewStatsLabel
@onready var operatives_container: GridContainer = $VBox/TabContainer/Operatives/Scroll/OperativesGrid
@onready var augments_container: GridContainer = $VBox/TabContainer/Augments/Scroll/AugmentsGrid
@onready var mortality_container: VBoxContainer = $VBox/TabContainer/Mortality/MortalityList
@onready var session_feed: RichTextLabel = $VBox/TabContainer/SessionFeed/FeedLog
@onready var status_lbl: Label = $VBox/BottomBar/StatusLabel

func _ready() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	refresh_dashboard()

func refresh_dashboard() -> void:
	records = TelemetryManager.load_all_records()
	if records.is_empty():
		records = TelemetryManager.generate_community_sample_data(50, repo)
		
	_populate_overview()
	_populate_operatives()
	_populate_augments()
	_populate_mortality()
	_populate_session_feed()

func _populate_overview() -> void:
	if not overview_label:
		return
	var overview = AnalyticsEngine.compute_overview(records)
	overview_label.text = """
TOTAL COMMUNITY RUNS RECORDED: %d
GLOBAL RUN VICTORY RATE: %.1f%% (%d Wins / %d Defeats)
AVERAGE RUN DURATION: %.1f minutes
AVERAGE CREDITS INVESTED PER RUN: %.0f credits
DISTRICT 4 RUN SUCCESS RATE: %.1f%%
""" % [
		overview.total_runs,
		overview.win_rate,
		overview.victories,
		overview.defeats,
		overview.avg_duration / 60.0,
		overview.avg_gold_spent,
		overview.win_rate
	]

func _populate_operatives() -> void:
	if not operatives_container:
		return
	for c in operatives_container.get_children():
		c.queue_free()
		
	var op_meta = AnalyticsEngine.compute_operative_meta(records, repo)
	for op in op_meta:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(230, 110)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		
		var name_lbl = Label.new()
		name_lbl.text = op.name
		name_lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		vbox.add_child(name_lbl)
		
		var role_lbl = Label.new()
		role_lbl.text = "%s | %s" % [op.role, op.faction]
		role_lbl.add_theme_font_size_override("font_size", 9)
		role_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 1.0))
		vbox.add_child(role_lbl)
		
		var stats_lbl = Label.new()
		stats_lbl.text = "Pick Rate: %.1f%% (%d runs)\nWin Rate: %.1f%% (%d wins)" % [
			op.pick_rate,
			op.picks,
			op.win_rate,
			op.wins
		]
		stats_lbl.add_theme_font_size_override("font_size", 9)
		stats_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0) if op.win_rate >= 50.0 else Color(0.8, 0.8, 0.9))
		vbox.add_child(stats_lbl)
		
		panel.add_child(vbox)
		operatives_container.add_child(panel)

func _populate_augments() -> void:
	if not augments_container:
		return
	for c in augments_container.get_children():
		c.queue_free()
		
	var aug_meta = AnalyticsEngine.compute_augment_meta(records, repo)
	for aug in aug_meta:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(230, 90)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		
		var name_lbl = Label.new()
		name_lbl.text = aug.name
		name_lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		vbox.add_child(name_lbl)
		
		var sub_lbl = Label.new()
		sub_lbl.text = "[%s | %s Slot]" % [aug.tier, aug.slot]
		sub_lbl.add_theme_font_size_override("font_size", 9)
		sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox.add_child(sub_lbl)
		
		var stats_lbl = Label.new()
		stats_lbl.text = "Equip Rate: %.1f%% | Win Rate: %.1f%%" % [aug.equip_rate, aug.win_rate]
		stats_lbl.add_theme_font_size_override("font_size", 9)
		vbox.add_child(stats_lbl)
		
		panel.add_child(vbox)
		augments_container.add_child(panel)

func _populate_mortality() -> void:
	if not mortality_container:
		return
	for c in mortality_container.get_children():
		c.queue_free()
		
	var mort = AnalyticsEngine.compute_mortality_curve(records)
	var entries = [
		{"name": "District 1 (Slum Market)", "deaths": mort.d1_deaths, "rate": mort.d1_rate, "color": Color(1, 0.3, 0.3)},
		{"name": "District 2 (Corp Arcology)", "deaths": mort.d2_deaths, "rate": mort.d2_rate, "color": Color(1, 0.5, 0.2)},
		{"name": "District 3 (Server Vault)", "deaths": mort.d3_deaths, "rate": mort.d3_rate, "color": Color(1, 0.8, 0.2)},
		{"name": "District 4 (Black Site)", "deaths": mort.d4_deaths, "rate": mort.d4_rate, "color": Color(0.8, 0.2, 0.8)},
		{"name": "RUN VICTORY (Secured)", "deaths": mort.victories, "rate": mort.victory_rate, "color": Color(0, 0.95, 0.83)}
	]
	
	for e in entries:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		
		var hbox = HBoxContainer.new()
		var title = Label.new()
		title.text = e.name
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color", e.color)
		hbox.add_child(title)
		
		var val_lbl = Label.new()
		val_lbl.text = "%d Runs (%.1f%%)" % [e.deaths, e.rate]
		val_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		hbox.add_child(val_lbl)
		vbox.add_child(hbox)
		
		var pbar = ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 12)
		pbar.max_value = 100
		pbar.value = e.rate
		pbar.show_percentage = false
		vbox.add_child(pbar)
		
		panel.add_child(vbox)
		mortality_container.add_child(panel)

func _populate_session_feed() -> void:
	if not session_feed:
		return
	var lines: Array[String] = []
	var rev_records = records.duplicate()
	rev_records.reverse()
	
	for i in range(mini(15, rev_records.size())):
		var r = rev_records[i]
		var outcome_tag = "[color=#00f5d4]VICTORY[/color]" if r.victory else "[color=#ff006e]DEFEAT (D%d)[/color]" % r.district_index
		lines.append("[%s] User [color=#ffd166]%s[/color] — Outcome: %s | Crew: %s | Credits: %dg" % [
			Time.get_time_string_from_unix_time(r.timestamp),
			r.session_id,
			outcome_tag,
			", ".join(r.fielded_unit_ids),
			r.gold_spent
		])
	session_feed.text = "\n".join(lines)

func _on_generate_sample_btn_pressed() -> void:
	TelemetryManager.generate_community_sample_data(50, repo)
	refresh_dashboard()
	if status_lbl:
		status_lbl.text = "Generated 50 fresh community test runs."

func _on_export_btn_pressed() -> void:
	var md = ExportTelemetryReport.generate_markdown_report(records, repo)
	var output_path = "res://data/community_analytics_report.md"
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(md)
		file.close()
		if status_lbl:
			status_lbl.text = "Exported report to data/community_analytics_report.md"

func _on_return_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").return_to_title()
