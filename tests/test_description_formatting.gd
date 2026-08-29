class_name TestDescriptionFormatting
extends RefCounted

## Coverage for the standardized augment/ability description formatting
## (see docs/superpowers/specs/2026-08-28-item-ability-description-standardization-design.md)

const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object

func _init() -> void:
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

# ---------------------------------------------------------------------------
# Enums helpers
# ---------------------------------------------------------------------------

func test_is_percent_stat() -> Dictionary:
	if not Enums.is_percent_stat(Enums.StatType.ATTACK_SPEED):
		return {"passed": false, "message": "ATTACK_SPEED should be a percent stat", "assertions": 1}
	if not Enums.is_percent_stat(Enums.StatType.CRIT_CHANCE):
		return {"passed": false, "message": "CRIT_CHANCE should be a percent stat", "assertions": 2}
	if not Enums.is_percent_stat(Enums.StatType.EVASION):
		return {"passed": false, "message": "EVASION should be a percent stat", "assertions": 3}
	if Enums.is_percent_stat(Enums.StatType.ARMOR):
		return {"passed": false, "message": "ARMOR should NOT be a percent stat", "assertions": 4}
	return {"passed": true, "assertions": 4}

func test_format_stat_value_flat() -> Dictionary:
	var result = Enums.format_stat_value(Enums.StatType.ARMOR, 12.0)
	if result != "+12":
		return {"passed": false, "message": "Expected '+12', got '%s'" % result, "assertions": 1}
	return {"passed": true, "assertions": 1}

func test_format_stat_value_percent() -> Dictionary:
	var result = Enums.format_stat_value(Enums.StatType.ATTACK_SPEED, 0.20)
	if result != "+20%":
		return {"passed": false, "message": "Expected '+20%%', got '%s'" % result, "assertions": 1}
	return {"passed": true, "assertions": 1}

func test_format_stat_value_negative() -> Dictionary:
	var flat = Enums.format_stat_value(Enums.StatType.SPEED, -15.0)
	if flat != "-15":
		return {"passed": false, "message": "Expected '-15', got '%s'" % flat, "assertions": 1}
	var pct = Enums.format_stat_value(Enums.StatType.ATTACK_SPEED, -0.25)
	if pct != "-25%":
		return {"passed": false, "message": "Expected '-25%%', got '%s'" % pct, "assertions": 2}
	return {"passed": true, "assertions": 2}

func test_trigger_to_string_all_values() -> Dictionary:
	var checked = 0
	for t in Enums.TriggerType.values():
		var s = Enums.trigger_to_string(t)
		if t == Enums.TriggerType.PASSIVE_STAT:
			if s != "":
				return {"passed": false, "message": "PASSIVE_STAT should map to empty string, got '%s'" % s, "assertions": checked + 1}
		else:
			if s.is_empty():
				return {"passed": false, "message": "TriggerType %d has no label" % t, "assertions": checked + 1}
		checked += 1
	return {"passed": true, "assertions": checked}

# ---------------------------------------------------------------------------
# AugmentResource helpers
# ---------------------------------------------------------------------------

func test_get_stat_lines_canonical_order() -> Dictionary:
	# rare_thermal_laser authors ABILITY_POWER(2) before ATTACK_SPEED(3) already,
	# so use a resource whose .tres authoring order is reversed vs enum order to
	# actually prove sorting happens rather than just echoing file order.
	var res = AugmentResource.new()
	res.stat_modifiers = {4: 12.0, 1: 32.0} # ARMOR(4) authored before ATTACK_DAMAGE(1)
	var lines = res.get_stat_lines()
	if lines != ["+32 Attack Damage", "+12 Armor"]:
		return {"passed": false, "message": "Expected canonical enum-ordinal order, got %s" % [lines], "assertions": 1}
	return {"passed": true, "assertions": 1}

func test_has_proc_and_proc_header() -> Dictionary:
	var passive = AugmentResource.new()
	passive.trigger_type = Enums.TriggerType.PASSIVE_STAT
	if passive.has_proc():
		return {"passed": false, "message": "PASSIVE_STAT augment should not have_proc()", "assertions": 1}
	if passive.get_proc_header() != "":
		return {"passed": false, "message": "Passive augment proc header should be empty", "assertions": 2}

	var proc = AugmentResource.new()
	proc.trigger_type = Enums.TriggerType.ON_ATTACK
	if not proc.has_proc():
		return {"passed": false, "message": "ON_ATTACK augment should have_proc()", "assertions": 3}
	if proc.get_proc_header() != "ON ATTACK":
		return {"passed": false, "message": "Expected 'ON ATTACK', got '%s'" % proc.get_proc_header(), "assertions": 4}
	return {"passed": true, "assertions": 4}

func test_get_proc_fragment_from_trigger_params() -> Dictionary:
	var cases = [
		[{"armor_pierce_pct": 0.20}, "Pierce 20% target armor"],
		[{"armor_melt_pct": 0.40}, "Melt 40% target armor"],
		[{"mana_drain": 15}, "Drain 15 mana from enemy"],
		[{"attack_speed_bonus": 0.15, "duration": 2.0}, "+15% Attack Speed for 2s"],
		[{"enemy_attack_speed_pct": -0.25}, "-25% enemy Attack Speed"],
		[{"shared_mana_pct": 0.35}, "Share 35% mana pool crew-wide"],
	]
	var n = 0
	for c in cases:
		var res = AugmentResource.new()
		res.trigger_type = Enums.TriggerType.ON_ATTACK
		res.trigger_params = c[0]
		res.description = "should not be used"
		var got = res.get_proc_fragment()
		n += 1
		if got != c[1]:
			return {"passed": false, "message": "params %s: expected '%s', got '%s'" % [c[0], c[1], got], "assertions": n}
	return {"passed": true, "assertions": n}

func test_get_proc_fragment_falls_back_to_literal_description() -> Dictionary:
	var res = AugmentResource.new()
	res.trigger_type = Enums.TriggerType.ON_KILL
	res.trigger_params = {}
	res.description = "Burst damage to nearby enemies"
	if res.get_proc_fragment() != "Burst damage to nearby enemies":
		return {"passed": false, "message": "Expected literal description fallback, got '%s'" % res.get_proc_fragment(), "assertions": 1}
	return {"passed": true, "assertions": 1}

func test_directional_helpers_augment_and_unit() -> Dictionary:
	var plain_aug = AugmentResource.new()
	if plain_aug.has_directional():
		return {"passed": false, "message": "Augment with NONE directional_target should not have_directional()", "assertions": 1}
	if plain_aug.get_directional_header() != "":
		return {"passed": false, "message": "Non-directional augment header should be empty", "assertions": 2}
	if not plain_aug.get_directional_stat_lines().is_empty():
		return {"passed": false, "message": "Non-directional augment stat lines should be empty", "assertions": 3}

	var dir_aug = AugmentResource.new()
	dir_aug.directional_target = Enums.GridDirection.ADJACENT
	dir_aug.directional_modifiers = {5: 80.0}
	if not dir_aug.has_directional():
		return {"passed": false, "message": "ADJACENT augment should have_directional()", "assertions": 4}
	if dir_aug.get_directional_header() != "ADJACENT":
		return {"passed": false, "message": "Expected 'ADJACENT', got '%s'" % dir_aug.get_directional_header(), "assertions": 5}
	if dir_aug.get_directional_stat_lines() != ["+80 Shield"]:
		return {"passed": false, "message": "Expected ['+80 Shield'], got %s" % [dir_aug.get_directional_stat_lines()], "assertions": 6}

	var dir_unit = UnitResource.new()
	dir_unit.directional_target = Enums.GridDirection.RIGHT
	dir_unit.directional_modifiers = {5: 150.0}
	if dir_unit.get_directional_header() != "RIGHT":
		return {"passed": false, "message": "Expected 'RIGHT', got '%s'" % dir_unit.get_directional_header(), "assertions": 7}
	if dir_unit.get_directional_stat_lines() != ["+150 Shield"]:
		return {"passed": false, "message": "Expected ['+150 Shield'], got %s" % [dir_unit.get_directional_stat_lines()], "assertions": 8}

	return {"passed": true, "assertions": 8}

# ---------------------------------------------------------------------------
# Augment golden table — the "Full mapping for all 20 augments" table in the spec
# ---------------------------------------------------------------------------

## id -> [description, proc_header, stat_lines, directional_header, directional_stat_lines]
##
## As of the tactical-grid feature (commit 21a9e96), 5 of these 20 also carry
## directional_target/directional_modifiers (a positional formation bonus,
## independent of the trigger/proc system). Where an augment now has BOTH a
## real trigger_type and empty trigger_params with no numeric magnitude in
## its (pre-standardization) description, its `description` here is a short
## qualitative proc tag, same as the two originally-qualitative Legendaries —
## see test_proc_augments_have_no_unbacked_numbers.
func _augment_golden() -> Dictionary:
	return {
		"common_kinetic_accelerator": ["", "", "+12 Attack Damage", "", []],
		"common_kinetic_plating": ["", "", "+60 Max Health, +8 Armor", "ADJACENT", ["+80 Shield"]],
		"common_neural_buffer": ["", "", "+60 Shield, +25 Starting Mana", "", []],
		"common_neural_link": ["", "", "+15 Ability Power, +15 Starting Mana", "", []],
		"common_thermal_blaster": ["", "", "+14 Attack Damage, +10 Ability Power", "", []],
		"common_thermal_core": ["", "", "+120 Max Health, +5 Armor", "", []],
		"common_viral_nanites": ["", "", "+10 Ability Power, +14% Attack Speed", "", []],
		"common_viral_spores": ["", "", "+140 Max Health, +8% Evasion", "", []],
		"rare_kinetic_overdrive": ["", "", "+25% Attack Speed, +16 Armor", "", []],
		"rare_thermal_laser": ["", "", "+28 Ability Power, +15% Attack Speed", "", []],
		"rare_kinetic_rail": ["", "ON ATTACK", "+32 Attack Damage, +15% Crit Chance", "", []],
		"rare_neural_daemon": ["", "ON ATTACK", "+30 Ability Power, +20 Starting Mana", "", []],
		"rare_viral_cascade": ["", "ON ALLY TAG TRIGGER", "+12% Attack Speed", "", []],
		"rare_neural_synapse": ["Synaptic burst at combat start", "ON COMBAT START", "+25 Starting Mana, +15 Speed", "ABOVE", ["+25 Starting Mana", "+10 Speed"]],
		"rare_thermal_exhaust": ["Thermal burn on ability cast", "ON ABILITY CAST", "+30 Ability Power, +15 Starting Mana", "SAME ROW", ["+25 Ability Power"]],
		"rare_viral_siphon": ["Leech HP from target", "ON ATTACK", "+120 Max Health, +18 Attack Damage, +10% Evasion", "ADJACENT", ["+80 Max Health"]],
		"legendary_kinetic_destroyer": ["Piercing burst to nearby enemies", "ON ATTACK", "+45 Attack Damage, +15 Armor", "FRONTLINE", ["+50 Attack Damage", "+15% Crit Chance"]],
		"legendary_neural_hive": ["", "ON ABILITY CAST", "+50 Ability Power, +30 Starting Mana", "", []],
		"legendary_neural_plague": ["Rot explosion on ability cast", "ON ABILITY CAST", "+150 Max Health, +45 Ability Power, +20 Starting Mana", "", []],
		"legendary_overclock_vanguard": ["Convert absorbed damage to speed", "ON COMBAT START", "+15% Attack Speed, +25 Armor, +180 Shield", "FRONTLINE", ["+15 Armor", "+100 Shield"]],
		"legendary_phantom_ledger": ["Crits grant credits and stealth", "ON ATTACK", "+35 Attack Damage, +20% Crit Chance, +15% Evasion", "", []],
		"legendary_thermal_supernova": ["", "ON ABILITY CAST", "+75 Ability Power", "", []],
		"legendary_viral_pandemic": ["", "ON KILL", "+40 Ability Power, +30% Attack Speed", "", []],
	}

## Proc fragment expected once trigger_params is populated, keyed the same as
## _augment_golden(). Only augments whose `description` is "" in the golden
## table (i.e. params-backed, not the hand-authored qualitative tags) need an
## entry here.
func _augment_proc_fragment_golden() -> Dictionary:
	return {
		"rare_kinetic_rail": "Pierce 20% target armor",
		"rare_neural_daemon": "Drain 15 mana from enemy",
		"rare_viral_cascade": "+15% Attack Speed for 2s",
		"legendary_neural_hive": "Share 35% mana pool crew-wide",
		"legendary_thermal_supernova": "Melt 50% target armor",
		"legendary_viral_pandemic": "-25% enemy Attack Speed",
	}

func test_augment_golden_table() -> Dictionary:
	var golden = _augment_golden()
	if repo.get_all_augments().size() != golden.size():
		return {"passed": false, "message": "Expected %d augments, repo has %d" % [golden.size(), repo.get_all_augments().size()], "assertions": 1}

	var proc_fragments = _augment_proc_fragment_golden()
	var n = 0
	for id in golden.keys():
		var aug: AugmentResource = repo.get_augment(id)
		n += 1
		if aug == null:
			return {"passed": false, "message": "Missing augment '%s'" % id, "assertions": n}

		var expected_desc: String = golden[id][0]
		var expected_header: String = golden[id][1]
		var expected_stats: String = golden[id][2]
		var expected_dir_header: String = golden[id][3]
		var expected_dir_stats: Array = golden[id][4]

		if aug.description != expected_desc:
			return {"passed": false, "message": "%s: description expected '%s', got '%s'" % [id, expected_desc, aug.description], "assertions": n}

		var expected_fragment: String = proc_fragments.get(id, expected_desc)
		if aug.get_proc_fragment() != expected_fragment:
			return {"passed": false, "message": "%s: get_proc_fragment() expected '%s', got '%s'" % [id, expected_fragment, aug.get_proc_fragment()], "assertions": n}

		if aug.get_proc_header() != expected_header:
			return {"passed": false, "message": "%s: proc header expected '%s', got '%s'" % [id, expected_header, aug.get_proc_header()], "assertions": n}

		var stat_line: String = ", ".join(aug.get_stat_lines())
		if stat_line != expected_stats:
			return {"passed": false, "message": "%s: stat lines expected '%s', got '%s'" % [id, expected_stats, stat_line], "assertions": n}

		if aug.get_directional_header() != expected_dir_header:
			return {"passed": false, "message": "%s: directional header expected '%s', got '%s'" % [id, expected_dir_header, aug.get_directional_header()], "assertions": n}

		if aug.get_directional_stat_lines() != expected_dir_stats:
			return {"passed": false, "message": "%s: directional stat lines expected %s, got %s" % [id, expected_dir_stats, aug.get_directional_stat_lines()], "assertions": n}

	return {"passed": true, "assertions": n}

func test_proc_augments_have_no_unbacked_numbers() -> Dictionary:
	# Proc augments whose description is a hand-authored qualitative tag (no
	# trigger_params magnitude anywhere in the data) must stay free of digits
	# so nobody can silently slip in a number with nothing backing it.
	var qualitative_ids = ["legendary_kinetic_destroyer", "rare_neural_synapse", "rare_thermal_exhaust", "rare_viral_siphon"]
	var n = 0
	for id in qualitative_ids:
		var aug: AugmentResource = repo.get_augment(id)
		n += 1
		if not aug.trigger_params.is_empty():
			return {"passed": false, "message": "%s should have empty trigger_params" % id, "assertions": n}
		var regex = RegEx.new()
		regex.compile("\\d")
		if regex.search(aug.description) != null:
			return {"passed": false, "message": "%s description '%s' contains a digit with no backing trigger_params" % [id, aug.description], "assertions": n}
	return {"passed": true, "assertions": n}

# ---------------------------------------------------------------------------
# Ability golden table — all 63 units
# ---------------------------------------------------------------------------

func _ability_golden() -> Dictionary:
	return {
		"ai_bastion": "240 Shield self, 100 Shield allies (4s)",
		"ai_byte": "130 AP dmg, -10 Armor (4s)",
		"ai_cipher": "3x 140 AP dmg (lowest-HP target)",
		"ai_dreadnought": "240 AP dmg (cone), blind nearby (2.5s)",
		"ai_glitch": "180 AP dmg, -30 mana",
		"ai_null_construct": "300 HP barrier, reflects 20% dmg",
		"ai_singularity": "350 AD/AP dmg, pull enemies inward, root (3s)",
		"ai_siphon": "220 HP heal (lowest-HP ally), cleanse debuffs",
		"ai_spindle": "170% AD dmg, burn 40 thermal dmg",
		"ai_worm": "180 AP dmg (3 random enemies) over 4s, spread on death",
		"bio_abomination": "320 toxic dmg (column)",
		"bio_chimera": "150 Shield self (4s)",
		"bio_fleshweaver": "heal 200 HP (2 adjacent allies)",
		"bio_gorgon": "80 physical dmg, stun (1.5s)",
		"bio_hydra": "heal 30% missing HP (3s)",
		"bio_leech": "drain 40 HP from target",
		"bio_manticore": "180 piercing dmg, -25% Attack Speed (target)",
		"bio_plague_doctor": "120 viral dmg over 4s (all frontline enemies)",
		"bio_symbiote": "heal 140 HP (lowest-HP ally)",
		"bio_viper": "110 physical dmg, 30 poison (3s)",
		"boss_ai_prime_overmind": "200 AP dmg (2 enemies), -30 mana",
		"boss_algo_arbitrageur": "230 AP dmg, reduce enemy Attack Damage",
		"boss_broker_prime": "260 dmg (highest-AD target), 100 Shield allies",
		"boss_chop_doc": "200 HP siphon (nearest enemy)",
		"boss_corp_commander": "320 piercing dmg (weakest enemy)",
		"boss_director_panopticon": "330 piercing dmg (highest-HP target)",
		"boss_dock_foreman": "200 dmg, 250 Shield self",
		"boss_foundry_overseer": "150 dmg, 300 Shield self",
		"boss_gala_security_chief": "280 Shield self + adjacent ally",
		"boss_ghost_daemon": "250 AP dmg, block mana gain (3s)",
		"boss_highway_reaper": "2x 260 dmg (bounce)",
		"boss_house_dealer": "250 HP heal self OR 260 AP dmg (random target)",
		"boss_machine_prophet": "200 Shield allies, 180 AP dmg",
		"boss_mindbreaker": "240 AP dmg, silence (3s)",
		"boss_nemesis_synthetic": "320 AP dmg (all enemies), triggers Phase 2 Singularity Surge below 35% HP",
		"boss_railmaster": "350 dmg, ignore 50% Armor",
		"boss_salvage_baron": "300 Shield self, 170 splash dmg",
		"boss_scrap_titan": "300 HP heal self, 160 area dmg",
		"boss_slum_enforcer": "180 dmg (frontline), 250 HP barrier self",
		"boss_static_warlord": "210 AP dmg, blind enemies (2s)",
		"boss_transit_warden": "220 AP dmg (2 fastest enemies)",
		"boss_warrant_bot": "320 Shield self, reflects 40 dmg",
		"boss_warren_overlord": "240 dmg, -15% Speed",
		"corp_apex": "250% AD dmg (line, all enemies)",
		"corp_auditor": "freeze target (2.5s), 160 AP dmg, +2 credits on kill",
		"corp_breacher": "stun frontline (2s), -15 Armor",
		"corp_commander": "200 HP barrier (adjacent allies)",
		"corp_deadeye": "300% AD dmg (line, all enemies)",
		"corp_director": "charm highest-dmg enemy (4s), 300 AP dmg",
		"corp_operative": "160% AD dmg (lowest-HP target)",
		"corp_patrol": "120 dmg, -25% enemy Attack Speed (3s)",
		"corp_sentinel": "-25% incoming dmg, crew (5s)",
		"corp_tactician": "+15 Armor, 150 Shield allies (5s)",
		"fixer_bouncer": "220% AD dmg, knockback + stun (2s)",
		"fixer_broker": "250 Shield (lowest-HP ally), +40% Attack Speed (highest-DPS ally)",
		"fixer_bruiser": "100 physical dmg, stun (1.5s)",
		"fixer_chemist": "160 AP dmg, -15 Armor (4s)",
		"fixer_dealer": "+30% Armor Penetration, +20% Crit Chance, allies (5s)",
		"fixer_doc": "260 HP heal, +25% Attack Speed (lowest-HP ally)",
		"fixer_hitman": "350% AD dmg, execute below 25% HP (non-boss)",
		"fixer_kingpin": "300 dmg (all enemies), +2 credits per kill",
		"fixer_scav": "150% AD dmg (primary), 50% AD dmg (adjacent)",
		"fixer_wiretap": "-30 mana (highest-mana enemy), 110 AP dmg, +1 credit on kill",
		"phantom_aegis": "untargetable (1.5s), reflect 50 dmg",
		"phantom_assassin": "teleport backline, 160 crit dmg",
		"phantom_bulwark": "120 Shield, +25% Evasion (3s)",
		"phantom_eidolon": "pull backline to center, 300 AP dmg",
		"phantom_mirage": "2 decoys distract 2 enemy attacks",
		"phantom_nightshade": "280 true dmg (lowest-HP enemy)",
		"phantom_nullifier": "silence target (2.5s), -25 mana",
		"phantom_spectre": "120 physical dmg, guaranteed crit",
		"phantom_whisper": "dispel debuffs (allies), +10 mana",
		"phantom_wraith": "-40% hit chance (target) (3s)",
		"runner_blitz": "taunt nearby, 200 Shield self (4s)",
		"runner_dash": "120 AP dmg (2 nearby enemies)",
		"runner_nexus": "220 AP dmg (all enemies), silence (3s)",
		"runner_overdrive": "+60% Attack Speed, +40 Armor, heal 30% dmg dealt (6s)",
		"runner_phantom": "untargetable (2s), 250% crit strike",
		"runner_rampart": "350 HP barrier, reflects 25% dmg",
		"runner_slasher": "3x 85% AD dmg, guaranteed crit (final hit)",
		"runner_spark": "140 AP dmg (2 nearby enemies), -20 mana",
		"runner_volt": "+40 mana, +35% Attack Speed (lowest-mana ally) (5s)",
		"street_ghost": "280 physical dmg (line)",
	}

func test_ability_golden_table() -> Dictionary:
	var golden = _ability_golden()
	var recruitable = repo.get_all_units().size()
	if recruitable != golden.size():
		return {"passed": false, "message": "Expected %d units, repo has %d" % [golden.size(), recruitable], "assertions": 1}

	var n = 0
	for id in golden.keys():
		var unit: UnitResource = repo.get_unit(id)
		n += 1
		if unit == null:
			return {"passed": false, "message": "Missing unit '%s'" % id, "assertions": n}
		if unit.ability_description != golden[id]:
			return {"passed": false, "message": "%s: expected '%s', got '%s'" % [id, golden[id], unit.ability_description], "assertions": n}
	return {"passed": true, "assertions": n}

# ---------------------------------------------------------------------------
# Numeric-preservation guard — every meaningful number from the pre-change
# prose must still appear somewhere in the rewritten fragment.
# ---------------------------------------------------------------------------

func _pre_change_ability_descriptions() -> Dictionary:
	return {
		"ai_bastion": "Projects an encrypted dome providing 240 Shield to itself and 100 Shield to adjacent allies for 4s.",
		"ai_byte": "Fires a binary logic pulse that deals 130 AP damage and reduces the target's armor by 10 for 4s.",
		"ai_cipher": "Fires 3 laser bursts that prioritize the lowest-health enemy for 140 AP damage each.",
		"ai_dreadnought": "Vents superheated coolant in a 360-degree cone, dealing 240 AP damage and blinding nearby enemies for 2.5s.",
		"ai_glitch": "Detonates digital logic bomb dealing 180 AP damage and draining 30 mana from targets.",
		"ai_null_construct": "Creates a 300 HP refractive barrier absorbing incoming damage and reflecting 20% back to attackers.",
		"ai_singularity": "Creates a micro-singularity that pulls all enemies inward, dealing 350 combined AD/AP damage and preventing movement for 3s.",
		"ai_siphon": "Repairs the most damaged ally for 220 health and removes all active debuffs.",
		"ai_spindle": "Focuses an ultraviolet laser dealing 170% AD damage and burning the target for 40 thermal damage.",
		"ai_worm": "Infects 3 random enemies with a logic bomb, dealing 180 AP damage over 4s and spreading to nearby foes upon death.",
		"bio_abomination": "Fires a devastating apex bio-laser column dealing 320 toxic damage.",
		"bio_chimera": "Reinforces chitinous plating, granting 150 Shield to self for 4s.",
		"bio_fleshweaver": "Rapidly reconstructs damaged organic tissue, healing 200 HP across 2 adjacent allies.",
		"bio_gorgon": "Slams the ground with calcified mass, dealing 80 physical damage and stunning for 1.5s.",
		"bio_hydra": "Triggers rapid cell regeneration, recovering 30% of missing HP over 3s.",
		"bio_leech": "Attaches parasitic viral tendrils, draining 40 HP from target.",
		"bio_manticore": "Launches a concentrated neurotoxin spine dealing 180 piercing damage and reducing target attack speed by 25%.",
		"bio_plague_doctor": "Vents a corrosive viral miasma dealing 120 viral damage over 4s to all frontline enemies.",
		"bio_symbiote": "Channels biological vitality to heal the lowest-HP ally for 140 HP.",
		"bio_viper": "Fires a venomous projectile dealing 110 physical damage and 30 poison over 3s.",
		"boss_ai_prime_overmind": "Overloads hostile cyberware, dealing 200 AP damage to 2 enemies and draining 30 mana.",
		"boss_algo_arbitrageur": "Liquidates enemy assets, dealing 230 AP damage and reducing enemy attack damage.",
		"boss_broker_prime": "Marks the highest-AD enemy, dealing 260 damage and granting allies 100 shield.",
		"boss_chop_doc": "Siphons 200 HP from the nearest operative to repair damaged cyberware.",
		"boss_corp_commander": "Calls down an orbital strike dealing 320 piercing damage to the weakest enemy operative.",
		"boss_director_panopticon": "Focuses total surveillance array, dealing 330 piercing damage to highest-HP enemy.",
		"boss_dock_foreman": "Drops heavy freight container dealing 200 damage and granting 250 shield.",
		"boss_foundry_overseer": "Superheats the floor, dealing 150 damage and generating a 300 HP thermal shield.",
		"boss_gala_security_chief": "Deploys corporate aegis field granting 280 shield to self and adjacent ally.",
		"boss_ghost_daemon": "Corrupts operative code, dealing 250 AP damage and preventing mana gain for 3s.",
		"boss_highway_reaper": "Fires accelerated sniper round bouncing between 2 targets for 260 damage each.",
		"boss_house_dealer": "Gambles on luck: heals self for 250 HP or deals 260 AP damage to a random target.",
		"boss_machine_prophet": "Channels digital psalm granting 200 shield to all allies and dealing 180 AP damage.",
		"boss_mindbreaker": "Shocks the enemy mind, dealing 240 AP damage and silencing ability charge for 3s.",
		"boss_nemesis_synthetic": "Unleashes a catastrophic singularity burst dealing 320 AP damage across all enemies.",
		"boss_railmaster": "Fires a high-caliber slug dealing 350 damage that ignores 50% target armor.",
		"boss_salvage_baron": "Slams submersible plating, gaining 300 shield and dealing 170 splash damage.",
		"boss_scrap_titan": "Overclocks scrap core, regenerating 300 HP and dealing 160 area damage.",
		"boss_slum_enforcer": "Strikes the frontline for 180 damage and deploys a 250 HP kinetic barrier to self.",
		"boss_static_warlord": "Discharges electromagnetic static dealing 210 AP damage and blinding enemies for 2s.",
		"boss_transit_warden": "Detonates an electromagnetic pulse dealing 220 AP damage to 2 fastest enemies.",
		"boss_warrant_bot": "Deploys heavy riot barrier gaining 320 shield and reflecting 40 damage.",
		"boss_warren_overlord": "Summons hidden ambush dealing 240 damage and applying 15% speed slow.",
		"corp_apex": "Charges a railgun beam penetrating all enemies in a line for 250% Attack Damage.",
		"corp_auditor": "Freezes target enemy for 2.5s, dealing 160 AP damage and siphoning 2 credits on victory.",
		"corp_breacher": "Stamps the ground with pneumatic force, stunning all frontline enemies for 2s and shattering 15 armor.",
		"corp_commander": "Broadcasts tactical telemetry, deploying a 200 HP barrier to all adjacent allies.",
		"corp_deadeye": "Fires a penetrating beam that pierces through all enemies in a line, dealing 300% AD damage.",
		"corp_director": "Dominates the highest-damage enemy, forcing them to attack their own allies for 4s while taking 300 AP damage.",
		"corp_operative": "Locks onto the lowest-health enemy, firing a high-velocity tracer round for 160% AD damage.",
		"corp_patrol": "Fires a sonic pulse dealing 120 damage and slowing enemy attack speed by 25% for 3s.",
		"corp_sentinel": "Plants heavy energy shield, reducing incoming crew damage by 25% for 5s.",
		"corp_tactician": "Calls down a corporate supply beam granting all allies +15 Armor and 150 Shield for 5s.",
		"fixer_bouncer": "Lands a brutal kinetic punch that knocks back the target, stunning them for 2s and dealing 220% AD damage.",
		"fixer_broker": "Supplies the lowest health ally with 250 shield and hypercharges highest DPS ally with +40% attack speed.",
		"fixer_bruiser": "Strikes the ground with hydraulic force, stunning the target for 1.5s and dealing 100 Physical Damage.",
		"fixer_chemist": "Lobs an acid flask that coats enemies in a corrosive haze, dealing 160 AP damage and reducing armor by 15 for 4s.",
		"fixer_dealer": "Supplies all allies with armor-piercing ammunition, granting +30% Armor Penetration and +20% Crit Chance for 5s.",
		"fixer_doc": "Injects the lowest-health ally with concentrated adrenaline, restoring 260 health and granting +25% Attack Speed.",
		"fixer_hitman": "Fires a suppressed lethal shot dealing 350% AD damage. Instantly executes non-boss targets below 25% health.",
		"fixer_kingpin": "Commands a syndicate drive-by strike, dealing 300 combined damage to all enemies and granting 2 credits per enemy eliminated.",
		"fixer_scav": "Fires a canister of rusted ball-bearings dealing 150% AD damage to the primary target and 50% to adjacent enemies.",
		"fixer_wiretap": "Siphons 30 mana from the highest mana enemy, dealing 110 AP damage and generating 1 bonus credit on kill.",
		"phantom_aegis": "Enters a phase-shifted state for 1.5s, becoming untargetable and reflecting 50 damage back to attackers.",
		"phantom_assassin": "Teleports into the enemy backline, unleashing a lethal strike for 160 critical damage.",
		"phantom_bulwark": "Deploys a localized phase barrier granting 120 Shield and +25% Evasion for 3s.",
		"phantom_eidolon": "Generates a deep-net singularity that drags all backline enemies to the center, dealing 300 AP damage.",
		"phantom_mirage": "Projects 2 solid-light holographic decoys that distract 2 incoming enemy attacks.",
		"phantom_nightshade": "Strikes from the void, executing the lowest-HP enemy for 280 true damage.",
		"phantom_nullifier": "Releases a black-ice pulse that silences the target for 2.5s and drains 25 mana.",
		"phantom_spectre": "Fires a silent particle bolt dealing 120 physical damage with guaranteed critical strike.",
		"phantom_whisper": "Emits a tactical blackout wave that dispels debuffs across all allies and restores 10 mana.",
		"phantom_wraith": "Injects a sensor-scrambling glitch into the target, reducing their hit chance by 40% for 3s.",
		"runner_blitz": "Dashes forward, taunting nearby enemies and granting a 200 HP kinetic shield for 4s.",
		"runner_dash": "Surges with electrical current, delivering a shockwave dealing 120 AP damage to 2 nearby enemies.",
		"runner_nexus": "Broadcasts a sensory overload wave dealing 220 AP damage to all enemies and silencing their abilities for 3s.",
		"runner_overdrive": "Enters maximum overdrive for 6s: gains +60% Attack Speed, +40 Armor, and heals for 30% of all damage dealt.",
		"runner_phantom": "Creates a holographic clone, becoming untargetable for 2s while delivering a 250% critical strike.",
		"runner_rampart": "Slams down a riot barrier, absorbing 350 incoming damage and reflecting 25% back as kinetic shrapnel.",
		"runner_slasher": "Unleashes 3 rapid strikes dealing 85% AD each with a guaranteed critical hit on the final slash.",
		"runner_spark": "Fires an electric chain that shocks 2 nearby enemies for 140 AP damage and drains 20 mana.",
		"runner_volt": "Surges 40 mana to the lowest-mana ally and increases their attack speed by 35% for 5s.",
		"street_ghost": "Fires high-velocity piercing round dealing 280 physical damage in a straight line.",
	}

# Numbers that are decorative/structural in the source prose (e.g. "360-degree"
# describes the cone shape, not a balance value) and are deliberately dropped
# when the shape becomes a bare "(cone)" qualifier. Anything not listed here
# must survive the rewrite.
func _decorative_number_exceptions() -> Dictionary:
	return {
		"ai_dreadnought": ["360"],
	}

func test_numeric_preservation_across_all_units() -> Dictionary:
	var old_map = _pre_change_ability_descriptions()
	var new_map = _ability_golden()
	var exceptions = _decorative_number_exceptions()
	var regex = RegEx.new()
	regex.compile("\\d+(?:\\.\\d+)?%?")

	var n = 0
	for id in old_map.keys():
		n += 1
		var old_tokens: Array[String] = []
		for m in regex.search_all(old_map[id]):
			old_tokens.append(m.get_string())
		# Consume longest tokens first: a short token like "2" (from "for 2s")
		# must not cannibalize a digit out of a longer token like "220%" that
		# happens to share a leading digit, or the longer token's search
		# below would spuriously fail against its own mutilated remainder.
		old_tokens.sort_custom(func(a, b): return a.length() > b.length())

		var skip: Array = exceptions.get(id, [])
		var new_text: String = new_map.get(id, "")
		var remaining = new_text

		for tok in old_tokens:
			if skip.has(tok):
				continue
			var idx = remaining.find(tok)
			if idx == -1:
				return {"passed": false, "message": "%s: number '%s' from old text missing in new text '%s'" % [id, tok, new_text], "assertions": n}
			# consume this occurrence so a repeated number in `old` requires a
			# repeated occurrence in `new` too, not just one shared substring
			remaining = remaining.substr(0, idx) + remaining.substr(idx + tok.length())

	return {"passed": true, "assertions": n}

# ---------------------------------------------------------------------------
# Directional formation passives. The tactical-grid feature (commit 21a9e96)
# gave 15 units a directional_target/directional_modifiers pair — 9 that were
# added alongside this standardization pass (fixed up directly) plus 6 that
# were already present on disk and were missed in the first pass of this
# change (caught in code review — see git history). directional_passive_description
# becomes a short name tag (it also doubles as a combat-log source tag, see
# CrewManager._apply_directional_mods) — the numbers live in
# directional_modifiers and are rendered via get_directional_stat_lines().
#
# fixer_broker's directional_modifiers is fixed here too: it was authored as
# {4: 10.0, 9: 0.10} ("+10 Armor" correct, but key 9 is SPEED, a flat stat —
# stored 0.10 would render as "+0"). The passive's own text says "+10%
# Evasion", i.e. key 10 (EVASION, percent-scaled). Corrected to {4: 10.0,
# 10: 0.10} as part of this same drift-elimination pass.
#
# The count check in test_unit_directional_golden_table_is_complete guards
# against exactly the kind of gap that let 6 units slip through unnoticed:
# it fails loudly if a unit has directional_target set but isn't in this table.
# ---------------------------------------------------------------------------

func _unit_directional_golden() -> Dictionary:
	return {
		"ai_bastion": ["Hard-Light Canopy", "ABOVE", ["+160 Shield"]],
		"ai_cipher": ["Subroutine Overclock", "SAME ROW", ["+20 Ability Power"]],
		"ai_siphon": ["Energy Leech Relay", "ADJACENT", ["+80 Max Health"]],
		"bio_abomination": ["Apex Pheromones", "ALL UNITS", ["+15 Attack Damage", "+10% Attack Speed"]],
		"bio_chimera": ["Subdermal Mesh", "ABOVE", ["+80 Max Health"]],
		"bio_fleshweaver": ["Tissue Regeneration", "ADJACENT", ["+15% Attack Speed"]],
		"bio_gorgon": ["Calcified Wall", "FRONTLINE", ["+12 Armor"]],
		"bio_hydra": ["Hydra Vitality", "FRONTLINE", ["+150 Max Health", "+10 Armor"]],
		"bio_leech": ["Spore Vector", "ADJACENT", ["+10 Ability Power"]],
		"bio_manticore": ["Predator Focus", "SAME ROW", ["+12% Crit Chance"]],
		"bio_plague_doctor": ["Toxic Aura", "BELOW", ["+15 Ability Power"]],
		"bio_symbiote": ["Symbiotic Pulse", "ADJACENT", ["+60 Max Health"]],
		"bio_viper": ["Venom Coating", "SAME ROW", ["+10 Attack Damage"]],
		"corp_breacher": ["Frontline Breacher", "FRONTLINE", ["+120 Max Health", "+20 Armor"]],
		"corp_deadeye": ["Elevated Perch", "BACKLINE", ["+20 Attack Damage", "+15% Crit Chance"]],
		"corp_operative": ["Tactical Uplink", "SAME ROW", ["+12% Attack Speed"]],
		"corp_sentinel": ["Aegis Phalanx", "RIGHT", ["+150 Shield"]],
		"fixer_bouncer": ["VIP Bodyguard", "RIGHT", ["+180 Shield"]],
		"fixer_broker": ["Contract Risk Hedge", "ADJACENT", ["+10 Armor", "+10% Evasion"]],
		"fixer_doc": ["Field Triage", "ADJACENT", ["+100 Max Health"]],
		"phantom_aegis": ["Aegis Cloak", "FRONTLINE", ["+15 Armor", "+10% Evasion"]],
		"phantom_assassin": ["Ambush Stance", "BACKLINE", ["+15% Crit Chance"]],
		"phantom_bulwark": ["Phase Distortion", "FRONTLINE", ["+10% Evasion"]],
		"phantom_eidolon": ["Singularity Core", "ALL UNITS", ["+25 Ability Power", "+15 Starting Mana"]],
		"phantom_mirage": ["Holo Projection", "ALL UNITS", ["+10% Evasion"]],
		"phantom_nightshade": ["Void Resonance", "SAME ROW", ["+20 Attack Damage", "+15% Crit Chance"]],
		"phantom_nullifier": ["Null Field", "ADJACENT", ["+15 Ability Power"]],
		"phantom_spectre": ["Spectre Sight", "SAME ROW", ["+8% Crit Chance"]],
		"phantom_whisper": ["Sub-Net Frequency", "SAME ROW", ["+10 Starting Mana"]],
		"phantom_wraith": ["Wraith Step", "ADJACENT", ["+10 Speed"]],
		"runner_nexus": ["Column Mesh Link", "SAME COLUMN", ["+20 Starting Mana"]],
		"runner_phantom": ["Shadow Infiltration", "BACKLINE", ["+15% Crit Chance", "+15 Speed"]],
		"runner_rampart": ["Junk Bastion", "ADJACENT", ["+140 Shield"]],
		"runner_slasher": ["Flank Cutter", "LEFT", ["+16 Attack Damage"]],
		"street_ghost": ["Backline Ghosting", "BACKLINE", ["+15 Attack Damage", "+15 Speed"]],
	}

## Fails loudly if any unit on disk has directional_target set but isn't
## covered by _unit_directional_golden() — this is the check that would have
## caught the 6-unit gap immediately instead of leaving it for code review.
func test_unit_directional_golden_table_is_complete() -> Dictionary:
	var golden = _unit_directional_golden()
	var actual_directional_ids: Array[String] = []
	for unit in repo.get_all_units():
		if unit.has_directional():
			actual_directional_ids.append(unit.id)

	if actual_directional_ids.size() != golden.size():
		return {"passed": false, "message": "Expected %d units with directional_target set, found %d: %s" % [golden.size(), actual_directional_ids.size(), actual_directional_ids], "assertions": 1}

	for id in actual_directional_ids:
		if not golden.has(id):
			return {"passed": false, "message": "Unit '%s' has directional_target set but is missing from _unit_directional_golden()" % id, "assertions": 1}

	return {"passed": true, "assertions": 1}

func test_unit_directional_golden_table() -> Dictionary:
	var golden = _unit_directional_golden()
	var n = 0
	for id in golden.keys():
		var unit: UnitResource = repo.get_unit(id)
		n += 1
		if unit == null:
			return {"passed": false, "message": "Missing unit '%s'" % id, "assertions": n}

		var expected_desc: String = golden[id][0]
		var expected_header: String = golden[id][1]
		var expected_stats: Array = golden[id][2]

		if unit.directional_passive_description != expected_desc:
			return {"passed": false, "message": "%s: directional_passive_description expected '%s', got '%s'" % [id, expected_desc, unit.directional_passive_description], "assertions": n}

		if unit.get_directional_header() != expected_header:
			return {"passed": false, "message": "%s: directional header expected '%s', got '%s'" % [id, expected_header, unit.get_directional_header()], "assertions": n}

		if unit.get_directional_stat_lines() != expected_stats:
			return {"passed": false, "message": "%s: directional stat lines expected %s, got %s" % [id, expected_stats, unit.get_directional_stat_lines()], "assertions": n}

	return {"passed": true, "assertions": n}
