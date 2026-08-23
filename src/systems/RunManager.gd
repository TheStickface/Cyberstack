class_name RunManager
extends RefCounted

## Controls the roguelite run loop, district scaling, node encounters, and scene routing

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var current_district_index: int = 1
var current_node_index: int = 0
var current_district: DistrictResource = null
var district_nodes: Array[Dictionary] = []

## The theme sequence drawn for this run: NORMAL_DISTRICTS_PER_RUN normal districts
## followed by one final-boss district. Index 0 corresponds to current_district_index 1.
var run_districts: Array[DistrictResource] = []

var shop_mgr: ShopManager = null
var crew_mgr: CrewManager = null
var _repo: Object = null

# Run Metrics
var run_active: bool = false
var fights_won: int = 0
var bosses_defeated: int = 0
var total_gold_earned: int = 0

func _init(p_repo: Object = null) -> void:
	_repo = p_repo if p_repo != null else _get_default_repo()
	shop_mgr = ShopManager.new(Constants.DEFAULT_STARTING_GOLD)
	crew_mgr = CrewManager.new(1, _repo)

func start_new_run(starter_unit_id: String = "runner_blitz") -> void:
	current_district_index = 1
	current_node_index = 0
	fights_won = 0
	bosses_defeated = 0
	total_gold_earned = Constants.DEFAULT_STARTING_GOLD
	run_active = true
	
	shop_mgr = ShopManager.new(Constants.DEFAULT_STARTING_GOLD)
	crew_mgr = CrewManager.new(1, _repo)
	
	# Add starter unit
	var starter_res = _repo.get_unit(starter_unit_id)
	if starter_res:
		crew_mgr.fielded_units.append(UnitInstance.new(starter_res))
		crew_mgr.recalculate_synergies()

	run_districts = _repo.draw_run_districts(Constants.NORMAL_DISTRICTS_PER_RUN)
	_load_district(current_district_index)

func _load_district(dist_idx: int) -> void:
	current_district_index = dist_idx
	current_node_index = 0

	var pool_idx = dist_idx - 1
	current_district = run_districts[pool_idx] if pool_idx >= 0 and pool_idx < run_districts.size() else null
	if current_district == null:
		# Fallback programmatic district (e.g. empty/misconfigured data pool)
		current_district = DistrictResource.new()
		current_district.id = "fallback_district_%d" % dist_idx
		current_district.display_name = "District %d" % dist_idx

	crew_mgr.current_district = dist_idx
	shop_mgr.current_district = dist_idx
	
	_generate_district_nodes()

func _generate_district_nodes() -> void:
	district_nodes.clear()
	var sequence = current_district.node_sequence if current_district else [
		Enums.EncounterType.FIGHT,
		Enums.EncounterType.SHOP,
		Enums.EncounterType.FIGHT,
		Enums.EncounterType.EVENT,
		Enums.EncounterType.SHOP,
		Enums.EncounterType.BOSS
	]
	
	for i in range(sequence.size()):
		district_nodes.append({
			"index": i,
			"type": sequence[i],
			"visited": false,
			"current": (i == 0)
		})

func get_current_encounter() -> Dictionary:
	if current_node_index >= 0 and current_node_index < district_nodes.size():
		return district_nodes[current_node_index]
	return {}

func get_current_encounter_type() -> Enums.EncounterType:
	var enc = get_current_encounter()
	return enc.get("type", Enums.EncounterType.FIGHT)

func complete_encounter(victory: bool = true, battle_stats: Dictionary = {}) -> Dictionary:
	if not run_active:
		return {"status": "inactive"}
		
	var enc = get_current_encounter()
	var enc_type = enc.get("type", Enums.EncounterType.FIGHT)
	
	if (enc_type == Enums.EncounterType.FIGHT or enc_type == Enums.EncounterType.BOSS) and not victory:
		run_active = false
		return {
			"status": "game_over",
			"district": current_district_index,
			"fights_won": fights_won
		}
		
	# Process Encounter Victory
	if enc_type == Enums.EncounterType.FIGHT:
		fights_won += 1
		# Active spend economy: district base payout + performance bonus (no interest)
		var base_payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(current_district_index, 4)
		var income = shop_mgr.collect_round_income(base_payout, 1)
		total_gold_earned += income.total
	elif enc_type == Enums.EncounterType.BOSS:
		bosses_defeated += 1
		var base_payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(current_district_index, 8) + 4
		var income = shop_mgr.collect_round_income(base_payout, 2)
		total_gold_earned += income.total
		
	enc["visited"] = true
	enc["current"] = false
	current_node_index += 1
	
	# Check if district complete
	if current_node_index >= district_nodes.size():
		if current_district_index >= 4:
			# Completed Final District!
			run_active = false
			return {
				"status": "victory",
				"district": current_district_index,
				"fights_won": fights_won,
				"bosses_defeated": bosses_defeated
			}
		else:
			# Advance to Next District
			_load_district(current_district_index + 1)
			return {
				"status": "district_advanced",
				"new_district": current_district_index,
				"new_crew_cap": crew_mgr.get_max_field_units()
			}
			
	# Next node in same district
	district_nodes[current_node_index]["current"] = true
	return {
		"status": "node_advanced",
		"next_node_index": current_node_index,
		"next_encounter_type": get_current_encounter_type()
	}

func _get_default_repo() -> Object:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	return repo
