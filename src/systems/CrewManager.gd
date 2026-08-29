class_name CrewManager
extends RefCounted

## Manages fielded operatives, bench reserves, augment inventory, and live synergy recalculation

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var fielded_units: Array[UnitInstance] = []
var benched_units: Array[UnitInstance] = []
var augment_inventory: Array[AugmentResource] = []
var last_combinations: Array[Dictionary] = []

## 2x3 Tactical Grid: Size 6.
## Bottom Row (Frontline): slots 0 (Left), 1 (Center), 2 (Right) - Unlocked in District 1
## Top Row (Backline):
##   - slot 4 (Top Center): Unlocks in District 2
##   - slot 3 (Top Left): Unlocks in District 3
##   - slot 5 (Top Right): Unlocks in District 4
var tactical_grid: Array[UnitInstance] = [null, null, null, null, null, null]

var current_district: int = 1
var active_synergy_report: SynergyReport = null

var _repo_cache: Object = null

func _init(p_district: int = 1, p_repo: Object = null) -> void:
	current_district = p_district
	_repo_cache = p_repo
	active_synergy_report = SynergyReport.new()
	tactical_grid = [null, null, null, null, null, null]

func get_max_field_units() -> int:
	return Constants.DISTRICT_CREW_LIMITS.get(current_district, 2)

func is_slot_unlocked(slot_idx: int) -> bool:
	match slot_idx:
		0, 1, 2: # Bottom Left, Bottom Center, Bottom Right - Full Frontline unlocked in District 1
			return true
		4: # Top Center (Backline Center) - Unlocks in District 2 (Crew cap expands to 4)
			return current_district >= 2
		3: # Top Left (Backline Left) - Unlocks in District 3 (Crew cap expands to 5)
			return current_district >= 3
		5: # Top Right (Backline Right) - Unlocks in District 4 (Crew cap expands to 6)
			return current_district >= 4
		_:
			return false

func get_slot_unlock_district(slot_idx: int) -> int:
	match slot_idx:
		0, 1, 2: return 1
		4: return 2
		3: return 3
		5: return 4
		_: return 99


func _sync_fielded_units() -> void:
	fielded_units.clear()
	for i in range(tactical_grid.size()):
		var u = tactical_grid[i]
		if u != null:
			u.grid_slot = i
			fielded_units.append(u)

# Unit Management
func add_unit(unit: UnitInstance) -> bool:
	if unit == null:
		return false
	var added = false
	if fielded_units.size() < get_max_field_units():
		var target_slot = _find_first_empty_unlocked_slot()
		if target_slot != -1:
			tactical_grid[target_slot] = unit
			unit.grid_slot = target_slot
			_sync_fielded_units()
			recalculate_synergies()
			added = true
	
	if not added and benched_units.size() < Constants.MAX_BENCH_UNITS:
		benched_units.append(unit)
		unit.grid_slot = -1
		added = true
		
	if added:
		check_and_execute_combinations()
	return added

func _find_first_empty_unlocked_slot() -> int:
	for i in range(tactical_grid.size()):
		if is_slot_unlocked(i) and tactical_grid[i] == null:
			return i
	return -1


func add_unit_to_bench(unit: UnitInstance) -> bool:
	if unit == null or benched_units.size() >= Constants.MAX_BENCH_UNITS:
		return false
	benched_units.append(unit)
	check_and_execute_combinations()
	return true

## Core Star Combination Engine:
## 2 copies of Tier 1 combine into Tier 2 (★2)
## 2 copies of Tier 2 combine into Tier 3 (★3)
func check_and_execute_combinations() -> Array[Dictionary]:
	var combinations_made: Array[Dictionary] = []
	last_combinations.clear()
	var keep_checking = true
	
	while keep_checking:
		keep_checking = false
		var all_units = fielded_units + benched_units
		
		# Group units by resource ID
		var units_by_id: Dictionary = {}
		for u in all_units:
			if u == null or u.unit_resource == null:
				continue
			var u_id = u.unit_resource.id
			if not units_by_id.has(u_id):
				units_by_id[u_id] = {
					1: [], # Tier 1 copies
					2: [], # Tier 2 copies
					3: []  # Tier 3 copies
				}
			var lvl = u.star_level
			if units_by_id[u_id].has(lvl):
				units_by_id[u_id][lvl].append(u)
				
		for u_id in units_by_id:
			var tiers = units_by_id[u_id]
			
			# Check Tier 1 -> Tier 2 (2 copies of Tier 1)
			if tiers[1].size() >= 2:
				var copy1: UnitInstance = tiers[1][0]
				var copy2: UnitInstance = tiers[1][1]
				
				var primary: UnitInstance = copy1
				var secondary: UnitInstance = copy2
				if fielded_units.has(copy2) and not fielded_units.has(copy1):
					primary = copy2
					secondary = copy1
					
				primary.star_level = 2
				primary.level = 2
				
				# Recover augments from secondary
				for i in range(secondary.equipped_augments.size()):
					var aug = secondary.unequip_augment(i)
					if aug != null:
						add_augment_to_inventory(aug)
						
				remove_unit(secondary)
				
				combinations_made.append({
					"unit": primary,
					"unit_name": primary.unit_resource.display_name,
					"new_star_level": 2
				})
				keep_checking = true
				break
				
			# Check Tier 2 -> Tier 3 (2 copies of Tier 2)
			if tiers[2].size() >= 2:
				var copy1: UnitInstance = tiers[2][0]
				var copy2: UnitInstance = tiers[2][1]
				
				var primary: UnitInstance = copy1
				var secondary: UnitInstance = copy2
				if fielded_units.has(copy2) and not fielded_units.has(copy1):
					primary = copy2
					secondary = copy1
					
				primary.star_level = 3
				primary.level = 3
				
				# Recover augments from secondary
				for i in range(secondary.equipped_augments.size()):
					var aug = secondary.unequip_augment(i)
					if aug != null:
						add_augment_to_inventory(aug)
				remove_unit(secondary)
					
				combinations_made.append({
					"unit": primary,
					"unit_name": primary.unit_resource.display_name,
					"new_star_level": 3
				})
				keep_checking = true
				break
				
	if not combinations_made.is_empty():
		recalculate_synergies()
		
	last_combinations = combinations_made
	return combinations_made

func deploy_unit_to_field(bench_index: int) -> bool:
	if bench_index < 0 or bench_index >= benched_units.size():
		return false
	if fielded_units.size() >= get_max_field_units():
		return false
	var target_slot = _find_first_empty_unlocked_slot()
	if target_slot == -1:
		return false
	return deploy_bench_to_grid(bench_index, target_slot)

func deploy_bench_to_grid(bench_index: int, target_slot_idx: int) -> bool:
	if bench_index < 0 or bench_index >= benched_units.size():
		return false
	if not is_slot_unlocked(target_slot_idx):
		return false
	if fielded_units.size() >= get_max_field_units() and tactical_grid[target_slot_idx] == null:
		return false
		
	var unit = benched_units[bench_index]
	var displaced = tactical_grid[target_slot_idx]
	
	benched_units.remove_at(bench_index)
	tactical_grid[target_slot_idx] = unit
	unit.grid_slot = target_slot_idx
	
	if displaced != null:
		displaced.grid_slot = -1
		benched_units.insert(bench_index, displaced)
		
	_sync_fielded_units()
	recalculate_synergies()
	return true

func place_unit_on_grid(unit: UnitInstance, target_slot_idx: int) -> bool:
	if unit == null or not is_slot_unlocked(target_slot_idx):
		return false
	var old_slot = tactical_grid.find(unit)
	var displaced = tactical_grid[target_slot_idx]
	
	if old_slot != -1:
		tactical_grid[old_slot] = displaced
		if displaced:
			displaced.grid_slot = old_slot
	else:
		if fielded_units.size() >= get_max_field_units() and displaced == null:
			return false
		var b_idx = benched_units.find(unit)
		if b_idx != -1:
			benched_units.remove_at(b_idx)
		if displaced:
			displaced.grid_slot = -1
			benched_units.append(displaced)
			
	tactical_grid[target_slot_idx] = unit
	unit.grid_slot = target_slot_idx
	
	_sync_fielded_units()
	recalculate_synergies()
	return true

func swap_grid_slots(slot_a: int, slot_b: int) -> bool:
	if not is_slot_unlocked(slot_a) or not is_slot_unlocked(slot_b):
		return false
	if slot_a < 0 or slot_a >= 6 or slot_b < 0 or slot_b >= 6:
		return false
		
	var u_a = tactical_grid[slot_a]
	var u_b = tactical_grid[slot_b]
	
	tactical_grid[slot_a] = u_b
	tactical_grid[slot_b] = u_a
	
	if u_a:
		u_a.grid_slot = slot_b
	if u_b:
		u_b.grid_slot = slot_a
		
	_sync_fielded_units()
	recalculate_synergies()
	return true

func recall_unit_to_bench(field_index: int) -> bool:
	if field_index < 0 or field_index >= fielded_units.size():
		return false
	if benched_units.size() >= Constants.MAX_BENCH_UNITS:
		return false
		
	var unit = fielded_units[field_index]
	var slot_idx = tactical_grid.find(unit)
	if slot_idx != -1:
		tactical_grid[slot_idx] = null
	unit.grid_slot = -1
	benched_units.append(unit)
	_sync_fielded_units()
	recalculate_synergies()
	return true

func recall_grid_slot_to_bench(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= 6:
		return false
	var unit = tactical_grid[slot_idx]
	if unit == null:
		return false
	if benched_units.size() >= Constants.MAX_BENCH_UNITS:
		return false
	tactical_grid[slot_idx] = null
	unit.grid_slot = -1
	benched_units.append(unit)
	_sync_fielded_units()
	recalculate_synergies()
	return true

func field_unit(unit: UnitInstance) -> bool:
	if unit == null:
		return false
	var b_idx = benched_units.find(unit)
	if b_idx != -1:
		return deploy_unit_to_field(b_idx)
	return false

func bench_unit(unit: UnitInstance) -> bool:
	if unit == null:
		return false
	var f_idx = fielded_units.find(unit)
	if f_idx != -1:
		return recall_unit_to_bench(f_idx)
	return false

func swap_field_and_bench(field_index: int, bench_index: int) -> bool:
	if field_index < 0 or field_index >= fielded_units.size():
		return false
	if bench_index < 0 or bench_index >= benched_units.size():
		return false
		
	var field_u = fielded_units[field_index]
	var bench_u = benched_units[bench_index]
	var slot_idx = tactical_grid.find(field_u)
	if slot_idx == -1:
		slot_idx = _find_first_empty_unlocked_slot()
		
	if slot_idx != -1:
		tactical_grid[slot_idx] = bench_u
		bench_u.grid_slot = slot_idx
	field_u.grid_slot = -1
	benched_units[bench_index] = field_u
	
	_sync_fielded_units()
	recalculate_synergies()
	return true

func remove_unit(unit: UnitInstance) -> bool:
	var slot_idx = tactical_grid.find(unit)
	if slot_idx != -1:
		tactical_grid[slot_idx] = null
		unit.grid_slot = -1
		_sync_fielded_units()
		recalculate_synergies()
		return true
		
	var b_idx = benched_units.find(unit)
	if b_idx != -1:
		benched_units.remove_at(b_idx)
		unit.grid_slot = -1
		return true
		
	return false

# Positional & Directional Grid Queries
func get_unit_at_coords(row: int, col: int) -> UnitInstance:
	if row < 0 or row > 1 or col < 0 or col > 2:
		return null
	var idx = UnitInstance.coords_to_slot(row, col)
	if idx < 0 or idx >= tactical_grid.size():
		return null
	return tactical_grid[idx]

func get_adjacent_units(row: int, col: int, direction: Enums.GridDirection) -> Array[UnitInstance]:
	var result: Array[UnitInstance] = []
	var center = get_unit_at_coords(row, col)
	
	match direction:
		Enums.GridDirection.LEFT:
			var u = get_unit_at_coords(row, col - 1)
			if u != null: result.append(u)
		Enums.GridDirection.RIGHT:
			var u = get_unit_at_coords(row, col + 1)
			if u != null: result.append(u)
		Enums.GridDirection.ABOVE:
			var u = get_unit_at_coords(row - 1, col)
			if u != null: result.append(u)
		Enums.GridDirection.BELOW:
			var u = get_unit_at_coords(row + 1, col)
			if u != null: result.append(u)
		Enums.GridDirection.ADJACENT:
			var dirs = [
				get_unit_at_coords(row, col - 1),
				get_unit_at_coords(row, col + 1),
				get_unit_at_coords(row - 1, col),
				get_unit_at_coords(row + 1, col)
			]
			for u in dirs:
				if u != null: result.append(u)
		Enums.GridDirection.SAME_ROW:
			for c in range(3):
				if c != col:
					var u = get_unit_at_coords(row, c)
					if u != null: result.append(u)
		Enums.GridDirection.SAME_COLUMN:
			for r in range(2):
				if r != row:
					var u = get_unit_at_coords(r, col)
					if u != null: result.append(u)
		Enums.GridDirection.ALL_UNITS:
			for u in fielded_units:
				if u != center and u != null:
					result.append(u)
		Enums.GridDirection.FRONTLINE:
			for c in range(3):
				var u = get_unit_at_coords(1, c) # Row 1 = Frontline
				if u != null: result.append(u)
		Enums.GridDirection.BACKLINE:
			for c in range(3):
				var u = get_unit_at_coords(0, c) # Row 0 = Backline
				if u != null: result.append(u)
				
	return result

## Calculates live formation synergy bonuses based on tactical grid placement
func calculate_formation_bonuses() -> Dictionary:
	var report: Dictionary = {}
	
	for slot_idx in range(6):
		var unit = tactical_grid[slot_idx]
		if unit == null:
			continue
			
		if not report.has(unit):
			report[unit] = {
				"shield_bonus": 0.0,
				"crit_bonus": 0.0,
				"attack_speed_bonus": 0.0,
				"starting_mana_bonus": 0.0,
				"armor_bonus": 0.0,
				"attack_damage_bonus": 0.0,
				"ability_power_bonus": 0.0,
				"max_health_bonus": 0.0,
				"speed_bonus": 0.0,
				"evasion_bonus": 0.0,
				"formation_tags": []
			}
			
		var coords = UnitInstance.slot_to_coords(slot_idx)
		var row = coords.x
		var col = coords.y
		var u_bonuses = report[unit]
		
		# 1. Base Tank Guard: Tanks shield adjacent allies (left & right)
		var left_neighbor = get_unit_at_coords(row, col - 1)
		var right_neighbor = get_unit_at_coords(row, col + 1)
		if left_neighbor and left_neighbor.unit_resource and left_neighbor.unit_resource.role == Enums.UnitRole.TANK:
			u_bonuses["shield_bonus"] += 120.0
			u_bonuses["formation_tags"].append("🛡️ Guarded from Left (+120 S)")
		if right_neighbor and right_neighbor.unit_resource and right_neighbor.unit_resource.role == Enums.UnitRole.TANK:
			u_bonuses["shield_bonus"] += 120.0
			u_bonuses["formation_tags"].append("🛡️ Guarded from Right (+120 S)")
			
		# 2. Base Hacker Row Uplink: Hackers grant +15 Starting Mana & +15% Speed to units in same row
		var same_row_units = get_adjacent_units(row, col, Enums.GridDirection.SAME_ROW)
		var hacker_row_count = 0
		for r_unit in same_row_units:
			if r_unit.unit_resource and r_unit.unit_resource.role == Enums.UnitRole.HACKER:
				hacker_row_count += 1
		if hacker_row_count > 0:
			u_bonuses["starting_mana_bonus"] += 15.0 * hacker_row_count
			u_bonuses["attack_speed_bonus"] += 0.15 * hacker_row_count
			u_bonuses["formation_tags"].append("⚡ Row Uplink (+%d Mana, +%d%% Haste)" % [15 * hacker_row_count, 15 * hacker_row_count])
			
		# 3. Base Sniper Backline Spotter: Snipers in Backline (Row 0) gain +25% Crit Chance
		if row == 0 and unit.unit_resource and unit.unit_resource.role == Enums.UnitRole.SNIPER:
			u_bonuses["crit_bonus"] += 0.25
			u_bonuses["formation_tags"].append("🎯 Backline Overwatch (+25% Crit)")
			
		# 4. Operative-Specific Directional Passives
		var u_res = unit.unit_resource
		if u_res and u_res.directional_target != Enums.GridDirection.NONE:
			_apply_directional_mods(unit, slot_idx, u_res.directional_target, u_res.directional_modifiers, u_res.directional_passive_description, report)
			
		# 5. Equipped Augment Directional Modifiers
		for aug in unit.equipped_augments:
			if aug and aug.directional_target != Enums.GridDirection.NONE:
				_apply_directional_mods(unit, slot_idx, aug.directional_target, aug.directional_modifiers, "%s Synergy" % aug.display_name, report)
				
	return report

func _apply_directional_mods(source_unit: UnitInstance, slot_idx: int, dir: Enums.GridDirection, mods: Dictionary, tag_desc: String, report: Dictionary) -> void:
	var coords = UnitInstance.slot_to_coords(slot_idx)
	var row = coords.x
	var col = coords.y
	
	# Self-position checks (Frontline / Backline)
	if dir == Enums.GridDirection.FRONTLINE:
		if row == 1: # Frontline
			_apply_mod_dict_to_unit(source_unit, mods, tag_desc, report)
		return
	elif dir == Enums.GridDirection.BACKLINE:
		if row == 0: # Backline
			_apply_mod_dict_to_unit(source_unit, mods, tag_desc, report)
		return
		
	# Directional target lookups
	var targets = get_adjacent_units(row, col, dir)
	for t_unit in targets:
		_apply_mod_dict_to_unit(t_unit, mods, tag_desc, report)

func _apply_mod_dict_to_unit(target_unit: UnitInstance, mods: Dictionary, tag_desc: String, report: Dictionary) -> void:
	if target_unit == null:
		return
	if not report.has(target_unit):
		report[target_unit] = {
			"shield_bonus": 0.0,
			"crit_bonus": 0.0,
			"attack_speed_bonus": 0.0,
			"starting_mana_bonus": 0.0,
			"armor_bonus": 0.0,
			"attack_damage_bonus": 0.0,
			"ability_power_bonus": 0.0,
			"max_health_bonus": 0.0,
			"speed_bonus": 0.0,
			"evasion_bonus": 0.0,
			"formation_tags": []
		}
	var entry = report[target_unit]
	for stat_key in mods:
		match int(stat_key):
			Enums.StatType.MAX_HEALTH: entry["max_health_bonus"] += mods[stat_key]
			Enums.StatType.ATTACK_DAMAGE: entry["attack_damage_bonus"] += mods[stat_key]
			Enums.StatType.ABILITY_POWER: entry["ability_power_bonus"] += mods[stat_key]
			Enums.StatType.ATTACK_SPEED: entry["attack_speed_bonus"] += mods[stat_key]
			Enums.StatType.ARMOR: entry["armor_bonus"] += mods[stat_key]
			Enums.StatType.SHIELD: entry["shield_bonus"] += mods[stat_key]
			Enums.StatType.STARTING_MANA: entry["starting_mana_bonus"] += mods[stat_key]
			Enums.StatType.CRIT_CHANCE: entry["crit_bonus"] += mods[stat_key]
			Enums.StatType.EVASION: entry["evasion_bonus"] += mods[stat_key]
			Enums.StatType.SPEED: entry["speed_bonus"] += mods[stat_key]
			
	if not tag_desc.is_empty() and not entry["formation_tags"].has(tag_desc):
		entry["formation_tags"].append(tag_desc)




# Augment Inventory & Slotting
func add_augment_to_inventory(augment: AugmentResource) -> bool:
	if augment == null or augment_inventory.size() >= Constants.MAX_BENCH_AUGMENTS:
		return false
	augment_inventory.append(augment)
	return true

func remove_augment_from_inventory(inventory_index: int) -> AugmentResource:
	if inventory_index < 0 or inventory_index >= augment_inventory.size():
		return null
	var removed = augment_inventory[inventory_index]
	augment_inventory.remove_at(inventory_index)
	return removed

func equip_augment_from_inventory(unit: UnitInstance, slot_index: int, inventory_index: int) -> bool:
	if unit == null or inventory_index < 0 or inventory_index >= augment_inventory.size():
		return false
		
	var target_aug = augment_inventory[inventory_index]
	if not unit.can_equip_augment(slot_index, target_aug):
		return false
		
	var existing_aug = unit.equipped_augments[slot_index]
	if existing_aug != null:
		# Swap into inventory slot
		augment_inventory[inventory_index] = existing_aug
		unit.equipped_augments[slot_index] = target_aug
	else:
		# Take from inventory and equip
		augment_inventory.remove_at(inventory_index)
		unit.equip_augment(slot_index, target_aug)
		
	recalculate_synergies()
	return true

func unequip_augment_to_inventory(unit: UnitInstance, slot_index: int) -> bool:
	if unit == null or augment_inventory.size() >= Constants.MAX_BENCH_AUGMENTS:
		return false
		
	var unequipped = unit.unequip_augment(slot_index)
	if unequipped != null:
		augment_inventory.append(unequipped)
		recalculate_synergies()
		return true
	return false

# Synergy Recalculation
func recalculate_synergies() -> SynergyReport:
	var repo = _get_repo()
	var factions_dict = repo.factions if repo != null else {}
	var tags_dict = repo.tags if repo != null else {}
	
	active_synergy_report = SynergyEngine.evaluate_crew(fielded_units, factions_dict, tags_dict)
	return active_synergy_report

# Combat Lock-In
func lock_in_crew() -> Dictionary:
	# Auto-deploy benched units into any open field slots
	while fielded_units.size() < get_max_field_units() and not benched_units.is_empty():
		deploy_unit_to_field(0)
		
	var validation = CrewValidator.validate_crew(fielded_units, current_district)
	if not validation.valid:
		return {
			"valid": false,
			"errors": validation.errors,
			"crew": []
		}
		
	recalculate_synergies()
	return {
		"valid": true,
		"errors": [],
		"crew": fielded_units,
		"report": active_synergy_report
	}

func _get_repo() -> Object:
	if _repo_cache == null:
		_repo_cache = DataRepoScript.new()
		_repo_cache.load_all_data("res://data")
	return _repo_cache
