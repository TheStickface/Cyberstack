class_name CrewValidator
extends RefCounted

## Validates crew configuration, slot constraints, role adherence, and district scaling rules

static func validate_crew_size(crew: Array[UnitInstance], district_id: int = 1) -> Dictionary:
	var max_allowed: int = Constants.DISTRICT_CREW_LIMITS.get(district_id, 2)
	var current_size = crew.size()
	
	if current_size > max_allowed:
		return {
			"valid": false,
			"error": "Crew size (%d) exceeds District %d limit (%d units)." % [current_size, district_id, max_allowed]
		}
	return {"valid": true, "error": ""}

static func validate_unit_slots(unit: UnitInstance) -> Dictionary:
	if unit == null or unit.unit_resource == null:
		return {"valid": false, "errors": ["Unit or UnitResource is null"]}
	
	var errors: Array[String] = []
	var allowed_slots = unit.unit_resource.get_slot_types()
	
	for i in range(unit.equipped_augments.size()):
		var aug = unit.equipped_augments[i]
		if aug == null:
			continue
		
		if i >= allowed_slots.size():
			errors.append("Augment in invalid slot index %d for unit '%s'" % [i, unit.unit_resource.display_name])
			continue
			
		var slot_type = allowed_slots[i]
		if not aug.can_equip_in_slot(slot_type):
			errors.append("Augment '%s' (Slot: %s) cannot be equipped in slot %d (Requires: %s) on unit '%s'" % [
				aug.display_name,
				Enums.role_to_string(aug.slot_type as int as Enums.UnitRole), # or slot_type string
				i,
				str(slot_type),
				unit.unit_resource.display_name
			])
			
	return {
		"valid": errors.is_empty(),
		"errors": errors
	}

static func validate_crew(crew: Array[UnitInstance], district_id: int = 1) -> Dictionary:
	var all_errors: Array[String] = []
	var warnings: Array[String] = []
	
	# Size check
	var size_check = validate_crew_size(crew, district_id)
	if not size_check.valid:
		all_errors.append(size_check.error)
		
	if crew.is_empty():
		all_errors.append("Crew cannot be empty. Recruit and deploy at least 1 operative.")
		
	# Slot checks for each unit
	for unit in crew:
		var slot_check = validate_unit_slots(unit)
		if not slot_check.valid:
			all_errors.append_array(slot_check.errors)
			
	return {
		"valid": all_errors.is_empty(),
		"errors": all_errors,
		"warnings": warnings
	}
