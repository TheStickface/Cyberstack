class_name SynergyTrackerHUD
extends PanelContainer

## Live HUD widget displaying active Faction synergies, Tag chains, and Cross-system combos

@onready var faction_list: VBoxContainer = $VBox/FactionList
@onready var tag_list: VBoxContainer = $VBox/TagList
@onready var combo_list: VBoxContainer = $VBox/ComboList

func update_synergies(report: SynergyReport) -> void:
	_update_factions(report)
	_update_tags(report)
	_update_combos(report)

func _update_factions(report: SynergyReport) -> void:
	if not faction_list:
		return
		
	for child in faction_list.get_children():
		child.queue_free()
		
	if report == null or report.faction_counts.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No active faction traits"
		empty_lbl.add_theme_font_size_override("font_size", 9)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		faction_list.add_child(empty_lbl)
		return
		
	for f in report.faction_counts.keys():
		var count = report.faction_counts[f]
		var f_name = Enums.faction_to_string(f as Enums.Faction)
		var is_active = (count >= 2)
		
		var lbl = Label.new()
		lbl.text = "• %s (%d): %s" % [f_name, count, "ACTIVE" if is_active else "Inactive"]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83) if is_active else Color(0.5, 0.5, 0.6))
		faction_list.add_child(lbl)

func _update_tags(report: SynergyReport) -> void:
	if not tag_list:
		return
		
	for child in tag_list.get_children():
		child.queue_free()
		
	if report == null or report.tag_counts.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No augment tags equipped"
		empty_lbl.add_theme_font_size_override("font_size", 9)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		tag_list.add_child(empty_lbl)
		return
		
	for t in report.tag_counts.keys():
		var count = report.tag_counts[t]
		var t_name = Enums.tag_to_string(t as Enums.AugmentTag)
		var is_active = (count >= 2)
		
		var lbl = Label.new()
		lbl.text = "• %s Tag (%d): %s" % [t_name, count, "ACTIVE" if is_active else "Inactive"]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.3, 1.0) if is_active else Color(0.5, 0.5, 0.6))
		tag_list.add_child(lbl)

func _update_combos(report: SynergyReport) -> void:
	if not combo_list:
		return
		
	for child in combo_list.get_children():
		child.queue_free()
		
	if report == null or report.cross_system_bonuses.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "None"
		empty_lbl.add_theme_font_size_override("font_size", 9)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		combo_list.add_child(empty_lbl)
		return
		
	for combo in report.cross_system_bonuses:
		var lbl = Label.new()
		lbl.text = "★ %s" % combo.name
		lbl.tooltip_text = combo.description
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.5))
		combo_list.add_child(lbl)
