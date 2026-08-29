class_name UnitInstance
extends RefCounted

## Runtime representation of a fielded or benched operative with equipped augments

var unit_resource: UnitResource = null
var instance_id: String = ""
var level: int = 1 # Legacy alias for tier
var star_level: int = 1 # 1 = Tier 1 (★), 2 = Tier 2 (★★), 3 = Tier 3 (★★★)

## 2x3 Tactical Grid placement: slot index 0..5
## Bottom Row (Row 1, Frontline): 0 (Left), 1 (Center), 2 (Right)
## Top Row (Row 0, Backline): 3 (Top Left - Dist 3), 4 (Top Center - Dist 2), 5 (Top Right - Dist 4)
var grid_slot: int = -1

static func slot_to_coords(slot: int) -> Vector2i:
	match slot:
		0: return Vector2i(1, 0) # Row 1, Col 0 (Bottom Left)
		1: return Vector2i(1, 1) # Row 1, Col 1 (Bottom Center)
		2: return Vector2i(1, 2) # Row 1, Col 2 (Bottom Right)
		3: return Vector2i(0, 0) # Row 0, Col 0 (Top Left)
		4: return Vector2i(0, 1) # Row 0, Col 1 (Top Center)
		5: return Vector2i(0, 2) # Row 0, Col 2 (Top Right)
		_: return Vector2i(-1, -1)

static func coords_to_slot(row: int, col: int) -> int:
	if row == 1:
		if col >= 0 and col <= 2:
			return col
	elif row == 0:
		match col:
			0: return 3 # Top Left
			1: return 4 # Top Center
			2: return 5 # Top Right
	return -1

func get_grid_row() -> int:
	return slot_to_coords(grid_slot).x

func get_grid_col() -> int:
	return slot_to_coords(grid_slot).y

func set_grid_coords(row: int, col: int) -> void:
	grid_slot = coords_to_slot(row, col)

func is_frontline() -> bool:
	return get_grid_row() == 1

func is_backline() -> bool:
	return get_grid_row() == 0


## 3 Augment slots: index 0 (Primary), index 1 (Secondary), index 2 (Passive)
var equipped_augments: Array[AugmentResource] = [null, null, null]


func get_star_string() -> String:
	match star_level:
		1: return "★"
		2: return "★★"
		3: return "★★★"
		_: return "★%d" % star_level

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
	
	# Scale core base stats by star level (Tier 1: 1.0x, Tier 2: 1.8x, Tier 3: 3.2x)
	var star_mult: float = 1.0
	match star_level:
		1: star_mult = 1.0
		2: star_mult = 1.8
		3: star_mult = 3.2
		_: star_mult = 1.0 + (float(star_level - 1) * 0.8)
		
	if stat_type == Enums.StatType.MAX_HEALTH or stat_type == Enums.StatType.ATTACK_DAMAGE or stat_type == Enums.StatType.ABILITY_POWER:
		base_val *= star_mult
	
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
