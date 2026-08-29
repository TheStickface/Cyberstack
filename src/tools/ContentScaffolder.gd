class_name ContentScaffolder
extends RefCounted

## Utility to programmatically generate and save validated .tres resources for Cyberstack

static func create_unit(
	id: String,
	display_name: String,
	bio: String,
	role: Enums.UnitRole,
	faction: Enums.Faction,
	hp: float,
	ad: float,
	start_mana: float,
	max_mana: float,
	cost: int = 2
) -> UnitResource:
	var res = UnitResource.new()
	res.id = id
	res.display_name = display_name
	res.bio = bio
	res.role = role
	res.faction = faction
	res.base_max_health = hp
	res.base_attack_damage = ad
	res.base_starting_mana = start_mana
	res.base_max_mana = max_mana
	res.base_cost = cost
	return res

static func create_augment(
	id: String,
	display_name: String,
	description: String,
	tier: Enums.AugmentTier,
	slot_type: Enums.SlotType,
	tags: Array[Enums.AugmentTag],
	stat_modifiers: Dictionary,
	cost: int = 2,
	trigger_type: Enums.TriggerType = Enums.TriggerType.PASSIVE_STAT,
	trigger_effect_id: String = ""
) -> AugmentResource:
	var res = AugmentResource.new()
	res.id = id
	res.display_name = display_name
	res.description = description
	res.tier = tier
	res.slot_type = slot_type
	res.tags = tags
	res.stat_modifiers = stat_modifiers
	res.base_cost = cost
	res.trigger_type = trigger_type
	res.trigger_effect_id = trigger_effect_id
	return res

static func create_district(
	id: String,
	display_name: String,
	district_index: int,
	crew_cap: int,
	node_sequence: Array[Enums.EncounterType],
	is_final_boss: bool = false,
	theme_color: Color = Color(0, 0.95, 0.83)
) -> DistrictResource:
	var res = DistrictResource.new()
	res.id = id
	res.display_name = display_name
	res.district_index = district_index
	res.crew_capacity = crew_cap
	res.node_sequence = node_sequence
	res.is_final_boss_district = is_final_boss
	res.theme_color = theme_color
	return res

static func save_resource_to_disk(res: Resource, file_path: String) -> Error:
	var dir = file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	return ResourceSaver.save(res, file_path)
