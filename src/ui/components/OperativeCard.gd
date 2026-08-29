class_name OperativeCard
extends PanelContainer

## Interactive UI Card for fielded or benched operatives with 3 augment slots

signal card_clicked(unit: UnitInstance)
signal slot_clicked(unit: UnitInstance, slot_index: int)
signal slot_unequip_requested(unit: UnitInstance, slot_index: int)
signal unit_toggle_field_requested(unit: UnitInstance)
signal unit_sell_requested(unit: UnitInstance)
signal card_mouse_entered(unit: UnitInstance, card_pos: Vector2)
signal card_mouse_exited()
signal augment_dropped(unit: UnitInstance, target_slot: int, drag_data: Dictionary)
signal unit_dropped_on_card(target_unit: UnitInstance, drag_data: Dictionary)

const SynergyTooltipScript = preload("res://src/ui/components/SynergyTooltip.gd")

var unit_instance: UnitInstance = null
var is_fielded: bool = true
var default_style: StyleBoxFlat = null

@onready var portrait_icon: TextureRect = $Margin/VBox/Header/PortraitIcon
@onready var name_label: Label = $Margin/VBox/Header/NameLabel
@onready var role_badge: Label = $Margin/VBox/Header/RoleBadge
@onready var faction_badge: Label = $Margin/VBox/Header/FactionBadge
@onready var stats_label: Label = $Margin/VBox/StatsLabel
@onready var formation_badge: Label = $Margin/VBox/FormationBadge
@onready var ability_label: Label = $Margin/VBox/AbilityLabel
@onready var slots_header: Label = $Margin/VBox/SlotsHeader
@onready var slots_container: HBoxContainer = $Margin/VBox/SlotsContainer
@onready var toggle_btn: Button = $Margin/VBox/Actions/ToggleFieldBtn
@onready var sell_btn: Button = $Margin/VBox/Actions/SellBtn

var active_formation_tags: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_card_mouse_entered)
	mouse_exited.connect(_on_card_mouse_exited)
	gui_input.connect(_on_card_gui_input)
	_set_mouse_filter_recursive(self)
	
	if portrait_icon:
		portrait_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if get_theme_stylebox("panel") is StyleBoxFlat:
		default_style = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
		
	if get_node_or_null("/root/EventBus"):
		var eb = get_node("/root/EventBus")
		eb.augment_drag_started.connect(_on_augment_drag_started)
		eb.augment_drag_ended.connect(_on_augment_drag_ended)
		eb.unit_drag_started.connect(_on_unit_drag_started)
		eb.unit_drag_ended.connect(_on_unit_drag_ended)

func _exit_tree() -> void:
	if get_node_or_null("/root/EventBus"):
		var eb = get_node("/root/EventBus")
		if eb.augment_drag_started.is_connected(_on_augment_drag_started):
			eb.augment_drag_started.disconnect(_on_augment_drag_started)
		if eb.augment_drag_ended.is_connected(_on_augment_drag_ended):
			eb.augment_drag_ended.disconnect(_on_augment_drag_ended)
		if eb.unit_drag_started.is_connected(_on_unit_drag_started):
			eb.unit_drag_started.disconnect(_on_unit_drag_started)
		if eb.unit_drag_ended.is_connected(_on_unit_drag_ended):
			eb.unit_drag_ended.disconnect(_on_unit_drag_ended)

func _on_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Quick toggle on right click
			unit_toggle_field_requested.emit(unit_instance)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(unit_instance)

var is_dragging_this: bool = false

func _get_drag_data(_pos: Vector2) -> Variant:
	if unit_instance == null or unit_instance.unit_resource == null:
		return null
	is_dragging_this = true
	if is_inside_tree() and get_node_or_null("/root/EventBus"):
		get_node("/root/EventBus").unit_drag_started.emit(unit_instance, unit_instance.grid_slot, is_fielded)

		
	var preview = PanelContainer.new()
	preview.custom_minimum_size = Vector2(150, 50)
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.08, 0.05, 0.16, 0.95)
	pstyle.border_width_left = 2
	pstyle.border_width_top = 2
	pstyle.border_width_right = 2
	pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.0, 0.95, 0.83, 1.0)
	pstyle.corner_radius_top_left = 6
	pstyle.corner_radius_top_right = 6
	pstyle.corner_radius_bottom_right = 6
	pstyle.corner_radius_bottom_left = 6
	pstyle.shadow_color = Color(0, 0.95, 0.83, 0.4)
	pstyle.shadow_size = 6
	preview.add_theme_stylebox_override("panel", pstyle)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	preview.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = "%s %s" % ["★".repeat(unit_instance.star_level), unit_instance.unit_resource.display_name]
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.0, 0.95, 0.83))
	vbox.add_child(name_lbl)
	
	var role_lbl = Label.new()
	role_lbl.text = "[%s] %s" % [unit_instance.unit_resource.get_role_name().to_upper(), unit_instance.unit_resource.get_faction_name().to_upper()]
	role_lbl.add_theme_font_size_override("font_size", 8)
	role_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	vbox.add_child(role_lbl)
	
	if is_inside_tree():
		set_drag_preview(preview)
	else:
		preview.free()

	
	return {
		"type": "unit",
		"unit": unit_instance,
		"source_slot": unit_instance.grid_slot,
		"is_fielded": is_fielded
	}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if is_dragging_this:
			is_dragging_this = false
			if get_node_or_null("/root/EventBus"):
				get_node("/root/EventBus").unit_drag_ended.emit()

func _on_unit_drag_started(dragged_unit: RefCounted, _src_slot: int, _drag_is_fielded: bool) -> void:
	if dragged_unit != unit_instance:
		var swap_style = default_style.duplicate() if default_style else StyleBoxFlat.new()
		swap_style.border_color = Color(0.8, 0.3, 1.0, 0.8)
		swap_style.border_width_left = 2
		swap_style.border_width_top = 2
		swap_style.border_width_right = 2
		swap_style.border_width_bottom = 2
		add_theme_stylebox_override("panel", swap_style)

func _on_unit_drag_ended() -> void:
	if default_style:
		add_theme_stylebox_override("panel", default_style)

func _on_augment_drag_started(aug_res: Resource) -> void:
	if not is_fielded or unit_instance == null or not aug_res is AugmentResource:
		return
		
	var aug = aug_res as AugmentResource
	var has_compat = false
	var slot_types = unit_instance.unit_resource.get_slot_types()
	
	for i in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
		var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
		var is_compat = (aug.slot_type == slot_type or aug.slot_type == Enums.SlotType.FLEX or slot_type == Enums.SlotType.FLEX)
		if is_compat:
			has_compat = true
			if slots_container and i < slots_container.get_child_count():
				var btn = slots_container.get_child(i) as Button
				if btn:
					btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
					
	if has_compat:
		var glow_style = default_style.duplicate() if default_style else StyleBoxFlat.new()
		glow_style.border_color = Color(0.0, 1.0, 0.85, 1.0)
		glow_style.border_width_left = 2
		glow_style.border_width_top = 2
		glow_style.border_width_right = 2
		glow_style.border_width_bottom = 2
		glow_style.shadow_color = Color(0.0, 0.95, 0.83, 0.5)
		glow_style.shadow_size = 6
		add_theme_stylebox_override("panel", glow_style)
		modulate.a = 1.0
	else:
		modulate.a = 0.45

func _on_augment_drag_ended() -> void:
	modulate.a = 1.0
	if default_style:
		add_theme_stylebox_override("panel", default_style)
	_refresh_slots()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var dtype = data.get("type", "")
	if dtype == "unit":
		var dragged_u = data.get("unit") as UnitInstance
		return dragged_u != null and dragged_u != unit_instance
	elif dtype == "augment" or dtype == "slotted_augment":
		if unit_instance == null:
			return false
		var aug_res = data.get("resource", null) as AugmentResource
		if aug_res == null:
			return false
		var slot_types = unit_instance.unit_resource.get_slot_types()
		for i in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
			var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
			if aug_res.slot_type == slot_type or aug_res.slot_type == Enums.SlotType.FLEX or slot_type == Enums.SlotType.FLEX:
				return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
		
	var dtype = data.get("type", "")
	if dtype == "unit":
		unit_dropped_on_card.emit(unit_instance, data)
		return
		
	var aug_res = data.get("resource", null) as AugmentResource
	if aug_res == null:
		return
		
	# Find which slot button was targeted, or find first compatible slot
	var target_slot: int = -1
	var slot_types = unit_instance.unit_resource.get_slot_types()
	
	if slots_container:
		for i in range(slots_container.get_child_count()):
			var btn = slots_container.get_child(i) as Button
			if btn and btn.get_global_rect().has_point(btn.get_global_mouse_position()):
				var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
				if aug_res.slot_type == slot_type or aug_res.slot_type == Enums.SlotType.FLEX or slot_type == Enums.SlotType.FLEX:
					target_slot = i
					break
					
	if target_slot == -1:
		for i in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
			var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
			if aug_res.slot_type == slot_type or aug_res.slot_type == Enums.SlotType.FLEX or slot_type == Enums.SlotType.FLEX:
				if unit_instance.equipped_augments[i] == null:
					target_slot = i
					break
				elif target_slot == -1:
					target_slot = i
					
	if target_slot != -1:
		augment_dropped.emit(unit_instance, target_slot, data)


func _set_mouse_filter_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			_set_mouse_filter_recursive(child)

func _on_card_mouse_entered() -> void:
	if unit_instance and unit_instance.unit_resource:
		card_mouse_entered.emit(unit_instance, global_position)

func _on_card_mouse_exited() -> void:
	card_mouse_exited.emit()

func _make_custom_tooltip(_for_text: String) -> Object:
	if unit_instance and unit_instance.unit_resource:
		return SynergyTooltipScript.create_custom_tooltip_node(unit_instance.unit_resource, {}, unit_instance.star_level)
	return null

func setup(unit: UnitInstance, fielded: bool = true, p_formation_tags: Array = []) -> void:
	unit_instance = unit
	is_fielded = fielded
	active_formation_tags = p_formation_tags
	_update_ui()

func set_active_formation_tags(tags: Array) -> void:
	active_formation_tags = tags
	_update_formation_badge()

func _ensure_nodes() -> void:
	if portrait_icon == null:
		portrait_icon = get_node_or_null("Margin/VBox/Header/PortraitIcon")
	if name_label == null:
		name_label = get_node_or_null("Margin/VBox/Header/NameLabel")
	if role_badge == null:
		role_badge = get_node_or_null("Margin/VBox/Header/RoleBadge")
	if faction_badge == null:
		faction_badge = get_node_or_null("Margin/VBox/Header/FactionBadge")
	if stats_label == null:
		stats_label = get_node_or_null("Margin/VBox/StatsLabel")
	if formation_badge == null:
		formation_badge = get_node_or_null("Margin/VBox/FormationBadge")
	if ability_label == null:
		ability_label = get_node_or_null("Margin/VBox/AbilityLabel")
	if slots_header == null:
		slots_header = get_node_or_null("Margin/VBox/SlotsHeader")
	if slots_container == null:
		slots_container = get_node_or_null("Margin/VBox/SlotsContainer")
	if toggle_btn == null:
		toggle_btn = get_node_or_null("Margin/VBox/Actions/ToggleFieldBtn")
	if sell_btn == null:
		sell_btn = get_node_or_null("Margin/VBox/Actions/SellBtn")

func _update_formation_badge() -> void:
	_ensure_nodes()
	if formation_badge == null or unit_instance == null or unit_instance.unit_resource == null:
		return
	var res = unit_instance.unit_resource
	var badge_parts: Array[String] = []
	
	var base_badge = res.get_formation_badge_text()
	if not base_badge.is_empty():
		badge_parts.append(base_badge)
		
	# Check equipped augment directional bonuses
	for aug in unit_instance.equipped_augments:
		if aug and aug.has_directional():
			var aug_b = aug.get_formation_badge_text()
			if not aug_b.is_empty():
				badge_parts.append("⚡" + aug_b)
				
	# If fielded and receiving active buffs from neighbors
	if is_fielded and not active_formation_tags.is_empty():
		badge_parts.append("✨BUFFED")
		
	if badge_parts.is_empty():
		formation_badge.visible = false
	else:
		formation_badge.visible = true
		formation_badge.text = " ".join(badge_parts)
		
		# Set distinct cyberpunk theme color for formation badge
		if res.has_directional():
			formation_badge.add_theme_color_override("font_color", Color(0.0, 0.95, 0.85)) # Neon Cyan
		elif res.role == Enums.UnitRole.TANK:
			formation_badge.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0)) # Electric Blue
		elif res.role == Enums.UnitRole.HACKER:
			formation_badge.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7)) # Mint Green
		elif res.role == Enums.UnitRole.SNIPER:
			formation_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1)) # Amber Gold
		else:
			formation_badge.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0)) # Lavender

func _update_ui() -> void:
	_ensure_nodes()
	if unit_instance == null or unit_instance.unit_resource == null:
		visible = false
		return
		
	visible = true
	tooltip_text = "Operative Profile"
	var res = unit_instance.unit_resource

	if portrait_icon:
		portrait_icon.texture = res.portrait
		portrait_icon.visible = res.portrait != null

	if name_label:
		if unit_instance.star_level == 1:
			name_label.text = res.display_name
			name_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		elif unit_instance.star_level == 2:
			name_label.text = "★★ %s" % res.display_name
			name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
		elif unit_instance.star_level >= 3:
			name_label.text = "★★★ %s" % res.display_name
			name_label.add_theme_color_override("font_color", Color(1, 0.2, 0.8))
			
	if role_badge:
		role_badge.text = res.get_role_name().to_upper()
	if faction_badge:
		faction_badge.text = res.get_faction_name().to_upper()
		
	if stats_label:
		stats_label.text = "HP: %.0f | AD: %.0f | AP: %.0f" % [
			unit_instance.calculate_effective_stat(Enums.StatType.MAX_HEALTH),
			unit_instance.calculate_effective_stat(Enums.StatType.ATTACK_DAMAGE),
			unit_instance.calculate_effective_stat(Enums.StatType.ABILITY_POWER)
		]
		
	_update_formation_badge()
		
	if ability_label:
		ability_label.text = res.ability_name
		
	if toggle_btn:
		toggle_btn.text = "BENCH" if is_fielded else "DEPLOY"
		
	if sell_btn:
		var sell_val = res.base_cost * (2 if unit_instance.star_level == 2 else (4 if unit_instance.star_level >= 3 else 1))
		sell_btn.text = "SELL (%s)" % Constants.format_currency(sell_val, true)
		
	if is_fielded:
		custom_minimum_size = Vector2(150, 112)
		if slots_header:
			slots_header.visible = false
		if slots_container:
			slots_container.visible = true
		_refresh_slots()
	else:
		custom_minimum_size = Vector2(135, 76)
		if slots_header:
			slots_header.visible = false
		if slots_container:
			slots_container.visible = false

func _refresh_slots() -> void:
	if not slots_container or unit_instance == null:
		return
		
	for child in slots_container.get_children():
		child.queue_free()
		
	var slot_types = unit_instance.unit_resource.get_slot_types()
	for i in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
		var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
		var aug = unit_instance.equipped_augments[i]
		
		var slot_btn = AugmentSlotButton.new()
		slot_btn.slot_index = i
		slot_btn.unit_instance = unit_instance
		slot_btn.augment_res = aug
		slot_btn.custom_minimum_size = Vector2(44, 20)
		slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_btn.add_theme_font_size_override("font_size", 8)
		
		if aug != null:
			slot_btn.text = "[%s]%s" % [aug.get_tier_name().substr(0, 1), aug.display_name.substr(0, 4)]
			var tier_col = Color(aug.get_tier_color_hex())
			slot_btn.add_theme_color_override("font_color", tier_col)
			var aug_lines: Array[String] = ["STATS"] + aug.get_stat_lines()
			if aug.has_directional():
				aug_lines.append("")
				aug_lines.append(aug.get_directional_header())
				aug_lines.append_array(aug.get_directional_stat_lines())
			if aug.has_proc():
				aug_lines.append("")
				aug_lines.append(aug.get_proc_header())
				aug_lines.append(aug.get_proc_fragment())
			aug_lines.append("")
			aug_lines.append("Drag to swap/move or right-click to unequip")
			slot_btn.tooltip_text = "\n".join(aug_lines)
		else:
			slot_btn.text = "+%s" % _slot_type_name(slot_type).substr(0, 3)
			slot_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
			slot_btn.tooltip_text = "Empty %s slot. Drag augment here to equip." % _slot_type_name(slot_type)
			
		var slot_idx = i
		slot_btn.pressed.connect(func(): slot_clicked.emit(unit_instance, slot_idx))
		slot_btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
				slot_unequip_requested.emit(unit_instance, slot_idx)
		)
		
		slots_container.add_child(slot_btn)

class AugmentSlotButton extends Button:
	var slot_index: int = 0
	var unit_instance: UnitInstance = null
	var augment_res: AugmentResource = null
	var is_dragging_this: bool = false
	
	func _get_drag_data(_pos: Vector2) -> Variant:
		if augment_res == null:
			return null
		is_dragging_this = true
		if get_node_or_null("/root/EventBus"):
			get_node("/root/EventBus").augment_drag_started.emit(augment_res)
			
		var preview = PanelContainer.new()
		preview.custom_minimum_size = Vector2(110, 28)
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = Color(0.08, 0.06, 0.18, 0.95)
		pstyle.border_width_left = 2
		pstyle.border_width_top = 2
		pstyle.border_width_right = 2
		pstyle.border_width_bottom = 2
		pstyle.border_color = Color(augment_res.get_tier_color_hex())
		pstyle.corner_radius_top_left = 4
		pstyle.corner_radius_top_right = 4
		pstyle.corner_radius_bottom_left = 4
		pstyle.corner_radius_bottom_right = 4
		preview.add_theme_stylebox_override("panel", pstyle)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_right", 6)
		preview.add_child(margin)
		
		var lbl = Label.new()
		lbl.text = "⚡ %s" % augment_res.display_name
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(augment_res.get_tier_color_hex()))
		margin.add_child(lbl)
		
		set_drag_preview(preview)
		
		return {
			"type": "slotted_augment",
			"source_unit": unit_instance,
			"source_slot": slot_index,
			"resource": augment_res
		}

	func _notification(what: int) -> void:
		if what == NOTIFICATION_DRAG_END:
			if is_dragging_this:
				is_dragging_this = false
				if get_node_or_null("/root/EventBus"):
					get_node("/root/EventBus").augment_drag_ended.emit()

func _slot_type_name(st: Enums.SlotType) -> String:
	match st:
		Enums.SlotType.DEFENSIVE: return "DEF"
		Enums.SlotType.UTILITY: return "UTIL"
		Enums.SlotType.OFFENSIVE: return "OFF"
		Enums.SlotType.PASSIVE: return "PASSIVE"
		_: return "FLEX"

func _on_toggle_field_pressed() -> void:
	unit_toggle_field_requested.emit(unit_instance)

func _on_sell_pressed() -> void:
	unit_sell_requested.emit(unit_instance)
