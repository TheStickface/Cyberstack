class_name CodexScreen
extends Control

## Cyber-Codex / Operative Dossier and Lifetime Career Archive

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object = null
var profile: MetaProfile = null

@onready var tab_container: TabContainer = $VBox/TabContainer
@onready var operatives_container: GridContainer = $VBox/TabContainer/Operatives/Scroll/OperativesGrid
@onready var augments_container: GridContainer = $VBox/TabContainer/Augments/Scroll/AugmentsGrid
@onready var factions_container: VBoxContainer = $VBox/TabContainer/FactionRep/FactionsList
@onready var career_label: Label = $VBox/TabContainer/CareerRecords/VBox/StatsSummaryLabel
@onready var return_btn: Button = $VBox/TopBar/ReturnBtn

func _ready() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	if get_node_or_null("/root/GameManager"):
		profile = get_node("/root/GameManager").active_profile
	if profile == null:
		profile = SaveManager.load_profile()
		
	_populate_all_tabs()

func _populate_all_tabs() -> void:
	_populate_operatives()
	_populate_augments()
	_populate_factions()
	_populate_career()

func _populate_operatives() -> void:
	if not operatives_container:
		return
	for c in operatives_container.get_children():
		c.queue_free()
		
	for unit in repo.get_all_units():
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(240, 200)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		
		var is_unlocked = profile.unlocked_operatives.has(unit.id)
		
		var header = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = unit.display_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83) if is_unlocked else Color(0.4, 0.4, 0.5))
		header.add_child(name_lbl)
		
		var status_lbl = Label.new()
		status_lbl.text = "[UNLOCKED]" if is_unlocked else "[LOCKED]"
		status_lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83) if is_unlocked else Color(0.8, 0.2, 0.2))
		status_lbl.add_theme_font_size_override("font_size", 9)
		header.add_child(status_lbl)
		vbox.add_child(header)
		
		var role_lbl = Label.new()
		role_lbl.text = "%s | %s" % [unit.get_role_name(), unit.get_faction_name()]
		role_lbl.add_theme_font_size_override("font_size", 10)
		role_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 1.0))
		vbox.add_child(role_lbl)
		
		var bio_lbl = Label.new()
		bio_lbl.text = unit.bio if is_unlocked else "Encrypted personnel dossier. Reach Level 2 with this faction to unlock."
		bio_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bio_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bio_lbl.add_theme_font_size_override("font_size", 9)
		bio_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8) if is_unlocked else Color(0.3, 0.3, 0.4))
		vbox.add_child(bio_lbl)

		if is_unlocked and not unit.ability_name.is_empty():
			var ability_lbl = Label.new()
			ability_lbl.text = "⚡ %s: %s" % [unit.ability_name, unit.ability_description]
			ability_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ability_lbl.add_theme_font_size_override("font_size", 9)
			ability_lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.6))
			vbox.add_child(ability_lbl)

		if is_unlocked and unit.has_directional():
			var dir_lbl = Label.new()
			dir_lbl.text = "◆ %s (%s): %s" % [
				unit.directional_passive_description,
				unit.get_directional_header(),
				", ".join(unit.get_directional_stat_lines())
			]
			dir_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dir_lbl.add_theme_font_size_override("font_size", 9)
			dir_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
			vbox.add_child(dir_lbl)

		panel.add_child(vbox)
		operatives_container.add_child(panel)

func _populate_augments() -> void:
	if not augments_container:
		return
	for c in augments_container.get_children():
		c.queue_free()
		
	for aug in repo.get_all_augments():
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(240, 100)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		
		var name_lbl = Label.new()
		name_lbl.text = aug.display_name
		name_lbl.add_theme_color_override("font_color", Color(aug.get_tier_color_hex()))
		vbox.add_child(name_lbl)
		
		var tag_names: Array[String] = []
		for t in aug.tags:
			tag_names.append(Enums.tag_to_string(t))
		var sub_lbl = Label.new()
		sub_lbl.text = "[%s Tier | %s] Tags: %s" % [
			aug.get_tier_name(),
			Enums.slot_type_to_string(aug.slot_type),
			", ".join(tag_names)
		]
		sub_lbl.add_theme_font_size_override("font_size", 9)
		sub_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox.add_child(sub_lbl)
		
		var desc_lbl = Label.new()
		var desc_lines: Array[String] = aug.get_stat_lines()
		if aug.has_directional():
			desc_lines.append("◆ %s: %s" % [aug.get_directional_header(), ", ".join(aug.get_directional_stat_lines())])
		if aug.has_proc():
			desc_lines.append("⚡ %s: %s" % [aug.get_proc_header(), aug.get_proc_fragment()])
		desc_lbl.text = "\n".join(desc_lines)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
		vbox.add_child(desc_lbl)

		panel.add_child(vbox)
		augments_container.add_child(panel)

func _populate_factions() -> void:
	if not factions_container:
		return
	for c in factions_container.get_children():
		c.queue_free()
		
	for f_key in [Enums.Faction.STREET_RUNNERS, Enums.Faction.CORP_ENFORCERS, Enums.Faction.ROGUE_AIS, Enums.Faction.FIXERS]:
		var fac = repo.get_faction(f_key)
		if fac == null:
			continue
			
		var pts = profile.faction_reputation.get(f_key, 0)
		var lvl = MetaManager.get_faction_level(pts)
		
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		
		var hbox = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = fac.display_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_color_override("font_color", fac.theme_color)
		hbox.add_child(name_lbl)
		
		var lvl_lbl = Label.new()
		lvl_lbl.text = "LEVEL %d (%d PTS)" % [lvl, pts]
		lvl_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0))
		lvl_lbl.add_theme_font_size_override("font_size", 11)
		hbox.add_child(lvl_lbl)
		vbox.add_child(hbox)
		
		var pbar = ProgressBar.new()
		pbar.custom_minimum_size = Vector2(0, 14)
		pbar.max_value = 500
		pbar.value = pts
		pbar.show_percentage = false
		vbox.add_child(pbar)
		
		var perk_lbl = Label.new()
		perk_lbl.text = "Perk: %s" % _get_perk_text(lvl)
		perk_lbl.add_theme_font_size_override("font_size", 9)
		perk_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		vbox.add_child(perk_lbl)
		
		panel.add_child(vbox)
		factions_container.add_child(panel)

func _get_perk_text(lvl: int) -> String:
	match lvl:
		1: return "Recruit Standing (Base Operatives Available)"
		2: return "Operative Unlocked (Alternative Starter Available)"
		3: return "Augment Cache (Faction-Exclusive Augments in Shop)"
		4: return "Synergy Overclock (+1 Starting Faction Counter)"
		_: return "Unknown"

func _populate_career() -> void:
	if not career_label:
		return
	var win_rate = (float(profile.total_victories) / float(maxi(1, profile.total_runs_played))) * 100.0
	career_label.text = """
TOTAL RUNS EXECUTED: %d
RUNS SUCCESSFULLY COMPLETED: %d (Win Rate: %.1f%%)
DISTRICT BOSSES ELIMINATED: %d
TOTAL BLACK-MARKET CREDITS EARNED: %d
OPERATIVES UNLOCKED IN ROSTER: %d / %d
""" % [
		profile.total_runs_played,
		profile.total_victories,
		win_rate,
		profile.total_bosses_defeated,
		profile.total_credits_earned,
		profile.unlocked_operatives.size(),
		repo.get_all_units().size()
	]

func _on_return_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").return_to_title()
