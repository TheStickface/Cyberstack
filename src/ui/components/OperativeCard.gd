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

const SynergyTooltipScript = preload("res://src/ui/components/SynergyTooltip.gd")

var unit_instance: UnitInstance = null
var is_fielded: bool = true
var default_style: StyleBoxFlat = null

@onready var name_label: Label = $Margin/VBox/Header/NameLabel
@onready var role_badge: Label = $Margin/VBox/Header/RoleBadge
@onready var faction_badge: Label = $Margin/VBox/Header/FactionBadge
@onready var stats_label: Label = $Margin/VBox/StatsLabel
@onready var ability_label: Label = $Margin/VBox/AbilityLabel
@onready var slots_header: Label = $Margin/VBox/SlotsHeader
@onready var slots_container: VBoxContainer = $Margin/VBox/SlotsContainer
@onready var toggle_btn: Button = $Margin/VBox/Actions/ToggleFieldBtn
@onready var sell_btn: Button = $Margin/VBox/Actions/SellBtn

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_card_mouse_entered)
	mouse_exited.connect(_on_card_mouse_exited)
	_set_mouse_filter_recursive(self)
	
	if get_theme_stylebox("panel") is StyleBoxFlat:
		default_style = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
		
	if get_node_or_null("/root/EventBus"):
		var eb = get_node("/root/EventBus")
		eb.augment_drag_started.connect(_on_augment_drag_started)
		eb.augment_drag_ended.connect(_on_augment_drag_ended)

func _exit_tree() -> void:
	if get_node_or_null("/root/EventBus"):
		var eb = get_node("/root/EventBus")
		if eb.augment_drag_started.is_connected(_on_augment_drag_started):
			eb.augment_drag_started.disconnect(_on_augment_drag_started)
		if eb.augment_drag_ended.is_connected(_on_augment_drag_ended):
			eb.augment_drag_ended.disconnect(_on_augment_drag_ended)

func _on_augment_drag_started(aug_res: Resource) -> void:
	if not is_fielded or unit_instance == null or not aug_res is AugmentResource:
		return
		
	var aug = aug_res as AugmentResource
	var has_compat = false
	var slot_types = unit_instance.unit_resource.get_slot_types()
	
	# Check compatibility across slots
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
	if not is_fielded or unit_instance == null:
		return false
	if not data is Dictionary:
		return false
	var dtype = data.get("type", "")
	if dtype != "augment" and dtype != "slotted_augment":
		return false
	var aug_res = data.get("resource", null) as AugmentResource
	if aug_res == null:
		return false
		
	# Check if any slot is compatible
	var slot_types = unit_instance.unit_resource.get_slot_types()
	for i in range(Constants.MAX_AUGMENT_SLOTS_PER_UNIT):
		var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
		if aug_res.slot_type == slot_type or aug_res.slot_type == Enums.SlotType.FLEX or slot_type == Enums.SlotType.FLEX:
			return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
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
			if btn and btn.get_rect().has_point(btn.get_local_mouse_position()):
				var slot_type = slot_types[i] if i < slot_types.size() else Enums.SlotType.PASSIVE
				if aug_res.slot_type == slot_type or aug_res.slot_type == Enums.SlotType.FLEX or slot_type == Enums.SlotType.FLEX:
					target_slot = i
					break
					
	if target_slot == -1:
		# Pick first empty compatible slot, or first compatible slot
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

func setup(unit: UnitInstance, fielded: bool = true) -> void:
	unit_instance = unit
	is_fielded = fielded
	_update_ui()

func _update_ui() -> void:
	if unit_instance == null or unit_instance.unit_resource == null:
		visible = false
		return
		
	visible = true
	tooltip_text = "Operative Profile"
	var res = unit_instance.unit_resource
	
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
		
	if ability_label:
		ability_label.text = res.ability_name
		
	if toggle_btn:
		toggle_btn.text = "BENCH" if is_fielded else "DEPLOY"
		
	if sell_btn:
		var sell_val = res.base_cost * (2 if unit_instance.star_level == 2 else (4 if unit_instance.star_level >= 3 else 1))
		sell_btn.text = "SELL (%s)" % Constants.format_currency(sell_val, true)
		
	if is_fielded:
		custom_minimum_size = Vector2(160, 155)
		if slots_header:
			slots_header.visible = true
		if slots_container:
			slots_container.visible = true
		_refresh_slots()
	else:
		custom_minimum_size = Vector2(140, 78)
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
		slot_btn.custom_minimum_size = Vector2(0, 24)
		slot_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_btn.add_theme_font_size_override("font_size", 9)
		
		if aug != null:
			slot_btn.text = " [%s] %s" % [aug.get_tier_name().substr(0, 1), aug.display_name]
			var tier_col = Color(aug.get_tier_color_hex())
			slot_btn.add_theme_color_override("font_color", tier_col)
			slot_btn.tooltip_text = "%s\nDrag to swap/move or right-click to unequip" % aug.description
		else:
			slot_btn.text = " + Slot %d [%s]" % [i + 1, _slot_type_name(slot_type)]
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
	
	func _get_drag_data(_pos: Vector2) -> Variant:
		if augment_res == null:
			return null
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
