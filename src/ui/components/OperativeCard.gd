class_name OperativeCard
extends PanelContainer

## Interactive UI Card for fielded or benched operatives with 3 augment slots

signal card_clicked(unit: UnitInstance)
signal slot_clicked(unit: UnitInstance, slot_index: int)
signal slot_unequip_requested(unit: UnitInstance, slot_index: int)
signal unit_toggle_field_requested(unit: UnitInstance)
signal unit_sell_requested(unit: UnitInstance)

var unit_instance: UnitInstance = null
var is_fielded: bool = true

@onready var name_label: Label = $Margin/VBox/Header/NameLabel
@onready var role_badge: Label = $Margin/VBox/Header/RoleBadge
@onready var faction_badge: Label = $Margin/VBox/Header/FactionBadge
@onready var stats_label: Label = $Margin/VBox/StatsLabel
@onready var ability_label: Label = $Margin/VBox/AbilityLabel
@onready var slots_header: Label = $Margin/VBox/SlotsHeader
@onready var slots_container: VBoxContainer = $Margin/VBox/SlotsContainer
@onready var toggle_btn: Button = $Margin/VBox/Actions/ToggleFieldBtn
@onready var sell_btn: Button = $Margin/VBox/Actions/SellBtn

func setup(unit: UnitInstance, fielded: bool = true) -> void:
	unit_instance = unit
	is_fielded = fielded
	_update_ui()

func _update_ui() -> void:
	if unit_instance == null or unit_instance.unit_resource == null:
		visible = false
		return
		
	visible = true
	var res = unit_instance.unit_resource
	
	if name_label:
		name_label.text = res.display_name
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
		sell_btn.text = "SELL (%dg)" % res.base_cost
		
	if is_fielded:
		custom_minimum_size = Vector2(185, 205)
		if slots_header:
			slots_header.visible = true
		if slots_container:
			slots_container.visible = true
		_refresh_slots()
	else:
		custom_minimum_size = Vector2(175, 95)
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
		
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(0, 24)
		slot_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_btn.add_theme_font_size_override("font_size", 9)
		
		if aug != null:
			slot_btn.text = " [%s] %s" % [aug.get_tier_name().substr(0, 1), aug.display_name]
			var tier_col = Color(aug.get_tier_color_hex())
			slot_btn.add_theme_color_override("font_color", tier_col)
			slot_btn.tooltip_text = "%s\nRight-click to unequip" % aug.description
		else:
			slot_btn.text = " + Slot %d [%s]" % [i + 1, _slot_type_name(slot_type)]
			slot_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
			slot_btn.tooltip_text = "Empty %s slot. Click with augment selected to equip." % _slot_type_name(slot_type)
			
		var slot_idx = i
		slot_btn.pressed.connect(func(): slot_clicked.emit(unit_instance, slot_idx))
		slot_btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
				slot_unequip_requested.emit(unit_instance, slot_idx)
		)
		
		slots_container.add_child(slot_btn)

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
