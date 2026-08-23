class_name PrepScreen
extends Control

## Main Preparation Phase Screen uniting Field, Bench, Augment Inventory, Shop, and Synergies

const OperativeCardScene = preload("res://src/ui/components/OperativeCard.tscn")
const AugmentChipScene = preload("res://src/ui/components/AugmentChip.tscn")
const ShopSlotCardScene = preload("res://src/ui/components/ShopSlotCard.tscn")
const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object = null
var shop_mgr: ShopManager = null
var crew_mgr: CrewManager = null

# Selection state for slotting
var selected_inventory_aug: AugmentResource = null
var selected_inventory_idx: int = -1

@onready var district_label: Label = $Margin/VBox/TopBar/DistrictLabel
@onready var crew_count_label: Label = $Margin/VBox/TopBar/CrewCountLabel
@onready var gold_label: Label = $Margin/VBox/TopBar/GoldLabel
@onready var lock_in_btn: Button = $Margin/VBox/TopBar/LockInBtn

@onready var field_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/FieldSection/FieldScroll/FieldContainer
@onready var bench_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/BenchSection/BenchScroll/BenchContainer
@onready var crew_shop_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/CrewShop/CrewShopScroll/CrewShopContainer
@onready var augment_shop_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/AugmentShop/AugmentShopScroll/AugmentShopContainer
@onready var reroll_btn: Button = $Margin/VBox/MainBody/BoardArea/CrewShop/CrewShopHeader/RerollBtn

@onready var synergy_hud: SynergyTrackerHUD = $Margin/VBox/MainBody/Sidebar/SynergyTrackerHUD
@onready var augment_tray: HBoxContainer = $Margin/VBox/MainBody/Sidebar/AugmentTray/AugmentScroll/AugmentContainer
@onready var status_label: Label = $Margin/VBox/StatusLabel

func _ready() -> void:
	if get_node_or_null("/root/GameManager") and get_node("/root/GameManager").active_run_manager:
		var gm = get_node("/root/GameManager")
		var rm = gm.active_run_manager
		repo = rm._repo if rm._repo else DataRepoScript.new()
		shop_mgr = rm.shop_mgr
		crew_mgr = rm.crew_mgr
	else:
		repo = DataRepoScript.new()
		repo.load_all_data("res://data")
		shop_mgr = ShopManager.new(12)
		crew_mgr = CrewManager.new(1, repo)
		var starter_unit = repo.get_unit("runner_blitz")
		if starter_unit:
			crew_mgr.fielded_units.append(UnitInstance.new(starter_unit))
		shop_mgr.generate_shop_offerings(1, repo)
		
	crew_mgr.recalculate_synergies()
	_refresh_all()

func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_field_and_bench()
	_refresh_augment_tray()
	_refresh_shop()
	_refresh_synergies()

func _refresh_top_bar() -> void:
	if district_label:
		district_label.text = "DISTRICT %d" % crew_mgr.current_district
	if crew_count_label:
		var max_units = crew_mgr.get_max_field_units()
		var cur_units = crew_mgr.fielded_units.size()
		if cur_units >= max_units:
			crew_count_label.text = "CREW: %d / %d (DISTRICT MAX)" % [cur_units, max_units]
			crew_count_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
		else:
			crew_count_label.text = "CREW: %d / %d" % [cur_units, max_units]
			crew_count_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
	if gold_label:
		gold_label.text = "%s: %d" % [Constants.CURRENCY_NAME.to_upper(), shop_mgr.gold]

func _refresh_field_and_bench() -> void:
	if field_container:
		for c in field_container.get_children():
			c.queue_free()
		for unit in crew_mgr.fielded_units:
			var card: OperativeCard = OperativeCardScene.instantiate()
			field_container.add_child(card)
			card.setup(unit, true)
			card.slot_clicked.connect(_on_unit_slot_clicked)
			card.slot_unequip_requested.connect(_on_unit_slot_unequip_requested)
			card.unit_toggle_field_requested.connect(_on_unit_toggle_field)
			card.unit_sell_requested.connect(_on_unit_sell)
			card.augment_dropped.connect(_on_augment_dropped_on_unit)

	if bench_container:
		for c in bench_container.get_children():
			c.queue_free()
		for unit in crew_mgr.benched_units:
			var card: OperativeCard = OperativeCardScene.instantiate()
			bench_container.add_child(card)
			card.setup(unit, false)
			card.slot_clicked.connect(_on_unit_slot_clicked)
			card.slot_unequip_requested.connect(_on_unit_slot_unequip_requested)
			card.unit_toggle_field_requested.connect(_on_unit_toggle_field)
			card.unit_sell_requested.connect(_on_unit_sell)
			card.augment_dropped.connect(_on_augment_dropped_on_unit)

func _refresh_augment_tray() -> void:
	if not augment_tray:
		return
		
	for c in augment_tray.get_children():
		c.queue_free()
		
	for i in range(crew_mgr.augment_inventory.size()):
		var aug = crew_mgr.augment_inventory[i]
		var chip: AugmentChip = AugmentChipScene.instantiate()
		augment_tray.add_child(chip)
		chip.setup(aug, i)
		chip.set_selected(selected_inventory_idx == i)
		chip.chip_clicked.connect(_on_augment_chip_clicked)

func _refresh_shop() -> void:
	# 1. Operative Recruitment Shelf (Pure Units)
	if crew_shop_container:
		for c in crew_shop_container.get_children():
			c.queue_free()
		for i in range(shop_mgr.unit_slots.size()):
			var slot_data = shop_mgr.unit_slots[i]
			var card: ShopSlotCard = ShopSlotCardScene.instantiate()
			crew_shop_container.add_child(card)
			card.setup(i, slot_data, shop_mgr.gold)
			card.buy_requested.connect(_on_crew_buy_requested)
			
	# 2. Black Market Armory Shelf (Pure Augments)
	if augment_shop_container:
		for c in augment_shop_container.get_children():
			c.queue_free()
		for i in range(shop_mgr.augment_slots.size()):
			var slot_data = shop_mgr.augment_slots[i]
			var card: ShopSlotCard = ShopSlotCardScene.instantiate()
			augment_shop_container.add_child(card)
			card.setup(i, slot_data, shop_mgr.gold)
			card.buy_requested.connect(_on_augment_buy_requested)
		
	if reroll_btn:
		reroll_btn.text = "REROLL (%s)" % Constants.format_currency(Constants.BASE_REROLL_COST, true)
		reroll_btn.disabled = (shop_mgr.gold < Constants.BASE_REROLL_COST)

func _refresh_synergies() -> void:
	if synergy_hud:
		synergy_hud.update_synergies(crew_mgr.active_synergy_report)

func _on_crew_buy_requested(slot_index: int) -> void:
	var result = shop_mgr.buy_unit_slot(slot_index, crew_mgr)
	if result.success:
		_set_status("Recruited %s to crew." % (result.item.display_name if result.item else "unit"), false)
		crew_mgr.recalculate_synergies()
		
		# Check for star upgrades
		if not crew_mgr.last_combinations.is_empty():
			var last_comb = crew_mgr.last_combinations.back()
			_show_star_upgrade_banner(last_comb.unit_name, last_comb.new_star_level)
			AudioManager.play_star_upgrade()
	else:
		_set_status("Recruitment failed: %s" % result.error, true)
	_refresh_all()

func _show_star_upgrade_banner(u_name: String, star_lvl: int) -> void:
	var banner = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.85, 0.0) if star_lvl == 2 else Color(1.0, 0.2, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	banner.add_theme_stylebox_override("panel", style)
	
	var star_str = "★★ (TIER 2)" if star_lvl == 2 else "★★★ (TIER 3)"
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(margin)
	
	var lbl = Label.new()
	lbl.text = "★ LEVEL UP! %s UPGRADED TO %s ★" % [u_name.to_upper(), star_str]
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0) if star_lvl == 2 else Color(1.0, 0.2, 0.6))
	margin.add_child(lbl)
	
	var vp_size = get_viewport_rect().size
	banner.position = Vector2((vp_size.x - 360) / 2.0, vp_size.y * 0.35)
	banner.scale = Vector2(0.8, 0.8)
	add_child(banner)
	
	var tween = create_tween()
	tween.tween_property(banner, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.2)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(banner.queue_free)

func _on_augment_buy_requested(slot_index: int) -> void:
	var result = shop_mgr.buy_augment_slot(slot_index, crew_mgr)
	if result.success:
		_set_status("Purchased %s augment chip." % (result.item.display_name if result.item else ""), false)
		crew_mgr.recalculate_synergies()
	else:
		_set_status("Armory purchase failed: %s" % result.error, true)
	_refresh_all()

func _on_shop_buy_requested(slot_index: int) -> void:
	var result = shop_mgr.buy_slot(slot_index, crew_mgr)
	if result.success:
		_set_status("Purchased item.", false)
		crew_mgr.recalculate_synergies()
	else:
		_set_status("Purchase failed: %s" % result.error, true)
	_refresh_all()

func _on_reroll_pressed() -> void:
	if shop_mgr.reroll_shop(repo):
		_set_status("Shop refreshed.", false)
	else:
		_set_status("Not enough %s to reroll." % Constants.CURRENCY_NAME.to_lower(), true)
	_refresh_all()

func _on_augment_chip_clicked(aug: AugmentResource, inv_idx: int) -> void:
	if selected_inventory_idx == inv_idx:
		selected_inventory_aug = null
		selected_inventory_idx = -1
		_set_status("Deselected augment.", false)
	else:
		selected_inventory_aug = aug
		selected_inventory_idx = inv_idx
		_set_status("Selected [%s]. Click a compatible unit slot to equip." % aug.display_name, false)
	_refresh_augment_tray()

func _on_unit_slot_clicked(unit: UnitInstance, slot_idx: int) -> void:
	if selected_inventory_aug == null or selected_inventory_idx < 0:
		var slotted = unit.slotted_augments[slot_idx]
		if slotted:
			_set_status("Slot %d contains [%s]. Right-click to unequip." % [slot_idx + 1, slotted.display_name], false)
		else:
			var slot_t = unit.unit_resource.slot_layout[slot_idx]
			_set_status("Slot %d is empty (%s). Select an augment first." % [
				slot_idx + 1, 
				Enums.slot_type_to_string(slot_t)
			], false)
		return
		
	# Attempt to equip
	var success = crew_mgr.equip_augment_to_unit(unit, slot_idx, selected_inventory_idx)
	if success:
		_set_status("Equipped [%s] to %s." % [selected_inventory_aug.display_name, unit.unit_resource.display_name], false)
		selected_inventory_aug = null
		selected_inventory_idx = -1
		_refresh_all()
	else:
		_set_status("Incompatible slot! Check augment tags and slot type.", true)

func _on_augment_dropped_on_unit(unit: UnitInstance, target_slot: int, drag_data: Dictionary) -> void:
	var dtype = drag_data.get("type", "")
	if dtype == "augment":
		var inv_idx = drag_data.get("inventory_index", -1)
		if inv_idx >= 0 and inv_idx < crew_mgr.augment_inventory.size():
			var aug_res = crew_mgr.augment_inventory[inv_idx]
			var success = crew_mgr.equip_augment_to_unit(unit, target_slot, inv_idx)
			if success:
				_set_status("Equipped [%s] to %s." % [aug_res.display_name, unit.unit_resource.display_name], false)
				AudioManager.play_ui_click()
			else:
				_set_status("Incompatible slot! Check tags & slot requirements.", true)
	elif dtype == "slotted_augment":
		var src_unit = drag_data.get("source_unit", null) as UnitInstance
		var src_slot = drag_data.get("source_slot", -1) as int
		if src_unit != null and src_slot >= 0 and src_slot < src_unit.slotted_augments.size():
			var src_aug = src_unit.slotted_augments[src_slot]
			if src_unit == unit:
				# Move within same unit
				var target_aug = unit.slotted_augments[target_slot]
				unit.slotted_augments[target_slot] = src_aug
				unit.slotted_augments[src_slot] = target_aug
				crew_mgr.recalculate_synergies()
				_set_status("Moved [%s] to slot %d." % [src_aug.display_name, target_slot + 1], false)
				AudioManager.play_ui_click()
			else:
				# Transfer between operatives
				if crew_mgr.unequip_augment_from_unit(src_unit, src_slot):
					var new_inv_idx = crew_mgr.augment_inventory.size() - 1
					if crew_mgr.equip_augment_to_unit(unit, target_slot, new_inv_idx):
						_set_status("Transferred [%s] to %s." % [src_aug.display_name, unit.unit_resource.display_name], false)
						AudioManager.play_ui_click()
					else:
						_set_status("Incompatible slot on target operative.", true)
	_refresh_all()

func _on_unit_slot_unequip_requested(unit: UnitInstance, slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= unit.slotted_augments.size() or unit.slotted_augments[slot_idx] == null:
		return
		
	var unequipped_aug = unit.slotted_augments[slot_idx]
	if crew_mgr.unequip_augment_from_unit(unit, slot_idx):
		_set_status("Unequipped [%s] back to inventory." % unequipped_aug.display_name, false)
		_refresh_all()
	else:
		_set_status("Cannot unequip: Inventory is full (Max %d)." % Constants.MAX_INVENTORY_AUGMENTS, true)

func _on_unit_toggle_field(unit: UnitInstance) -> void:
	if crew_mgr.fielded_units.has(unit):
		crew_mgr.bench_unit(unit)
		_set_status("Recalled %s to bench." % unit.unit_resource.display_name, false)
	else:
		if crew_mgr.fielded_units.size() < crew_mgr.get_max_field_units():
			crew_mgr.field_unit(unit)
			_set_status("Deployed %s to field." % unit.unit_resource.display_name, false)
		else:
			_set_status("Field limit reached (%d/%d for District %d)." % [
					crew_mgr.fielded_units.size(),
					crew_mgr.get_max_field_units(),
					crew_mgr.current_district
				], true)
	_refresh_all()

func _on_unit_sell(unit: UnitInstance) -> void:
	var refund = shop_mgr.sell_unit(unit, crew_mgr)
	_set_status("Sold %s for +%s." % [unit.unit_resource.display_name, Constants.format_currency(refund)], false)
	_refresh_all()

func _on_lock_in_pressed() -> void:
	var result = crew_mgr.lock_in_crew()
	if result.valid:
		_set_status("CREW LOCKED! Deploying to District Map...", false)
		if get_node_or_null("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			if gm.active_run_manager:
				SaveManager.save_active_run(gm.active_run_manager)
			gm.open_map()
	else:
		var err_msg = ", ".join(result.errors)
		_set_status("Lock-in failed: %s" % err_msg, true)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	return data.get("type", "") == "slotted_augment"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var src_unit = data.get("source_unit", null) as UnitInstance
	var src_slot = data.get("source_slot", -1) as int
	if src_unit != null and src_slot >= 0:
		var unequipped_aug = src_unit.slotted_augments[src_slot]
		if crew_mgr.unequip_augment_from_unit(src_unit, src_slot):
			_set_status("Unequipped [%s] back to inventory." % (unequipped_aug.display_name if unequipped_aug else ""), false)
			AudioManager.play_ui_click()
			_refresh_all()
		else:
			_set_status("Cannot unequip: Inventory is full (Max %d)." % Constants.MAX_INVENTORY_AUGMENTS, true)

func _set_status(msg: String, is_error: bool = false) -> void:
	if status_label:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if is_error else Color(0, 0.95, 0.83))
