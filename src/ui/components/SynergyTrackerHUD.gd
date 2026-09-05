class_name SynergyTrackerHUD
extends PanelContainer

## Live HUD widget displaying active Faction synergies, Tag chains, and Cross-system combos
## Hovering over any faction or tag item displays full trait threshold benefits and current counts

const SynergyTooltipScript = preload("res://src/ui/components/SynergyTooltip.gd")
const DataRepoScript = preload("res://src/systems/DataRepository.gd")

@onready var faction_list: VBoxContainer = _find_list("FactionList")
@onready var tag_list: VBoxContainer = _find_list("TagList")
@onready var combo_list: VBoxContainer = _find_list("ComboList")

var repo: Object = null

func _find_list(node_name: String) -> VBoxContainer:
	var node = find_child(node_name, true, false)
	return node as VBoxContainer

func _get_repo() -> Object:
	if repo != null:
		return repo
	if is_inside_tree() and get_node_or_null("/root/GameManager") and get_node("/root/GameManager").active_run_manager:
		var rm = get_node("/root/GameManager").active_run_manager
		if rm._repo:
			repo = rm._repo
			return repo
	repo = DataRepoScript.new()
	if not repo.is_loaded:
		repo.load_all_data("res://data")
	return repo

func update_synergies(report: SynergyReport) -> void:
	_update_factions(report)
	_update_tags(report)
	_update_combos(report)

func _update_factions(report: SynergyReport) -> void:
	var target_list = faction_list if faction_list else _find_list("FactionList")
	if not target_list:
		return
		
	for child in target_list.get_children():
		child.queue_free()
		
	var r = _get_repo()
	var all_factions: Array[Enums.Faction] = [
		Enums.Faction.STREET_RUNNERS,
		Enums.Faction.CORP_ENFORCERS,
		Enums.Faction.ROGUE_AIS,
		Enums.Faction.FIXERS,
		Enums.Faction.BIO_HACKERS,
		Enums.Faction.NET_PHANTOMS
	]
	
	for f in all_factions:
		var count = report.faction_counts.get(f, 0) if report else 0
		var f_name = Enums.faction_to_string(f)
		var is_active = (count >= 2)
		var fac_res = r.get_faction(f) if r else null
		
		var display_text = "• %s (%d): %s" % [f_name, count, "ACTIVE" if is_active else "Inactive"]
		var color = Color(0, 0.95, 0.83) if is_active else (Color(0.7, 0.7, 0.8) if count > 0 else Color(0.4, 0.4, 0.5))
		
		var item = SynergyHUDItem.new(display_text, "faction", fac_res, count, color)
		target_list.add_child(item)

func _update_tags(report: SynergyReport) -> void:
	var target_list = tag_list if tag_list else _find_list("TagList")
	if not target_list:
		return
		
	for child in target_list.get_children():
		child.queue_free()
		
	var r = _get_repo()
	var all_tags: Array[Enums.AugmentTag] = [
		Enums.AugmentTag.KINETIC,
		Enums.AugmentTag.THERMAL,
		Enums.AugmentTag.NEURAL,
		Enums.AugmentTag.VIRAL
	]
	
	for t in all_tags:
		var count = report.tag_counts.get(t, 0) if report else 0
		var t_name = Enums.tag_to_string(t)
		var is_active = (count >= 2)
		var tag_res = r.get_tag(t) if r else null
		
		var display_text = "• %s Tag (%d): %s" % [t_name, count, "ACTIVE" if is_active else "Inactive"]
		var color = Color(0.7, 0.3, 1.0) if is_active else (Color(0.7, 0.7, 0.8) if count > 0 else Color(0.4, 0.4, 0.5))
		
		var item = SynergyHUDItem.new(display_text, "tag", tag_res, count, color)
		target_list.add_child(item)

func _update_combos(report: SynergyReport) -> void:
	var target_list = combo_list if combo_list else _find_list("ComboList")
	if not target_list:
		return
		
	for child in target_list.get_children():
		child.queue_free()
		
	if report == null or report.cross_system_bonuses.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "None"
		empty_lbl.add_theme_font_size_override("font_size", 9)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		target_list.add_child(empty_lbl)
		return
		
	for combo in report.cross_system_bonuses:
		var lbl = Label.new()
		lbl.text = "★ %s" % combo.name
		lbl.tooltip_text = "[%s]\n%s" % [combo.name, combo.description]
		lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.5))
		target_list.add_child(lbl)

class SynergyHUDItem extends Label:
	var item_type: String = ""
	var item_resource: Resource = null
	var current_count: int = 0
	
	func _init(p_text: String, p_type: String, p_res: Resource, p_count: int, p_color: Color) -> void:
		text = p_text
		item_type = p_type
		item_resource = p_res
		current_count = p_count
		mouse_filter = Control.MOUSE_FILTER_PASS
		tooltip_text = "synergy_details"
		add_theme_font_size_override("font_size", 9)
		add_theme_color_override("font_color", p_color)
		
	func _make_custom_tooltip(_for_text: String) -> Object:
		if item_type == "faction" and item_resource is FactionResource:
			return SynergyTooltipScript.create_faction_tooltip_node(item_resource as FactionResource, current_count)
		elif item_type == "tag" and item_resource is TagResource:
			return SynergyTooltipScript.create_tag_tooltip_node(item_resource as TagResource, current_count)
		return null

