class_name CrewManager
extends RefCounted

## Manages fielded operatives, bench reserves, augment inventory, and live synergy recalculation

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var fielded_units: Array[UnitInstance] = []
var benched_units: Array[UnitInstance] = []
var augment_inventory: Array[AugmentResource] = []

var current_district: int = 1
var active_synergy_report: SynergyReport = null

var _repo_cache: Object = null

func _init(p_district: int = 1, p_repo: Object = null) -> void:
	current_district = p_district
	_repo_cache = p_repo
	active_synergy_report = SynergyReport.new()

func get_max_field_units() -> int:
	return Constants.DISTRICT_CREW_LIMITS.get(current_district, 2)

# Unit Management
func add_unit(unit: UnitInstance) -> bool:
	if unit == null:
		return false
	var added = false
	if fielded_units.size() < get_max_field_units():
		fielded_units.append(unit)
		recalculate_synergies()
		added = true
	elif benched_units.size() < Constants.MAX_BENCH_UNITS:
		benched_units.append(unit)
		added = true
		
	if added:
		check_and_execute_combinations()
	return added

func add_unit_to_bench(unit: UnitInstance) -> bool:
	if unit == null or benched_units.size() >= Constants.MAX_BENCH_UNITS:
		return false
	benched_units.append(unit)
	check_and_execute_combinations()
	return true

## Core Star Combination Engine:
## 2 copies of Tier 1 combine into Tier 2 (★2)
## 3 copies of Tier 2 combine into Tier 3 (★3)
func check_and_execute_combinations() -> Array[Dictionary]:
	var combinations_made: Array[Dictionary] = []
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
		
	return combinations_made

func deploy_unit_to_field(bench_index: int) -> bool:
	if bench_index < 0 or bench_index >= benched_units.size():
		return false
	if fielded_units.size() >= get_max_field_units():
		return false
		
	var unit = benched_units[bench_index]
	benched_units.remove_at(bench_index)
	fielded_units.append(unit)
	recalculate_synergies()
	return true

func recall_unit_to_bench(field_index: int) -> bool:
	if field_index < 0 or field_index >= fielded_units.size():
		return false
	if benched_units.size() >= Constants.MAX_BENCH_UNITS:
		return false
		
	var unit = fielded_units[field_index]
	fielded_units.remove_at(field_index)
	benched_units.append(unit)
	recalculate_synergies()
	return true

func swap_field_and_bench(field_index: int, bench_index: int) -> bool:
	if field_index < 0 or field_index >= fielded_units.size():
		return false
	if bench_index < 0 or bench_index >= benched_units.size():
		return false
		
	var field_unit = fielded_units[field_index]
	var bench_unit = benched_units[bench_index]
	
	fielded_units[field_index] = bench_unit
	benched_units[bench_index] = field_unit
	recalculate_synergies()
	return true

func remove_unit(unit: UnitInstance) -> bool:
	var f_idx = fielded_units.find(unit)
	if f_idx != -1:
		fielded_units.remove_at(f_idx)
		recalculate_synergies()
		return true
		
	var b_idx = benched_units.find(unit)
	if b_idx != -1:
		benched_units.remove_at(b_idx)
		return true
		
	return false

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
