class_name TestUIDimensions
extends RefCounted

## Unit Tests for UI Card Dimensions, Texture Expand Modes, and Responsive Bounding

const OperativeCardScene = preload("res://src/ui/components/OperativeCard.tscn")
const ShopSlotCardScene = preload("res://src/ui/components/ShopSlotCard.tscn")
const AugmentChipScene = preload("res://src/ui/components/AugmentChip.tscn")
const PrepScreenScene = preload("res://src/ui/screens/PrepScreen.tscn")
const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func test_card_texture_expand_modes() -> Dictionary:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	var unit_res = repo.get_unit("runner_blitz")
	var aug_res = repo.get_augment("common_viral_nanites")
	
	# 1. OperativeCard portrait
	var op_card = OperativeCardScene.instantiate()
	var unit_inst = UnitInstance.new(unit_res)
	op_card.setup(unit_inst, true)
	var portrait: TextureRect = op_card.get_node("Margin/VBox/Header/PortraitIcon")
	if portrait == null or portrait.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		op_card.queue_free()
		return {"passed": false, "message": "OperativeCard portrait missing EXPAND_IGNORE_SIZE", "assertions": 1}
		
	# 2. ShopSlotCard unit icon
	var shop_unit_card = ShopSlotCardScene.instantiate()
	shop_unit_card.setup(0, {"type": "unit", "resource": unit_res, "cost": 1, "is_bought": false}, 10)
	var shop_unit_icon: TextureRect = shop_unit_card.get_node("Margin/VBox/NameRow/IconRect")
	if shop_unit_icon == null or shop_unit_icon.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		op_card.queue_free()
		shop_unit_card.queue_free()
		return {"passed": false, "message": "ShopSlotCard unit icon missing EXPAND_IGNORE_SIZE", "assertions": 2}
		
	# 3. ShopSlotCard augment icon
	var shop_aug_card = ShopSlotCardScene.instantiate()
	shop_aug_card.setup(1, {"type": "augment", "resource": aug_res, "cost": 2, "is_bought": false}, 10)
	var shop_aug_icon: TextureRect = shop_aug_card.get_node("Margin/VBox/NameRow/IconRect")
	if shop_aug_icon == null or shop_aug_icon.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		op_card.queue_free()
		shop_unit_card.queue_free()
		shop_aug_card.queue_free()
		return {"passed": false, "message": "ShopSlotCard augment icon missing EXPAND_IGNORE_SIZE", "assertions": 3}
		
	# 4. AugmentChip icon
	var chip = AugmentChipScene.instantiate()
	chip.setup(aug_res, 0)
	var chip_icon: TextureRect = chip.get_node("VBox/TopRow/IconRect")
	if chip_icon == null or chip_icon.expand_mode != TextureRect.EXPAND_IGNORE_SIZE:
		op_card.queue_free()
		shop_unit_card.queue_free()
		shop_aug_card.queue_free()
		chip.queue_free()
		return {"passed": false, "message": "AugmentChip icon missing EXPAND_IGNORE_SIZE", "assertions": 4}
		
	op_card.queue_free()
	shop_unit_card.queue_free()
	shop_aug_card.queue_free()
	chip.queue_free()
	return {"passed": true, "assertions": 4}

func test_screen_containment_dimensions() -> Dictionary:
	var prep = PrepScreenScene.instantiate()
	if prep == null:
		return {"passed": false, "message": "Failed to instantiate PrepScreen", "assertions": 1}
		
	var vbox: VBoxContainer = prep.get_node_or_null("Margin/VBox")
	if vbox == null:
		prep.queue_free()
		return {"passed": false, "message": "PrepScreen missing root VBox", "assertions": 2}
		
	var synergy_hud = prep.get_node_or_null("Margin/VBox/MainBody/Sidebar/SynergyTrackerHUD")
	if synergy_hud == null:
		prep.queue_free()
		return {"passed": false, "message": "PrepScreen missing SynergyTrackerHUD", "assertions": 3}
	if synergy_hud.size_flags_horizontal != Control.SIZE_SHRINK_END:
		prep.queue_free()
		return {"passed": false, "message": "SynergyTrackerHUD should have SIZE_SHRINK_END (8) for upper-right anchoring", "assertions": 4}
		
	prep.queue_free()
	return {"passed": true, "assertions": 4}

func test_synergy_tracker_hud_dimensions_and_scroll() -> Dictionary:
	var hud_scene = preload("res://src/ui/components/SynergyTrackerHUD.tscn")
	var hud = hud_scene.instantiate()
	if hud == null:
		return {"passed": false, "message": "Failed to instantiate SynergyTrackerHUD", "assertions": 1}
		
	var scroll: ScrollContainer = hud.find_child("SynergyScroll", true, false)
	if scroll == null:
		hud.queue_free()
		return {"passed": false, "message": "SynergyTrackerHUD missing SynergyScroll ScrollContainer", "assertions": 2}
		
	if hud.custom_minimum_size.x > 280 or hud.custom_minimum_size.y > 180:
		hud.queue_free()
		return {"passed": false, "message": "SynergyTrackerHUD exceeds sensible window dimensions: %s" % str(hud.custom_minimum_size), "assertions": 3}
		
	var report = SynergyReport.new()
	hud.update_synergies(report)
	var faction_list: VBoxContainer = hud.find_child("FactionList", true, false)
	if faction_list == null or faction_list.get_child_count() == 0:
		hud.queue_free()
		return {"passed": false, "message": "SynergyTrackerHUD failed to populate faction list inside scroll container", "assertions": 4}
		
	hud.queue_free()
	return {"passed": true, "assertions": 5}
