class_name CombatBridge
extends RefCounted

## Decoupled data adapter connecting RunManager and the Combat Arena

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

static func package_combat_payload(
	player_crew: Array[UnitInstance],
	synergies: SynergyReport,
	district_id: int,
	is_boss: bool = false,
	repo_instance: Object = null
) -> Dictionary:
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	var enemy_squad: Array[UnitInstance] = _generate_enemy_squad(district_id, is_boss, repo)
	
	return {
		"district_id": district_id,
		"is_boss": is_boss,
		"player_crew": player_crew,
		"player_synergies": synergies,
		"enemy_squad": enemy_squad,
		"combat_timestamp": Time.get_unix_time_from_system()
	}

static func _generate_enemy_squad(district_id: int, is_boss: bool, repo: Object) -> Array[UnitInstance]:
	var squad: Array[UnitInstance] = []
	var enemy_count = Constants.DISTRICT_CREW_LIMITS.get(district_id, 2)
	
	var all_units = repo.get_all_units()
	if all_units.is_empty():
		return squad
		
	# Select faction themed for district
	var target_faction = Enums.Faction.CORP_ENFORCERS
	match district_id:
		1: target_faction = Enums.Faction.STREET_RUNNERS
		2: target_faction = Enums.Faction.CORP_ENFORCERS
		3: target_faction = Enums.Faction.ROGUE_AIS
		4: target_faction = Enums.Faction.FIXERS
		
	var faction_units = repo.get_units_by_faction(target_faction)
	var pool = faction_units if not faction_units.is_empty() else all_units
	
	for i in range(enemy_count):
		var base_res = pool[randi() % pool.size()]
		var enemy_instance = UnitInstance.new(base_res)
		
		# Give enemies appropriate tier augments based on district
		if district_id >= 2:
			var common_aug = repo.get_augment("common_thermal_core")
			if common_aug:
				enemy_instance.equipped_augments[0] = common_aug
		if district_id >= 3:
			var rare_aug = repo.get_augment("rare_kinetic_rail")
			if rare_aug:
				enemy_instance.equipped_augments[1] = rare_aug
				
		squad.append(enemy_instance)
		
	if is_boss and not squad.is_empty():
		var apex_id = "runner_overdrive"
		match district_id:
			1: apex_id = "runner_overdrive"
			2: apex_id = "corp_director"
			3: apex_id = "ai_singularity"
			4: apex_id = "fixer_kingpin"
		var boss_res = repo.get_unit(apex_id)
		if boss_res:
			var boss_inst = UnitInstance.new(boss_res)
			boss_inst.star_level = 2
			squad[0] = boss_inst
		
	return squad

static func _get_default_repo() -> Object:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	return repo
