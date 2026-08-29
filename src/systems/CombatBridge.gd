class_name CombatBridge
extends RefCounted

## Decoupled data adapter connecting RunManager and the Combat Arena

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

static func package_combat_payload(
	player_crew: Array[UnitInstance],
	synergies: SynergyReport,
	district_id: int,
	is_boss: bool = false,
	repo_instance: Object = null,
	district_res: DistrictResource = null,
	player_grid: Array = []
) -> Dictionary:
	var repo = repo_instance if repo_instance != null else _get_default_repo()
	var enemy_squad: Array[UnitInstance] = _generate_enemy_squad(district_id, is_boss, repo, district_res)
	var enemy_grid: Array[UnitInstance] = _place_squad_on_grid(enemy_squad, district_id)
	
	var final_player_grid: Array[UnitInstance] = []
	if not player_grid.is_empty() and player_grid.size() == 6:
		for item in player_grid:
			final_player_grid.append(item as UnitInstance)
	else:
		final_player_grid = _place_squad_on_grid(player_crew, district_id)
	
	return {
		"district_id": district_id,
		"is_boss": is_boss,
		"district_name": district_res.display_name if district_res else ("District %d" % district_id),
		"player_crew": player_crew,
		"player_grid": final_player_grid,
		"player_synergies": synergies,
		"enemy_squad": enemy_squad,
		"enemy_grid": enemy_grid,
		"combat_timestamp": Time.get_unix_time_from_system()
	}

static func _place_squad_on_grid(squad: Array[UnitInstance], district_id: int) -> Array[UnitInstance]:
	var grid: Array[UnitInstance] = [null, null, null, null, null, null]
	var front_idx = 0
	var back_idx = 3
	
	for unit in squad:
		if unit == null:
			continue
		var is_tank = (unit.unit_resource and unit.unit_resource.role == Enums.UnitRole.TANK)
		var is_boss = (unit.unit_resource and unit.unit_resource.id.begins_with("boss_"))
		
		# Prefer Tanks/Bosses in front row (0..2), Backline for Snipers/Hackers (3..5 in dist 2+)
		if (is_tank or is_boss or district_id == 1 or back_idx >= 6) and front_idx < 3:
			grid[front_idx] = unit
			unit.grid_slot = front_idx
			front_idx += 1
		elif back_idx < 6 and district_id >= 2:
			grid[back_idx] = unit
			unit.grid_slot = back_idx
			back_idx += 1
		elif front_idx < 3:
			grid[front_idx] = unit
			unit.grid_slot = front_idx
			front_idx += 1
		elif back_idx < 6:
			grid[back_idx] = unit
			unit.grid_slot = back_idx
			back_idx += 1
			
	return grid


static func _generate_enemy_squad(district_id: int, is_boss: bool, repo: Object, district_res: DistrictResource = null) -> Array[UnitInstance]:
	var squad: Array[UnitInstance] = []
	var enemy_count = Constants.DISTRICT_CREW_LIMITS.get(district_id, 2)
	
	var raw_units = repo.get_all_units()
	if raw_units.is_empty():
		return squad
		
	var all_units: Array[UnitResource] = []
	for u in raw_units:
		if not u.id.begins_with("boss_"):
			all_units.append(u)
			
	if all_units.is_empty():
		all_units = raw_units
		
	# Select faction themed for district
	var target_faction = Enums.Faction.CORP_ENFORCERS
	match district_id % 4:
		1: target_faction = Enums.Faction.STREET_RUNNERS
		2: target_faction = Enums.Faction.CORP_ENFORCERS
		3: target_faction = Enums.Faction.ROGUE_AIS
		0: target_faction = Enums.Faction.FIXERS
		
	var faction_units: Array[UnitResource] = []
	for u in all_units:
		if u.faction == target_faction:
			faction_units.append(u)
	var pool = faction_units if not faction_units.is_empty() else all_units
	
	for i in range(enemy_count):
		var base_res = pool[randi() % pool.size()]
		var enemy_instance = UnitInstance.new(base_res)
		
		# Give minions appropriate tier augments based on district
		if district_id >= 2:
			var common_aug = repo.get_augment("common_kinetic_plating")
			if district_res and district_res.preferred_tag == Enums.AugmentTag.THERMAL:
				common_aug = repo.get_augment("common_thermal_core")
			elif district_res and district_res.preferred_tag == Enums.AugmentTag.NEURAL:
				common_aug = repo.get_augment("common_neural_buffer")
			elif district_res and district_res.preferred_tag == Enums.AugmentTag.VIRAL:
				common_aug = repo.get_augment("common_viral_nanites")
			if common_aug:
				enemy_instance.equipped_augments[0] = common_aug
				
		if district_id >= 3:
			var rare_aug = repo.get_augment("rare_kinetic_rail")
			if district_res and district_res.preferred_tag == Enums.AugmentTag.THERMAL:
				rare_aug = repo.get_augment("rare_thermal_exhaust")
			elif district_res and district_res.preferred_tag == Enums.AugmentTag.NEURAL:
				rare_aug = repo.get_augment("rare_neural_synapse")
			elif district_res and district_res.preferred_tag == Enums.AugmentTag.VIRAL:
				rare_aug = repo.get_augment("rare_viral_siphon")
			if rare_aug:
				enemy_instance.equipped_augments[1] = rare_aug
				
		squad.append(enemy_instance)
		
	if is_boss and not squad.is_empty():
		var boss_id = "boss_slum_enforcer"
		if district_res and not district_res.boss_unit_id.is_empty():
			boss_id = district_res.boss_unit_id
		else:
			match district_id:
				1: boss_id = "boss_slum_enforcer"
				2: boss_id = "boss_corp_commander"
				3: boss_id = "boss_ai_prime_overmind"
				4: boss_id = "boss_nemesis_synthetic"
				_: boss_id = "boss_nemesis_synthetic"
				
		var boss_res = repo.get_unit(boss_id)
		if boss_res == null:
			# Fallback to apex unit if specific boss not found
			boss_res = repo.get_unit("runner_overdrive")
			
		if boss_res != null:
			var boss_inst = UnitInstance.new(boss_res)
			boss_inst.star_level = 3 if district_id >= 4 else 2
			
			# Equip Boss with specialized augment loadout
			if district_id >= 2:
				var boss_aug1 = repo.get_augment("rare_thermal_laser")
				if district_res and district_res.preferred_tag == Enums.AugmentTag.KINETIC:
					boss_aug1 = repo.get_augment("rare_kinetic_overdrive")
				elif district_res and district_res.preferred_tag == Enums.AugmentTag.NEURAL:
					boss_aug1 = repo.get_augment("rare_neural_daemon")
				elif district_res and district_res.preferred_tag == Enums.AugmentTag.VIRAL:
					boss_aug1 = repo.get_augment("rare_viral_cascade")
				if boss_aug1:
					boss_inst.equipped_augments[0] = boss_aug1
					
			if district_id >= 3:
				var boss_aug2 = repo.get_augment("legendary_kinetic_destroyer")
				if district_res and district_res.preferred_tag == Enums.AugmentTag.THERMAL:
					boss_aug2 = repo.get_augment("legendary_thermal_supernova")
				elif district_res and district_res.preferred_tag == Enums.AugmentTag.NEURAL:
					boss_aug2 = repo.get_augment("legendary_neural_hive")
				elif district_res and district_res.preferred_tag == Enums.AugmentTag.VIRAL:
					boss_aug2 = repo.get_augment("legendary_viral_pandemic")
				if boss_aug2:
					boss_inst.equipped_augments[1] = boss_aug2
					
			squad[0] = boss_inst
		
	return squad

static func _get_default_repo() -> Object:
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	return repo
