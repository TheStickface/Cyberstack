class_name SynergyTooltip
extends PanelContainer

## Cyberpunk Floating Synergy Intelligence & Operative Profile Tooltip

var title_label: Label = Label.new()
var subtitle_label: Label = Label.new()
var bio_label: Label = Label.new()
var stats_label: Label = Label.new()
var ability_header: Label = Label.new()
var ability_desc: Label = Label.new()
var synergy_box: VBoxContainer = VBoxContainer.new()
var main_vbox: VBoxContainer = VBoxContainer.new()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	visible = false
	z_index = 100
	custom_minimum_size = Vector2(290, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.10, 0.98)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0, 0.95, 0.83, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 6
	add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 5)
	margin.add_child(main_vbox)
	
	# Title
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(0, 1, 0.9))
	main_vbox.add_child(title_label)
	
	# Subtitle / Role & Faction
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_label.add_theme_font_size_override("font_size", 9)
	subtitle_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	main_vbox.add_child(subtitle_label)
	
	# Bio
	bio_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bio_label.add_theme_font_size_override("font_size", 8)
	bio_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	main_vbox.add_child(bio_label)
	
	# Stats
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	main_vbox.add_child(stats_label)
	
	# Ability Section
	ability_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_header.add_theme_font_size_override("font_size", 10)
	ability_header.add_theme_color_override("font_color", Color(1, 0.2, 0.6))
	main_vbox.add_child(ability_header)
	
	ability_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_desc.add_theme_font_size_override("font_size", 8)
	ability_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	main_vbox.add_child(ability_desc)
	
	# Synergy Intel Box
	synergy_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(synergy_box)

func show_for_unit(unit_res: UnitResource, impact_info: Dictionary = {}, star_lvl: int = 1) -> void:
	if unit_res == null:
		hide()
		return
		
	var star_str = " ★" if star_lvl == 1 else (" ★★" if star_lvl == 2 else " ★★★")
	title_label.text = "%s%s" % [unit_res.display_name, star_str]
	subtitle_label.text = "[%s] • [%s] • Cost: %d CR" % [
		unit_res.get_role_name().to_upper(),
		unit_res.get_faction_name().to_upper(),
		unit_res.base_cost
	]
	bio_label.text = "\"%s\"" % unit_res.bio if not unit_res.bio.is_empty() else ""
	bio_label.visible = not unit_res.bio.is_empty()
	
	stats_label.text = "HP: %.0f | Armor: %.0f | AD: %.0f | AP: %.0f | Spd: %.0f | Crit: %.0f%%" % [
		unit_res.base_max_health,
		unit_res.base_armor,
		unit_res.base_attack_damage,
		unit_res.base_ability_power,
		unit_res.base_speed,
		unit_res.base_crit_chance * 100.0
	]
	
	ability_header.text = "⚡ %s" % unit_res.ability_name
	ability_header.visible = not unit_res.ability_name.is_empty()
	ability_desc.text = unit_res.ability_description
	ability_desc.visible = not unit_res.ability_description.is_empty()
	
	# Populate Synergy Intel Box
	for c in synergy_box.get_children():
		c.queue_free()
		
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	synergy_box.add_child(sep)
	
	var intel_header = Label.new()
	intel_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intel_header.text = "⚡ SYNERGY INTELLIGENCE"
	intel_header.add_theme_font_size_override("font_size", 9)
	intel_header.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
	synergy_box.add_child(intel_header)
	
	if not impact_info.is_empty():
		var f_name = impact_info.get("faction_name", "")
		var prev = impact_info.get("prev_count", 0)
		var nxt = impact_info.get("new_count", 0)
		var will_act = impact_info.get("will_activate_threshold", false)
		var is_dup = impact_info.get("is_duplicate", false)
		
		var f_lbl = Label.new()
		f_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if will_act:
			f_lbl.text = "• %s: [%d -> %d] ★ ACTIVATES NEW TIER!" % [f_name, prev, nxt]
			f_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			f_lbl.text = "• %s: Current [%d] -> With Operative [%d]" % [f_name, prev, nxt]
			f_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		f_lbl.add_theme_font_size_override("font_size", 9)
		synergy_box.add_child(f_lbl)
		
		if is_dup:
			var dup_lbl = Label.new()
			dup_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dup_lbl.text = "★ 2-COPY MERGE: Combines toward Star Level Up!"
			dup_lbl.add_theme_font_size_override("font_size", 9)
			dup_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			synergy_box.add_child(dup_lbl)
			
		var new_combos = impact_info.get("new_combos", [])
		for combo in new_combos:
			var c_lbl = Label.new()
			c_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c_lbl.text = "★ UNLOCKS COMBO: %s!" % combo.name
			c_lbl.add_theme_font_size_override("font_size", 9)
			c_lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.6))
			synergy_box.add_child(c_lbl)
			
	synergy_box.visible = true
	show()

func show_for_augment(aug_res: AugmentResource) -> void:
	if aug_res == null:
		hide()
		return
		
	title_label.text = aug_res.display_name
	title_label.add_theme_color_override("font_color", Color(aug_res.get_tier_color_hex()))
	
	var tag_names: Array[String] = []
	for t in aug_res.tags:
		tag_names.append(Enums.tag_to_string(t))
		
	subtitle_label.text = "[%s TIER] • [%s SLOT] • Cost: %d CR" % [
		aug_res.get_tier_name().to_upper(),
		Enums.slot_type_to_string(aug_res.slot_type).to_upper(),
		aug_res.base_cost
	]
	bio_label.text = "Tags: %s" % (", ".join(tag_names) if not tag_names.is_empty() else "None")
	bio_label.visible = true
	
	stats_label.text = aug_res.description
	ability_header.visible = false
	ability_desc.visible = false
	
	for c in synergy_box.get_children():
		c.queue_free()
	synergy_box.visible = false
	show()

func update_screen_position(target_pos: Vector2, vp_size: Vector2) -> void:
	var m_pos = get_global_mouse_position()
	if m_pos.length_squared() > 10:
		target_pos = m_pos
		
	var tip_size = size if size.x > 50 else Vector2(290, 240)
	var pos_x = target_pos.x + 18
	var pos_y = target_pos.y + 12
	
	# Clamp within screen bounds
	if pos_x + tip_size.x > vp_size.x - 10:
		pos_x = target_pos.x - tip_size.x - 18
	if pos_x < 10:
		pos_x = 10
	if pos_y + tip_size.y > vp_size.y - 10:
		pos_y = vp_size.y - tip_size.y - 10
	if pos_y < 10:
		pos_y = 10
		
	global_position = Vector2(pos_x, pos_y)
