class_name TestSynergyEngine
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_faction_threshold_activation() -> Dictionary:
	var blitz_res = repo.get_unit("runner_blitz")
	var ghost_res = repo.get_unit("street_ghost")
	
	var blitz = UnitInstance.new(blitz_res)
	var ghost = UnitInstance.new(ghost_res)
	
	var crew: Array[UnitInstance] = [blitz, ghost]
	var report = SynergyEngine.evaluate_crew(crew, repo.factions, repo.tags)
	
	var count = report.faction_counts.get(Enums.Faction.STREET_RUNNERS, 0)
	if count != 2:
		return {"passed": false, "message": "Expected 2 Street Runners, got %d" % count, "assertions": 1}
		
	if not report.has_active_faction(Enums.Faction.STREET_RUNNERS, 2):
		return {"passed": false, "message": "Expected Street Runners threshold 2 to be active", "assertions": 2}
		
	var active_bonuses = report.active_faction_bonuses.get(Enums.Faction.STREET_RUNNERS, [])
	if active_bonuses.size() != 1:
		return {"passed": false, "message": "Expected 1 active bonus, got %d" % active_bonuses.size(), "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_duplicate_operatives_only_count_once() -> Dictionary:
	var blitz_res = repo.get_unit("runner_blitz")
	var blitz_1 = UnitInstance.new(blitz_res)
	var blitz_2 = UnitInstance.new(blitz_res)
	
	var crew: Array[UnitInstance] = [blitz_1, blitz_2]
	var report = SynergyEngine.evaluate_crew(crew, repo.factions, repo.tags)
	
	var count = report.faction_counts.get(Enums.Faction.STREET_RUNNERS, 0)
	if count != 1:
		return {"passed": false, "message": "Duplicate units should only count as 1 unique operative. Got %d" % count, "assertions": 1}
		
	if report.has_active_faction(Enums.Faction.STREET_RUNNERS, 2):
		return {"passed": false, "message": "Threshold 2 should not activate with duplicate operatives", "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_tag_chain_activation() -> Dictionary:
	var broker_res = repo.get_unit("fixer_broker")
	var broker = UnitInstance.new(broker_res)
	
	var viral_1 = repo.get_augment("common_viral_nanites")
	var viral_2 = repo.get_augment("rare_viral_cascade")
	
	# Slot 2 is Passive on Fixer
	broker.equip_augment(2, viral_1)
	# Create second unit to hold second viral augment
	var blitz_res = repo.get_unit("runner_blitz")
	var blitz = UnitInstance.new(blitz_res)
	blitz.equip_augment(2, viral_2) # Slot 2 is Passive on Tank
	
	var crew: Array[UnitInstance] = [broker, blitz]
	var report = SynergyEngine.evaluate_crew(crew, repo.factions, repo.tags)
	
	var viral_count = report.tag_counts.get(Enums.AugmentTag.VIRAL, 0)
	if viral_count != 2:
		return {"passed": false, "message": "Expected 2 Viral tags, got %d" % viral_count, "assertions": 1}
		
	if not report.has_active_tag(Enums.AugmentTag.VIRAL, 2):
		return {"passed": false, "message": "Expected Viral chain threshold 2 to be active", "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_cross_system_combo_rogue_ai_neural() -> Dictionary:
	var ai_res = repo.get_unit("ai_glitch")
	var ai_1 = UnitInstance.new(ai_res)
	
	# Create a second dummy rogue AI to reach 2 threshold
	var ai_res_2 = UnitResource.new()
	ai_res_2.id = "ai_daemon_two"
	ai_res_2.faction = Enums.Faction.ROGUE_AIS
	ai_res_2.role = Enums.UnitRole.HACKER
	var ai_2 = UnitInstance.new(ai_res_2)
	
	var neural_aug = repo.get_augment("common_neural_link")
	var legend_neural = repo.get_augment("legendary_neural_hive")
	
	ai_1.equip_augment(0, neural_aug)
	ai_1.equip_augment(1, legend_neural)
	ai_2.equip_augment(0, neural_aug)
	ai_2.equip_augment(1, neural_aug)
	
	var crew: Array[UnitInstance] = [ai_1, ai_2]
	var report = SynergyEngine.evaluate_crew(crew, repo.factions, repo.tags)
	
	if report.cross_system_bonuses.is_empty():
		return {"passed": false, "message": "Expected cross-system combo to trigger for 2 Rogue AIs + 4 Neural tags", "assertions": 1}
		
	var combo_id = report.cross_system_bonuses[0].id
	if combo_id != "combo_ai_neural":
		return {"passed": false, "message": "Expected combo_ai_neural, got %s" % combo_id, "assertions": 2}
		
	return {"passed": true, "assertions": 2}

func test_effective_stat_calculation() -> Dictionary:
	var blitz_res = repo.get_unit("runner_blitz")
	var blitz = UnitInstance.new(blitz_res)
	
	var base_hp = blitz.calculate_effective_stat(Enums.StatType.MAX_HEALTH)
	if base_hp != blitz_res.base_max_health:
		return {"passed": false, "message": "Base HP mismatch. Expected %.1f, got %.1f" % [blitz_res.base_max_health, base_hp], "assertions": 1}
		
	# Equip thermal core (+120 HP, +5 Armor) in slot 0 (Defensive)
	var thermal_core = repo.get_augment("common_thermal_core")
	var equipped = blitz.equip_augment(0, thermal_core)
	if not equipped:
		return {"passed": false, "message": "Failed to equip thermal core on Tank", "assertions": 2}
		
	var new_hp = blitz.calculate_effective_stat(Enums.StatType.MAX_HEALTH)
	if new_hp != (blitz_res.base_max_health + 120.0):
		return {"passed": false, "message": "Expected %.1f HP with augment, got %.1f" % [blitz_res.base_max_health + 120.0, new_hp], "assertions": 3}
		
	# Add global synergy bonus
	var global_stats = {Enums.StatType.MAX_HEALTH: 50.0}
	var total_hp = blitz.calculate_effective_stat(Enums.StatType.MAX_HEALTH, global_stats)
	if total_hp != (blitz_res.base_max_health + 170.0):
		return {"passed": false, "message": "Expected %.1f HP with global synergy, got %.1f" % [blitz_res.base_max_health + 170.0, total_hp], "assertions": 4}
		
	return {"passed": true, "assertions": 4}

func test_calculate_synergy_impact() -> Dictionary:
	var blitz_res = repo.get_unit("runner_blitz")
	var dash_res = repo.get_unit("runner_dash")
	
	var blitz = UnitInstance.new(blitz_res)
	var current_crew: Array[UnitInstance] = [blitz]
	
	# Prospect adding Dash (another Street Runner) -> should activate 2-threshold
	var impact = SynergyEngine.calculate_synergy_impact(current_crew, dash_res, repo.factions, repo.tags)
	
	if not impact["will_activate_threshold"]:
		return {"passed": false, "message": "Expected will_activate_threshold to be true for second Street Runner", "assertions": 1}
	if impact["prev_count"] != 1 or impact["new_count"] != 2:
		return {"passed": false, "message": "Expected prev 1, new 2 counts. Got %d -> %d" % [impact["prev_count"], impact["new_count"]], "assertions": 2}
		
	# Prospect adding duplicate Blitz -> should flag duplicate
	var dup_impact = SynergyEngine.calculate_synergy_impact(current_crew, blitz_res, repo.factions, repo.tags)
	if not dup_impact["is_duplicate"]:
		return {"passed": false, "message": "Expected is_duplicate to be true for duplicate Blitz", "assertions": 3}
		
	return {"passed": true, "assertions": 3}

func test_synergy_hud_hover_tooltips() -> Dictionary:
	var fac_res = repo.get_faction(Enums.Faction.STREET_RUNNERS)
	if fac_res == null:
		return {"passed": false, "message": "Street Runners faction resource missing", "assertions": 1}
		
	var tooltip_node = SynergyTooltip.create_faction_tooltip_node(fac_res, 2)
	if tooltip_node == null:
		return {"passed": false, "message": "create_faction_tooltip_node returned null", "assertions": 2}
		
	var tag_res = repo.get_tag(Enums.AugmentTag.KINETIC)
	if tag_res == null:
		return {"passed": false, "message": "Kinetic tag resource missing", "assertions": 3}
		
	var tag_tooltip_node = SynergyTooltip.create_tag_tooltip_node(tag_res, 1)
	if tag_tooltip_node == null:
		return {"passed": false, "message": "create_tag_tooltip_node returned null", "assertions": 4}
		
	tooltip_node.free()
	tag_tooltip_node.free()
	return {"passed": true, "assertions": 4}
