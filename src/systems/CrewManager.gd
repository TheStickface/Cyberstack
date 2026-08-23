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
func add_unit_to_bench(unit: UnitInstance) -> bool:
	if unit == null or benched_units.size() >= Constants.MAX_BENCH_UNITS:
		return false
	benched_units.append(unit)
	return true

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
