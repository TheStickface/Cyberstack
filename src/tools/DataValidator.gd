extends SceneTree

## Headless CLI Tool: Scans and validates all resources in data/ for schema compliance, valid enums, and integrity.

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

func _init() -> void:
	print("========================================")
	print("   CYBERSTACK DATA VALIDATION TOOL      ")
	print("========================================")
	
	var errors_count = 0
	var warnings_count = 0
	
	var repo = DataRepoScript.new()
	repo.load_all_data("res://data")
	
	print("\n[+] Registered Factions: %d" % repo.factions.size())
	for f in repo.factions.keys():
		var fac: FactionResource = repo.factions[f]
		print("  - %s (ID: %s, Thresholds: %d)" % [fac.display_name, fac.id, fac.threshold_bonuses.size()])
		if fac.threshold_bonuses.is_empty():
			printerr("    [WARNING] Faction %s has no threshold bonuses configured!" % fac.display_name)
			warnings_count += 1
			
	print("\n[+] Registered Tags: %d" % repo.tags.size())
	for t in repo.tags.keys():
		var tag_res: TagResource = repo.tags[t]
		print("  - %s (ID: %s, Chains: %d)" % [tag_res.display_name, tag_res.id, tag_res.chain_bonuses.size()])
		if tag_res.chain_bonuses.is_empty():
			printerr("    [WARNING] Tag %s has no chain bonuses configured!" % tag_res.display_name)
			warnings_count += 1
			
	print("\n[+] Registered Units: %d" % repo.units.size())
	for u_id in repo.units.keys():
		var unit: UnitResource = repo.units[u_id]
		print("  - %s [%s | %s] (HP: %.0f, AD: %.0f, Mana: %.0f/%.0f)" % [
			unit.display_name,
			unit.get_role_name(),
			unit.get_faction_name(),
			unit.base_max_health,
			unit.base_attack_damage,
			unit.base_starting_mana,
			unit.base_max_mana
		])
		if unit.faction == Enums.Faction.NONE:
			printerr("    [ERROR] Unit %s has no faction assigned!" % unit.display_name)
			errors_count += 1
		if unit.base_max_health <= 0:
			printerr("    [ERROR] Unit %s has 0 or negative base health!" % unit.display_name)
			errors_count += 1

	print("\n[+] Registered Augments: %d" % repo.augments.size())
	for a_id in repo.augments.keys():
		var aug: AugmentResource = repo.augments[a_id]
		var tag_names: Array[String] = []
		for t in aug.tags:
			tag_names.append(Enums.tag_to_string(t))
		print("  - %s [%s Tier | %s] Tags: [%s]" % [
			aug.display_name,
			aug.get_tier_name(),
			Enums.role_to_string(aug.slot_type as int as Enums.UnitRole),
			", ".join(tag_names)
		])
		if aug.tags.is_empty():
			printerr("    [WARNING] Augment %s has no tags assigned!" % aug.display_name)
			warnings_count += 1

	print("\n[+] Registered Districts: %d" % repo.districts.size())
	for d_id in repo.districts.keys():
		var dist: DistrictResource = repo.districts[d_id]
		print("  - %s (ID: %s, Final Boss: %s, Nodes: %d)" % [
			dist.display_name,
			dist.id,
			str(dist.is_final_boss),
			dist.node_sequence.size()
		])
		if dist.node_sequence.is_empty():
			printerr("    [ERROR] District %s has empty node sequence!" % dist.display_name)
			errors_count += 1
	if repo.get_final_boss_districts().is_empty():
		printerr("    [ERROR] No final-boss district (is_final_boss = true) is registered!")
		errors_count += 1

	print("\n[+] Registered Narrative Events: %d" % repo.events.size())
	for e_id in repo.events.keys():
		var ev: NarrativeEventResource = repo.events[e_id]
		print("  - Event '%s' (Choices: %d)" % [ev.title, ev.choices.size()])
		if ev.choices.is_empty():
			printerr("    [WARNING] Event %s has no choices configured!" % ev.title)
			warnings_count += 1
			
	print("\n========================================")
	print("VALIDATION SUMMARY: %d Errors, %d Warnings" % [errors_count, warnings_count])
	print("========================================\n")
	
	if errors_count > 0:
		quit(1)
	else:
		quit(0)
