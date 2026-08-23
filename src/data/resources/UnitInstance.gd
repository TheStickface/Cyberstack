class_name UnitInstance
extends RefCounted

## Runtime representation of a fielded or benched operative with equipped augments

var unit_resource: UnitResource = null
var instance_id: String = ""
var level: int = 1 # Tier / veteran level (1 = Standard, 2 = Veteran, etc.)

## 3 Augment slots: index 0 (Primary), index 1 (Secondary), index 2 (Passive)
var equipped_augments: Array[AugmentResource] = [null, null, null]

func _init(p_unit_res: UnitResource = null) -> void:
	unit_resource = p_unit_res
	instance_id = str(ResourceUID.create_id()) if ResourceUID.has_method("create_id") else str(randi())

func get_slot_type(slot_index: int) -> Enums.SlotType:
	if unit_resource == null:
		return Enums.SlotType.PASSIVE
	var slots = unit_resource.get_slot_types()
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index]
	return Enums.SlotType.PASSIVE

func can_equip_augment(slot_index: int, augment: AugmentResource) -> bool:
	if augment == null:
		return false
	if slot_index < 0 or slot_index >= Constants.MAX_AUGMENT_SLOTS_PER_UNIT:
		return false
	var target_slot_type = get_slot_type(slot_index)
	return augment.can_equip_in_slot(target_slot_type)

func equip_augment(slot_index: int, augment: AugmentResource) -> bool:
	if not can_equip_augment(slot_index, augment):
		return false
	equipped_augments[slot_index] = augment
	return true

func unequip_augment(slot_index: int) -> AugmentResource:
	if slot_index < 0 or slot_index >= equipped_augments.size():
		return null
	var removed = equipped_augments[slot_index]
	equipped_augments[slot_index] = null
	return removed

func get_equipped_augments() -> Array[AugmentResource]:
	var result: Array[AugmentResource] = []
	for aug in equipped_augments:
		if aug != null:
			result.append(aug)
	return result

func get_all_tags() -> Array[Enums.AugmentTag]:
	var tags: Array[Enums.AugmentTag] = []
	for aug in equipped_augments:
		if aug != null:
			for t in aug.tags:
				tags.append(t)
	return tags

## Calculates cumulative stat combining base unit stats, equipped augment modifiers, and global crew bonuses
func calculate_effective_stat(stat_type: Enums.StatType, global_modifiers: Dictionary = {}) -> float:
	if unit_resource == null:
		return 0.0
	
	var base_val: float = 0.0
	match stat_type:
		Enums.StatType.MAX_HEALTH: base_val = unit_resource.base_max_health
		Enums.StatType.ATTACK_DAMAGE: base_val = unit_resource.base_attack_damage
		Enums.StatType.ABILITY_POWER: base_val = unit_resource.base_ability_power
		Enums.StatType.ATTACK_SPEED: base_val = unit_resource.base_attack_speed
		Enums.StatType.ARMOR: base_val = unit_resource.base_armor
		Enums.StatType.SHIELD: base_val = unit_resource.base_shield
		Enums.StatType.STARTING_MANA: base_val = unit_resource.base_starting_mana
		Enums.StatType.MAX_MANA: base_val = unit_resource.base_max_mana
		Enums.StatType.SPEED: base_val = unit_resource.base_speed
		Enums.StatType.CRIT_CHANCE: base_val = unit_resource.base_crit_chance
		Enums.StatType.EVASION: base_val = unit_resource.base_evasion
	
	# Apply equipped augment modifiers
	var flat_mod: float = 0.0
	var pct_mod: float = 0.0
	for aug in equipped_augments:
		if aug != null and aug.stat_modifiers.has(stat_type):
			var mod_val = float(aug.stat_modifiers[stat_type])
			if stat_type == Enums.StatType.ATTACK_SPEED or stat_type == Enums.StatType.CRIT_CHANCE or stat_type == Enums.StatType.EVASION:
				# Typically percentage values (e.g. 0.15 for +15%)
				flat_mod += mod_val
			else:
				flat_mod += mod_val
	
	# Apply global synergy bonuses if provided
	if global_modifiers.has(stat_type):
		flat_mod += float(global_modifiers[stat_type])
		
	return base_val + flat_mod
