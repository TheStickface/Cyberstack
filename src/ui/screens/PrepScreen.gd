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
@onready var bench_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/BenchAndTray/BenchSection/BenchScroll/BenchContainer
@onready var augment_tray: HBoxContainer = $Margin/VBox/MainBody/BoardArea/BenchAndTray/AugmentTray/AugmentScroll/AugmentContainer
@onready var shop_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/ShopSection/ShopScroll/ShopContainer
@onready var reroll_btn: Button = $Margin/VBox/MainBody/BoardArea/ShopSection/ShopControls/RerollBtn

@onready var synergy_hud: SynergyTrackerHUD = $Margin/VBox/MainBody/Sidebar/SynergyTrackerHUD
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
		crew_count_label.text = "CREW: %d / %d" % [crew_mgr.fielded_units.size(), crew_mgr.get_max_field_units()]
	if gold_label:
		gold_label.text = "CREDITS: %d" % shop_mgr.gold

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
	if not shop_container:
		return
		
	for c in shop_container.get_children():
		c.queue_free()
		
	for i in range(shop_mgr.shop_slots.size()):
		var slot_data = shop_mgr.shop_slots[i]
		var card: ShopSlotCard = ShopSlotCardScene.instantiate()
		shop_container.add_child(card)
		card.setup(i, slot_data, shop_mgr.gold)
		card.buy_requested.connect(_on_shop_buy_requested)
		
	if reroll_btn:
		reroll_btn.text = "REROLL (%dg)" % Constants.BASE_REROLL_COST
		reroll_btn.disabled = (shop_mgr.gold < Constants.BASE_REROLL_COST)

func _refresh_synergies() -> void:
	if synergy_hud:
		synergy_hud.update_synergies(crew_mgr.active_synergy_report)

# Event Handlers
func _on_shop_buy_requested(slot_index: int) -> void:
	var result = shop_mgr.buy_slot(slot_index, crew_mgr)
	if result.success:
		_set_status("Purchased %s." % result.type, false)
		crew_mgr.recalculate_synergies()
	else:
		_set_status("Purchase failed: %s" % result.error, true)
	_refresh_all()

func _on_reroll_pressed() -> void:
	if shop_mgr.reroll_shop(repo):
		_set_status("Shop refreshed.", false)
	else:
		_set_status("Not enough gold to reroll.", true)
	_refresh_all()

func _on_augment_chip_clicked(aug: AugmentResource, inv_idx: int) -> void:
	if selected_inventory_idx == inv_idx:
		selected_inventory_aug = null
		selected_inventory_idx = -1
		_set_status("Augment deselected.", false)
	else:
		selected_inventory_aug = aug
		selected_inventory_idx = inv_idx
		_set_status("Selected '%s'. Click a unit slot to equip." % aug.display_name, false)
	_refresh_augment_tray()

func _on_unit_slot_clicked(unit: UnitInstance, slot_idx: int) -> void:
	if selected_inventory_aug != null and selected_inventory_idx >= 0:
		var success = crew_mgr.equip_augment_from_inventory(unit, slot_idx, selected_inventory_idx)
		if success:
			_set_status("Equipped '%s' to slot %d." % [selected_inventory_aug.display_name, slot_idx + 1], false)
			selected_inventory_aug = null
			selected_inventory_idx = -1
		else:
			_set_status("Cannot equip '%s' in slot %d (Invalid slot type)." % [selected_inventory_aug.display_name, slot_idx + 1], true)
		_refresh_all()

func _on_unit_slot_unequip_requested(unit: UnitInstance, slot_idx: int) -> void:
	var success = crew_mgr.unequip_augment_to_inventory(unit, slot_idx)
	if success:
		_set_status("Unequipped augment from slot %d." % (slot_idx + 1), false)
	else:
		_set_status("Failed to unequip augment (Inventory may be full).", true)
	_refresh_all()

func _on_unit_toggle_field(unit: UnitInstance) -> void:
	var f_idx = crew_mgr.fielded_units.find(unit)
	if f_idx != -1:
		crew_mgr.recall_unit_to_bench(f_idx)
		_set_status("Recalled %s to bench." % unit.unit_resource.display_name, false)
	else:
		var b_idx = crew_mgr.benched_units.find(unit)
		if b_idx != -1:
			var success = crew_mgr.deploy_unit_to_field(b_idx)
			if success:
				_set_status("Deployed %s to field." % unit.unit_resource.display_name, false)
			else:
				_set_status("Field is full for District %d." % crew_mgr.current_district, true)
	_refresh_all()

func _on_unit_sell(unit: UnitInstance) -> void:
	var refund = shop_mgr.sell_unit(unit, crew_mgr)
	_set_status("Sold %s for +%dg." % [unit.unit_resource.display_name, refund], false)
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

func _set_status(msg: String, is_error: bool = false) -> void:
	if status_label:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if is_error else Color(0, 0.95, 0.83))
