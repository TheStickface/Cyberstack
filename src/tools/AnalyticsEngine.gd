class_name AnalyticsEngine
extends RefCounted

## Statistical aggregator computing multi-user meta trends and balance KPIs

static func compute_overview(records: Array[TelemetryEvent]) -> Dictionary:
	var total = records.size()
	if total == 0:
		return {
			"total_runs": 0,
			"victories": 0,
			"defeats": 0,
			"win_rate": 0.0,
			"avg_duration": 0.0,
			"avg_gold_spent": 0.0
		}
		
	var wins = 0
	var total_dur = 0.0
	var total_gold = 0
	
	for r in records:
		if r.victory:
			wins += 1
		total_dur += r.duration_seconds
		total_gold += r.gold_spent
		
	return {
		"total_runs": total,
		"victories": wins,
		"defeats": total - wins,
		"win_rate": (float(wins) / float(total)) * 100.0,
		"avg_duration": total_dur / float(total),
		"avg_gold_spent": float(total_gold) / float(total)
	}

static func compute_operative_meta(records: Array[TelemetryEvent], repo: Object) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_runs = maxi(1, records.size())
	var all_units = repo.get_all_units()
	
	for unit in all_units:
		var picks = 0
		var wins = 0
		
		for r in records:
			if r.fielded_unit_ids.has(unit.id):
				picks += 1
				if r.victory:
					wins += 1
					
		var pick_rate = (float(picks) / float(total_runs)) * 100.0
		var win_rate = (float(wins) / float(maxi(1, picks))) * 100.0 if picks > 0 else 0.0
		
		result.append({
			"id": unit.id,
			"name": unit.display_name,
			"role": unit.get_role_name(),
			"faction": unit.get_faction_name(),
			"picks": picks,
			"pick_rate": pick_rate,
			"wins": wins,
			"win_rate": win_rate
		})
		
	# Sort by pick rate descending
	result.sort_custom(func(a, b): return a.picks > b.picks)
	return result

static func compute_augment_meta(records: Array[TelemetryEvent], repo: Object) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_runs = maxi(1, records.size())
	var all_augs = repo.get_all_augments()
	
	for aug in all_augs:
		var equips = 0
		var wins = 0
		
		for r in records:
			if r.equipped_augment_ids.has(aug.id):
				equips += 1
				if r.victory:
					wins += 1
					
		var equip_rate = (float(equips) / float(total_runs)) * 100.0
		var win_rate = (float(wins) / float(maxi(1, equips))) * 100.0 if equips > 0 else 0.0
		
		result.append({
			"id": aug.id,
			"name": aug.display_name,
			"tier": aug.get_tier_name(),
			"slot": Enums.role_to_string(aug.slot_type as int as Enums.UnitRole),
			"equips": equips,
			"equip_rate": equip_rate,
			"win_rate": win_rate
		})
		
	result.sort_custom(func(a, b): return a.equips > b.equips)
	return result

static func compute_mortality_curve(records: Array[TelemetryEvent]) -> Dictionary:
	var total = maxi(1, records.size())
	var deaths_by_district: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0}
	var victories = 0
	
	for r in records:
		if r.victory:
			victories += 1
		else:
			var d = clampi(r.district_index, 1, 4)
			deaths_by_district[d] = deaths_by_district.get(d, 0) + 1
			
	return {
		"d1_deaths": deaths_by_district[1],
		"d1_rate": (float(deaths_by_district[1]) / float(total)) * 100.0,
		"d2_deaths": deaths_by_district[2],
		"d2_rate": (float(deaths_by_district[2]) / float(total)) * 100.0,
		"d3_deaths": deaths_by_district[3],
		"d3_rate": (float(deaths_by_district[3]) / float(total)) * 100.0,
		"d4_deaths": deaths_by_district[4],
		"d4_rate": (float(deaths_by_district[4]) / float(total)) * 100.0,
		"victories": victories,
		"victory_rate": (float(victories) / float(total)) * 100.0
	}
