class_name SaveManager
extends RefCounted

## Handles JSON serialization for player meta profiles and active run state

const PROFILE_PATH = "user://cyberstack_profile.json"
const ACTIVE_RUN_PATH = "user://cyberstack_active_run.json"

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

# Meta Profile Save / Load
static func save_profile(profile: MetaProfile, path: String = PROFILE_PATH) -> bool:
	if profile == null:
		return false
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
		
	var json_string = JSON.stringify(profile.to_dict(), "\t")
	file.store_string(json_string)
	file.close()
	return true

static func load_profile(path: String = PROFILE_PATH) -> MetaProfile:
	var profile = MetaProfile.new()
	if not FileAccess.file_exists(path):
		return profile
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return profile
		
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err == OK and json.data is Dictionary:
		profile.from_dict(json.data)
		
	return profile

# Active Run Suspend / Resume
static func save_active_run(run_mgr: RunManager, path: String = ACTIVE_RUN_PATH) -> bool:
	if run_mgr == null or not run_mgr.run_active:
		delete_active_run(path)
		return false
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
		
	var data = {
		"schema_version": 1,
		"district_index": run_mgr.current_district_index,
		"node_index": run_mgr.current_node_index,
		"fights_won": run_mgr.fights_won,
		"bosses_defeated": run_mgr.bosses_defeated,
		"total_gold_earned": run_mgr.total_gold_earned,
		"gold": run_mgr.shop_mgr.gold if run_mgr.shop_mgr else 10,
		"is_locked": run_mgr.shop_mgr.is_locked if run_mgr.shop_mgr else false,
		"run_districts": _serialize_districts(run_mgr.run_districts),
		"fielded_units": _serialize_units(run_mgr.crew_mgr.fielded_units if run_mgr.crew_mgr else []),
		"benched_units": _serialize_units(run_mgr.crew_mgr.benched_units if run_mgr.crew_mgr else []),
		"augment_inventory": _serialize_augments(run_mgr.crew_mgr.augment_inventory if run_mgr.crew_mgr else [])
	}
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true

static func load_active_run(repo: Object = null, path: String = ACTIVE_RUN_PATH) -> RunManager:
	if not has_active_run(path):
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
		
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK or not (json.data is Dictionary):
		return null
		
	var data: Dictionary = json.data
	var repo_obj = repo if repo != null else _get_default_repo()
	
	var run_mgr = RunManager.new(repo_obj)
	run_mgr.run_active = true
	run_mgr.current_district_index = data.get("district_index", 1)
	run_mgr.current_node_index = data.get("node_index", 0)
	run_mgr.fights_won = data.get("fights_won", 0)
	run_mgr.bosses_defeated = data.get("bosses_defeated", 0)
	run_mgr.total_gold_earned = data.get("total_gold_earned", 10)
	
	# Setup Shop and Crew Managers
	run_mgr.shop_mgr = ShopManager.new(data.get("gold", 10))
	run_mgr.shop_mgr.current_district = run_mgr.current_district_index
	run_mgr.shop_mgr.is_locked = data.get("is_locked", false)
	
	run_mgr.crew_mgr = CrewManager.new(run_mgr.current_district_index, repo_obj)
	var loaded_fielded = _deserialize_units(data.get("fielded_units", []), repo_obj)
	run_mgr.crew_mgr.benched_units = _deserialize_units(data.get("benched_units", []), repo_obj)
	run_mgr.crew_mgr.augment_inventory = _deserialize_augments(data.get("augment_inventory", []), repo_obj)
	
	# Reconstruct tactical grid from fielded units
	for u in loaded_fielded:
		if u != null:
			if u.grid_slot >= 0 and u.grid_slot < run_mgr.crew_mgr.tactical_grid.size():
				run_mgr.crew_mgr.tactical_grid[u.grid_slot] = u
			else:
				var open_slot = run_mgr.crew_mgr._find_first_empty_unlocked_slot()
				if open_slot != -1:
					run_mgr.crew_mgr.tactical_grid[open_slot] = u
					u.grid_slot = open_slot
				else:
					run_mgr.crew_mgr.benched_units.append(u)
					u.grid_slot = -1
	run_mgr.crew_mgr._sync_fielded_units()

	# Reconstruct run districts
	var district_ids: Array = data.get("run_districts", [])
	if not district_ids.is_empty():
		run_mgr.run_districts.clear()
		for d_id in district_ids:
			var d_res = repo_obj.get_district(str(d_id))
			if d_res:
				run_mgr.run_districts.append(d_res)
	else:
		run_mgr.run_districts = repo_obj.draw_run_districts(Constants.NORMAL_DISTRICTS_PER_RUN)

	run_mgr._load_district(run_mgr.current_district_index)
	run_mgr.current_node_index = data.get("node_index", 0)
	
	# Sync node statuses
	for i in range(run_mgr.district_nodes.size()):
		var n = run_mgr.district_nodes[i]
		n["visited"] = (i < run_mgr.current_node_index)
		n["current"] = (i == run_mgr.current_node_index)
		
	run_mgr.crew_mgr.recalculate_synergies()
	return run_mgr

static func has_active_run(path: String = ACTIVE_RUN_PATH) -> bool:
	return FileAccess.file_exists(path)

static func delete_active_run(path: String = ACTIVE_RUN_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# Helper Serializers
static func _serialize_districts(districts: Array[DistrictResource]) -> Array[String]:
	var list: Array[String] = []
	for d in districts:
		if d and not d.id.is_empty():
			list.append(d.id)
	return list

static func _serialize_units(units: Array[UnitInstance]) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for u in units:
		if u and u.unit_resource:
			var aug_ids: Array = []
			for aug in u.equipped_augments:
				aug_ids.append(aug.id if aug else "")
			list.append({
				"unit_id": u.unit_resource.id,
				"level": u.level,
				"star_level": u.star_level,
				"grid_slot": u.grid_slot,
				"equipped_augments": aug_ids
			})
	return list

static func _deserialize_units(data_list: Array, repo: Object) -> Array[UnitInstance]:
	var list: Array[UnitInstance] = []
	for item in data_list:
		var dict = item as Dictionary
		var u_id = dict.get("unit_id", "")
		var unit_res = repo.get_unit(u_id)
		if unit_res:
			var instance = UnitInstance.new(unit_res)
			instance.level = dict.get("level", 1)
			instance.star_level = dict.get("star_level", instance.level)
			instance.grid_slot = dict.get("grid_slot", -1)
			var aug_ids = dict.get("equipped_augments", [])
			for i in range(mini(aug_ids.size(), Constants.MAX_AUGMENT_SLOTS_PER_UNIT)):
				var a_id = aug_ids[i]
				if not a_id.is_empty():
					var aug_res = repo.get_augment(a_id)
					if aug_res:
						instance.equipped_augments[i] = aug_res
			list.append(instance)
	return list

static func _serialize_augments(augments: Array[AugmentResource]) -> Array[String]:
	var list: Array[String] = []
	for a in augments:
		if a and not a.id.is_empty():
			list.append(a.id)
	return list

static func _deserialize_augments(id_list: Array, repo: Object) -> Array[AugmentResource]:
	var list: Array[AugmentResource] = []
	for item in id_list:
		var a_id = str(item)
		var aug_res = repo.get_augment(a_id)
		if aug_res:
			list.append(aug_res)
	return list

static func _get_default_repo() -> Object:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	return repo
