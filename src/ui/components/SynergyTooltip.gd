class_name SynergyTooltip
extends CanvasLayer

## Cyberpunk Floating Synergy Intelligence & Operative Profile Tooltip

static func create_custom_tooltip_node(unit_res: UnitResource, impact_info: Dictionary = {}, star_lvl: int = 1) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(290, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.10, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0, 0.95, 0.83, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	margin.add_child(main_vbox)
	
	if unit_res == null:
		return panel
		
	var star_str = " ★" if star_lvl == 1 else (" ★★" if star_lvl == 2 else " ★★★")
	var title_label = Label.new()
	title_label.text = "%s%s" % [unit_res.display_name, star_str]
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(0, 1, 0.9))
	main_vbox.add_child(title_label)
	
	var subtitle_label = Label.new()
	subtitle_label.text = "[%s] • [%s] • Cost: %d CR" % [
		unit_res.get_role_name().to_upper(),
		unit_res.get_faction_name().to_upper(),
		unit_res.base_cost
	]
	subtitle_label.add_theme_font_size_override("font_size", 9)
	subtitle_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	main_vbox.add_child(subtitle_label)
	
	if not unit_res.bio.is_empty():
		var bio_label = Label.new()
		bio_label.text = "\"%s\"" % unit_res.bio
		bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bio_label.add_theme_font_size_override("font_size", 8)
		bio_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
		main_vbox.add_child(bio_label)
		
	var stats_label = Label.new()
	stats_label.text = "HP: %.0f | Armor: %.0f | AD: %.0f | AP: %.0f | Spd: %.0f | Crit: %.0f%%" % [
		unit_res.base_max_health,
		unit_res.base_armor,
		unit_res.base_attack_damage,
		unit_res.base_ability_power,
		unit_res.base_speed,
		unit_res.base_crit_chance * 100.0
	]
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	main_vbox.add_child(stats_label)
	
	if not unit_res.ability_name.is_empty():
		var ability_header = Label.new()
		ability_header.text = "⚡ %s" % unit_res.ability_name
		ability_header.add_theme_font_size_override("font_size", 10)
		ability_header.add_theme_color_override("font_color", Color(1, 0.2, 0.6))
		main_vbox.add_child(ability_header)
		
		var ability_desc = Label.new()
		ability_desc.text = unit_res.ability_description
		ability_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability_desc.add_theme_font_size_override("font_size", 8)
		ability_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		main_vbox.add_child(ability_desc)
		
	# Synergy Intel Box
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	var intel_header = Label.new()
	intel_header.text = "⚡ SYNERGY INTELLIGENCE"
	intel_header.add_theme_font_size_override("font_size", 9)
	intel_header.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
	main_vbox.add_child(intel_header)
	
	if not impact_info.is_empty():
		var f_name = impact_info.get("faction_name", "")
		var prev = impact_info.get("prev_count", 0)
		var nxt = impact_info.get("new_count", 0)
		var will_act = impact_info.get("will_activate_threshold", false)
		var is_dup = impact_info.get("is_duplicate", false)
		
		var f_lbl = Label.new()
		if will_act:
			f_lbl.text = "• %s: [%d -> %d] ★ ACTIVATES NEW TIER!" % [f_name, prev, nxt]
			f_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			f_lbl.text = "• %s: Current [%d] -> With Operative [%d]" % [f_name, prev, nxt]
			f_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		f_lbl.add_theme_font_size_override("font_size", 9)
		main_vbox.add_child(f_lbl)
		
		if is_dup:
			var dup_lbl = Label.new()
			dup_lbl.text = "★ 2-COPY MERGE: Combines toward Star Level Up!"
			dup_lbl.add_theme_font_size_override("font_size", 9)
			dup_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			main_vbox.add_child(dup_lbl)
			
		var new_combos = impact_info.get("new_combos", [])
		for combo in new_combos:
			var c_lbl = Label.new()
			c_lbl.text = "★ UNLOCKS COMBO: %s!" % combo.name
			c_lbl.add_theme_font_size_override("font_size", 9)
			c_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.6))
			main_vbox.add_child(c_lbl)
			
	return panel

static func create_augment_tooltip_node(aug_res: AugmentResource) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.10, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.3, 1, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 5)
	margin.add_child(main_vbox)
	
	if aug_res == null:
		return panel
		
	var title_label = Label.new()
	title_label.text = aug_res.display_name
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(aug_res.get_tier_color_hex()))
	main_vbox.add_child(title_label)
	
	var tag_names: Array[String] = []
	for t in aug_res.tags:
		tag_names.append(Enums.tag_to_string(t))
		
	var subtitle_label = Label.new()
	subtitle_label.text = "[%s TIER] • [%s SLOT] • Cost: %d CR" % [
		aug_res.get_tier_name().to_upper(),
		Enums.slot_type_to_string(aug_res.slot_type).to_upper(),
		aug_res.base_cost
	]
	subtitle_label.add_theme_font_size_override("font_size", 9)
	subtitle_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	main_vbox.add_child(subtitle_label)
	
	var bio_label = Label.new()
	bio_label.text = "Tags: %s" % (", ".join(tag_names) if not tag_names.is_empty() else "None")
	bio_label.add_theme_font_size_override("font_size", 8)
	bio_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	main_vbox.add_child(bio_label)
	
	var stats_label = Label.new()
	stats_label.text = aug_res.description
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	main_vbox.add_child(stats_label)
	
	return panel
