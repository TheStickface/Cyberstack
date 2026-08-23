class_name TestEventSystem
extends RefCounted

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

func test_all_new_events_loaded() -> Dictionary:
	var event_ids = [
		"event_corrupted_courier",
		"event_downed_corp_drone",
		"event_ghost_terminal",
		"event_black_market_clinic",
		"event_corporate_whistleblower",
		"event_underground_betting_ring",
		"event_rogue_daemon_vault",
		"event_chop_shop_salvage",
		"event_smuggler_airdrop",
		"event_viral_containment_breach",
		"event_panopticon_bribe",
		"event_megachurch_tithe",
		"event_arcology_executive_offer"
	]
	
	if repo.events.size() < 13:
		return {"passed": false, "message": "Expected at least 13 events, got %d" % repo.events.size(), "assertions": 1}
		
	for e_id in event_ids:
		var ev: NarrativeEventResource = repo.get_event(e_id)
		if ev == null:
			return {"passed": false, "message": "Missing expected event: %s" % e_id, "assertions": 2}
		if ev.choices.size() < 2:
			return {"passed": false, "message": "Event %s has fewer than 2 choices" % e_id, "assertions": 3}
			
	return {"passed": true, "assertions": 3}

func test_role_and_gold_requirements() -> Dictionary:
	var courier_event = repo.get_event("event_corrupted_courier")
	if courier_event == null:
		return {"passed": false, "message": "Courier event resource not found", "assertions": 1}
		
	var blitz = UnitInstance.new(repo.get_unit("runner_blitz")) # Tank
	var hacker = UnitInstance.new(repo.get_unit("ai_glitch"))   # Hacker
	
	var choice_1: EventChoiceResource = courier_event.choices[0] # Requires 4 gold
	var choice_2: EventChoiceResource = courier_event.choices[1] # Requires Hacker
	
	# Test with 2 gold and Tank only
	var crew_tank_only: Array[UnitInstance] = [blitz]
	if choice_1.is_available(2, crew_tank_only):
		return {"passed": false, "message": "Choice 1 should require 4 gold", "assertions": 2}
	if choice_2.is_available(2, crew_tank_only):
		return {"passed": false, "message": "Choice 2 should require Hacker", "assertions": 3}
		
	# Test with 5 gold and Hacker in crew
	var crew_with_hacker: Array[UnitInstance] = [blitz, hacker]
	if not choice_1.is_available(5, crew_with_hacker):
		return {"passed": false, "message": "Choice 1 should be available with 5 gold", "assertions": 4}
	if not choice_2.is_available(5, crew_with_hacker):
		return {"passed": false, "message": "Choice 2 should be available with Hacker", "assertions": 5}
		
	return {"passed": true, "assertions": 5}

func test_event_choice_execution() -> Dictionary:
	var courier_event = repo.get_event("event_corrupted_courier")
	var choice_2: EventChoiceResource = courier_event.choices[1] # Hacker choice: +3 gold, grants augment
	
	var shop = ShopManager.new(10)
	var crew_mgr = CrewManager.new(1, repo)
	var hacker = UnitInstance.new(repo.get_unit("ai_glitch"))
	crew_mgr.fielded_units.append(hacker)
	
	var outcome = EventManager.execute_choice(choice_2, shop, crew_mgr)
	if not outcome.success:
		return {"passed": false, "message": "Execution of valid choice failed", "assertions": 1}
	if shop.gold != 13:
		return {"passed": false, "message": "Expected 13 gold (+3 reward), got %d" % shop.gold, "assertions": 2}
	if crew_mgr.augment_inventory.size() != 1:
		return {"passed": false, "message": "Expected 1 augment in inventory after event reward", "assertions": 3}
		
	return {"passed": true, "assertions": 3}
