class_name PrepScreen
extends Control

## Main Preparation Phase Screen uniting Field, Bench, Augment Inventory, Shop, and Synergies

const OperativeCardScene = preload("res://src/ui/components/OperativeCard.tscn")
const AugmentChipScene = preload("res://src/ui/components/AugmentChip.tscn")
const ShopSlotCardScene = preload("res://src/ui/components/ShopSlotCard.tscn")
const TacticalTetherOverlayScript = preload("res://src/ui/components/TacticalTetherOverlay.gd")
const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object = null
var run_mgr: RunManager = null
var shop_mgr: ShopManager = null
var crew_mgr: CrewManager = null


# Selection state for slotting
var selected_inventory_aug: AugmentResource = null
var selected_inventory_idx: int = -1

@onready var district_label: Label = $Margin/VBox/TopBar/DistrictLabel
@onready var crew_count_label: Label = $Margin/VBox/TopBar/CrewCountLabel
@onready var gold_label: Label = $Margin/VBox/TopBar/GoldLabel
@onready var lock_in_btn: Button = $Margin/VBox/TopBar/LockInBtn

@onready var field_container: VBoxContainer = $Margin/VBox/MainBody/BoardArea/FieldSection/FieldScroll/FieldContainer
@onready var bench_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/BenchSection/BenchScroll/BenchContainer
@onready var crew_shop_container: HBoxContainer = $Margin/VBox/MainBody/BoardArea/CrewShop/CrewShopScroll/CrewShopContainer
@onready var augment_shop_container: HBoxContainer = $Margin/VBox/MainBody/Sidebar/AugmentShop/AugmentShopScroll/AugmentShopContainer
@onready var freeze_btn: Button = $Margin/VBox/MainBody/BoardArea/CrewShop/CrewShopHeader/FreezeBtn
@onready var reroll_btn: Button = $Margin/VBox/MainBody/BoardArea/CrewShop/CrewShopHeader/RerollBtn
@onready var tier_odds_label: RichTextLabel = get_node_or_null("Margin/VBox/MainBody/BoardArea/CrewShop/CrewShopHeader/TierOddsLabel")

@onready var synergy_hud: SynergyTrackerHUD = $Margin/VBox/MainBody/Sidebar/SynergyTrackerHUD
@onready var overdrive_section: VBoxContainer = get_node_or_null("Margin/VBox/MainBody/Sidebar/OverdriveSection")
@onready var overdrive_btn: Button = get_node_or_null("Margin/VBox/MainBody/Sidebar/OverdriveSection/OverdriveBtn")
@onready var augment_tray: HBoxContainer = $Margin/VBox/MainBody/Sidebar/AugmentTray/AugmentScroll/AugmentContainer
@onready var status_label: Label = $Margin/VBox/StatusLabel

func _ready() -> void:
	if get_node_or_null("/root/GameManager") and get_node("/root/GameManager").active_run_manager:
		var gm = get_node("/root/GameManager")
		var rm = gm.active_run_manager
		run_mgr = rm
		repo = rm._repo if rm._repo else DataRepoScript.new()
		shop_mgr = rm.shop_mgr
		crew_mgr = rm.crew_mgr
	elif run_mgr:
		repo = run_mgr._repo if run_mgr._repo else DataRepoScript.new()
		shop_mgr = run_mgr.shop_mgr
		crew_mgr = run_mgr.crew_mgr
	else:
		repo = DataRepoScript.new()
		repo.load_all_data("res://data")
		shop_mgr = ShopManager.new(12)
		crew_mgr = CrewManager.new(1, repo)
		var starter_unit = repo.get_unit("runner_blitz")
		if starter_unit:
			crew_mgr.place_unit_on_grid(UnitInstance.new(starter_unit), 1)
		shop_mgr.generate_shop_offerings(1, repo)
		
	# Ensure shop is generated if empty
	if shop_mgr and shop_mgr.unit_slots.is_empty() and shop_mgr.augment_slots.is_empty():
		shop_mgr.generate_shop_offerings(crew_mgr.current_district, repo, Constants.DEFAULT_CREW_SHOP_SLOTS, Constants.DEFAULT_AUGMENT_SHOP_SLOTS, false, shop_mgr.active_district_res)

	if crew_mgr:
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
		if shop_mgr.active_district_res:
			district_label.text = "DISTRICT %d: %s" % [crew_mgr.current_district, shop_mgr.active_district_res.display_name.to_upper()]
			district_label.add_theme_color_override("font_color", shop_mgr.active_district_res.theme_color)
		else:
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

var tether_overlay: Control = null
var hovered_grid_card: OperativeCard = null

func _refresh_field_and_bench() -> void:
	if field_container:
		for c in field_container.get_children():
			c.queue_free()
			
		var formation_report = crew_mgr.calculate_formation_bonuses()
		
		# Overlay for holographic formation tethers
		if tether_overlay == null or not is_instance_valid(tether_overlay):
			tether_overlay = TacticalTetherOverlayScript.new()
			tether_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			field_container.get_parent().add_child(tether_overlay)
			
		tether_overlay.clear_tethers()

		
		# Grid Container: 2 Rows (Top Row = Backline slots [3, 4, 5], Bottom Row = Frontline slots [0, 1, 2])
		var grid_vbox = VBoxContainer.new()
		grid_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid_vbox.add_theme_constant_override("separation", 6)
		field_container.add_child(grid_vbox)
		
		# 1. TOP ROW (BACKLINE: Slots 3 [Left - D3], 4 [Center - D2], 5 [Right - D4])
		var top_header = Label.new()
		top_header.text = "▲ BACKLINE (Protected Row — Snipers & Hackers)"
		top_header.add_theme_font_size_override("font_size", 9)
		top_header.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
		grid_vbox.add_child(top_header)
		
		var top_row_hbox = HBoxContainer.new()
		top_row_hbox.add_theme_constant_override("separation", 8)
		grid_vbox.add_child(top_row_hbox)
		
		var top_slots = [3, 4, 5]
		for slot_idx in top_slots:
			_build_grid_slot_cell(top_row_hbox, slot_idx, formation_report)
			
		# 2. BOTTOM ROW (FRONTLINE: Slots 0 [Left], 1 [Center], 2 [Right] — Unlocked in D1)
		var bot_header = Label.new()
		bot_header.text = "▼ FRONTLINE (Aggro Absorption & Directional Shields)"
		bot_header.add_theme_font_size_override("font_size", 9)
		bot_header.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		grid_vbox.add_child(bot_header)
		
		var bot_row_hbox = HBoxContainer.new()
		bot_row_hbox.add_theme_constant_override("separation", 8)
		grid_vbox.add_child(bot_row_hbox)
		
		var bot_slots = [0, 1, 2]
		for slot_idx in bot_slots:
			_build_grid_slot_cell(bot_row_hbox, slot_idx, formation_report)
			
		# Schedule tether line calculation after UI layout pass
		call_deferred("_recalculate_formation_tethers")

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
			card.unit_dropped_on_card.connect(_on_unit_dropped_on_card)

func _build_grid_slot_cell(parent: HBoxContainer, slot_idx: int, formation_report: Dictionary) -> void:
	var is_unlocked = crew_mgr.is_slot_unlocked(slot_idx)
	var unlock_dist = crew_mgr.get_slot_unlock_district(slot_idx)
	var unit = crew_mgr.tactical_grid[slot_idx]
	
	if is_unlocked:
		if unit != null:
			var card: OperativeCard = OperativeCardScene.instantiate()
			parent.add_child(card)
			var tags = formation_report[unit].get("formation_tags", []) if formation_report.has(unit) else []
			card.setup(unit, true, tags)
			card.slot_clicked.connect(_on_unit_slot_clicked)
			card.slot_unequip_requested.connect(_on_unit_slot_unequip_requested)
			card.unit_toggle_field_requested.connect(_on_unit_toggle_field)
			card.unit_sell_requested.connect(_on_unit_sell)
			card.augment_dropped.connect(_on_augment_dropped_on_unit)
			card.unit_dropped_on_card.connect(_on_unit_dropped_on_card)
			card.mouse_entered.connect(func(): _on_grid_card_hovered(card, unit))
			card.mouse_exited.connect(func(): _on_grid_card_unhovered(card))
		else:
			# Empty unlocked tactical slot with drag/drop acceptance
			var btn = TacticalEmptySlot.new()
			btn.custom_minimum_size = Vector2(150, 112)
			btn.slot_idx = slot_idx
			btn.crew_mgr = crew_mgr
			btn.text = "+ DEPLOY\n[SLOT %d]\n(CLICK/DROP)" % (slot_idx + 1)
			btn.add_theme_font_size_override("font_size", 8)
			btn.add_theme_color_override("font_color", Color(0, 0.85, 0.75, 0.7))
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.04, 0.03, 0.08, 0.6)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(0, 0.85, 0.75, 0.4)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_right = 6
			style.corner_radius_bottom_left = 6
			btn.add_theme_stylebox_override("normal", style)
			btn.slot_clicked.connect(_on_empty_slot_clicked)
			btn.unit_dropped.connect(_on_unit_dropped_on_empty_slot)
			parent.add_child(btn)
	else:
		# Locked slot
		var panel = TacticalLockedSlot.new()
		panel.custom_minimum_size = Vector2(150, 112)
		panel.slot_idx = slot_idx
		panel.unlock_district = unlock_dist
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.03, 0.02, 0.05, 0.9)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.2, 0.4, 0.5)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		panel.add_theme_stylebox_override("panel", style)
		
		var lbl = Label.new()
		lbl.text = "🔒 LOCKED\n(DISTRICT %d)" % unlock_dist
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.4, 0.7, 0.6))
		panel.add_child(lbl)
		parent.add_child(panel)

func _on_unit_dropped_on_card(target_unit: UnitInstance, drag_data: Dictionary) -> void:
	var incoming_unit = drag_data.get("unit") as UnitInstance
	if incoming_unit == null or incoming_unit == target_unit:
		return
		
	var is_incoming_fielded = drag_data.get("is_fielded", false)
	var src_slot = drag_data.get("source_slot", -1)
	var tgt_slot = target_unit.grid_slot
	
	if is_incoming_fielded and src_slot >= 0 and tgt_slot >= 0:
		# Grid to Grid Swap
		crew_mgr.swap_grid_slots(src_slot, tgt_slot)
		_set_status("Swapped positions of %s and %s." % [incoming_unit.unit_resource.display_name, target_unit.unit_resource.display_name], false)
	else:
		# Bench to Field Swap
		var b_idx = crew_mgr.benched_units.find(incoming_unit)
		if b_idx != -1 and tgt_slot >= 0:
			crew_mgr.deploy_bench_to_grid(b_idx, tgt_slot)
			_set_status("Deployed %s to slot %d (swapped %s to bench)." % [
				incoming_unit.unit_resource.display_name, tgt_slot + 1, target_unit.unit_resource.display_name
			], false)
			
	_play_sfx("play_ui_click")
	_refresh_all()

func _on_unit_dropped_on_empty_slot(slot_idx: int, drag_data: Dictionary) -> void:
	var incoming_unit = drag_data.get("unit") as UnitInstance
	if incoming_unit == null:
		return
		
	var is_incoming_fielded = drag_data.get("is_fielded", false)
	if is_incoming_fielded:
		crew_mgr.place_unit_on_grid(incoming_unit, slot_idx)
		_set_status("Moved %s to Tactical Slot %d." % [incoming_unit.unit_resource.display_name, slot_idx + 1], false)
	else:
		var b_idx = crew_mgr.benched_units.find(incoming_unit)
		if b_idx != -1:
			if crew_mgr.fielded_units.size() >= crew_mgr.get_max_field_units() and crew_mgr.tactical_grid[slot_idx] == null:
				_set_status("Cannot deploy %s: District crew limit reached (%d/%d max fielded)." % [
					incoming_unit.unit_resource.display_name, crew_mgr.fielded_units.size(), crew_mgr.get_max_field_units()
				], true)
				_play_sfx("play_ui_error")
				return
			var deployed = crew_mgr.deploy_bench_to_grid(b_idx, slot_idx)
			if deployed:
				_set_status("Deployed %s to Tactical Slot %d." % [incoming_unit.unit_resource.display_name, slot_idx + 1], false)
			else:
				_set_status("Failed to deploy %s to slot %d." % [incoming_unit.unit_resource.display_name, slot_idx + 1], true)
			
	_play_sfx("play_ui_click")
	_refresh_all()

func _on_empty_slot_clicked(slot_idx: int) -> void:
	if not crew_mgr.benched_units.is_empty():
		if crew_mgr.fielded_units.size() >= crew_mgr.get_max_field_units() and crew_mgr.tactical_grid[slot_idx] == null:
			_set_status("Cannot deploy: District crew limit reached (%d/%d max fielded)." % [
				crew_mgr.fielded_units.size(), crew_mgr.get_max_field_units()
			], true)
			_play_sfx("play_ui_error")
			return
		var deployed = crew_mgr.deploy_bench_to_grid(0, slot_idx)
		if deployed:
			_set_status("Operative deployed to Tactical Slot %d." % (slot_idx + 1), false)
			_play_sfx("play_ui_click")
			_refresh_all()
	else:
		_set_status("No reserve operatives on bench to deploy.", true)

func _on_grid_card_hovered(card: OperativeCard, unit: UnitInstance) -> void:

	hovered_grid_card = card
	_recalculate_formation_tethers(unit)

func _on_grid_card_unhovered(card: OperativeCard) -> void:
	if hovered_grid_card == card:
		hovered_grid_card = null
		_recalculate_formation_tethers()

func _recalculate_formation_tethers(focused_unit: UnitInstance = null) -> void:
	if tether_overlay == null or not is_instance_valid(tether_overlay):
		return
		
	tether_overlay.clear_tethers()
	var card_map: Dictionary = {}
	
	# Find all card centers in field_container
	if field_container:
		for card in _get_all_operative_cards(field_container):
			if card.unit_instance != null:
				card_map[card.unit_instance] = (card.global_position + card.size * 0.5) - tether_overlay.global_position
				
	for slot_idx in range(6):
		var unit = crew_mgr.tactical_grid[slot_idx]
		if unit == null or not card_map.has(unit):
			continue
			
		if focused_unit != null and focused_unit != unit:
			# If a specific unit is hovered, only draw links directly involving that unit
			continue
			
		var u_pos = card_map[unit]
		var coords = UnitInstance.slot_to_coords(slot_idx)
		var row = coords.x
		var col = coords.y
		var role = unit.unit_resource.role if unit.unit_resource else Enums.UnitRole.TANK
		
		# 1. Tank Lateral Shield Tethers (Electric Blue)
		if role == Enums.UnitRole.TANK:
			var left_u = crew_mgr.get_unit_at_coords(row, col - 1)
			var right_u = crew_mgr.get_unit_at_coords(row, col + 1)
			if left_u and card_map.has(left_u):
				tether_overlay.add_tether(u_pos, card_map[left_u], TacticalTetherOverlayScript.COLOR_TANK_GUARD, "Guard")
			if right_u and card_map.has(right_u):
				tether_overlay.add_tether(u_pos, card_map[right_u], TacticalTetherOverlayScript.COLOR_TANK_GUARD, "Guard")
				
		# 2. Hacker Row Uplink Tethers (Cyan)
		if role == Enums.UnitRole.HACKER:
			var row_units = crew_mgr.get_adjacent_units(row, col, Enums.GridDirection.SAME_ROW)
			for r_u in row_units:
				if card_map.has(r_u):
					tether_overlay.add_tether(u_pos, card_map[r_u], TacticalTetherOverlayScript.COLOR_HACKER_UPLINK, "Uplink")
					
		# 3. Fixer Adjacent Bio-Links (Emerald)
		if role == Enums.UnitRole.FIXER:
			var adj_units = crew_mgr.get_adjacent_units(row, col, Enums.GridDirection.ADJACENT)
			for a_u in adj_units:
				if card_map.has(a_u):
					tether_overlay.add_tether(u_pos, card_map[a_u], TacticalTetherOverlayScript.COLOR_FIXER_LINK, "Bio-Link")
					
		# 4. Operative & Augment Directional Modifiers
		var u_res = unit.unit_resource
		if u_res and u_res.directional_target != Enums.GridDirection.NONE:
			var targets = crew_mgr.get_adjacent_units(row, col, u_res.directional_target)
			for t_u in targets:
				if card_map.has(t_u):
					tether_overlay.add_tether(u_pos, card_map[t_u], TacticalTetherOverlayScript.COLOR_GENERIC_LINK, u_res.display_name)
					
		for aug in unit.equipped_augments:
			if aug and aug.directional_target != Enums.GridDirection.NONE:
				var targets = crew_mgr.get_adjacent_units(row, col, aug.directional_target)
				for t_u in targets:
					if card_map.has(t_u):
						tether_overlay.add_tether(u_pos, card_map[t_u], TacticalTetherOverlayScript.COLOR_GENERIC_LINK, aug.display_name)


func _get_all_operative_cards(node: Node) -> Array[OperativeCard]:
	var result: Array[OperativeCard] = []
	for c in node.get_children():
		if c is OperativeCard:
			result.append(c)
		else:
			result.append_array(_get_all_operative_cards(c))
	return result

class TacticalEmptySlot extends Button:
	var slot_idx: int = 0
	var crew_mgr: Object = null
	signal slot_clicked(slot: int)
	signal unit_dropped(slot: int, data: Dictionary)
	
	func _ready() -> void:
		pressed.connect(func(): slot_clicked.emit(slot_idx))
		
	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		if not data is Dictionary:
			return false
		if data.get("type") != "unit":
			return false
		var incoming_unit = data.get("unit") as UnitInstance
		if incoming_unit == null:
			return false
		if crew_mgr != null:
			if not crew_mgr.is_slot_unlocked(slot_idx):
				return false
			var is_fielded = data.get("is_fielded", false)
			if not is_fielded and crew_mgr.fielded_units.size() >= crew_mgr.get_max_field_units():
				return false
		return true
		
	func _drop_data(_pos: Vector2, data: Variant) -> void:
		if _can_drop_data(_pos, data):
			unit_dropped.emit(slot_idx, data)

class TacticalLockedSlot extends PanelContainer:
	var slot_idx: int = 0
	var unlock_district: int = 2
	
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		
	func _can_drop_data(_pos: Vector2, _data: Variant) -> bool:
		return false
		
	func _drop_data(_pos: Vector2, _data: Variant) -> void:
		pass



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
		
	if freeze_btn:
		if shop_mgr.is_locked:
			freeze_btn.text = "🔓 UNFREEZE"
			freeze_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.85))
		else:
			freeze_btn.text = "🔒 FREEZE (FREE)"
			freeze_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
			
	if reroll_btn:
		var cost = shop_mgr.get_reroll_cost()
		reroll_btn.text = "REROLL (%s)" % Constants.format_currency(cost, true)
		reroll_btn.disabled = (shop_mgr.gold < cost)
		
	if tier_odds_label and shop_mgr:
		var odds = shop_mgr.get_current_unit_tier_odds()
		var t1 = int(odds.get(1, 0.0) * 100)
		var t2 = int(odds.get(2, 0.0) * 100)
		var t3 = int(odds.get(3, 0.0) * 100)
		tier_odds_label.text = "[font_size=8][color=#9999aa]T1:[/color]%d%% [color=#00f5d4]T2:[/color]%d%% [color=#ffd166]T3:[/color]%d%%[/font_size]" % [t1, t2, t3]
		
	if overdrive_section:
		overdrive_section.visible = (crew_mgr != null and crew_mgr.current_district >= 3)
	if overdrive_btn and shop_mgr:
		var cost = shop_mgr.get_overdrive_cost()
		overdrive_btn.text = "⚡ OVERDRIVE (%s)" % Constants.format_currency(cost, true)
		overdrive_btn.disabled = (shop_mgr.gold < cost)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_on_freeze_pressed()
		elif event.keycode == KEY_D:
			_on_reroll_pressed()

func _on_freeze_pressed() -> void:
	var locked = shop_mgr.toggle_lock()
	if locked:
		_set_status("Shop FROZEN 🔒 — Current offerings will be saved across rounds.", false)
	else:
		_set_status("Shop UNLOCKED 🔓 — Offerings will auto-refresh on next round.", false)
	_play_sfx("play_ui_click")
	_refresh_shop()

func _refresh_synergies() -> void:
	if synergy_hud:
		synergy_hud.update_synergies(crew_mgr.active_synergy_report)

func _on_crew_buy_requested(slot_index: int) -> void:
	var result = shop_mgr.buy_unit_slot(slot_index, crew_mgr)
	if result.success:
		var u_name = "unit"
		if result.item:
			if result.item is UnitInstance and result.item.unit_resource:
				u_name = result.item.unit_resource.display_name
			elif "display_name" in result.item:
				u_name = result.item.display_name
		_set_status("Recruited %s to crew." % u_name, false)
		crew_mgr.recalculate_synergies()
		
		# Check for star upgrades
		if not crew_mgr.last_combinations.is_empty():
			var last_comb = crew_mgr.last_combinations.back()
			_show_star_upgrade_banner(last_comb.unit_name, last_comb.new_star_level)
			_play_sfx("play_star_upgrade")
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

func _on_overdrive_pressed() -> void:
	if shop_mgr == null or crew_mgr == null:
		return
		
	var cost = shop_mgr.get_overdrive_cost()
	if shop_mgr.gold < cost:
		_set_status("Overdrive synthesis requires %s credits (Have %s)." % [cost, shop_mgr.gold], true)
		_play_sfx("play_error")
		return
		
	# Find an upgradeable augment across fielded units first, then benched units
	var target_unit: UnitInstance = null
	var target_slot: int = -1
	for u in crew_mgr.fielded_units:
		for s in range(u.equipped_augments.size()):
			if shop_mgr.can_overdrive_augment(u, s):
				target_unit = u
				target_slot = s
				break
		if target_unit != null:
			break
			
	if target_unit == null:
		for u in crew_mgr.benched_units:
			for s in range(u.equipped_augments.size()):
				if shop_mgr.can_overdrive_augment(u, s):
					target_unit = u
					target_slot = s
					break
			if target_unit != null:
				break
				
	if target_unit == null:
		_set_status("No upgradeable equipped augments on crew (Common or Rare required).", true)
		_play_sfx("play_error")
		return
		
	var prev_name = target_unit.equipped_augments[target_slot].display_name
	var upgraded_aug = shop_mgr.overdrive_augment(target_unit, target_slot, repo)
	if upgraded_aug != null:
		_set_status("⚡ OVERDRIVE SYNTHESIS: %s on %s upgraded to %s (%s)!" % [
			prev_name,
			target_unit.display_name,
			upgraded_aug.display_name,
			Enums.tier_to_string(upgraded_aug.tier).to_upper()
		], false)
		_show_overdrive_upgrade_banner(upgraded_aug.display_name, target_unit.display_name, upgraded_aug.tier)
		_play_sfx("play_star_upgrade")
		crew_mgr.recalculate_synergies()
		_refresh_all()
	else:
		_set_status("Overdrive synthesis failed.", true)
		_play_sfx("play_error")

func _show_overdrive_upgrade_banner(aug_name: String, unit_name: String, tier: Enums.AugmentTier) -> void:
	var banner = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.04, 0.22, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.9, 0.2, 1.0) if tier == Enums.AugmentTier.RARE else Color(1.0, 0.85, 0.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	banner.add_theme_stylebox_override("panel", style)
	
	var tier_str = "RARE" if tier == Enums.AugmentTier.RARE else "LEGENDARY"
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(margin)
	
	var lbl = Label.new()
	lbl.text = "⚡ OVERDRIVE SYNTHESIS! %s UPGRADED TO %s (%s) ⚡" % [unit_name.to_upper(), aug_name.to_upper(), tier_str]
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	margin.add_child(lbl)
	
	var vp_size = get_viewport_rect().size
	banner.position = Vector2((vp_size.x - 420) / 2.0, vp_size.y * 0.30)
	banner.scale = Vector2(0.8, 0.8)
	add_child(banner)
	
	var tween = create_tween()
	tween.tween_property(banner, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.4)
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
				_play_sfx("play_ui_click")
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
				_play_sfx("play_ui_click")
			else:
				# Transfer between operatives
				if crew_mgr.unequip_augment_from_unit(src_unit, src_slot):
					var new_inv_idx = crew_mgr.augment_inventory.size() - 1
					if crew_mgr.equip_augment_to_unit(unit, target_slot, new_inv_idx):
						_set_status("Transferred [%s] to %s." % [src_aug.display_name, unit.unit_resource.display_name], false)
						_play_sfx("play_ui_click")
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

func _on_abandon_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").abandon_run()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var dtype = data.get("type", "")
	return dtype == "slotted_augment" or dtype == "unit" or dtype == "augment"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	var dtype = data.get("type", "")
	if dtype == "slotted_augment":
		var src_unit = data.get("source_unit", null) as UnitInstance
		var src_slot = data.get("source_slot", -1) as int
		if src_unit != null and src_slot >= 0:
			var unequipped_aug = src_unit.equipped_augments[src_slot]
			if crew_mgr.unequip_augment_from_unit(src_unit, src_slot):
				_set_status("Unequipped [%s] back to inventory." % (unequipped_aug.display_name if unequipped_aug else ""), false)
				_play_sfx("play_ui_click")
				_refresh_all()
			else:
				_set_status("Cannot unequip: Inventory is full (Max %d)." % Constants.MAX_INVENTORY_AUGMENTS, true)
	elif dtype == "unit":
		var dragged_u = data.get("unit") as UnitInstance
		if dragged_u:
			_set_status("Cannot deploy %s to locked slot or invalid area." % dragged_u.unit_resource.display_name, true)
		_play_sfx("play_ui_error")
		_refresh_all()
	elif dtype == "augment":
		_set_status("Augment returned to inventory.", false)
		_refresh_all()

func _play_sfx(method_name: String) -> void:
	if get_node_or_null("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method(method_name):
			am.call(method_name)

func _set_status(msg: String, is_error: bool = false) -> void:
	if status_label:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if is_error else Color(0, 0.95, 0.83))
