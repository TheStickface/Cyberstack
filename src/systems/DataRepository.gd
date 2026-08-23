extends Node

## Centralized registry and caching service for all static game resources

var units: Dictionary = {}          # id (String) -> UnitResource
var augments: Dictionary = {}       # id (String) -> AugmentResource
var factions: Dictionary = {}       # Faction (int) -> FactionResource
var tags: Dictionary = {}           # AugmentTag (int) -> TagResource
var districts: Dictionary = {}      # id (String) -> DistrictResource
var events: Dictionary = {}         # id (String) -> NarrativeEventResource

var is_loaded: bool = false

func _ready() -> void:
	load_all_data()

func load_all_data(base_path: String = "res://data") -> void:
	clear_all()
	_load_factions(base_path + "/factions")
	_load_tags(base_path + "/tags")
	_load_units(base_path + "/units")
	_load_augments(base_path + "/augments")
	_load_districts(base_path + "/districts")
	_load_events(base_path + "/events")
	is_loaded = true

func clear_all() -> void:
	units.clear()
	augments.clear()
	factions.clear()
	tags.clear()
	districts.clear()
	events.clear()
	is_loaded = false

# Registration APIs
func register_unit(unit_res: UnitResource) -> void:
	if unit_res and not unit_res.id.is_empty():
		units[unit_res.id] = unit_res

func register_augment(aug_res: AugmentResource) -> void:
	if aug_res and not aug_res.id.is_empty():
		augments[aug_res.id] = aug_res

func register_faction(fac_res: FactionResource) -> void:
	if fac_res and fac_res.faction_type != Enums.Faction.NONE:
		factions[fac_res.faction_type] = fac_res

func register_tag(tag_res: TagResource) -> void:
	if tag_res and tag_res.tag_type != Enums.AugmentTag.NONE:
		tags[tag_res.tag_type] = tag_res

func register_district(dist_res: DistrictResource) -> void:
	if dist_res and not dist_res.id.is_empty():
		districts[dist_res.id] = dist_res

func register_event(ev_res: NarrativeEventResource) -> void:
	if ev_res and not ev_res.id.is_empty():
		events[ev_res.id] = ev_res

# Lookup APIs
func get_unit(id: String) -> UnitResource:
	return units.get(id, null)

func get_all_units() -> Array[UnitResource]:
	var list: Array[UnitResource] = []
	for u in units.values():
		list.append(u as UnitResource)
	return list

func get_units_by_faction(faction: Enums.Faction) -> Array[UnitResource]:
	var result: Array[UnitResource] = []
	for u in units.values():
		var unit = u as UnitResource
		if unit.faction == faction:
			result.append(unit)
	return result

func get_units_by_role(role: Enums.UnitRole) -> Array[UnitResource]:
	var result: Array[UnitResource] = []
	for u in units.values():
		var unit = u as UnitResource
		if unit.role == role:
			result.append(unit)
	return result

func get_augment(id: String) -> AugmentResource:
	return augments.get(id, null)

func get_all_augments() -> Array[AugmentResource]:
	var list: Array[AugmentResource] = []
	for a in augments.values():
		list.append(a as AugmentResource)
	return list

func get_augments_by_tier(tier: Enums.AugmentTier) -> Array[AugmentResource]:
	var result: Array[AugmentResource] = []
	for a in augments.values():
		var aug = a as AugmentResource
		if aug.tier == tier:
			result.append(aug)
	return result

func get_augments_by_tag(tag: Enums.AugmentTag) -> Array[AugmentResource]:
	var result: Array[AugmentResource] = []
	for a in augments.values():
		var aug = a as AugmentResource
		if aug.has_tag(tag):
			result.append(aug)
	return result

func get_faction(faction: Enums.Faction) -> FactionResource:
	return factions.get(faction, null)

func get_tag(tag: Enums.AugmentTag) -> TagResource:
	return tags.get(tag, null)

func get_district(id: String) -> DistrictResource:
	return districts.get(id, null)

func get_all_districts() -> Array[DistrictResource]:
	var list: Array[DistrictResource] = []
	for d in districts.values():
		list.append(d as DistrictResource)
	return list

func get_normal_districts() -> Array[DistrictResource]:
	var result: Array[DistrictResource] = []
	for d in districts.values():
		var dist = d as DistrictResource
		if not dist.is_final_boss:
			result.append(dist)
	return result

func get_final_boss_districts() -> Array[DistrictResource]:
	var result: Array[DistrictResource] = []
	for d in districts.values():
		var dist = d as DistrictResource
		if dist.is_final_boss:
			result.append(dist)
	return result

## Draws a randomized run sequence from the district pool: `normal_count` distinct
## non-final districts (shuffled, no repeats within the run) followed by one random
## final-boss district. Returns an array of length <= normal_count + 1.
func draw_run_districts(normal_count: int) -> Array[DistrictResource]:
	var pool = get_normal_districts()
	pool.shuffle()

	var result: Array[DistrictResource] = []
	for i in range(mini(normal_count, pool.size())):
		result.append(pool[i])

	var finals = get_final_boss_districts()
	if not finals.is_empty():
		result.append(finals[randi() % finals.size()])

	return result

func get_event(id: String) -> NarrativeEventResource:
	return events.get(id, null)

func get_random_event() -> NarrativeEventResource:
	var list = events.values()
	if not list.is_empty():
		return list[randi() % list.size()] as NarrativeEventResource
	return null

# Internal loaders
func _load_factions(dir_path: String) -> void:
	var files = _scan_tres_files(dir_path)
	for path in files:
		var res = load(path)
		if res is FactionResource:
			register_faction(res)

func _load_tags(dir_path: String) -> void:
	var files = _scan_tres_files(dir_path)
	for path in files:
		var res = load(path)
		if res is TagResource:
			register_tag(res)

func _load_units(dir_path: String) -> void:
	var files = _scan_tres_files(dir_path)
	for path in files:
		var res = load(path)
		if res is UnitResource:
			register_unit(res)

func _load_augments(dir_path: String) -> void:
	var files = _scan_tres_files(dir_path)
	for path in files:
		var res = load(path)
		if res is AugmentResource:
			register_augment(res)

func _load_districts(dir_path: String) -> void:
	var files = _scan_tres_files(dir_path)
	for path in files:
		var res = load(path)
		if res is DistrictResource:
			register_district(res)

func _load_events(dir_path: String) -> void:
	var files = _scan_tres_files(dir_path)
	for path in files:
		var res = load(path)
		if res is NarrativeEventResource:
			register_event(res)

func _scan_tres_files(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				paths.append(dir_path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return paths
