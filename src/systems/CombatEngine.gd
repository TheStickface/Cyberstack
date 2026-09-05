class_name CombatEngine
extends RefCounted

## Pure, headless combat simulation engine shared between real-time CombatMockArena and BalanceSimulator.
## Executes combat at sub-frame precision (dt = 1.0 / 60.0 by default) with fractional remainder carryover.

class CombatantState extends RefCounted:
	var unit: UnitInstance = null
	var is_player: bool = true
	var grid_slot: int = 0
	var grid_row: int = 0
	var grid_col: int = 0
	var max_hp: float = 500.0
	var current_hp: float = 500.0
	var shield: float = 0.0
	var max_mana: float = 100.0
	var current_mana: float = 0.0
	var attack_damage: float = 40.0
	var ability_power: float = 20.0
	var attack_speed: float = 1.0 # Attacks per second
	var crit_chance: float = 0.05
	var armor: float = 20.0
	var evasion: float = 0.0
	var attack_timer: float = 0.0
	var alive: bool = true
	var active_conduit_id: String = ""
	var slot_doctrine_id: String = ""
	var retaliation_icd: float = 0.0
	var enraged: bool = false
	var has_enrage: bool = false
	var healing_mult: float = 1.0
	var active_dots: Array[Dictionary] = []
	
	# UI Hooks (nullable in headless simulation)
	var box_panel: PanelContainer = null
	var hp_bar: ProgressBar = null
	var hp_label: Label = null
	var mana_bar: ProgressBar = null
	var status_label: Label = null
	var formation_label: Label = null


# --- CREATION & SETUP --------------------------------------------------------

static func create_combatant(unit: UnitInstance, is_player: bool, slot_idx: int = 0, formation_bonuses: Dictionary = {}, district_id: int = 1, is_boss: bool = false, synergy_report: SynergyReport = null) -> CombatantState:
	var state = CombatantState.new()
	state.unit = unit
	state.is_player = is_player
	state.grid_slot = slot_idx
	var coords = UnitInstance.slot_to_coords(slot_idx)
	state.grid_row = coords.x
	state.grid_col = coords.y
	
	if unit != null:
		state.max_hp = unit.calculate_effective_stat(Enums.StatType.MAX_HEALTH)
		state.current_hp = state.max_hp
		state.attack_damage = unit.calculate_effective_stat(Enums.StatType.ATTACK_DAMAGE)
		state.ability_power = unit.calculate_effective_stat(Enums.StatType.ABILITY_POWER)
		var spd = unit.calculate_effective_stat(Enums.StatType.SPEED)
		state.attack_speed = clampf(spd / 50.0, 0.6, 2.5)
		state.crit_chance = unit.calculate_effective_stat(Enums.StatType.CRIT_CHANCE)
		state.armor = unit.calculate_effective_stat(Enums.StatType.ARMOR)
		state.evasion = unit.calculate_effective_stat(Enums.StatType.EVASION)

		# Apply active SynergyReport bonuses for player squad if provided
		if is_player and synergy_report != null:
			var faction = unit.unit_resource.faction if unit.unit_resource else Enums.Faction.NONE
			for f_id in synergy_report.faction_counts:
				var count = synergy_report.faction_counts[f_id]
				if f_id == faction:
					if f_id == Enums.Faction.STREET_RUNNERS:
						if count >= 2: state.attack_speed *= 1.15
						if count >= 4: state.attack_speed *= 1.25; state.crit_chance += 0.10
					elif f_id == Enums.Faction.CORP_ENFORCERS:
						if count >= 2: state.armor += 25.0
						if count >= 4: state.armor += 40.0; state.max_hp += 150.0; state.current_hp += 150.0
					elif f_id == Enums.Faction.ROGUE_AIS:
						if count >= 2: state.ability_power += 20.0
						if count >= 4: state.ability_power += 35.0; state.max_mana = maxf(50.0, state.max_mana - 20.0)
					elif f_id == Enums.Faction.BIO_HACKERS:
						if count >= 2: state.max_hp += 120.0; state.current_hp += 120.0
						if count >= 4: state.max_hp += 200.0; state.current_hp += 200.0; state.evasion += 0.10
					elif f_id == Enums.Faction.NET_PHANTOMS:
						if count >= 2: state.evasion += 0.15
						if count >= 4: state.evasion += 0.20; state.crit_chance += 0.15
					elif f_id == Enums.Faction.FIXERS:
						if count >= 2: state.shield += 80.0
						if count >= 4: state.shield += 150.0; state.attack_damage += 15.0

		# Integrate formation auras, intrinsic socket doctrines, and tactical conduits
		if formation_bonuses.has(unit):
			var b = formation_bonuses[unit]
			state.max_hp += b.get("max_health_bonus", 0.0)
			state.current_hp = state.max_hp
			state.shield += b.get("shield_bonus", 0.0)
			state.attack_damage += b.get("attack_damage_bonus", 0.0)
			state.ability_power += b.get("ability_power_bonus", 0.0)
			state.attack_speed *= (1.0 + b.get("attack_speed_bonus", 0.0))
			state.crit_chance += b.get("crit_bonus", 0.0)
			state.armor += b.get("armor_bonus", 0.0)
			state.evasion += b.get("evasion_bonus", 0.0)
			state.current_mana = clampf(state.current_mana + b.get("starting_mana_bonus", 0.0), 0.0, state.max_mana)
			state.active_conduit_id = b.get("active_conduit_id", "")
			state.slot_doctrine_id = b.get("slot_doctrine_id", "")
	else:
		state.max_hp = 450.0
		state.current_hp = 450.0
		state.attack_damage = 35.0
		state.ability_power = 20.0
		state.attack_speed = 1.0
		state.crit_chance = 0.05
		state.armor = 20.0
		state.evasion = 0.0

	# Scale enemy combatants by district progression and boss tier
	if not is_player:
		var scaling = Constants.DISTRICT_ENEMY_SCALING.get(district_id, {"hp_mult": 1.0, "dmg_mult": 1.0})
		state.max_hp *= scaling.get("hp_mult", 1.0)
		state.current_hp = state.max_hp
		state.attack_damage *= scaling.get("dmg_mult", 1.0)
		state.ability_power *= scaling.get("dmg_mult", 1.0)
		if is_boss:
			state.max_hp *= 1.35
			state.current_hp = state.max_hp
			state.attack_damage *= 1.20
			state.has_enrage = true

	# Slight desync for natural autobattler flow
	state.attack_timer = randf_range(0.0, 0.4)
	return state


# --- FORMATIONS & HAZARDS ----------------------------------------------------

static func apply_start_of_combat_formations(squad: Array[CombatantState], callbacks: Dictionary = {}) -> void:
	for state in squad:
		if not state.unit or not state.unit.unit_resource:
			continue
		var u_name = state.unit.unit_resource.display_name
		var role = state.unit.unit_resource.role
		var row = state.grid_row
		var col = state.grid_col
		
		# 1. Tank Adjacent Shielding (Kinetic Guard)
		for other in squad:
			if other != state and other.unit and other.unit.unit_resource:
				if other.unit.unit_resource.role == Enums.UnitRole.TANK and other.grid_row == row and abs(other.grid_col - col) == 1:
					state.shield += 120.0
					_call_cb(callbacks, "on_floating_text", [state, "🛡️ GUARD +120", Color(0.2, 0.85, 1.0), false])
					_call_cb(callbacks, "on_log", ["   🛡️ [b]%s[/b] receives +120 kinetic shield from adjacent Tank %s!" % [u_name, other.unit.unit_resource.display_name]])
					
		# 2. Hacker Row Uplink (+15 Mana & +15% Speed)
		for other in squad:
			if other != state and other.unit and other.unit.unit_resource:
				if other.unit.unit_resource.role == Enums.UnitRole.HACKER and other.grid_row == row:
					state.current_mana = minf(state.current_mana + 15.0, 100.0)
					state.attack_speed *= 1.15
					_call_cb(callbacks, "on_floating_text", [state, "⚡ UPLINK +15M", Color(0.0, 1.0, 0.85), false])
					_call_cb(callbacks, "on_log", ["   ⚡ [b]%s[/b] boosted by Hacker Row Uplink (+15 Mana, +15%% Haste)!" % u_name])
					
		# 3. Sniper Backline Spotter (+25% Crit in Row 0)
		if row == 0 and role == Enums.UnitRole.SNIPER:
			state.crit_chance += 0.25
			_call_cb(callbacks, "on_floating_text", [state, "🎯 OVERWATCH +25%", Color(1.0, 0.85, 0.1), false])
			_call_cb(callbacks, "on_log", ["   🎯 [b]%s[/b] secures elevated Backline Overwatch (+25%% Crit Chance)!" % u_name])
			
		# 4. Operative-Specific Directional Formation Passives
		var u_res = state.unit.unit_resource
		if u_res and u_res.directional_target != Enums.GridDirection.NONE:
			_apply_combat_directional_mods(state, squad, u_res.directional_target, u_res.directional_modifiers, u_res.directional_passive_description, callbacks)
			
		# 5. Equipped Augment Directional Formation Modifiers
		for aug in state.unit.equipped_augments:
			if aug and aug.directional_target != Enums.GridDirection.NONE:
				_apply_combat_directional_mods(state, squad, aug.directional_target, aug.directional_modifiers, "%s Synergy" % aug.display_name, callbacks)

static func _apply_combat_directional_mods(source: CombatantState, squad: Array[CombatantState], dir: Enums.GridDirection, mods: Dictionary, desc: String, callbacks: Dictionary = {}) -> void:
	var s_row = source.grid_row
	var s_col = source.grid_col
	
	if dir == Enums.GridDirection.FRONTLINE:
		if s_row == 1:
			_apply_mods_to_combat_state(source, mods, desc, callbacks)
		return
	elif dir == Enums.GridDirection.BACKLINE:
		if s_row == 0:
			_apply_mods_to_combat_state(source, mods, desc, callbacks)
		return
		
	for other in squad:
		if not other.alive: continue
		var o_row = other.grid_row
		var o_col = other.grid_col
		var matches = false
		match dir:
			Enums.GridDirection.LEFT: matches = (o_row == s_row and o_col == s_col - 1)
			Enums.GridDirection.RIGHT: matches = (o_row == s_row and o_col == s_col + 1)
			Enums.GridDirection.ABOVE: matches = (o_row == s_row - 1 and o_col == s_col)
			Enums.GridDirection.BELOW: matches = (o_row == s_row + 1 and o_col == s_col)
			Enums.GridDirection.ADJACENT: matches = ((o_row == s_row and abs(o_col - s_col) == 1) or (o_col == s_col and abs(o_row - s_row) == 1))
			Enums.GridDirection.SAME_ROW: matches = (o_row == s_row and other != source)
			Enums.GridDirection.SAME_COLUMN: matches = (o_col == s_col and other != source)
			Enums.GridDirection.ALL_UNITS: matches = (other != source)
			
		if matches:
			_apply_mods_to_combat_state(other, mods, desc, callbacks)

static func _apply_mods_to_combat_state(target: CombatantState, mods: Dictionary, desc: String, callbacks: Dictionary = {}) -> void:
	for k in mods:
		var v = mods[k]
		match int(k):
			Enums.StatType.MAX_HEALTH:
				target.max_hp += v
				target.current_hp += v
			Enums.StatType.ATTACK_DAMAGE: target.attack_damage += v
			Enums.StatType.ABILITY_POWER: target.ability_power += v
			Enums.StatType.ATTACK_SPEED: target.attack_speed += v
			Enums.StatType.ARMOR: target.armor += v
			Enums.StatType.SHIELD: target.shield += v
			Enums.StatType.STARTING_MANA: target.current_mana = minf(target.current_mana + v, 100.0)
			Enums.StatType.CRIT_CHANCE: target.crit_chance += v
			Enums.StatType.EVASION: target.evasion += v
	if not desc.is_empty() and target.unit and target.unit.unit_resource:
		_call_cb(callbacks, "on_log", ["   ✨ [b]%s[/b] receives formation effect: %s" % [target.unit.unit_resource.display_name, desc]])

static func apply_district_environmental_hazards(player_states: Array[CombatantState], enemy_states: Array[CombatantState], district_id: int, callbacks: Dictionary = {}) -> void:
	match district_id:
		1:
			# District 1: Corrosive sludge dampens healing effectiveness
			for c in player_states:
				c.healing_mult = 0.85
		2:
			# District 2: High security grid gives enemies initial barrier shield
			for c in enemy_states:
				c.shield += 120.0
		3:
			# District 3: EMP dampener reduces player starting mana
			for c in player_states:
				c.current_mana = maxf(0.0, c.current_mana - 15.0)
		4:
			# District 4: Boss has enrage capability
			for c in enemy_states:
				c.has_enrage = true


# --- COMBAT LOOP & STEPPING --------------------------------------------------

static func tick_squad(attackers: Array[CombatantState], defenders: Array[CombatantState], allies: Array[CombatantState], delta: float, callbacks: Dictionary = {}) -> void:
	for att in attackers:
		if not att.alive:
			continue
			
		# Process active DoTs on this combatant
		if not att.active_dots.is_empty():
			var remaining_dots: Array[Dictionary] = []
			for dot in att.active_dots:
				dot["timer"] -= delta
				apply_damage(att, dot["dps"] * delta, null, true, false, callbacks, attackers, defenders)
				if dot["timer"] > 0.0 and att.alive:
					remaining_dots.append(dot)
			att.active_dots = remaining_dots
			if not att.alive:
				continue

		att.retaliation_icd = maxf(0.0, att.retaliation_icd - delta)
		att.attack_timer += delta
		var req_time = 1.0 / maxf(att.attack_speed, 0.1)
		
		# While loop preserves fractional remainder across frame boundaries
		while att.attack_timer >= req_time and att.alive:
			att.attack_timer -= req_time
			perform_auto_attack(att, defenders, allies, callbacks)


static func perform_auto_attack(att: CombatantState, defenders: Array[CombatantState], allies: Array[CombatantState], callbacks: Dictionary = {}) -> void:
	var target = find_tactical_target(att, defenders)
	if target == null:
		return

	# Evasion: a full dodge
	if randf() < target.evasion:
		_call_cb(callbacks, "on_floating_text", [target, "MISS", Color(0.7, 0.7, 0.8), false])
		return

	var crit_chance = att.crit_chance
	var is_crit = randf() < crit_chance
	var mult = 1.5 if is_crit else 1.0
	var dmg = att.attack_damage * randf_range(0.9, 1.1) * mult

	# Thermal Tag: attacker's own Thermal-tagged augments burn target armor
	if att.unit:
		var thermal_tags := 0
		for t in att.unit.get_all_tags():
			if t == Enums.AugmentTag.THERMAL:
				thermal_tags += 1
		if thermal_tags >= 2:
			target.armor = maxf(-25.0, target.armor - 2.5 * thermal_tags)

	# Armor mitigation
	var damage_mult = 100.0 / (100.0 + maxf(0.0, target.armor))
	dmg *= damage_mult

	apply_damage(target, dmg, att, false, is_crit, callbacks, defenders, allies)
	
	# Legendary Kinetic Destroyer Ricochet: On crit, ricochet 50% damage to same-row enemies
	if is_crit and att.unit:
		var has_ricochet = false
		for aug in att.unit.get_equipped_augments():
			if aug and (aug.id == "legendary_kinetic_destroyer" or aug.trigger_effect_id == "kinetic_destroyer_blast" or aug.trigger_effect_id == "kinetic_destroyer_ricochet"):
				has_ricochet = true
				break
		if has_ricochet:
			for d in defenders:
				if d != target and d.alive and d.grid_row == target.grid_row:
					apply_damage(d, dmg * 0.50, att, false, false, callbacks, defenders, allies)
					_call_cb(callbacks, "on_floating_text", [d, "⚡ RICOCHET -%.0f!" % (dmg * 0.50), Color(1.0, 0.8, 0.2), true])
			_call_cb(callbacks, "on_log", ["   ⚡ [b]%s[/b]'s Singularity Rail ricochets damage across the row!" % (att.unit.unit_resource.display_name if att.unit else "Operative")])
	
	# Gain Mana on attack
	att.current_mana = minf(att.current_mana + 20.0, 100.0)
	if att.current_mana >= 100.0:
		cast_ability(att, defenders, allies, callbacks)


static func cast_ability(caster: CombatantState, defenders: Array[CombatantState], allies: Array[CombatantState], callbacks: Dictionary = {}) -> void:
	caster.current_mana = 0.0
	var u_name = caster.unit.unit_resource.display_name if caster.unit else "Operative"
	var ab_name = caster.unit.unit_resource.ability_name if caster.unit else "Overclock Strike"
	var u_id = caster.unit.unit_resource.id if caster.unit else ""
	
	_call_cb(callbacks, "on_log", ["[b][color=%s]⚡ %s triggers %s![/color][/b]" % [
		"#00f5d4" if caster.is_player else "#ff3366",
		u_name,
		ab_name
	]])
	_call_cb(callbacks, "on_sfx", ["play_ability_cast"])
	_call_cb(callbacks, "on_flash", [caster, Color(2.0, 1.8, 0.5), 0.35])
	_call_cb(callbacks, "on_floating_text", [caster, "⚡ " + ab_name + "!", Color(0, 1, 0.9) if caster.is_player else Color(1, 0.2, 0.6), true])
	
	# Legendary Neural Singularity Daemon: Grant +20 mana to all living allies on cast
	if caster.unit:
		for aug in caster.unit.get_equipped_augments():
			if aug and (aug.id == "legendary_neural_hive" or aug.trigger_effect_id == "neural_singularity_synchronize"):
				for ally in allies:
					if ally != caster and ally.alive:
						ally.current_mana = minf(ally.current_mana + 20.0, 100.0)
						_call_cb(callbacks, "on_floating_text", [ally, "⚡ +20 MANA", Color(0.2, 0.8, 1.0), false])
				_call_cb(callbacks, "on_log", ["   ⚡ [b]%s[/b] synchronizes neural hive, restoring +20 mana to all allies!" % u_name])
				break
				
	# Legendary Thermal Supernova Core: Melts 40% target armor on cast
	if caster.unit:
		for aug in caster.unit.get_equipped_augments():
			if aug and (aug.id == "legendary_thermal_supernova" or aug.trigger_effect_id == "thermal_supernova"):
				var target = find_tactical_target(caster, defenders)
				if target:
					_call_cb(callbacks, "on_floating_text", [target, "🔥 ARMOR MELT -40%!", Color(1.0, 0.4, 0.1), true])
					_call_cb(callbacks, "on_log", ["   🔥 [b]%s[/b]'s Supernova Core vaporizes 40%% of target armor!" % u_name])
				break
				
	# Hyper-Frequency Siphon: Refund 20 mana & grant +20% attack speed on cast
	if caster.active_conduit_id == "conduit_overclock_siphon":
		caster.current_mana = minf(caster.current_mana + 20.0, 100.0)
		caster.attack_speed *= 1.20
		_call_cb(callbacks, "on_floating_text", [caster, "🔮 +20 MANA & HASTE!", Color(1.0, 0.2, 0.7), false])
		_call_cb(callbacks, "on_log", ["   🔮 [b]%s[/b]'s Hyper-Frequency Siphon refunds 20 Mana & surges speed!" % u_name])
	
	# Vector (Conduit Sapper): Overload Pulse
	if u_id == "ai_vector" or (caster.unit and caster.unit.unit_resource and caster.unit.unit_resource.ability_effect_id == "ability_overload_pulse"):
		var aoe_dmg = 120.0 + (caster.ability_power * 0.75)
		for d in defenders:
			if d.alive:
				apply_damage(d, aoe_dmg, caster, true, false, callbacks, defenders, allies)
		if not caster.slot_doctrine_id.is_empty() or not caster.active_conduit_id.is_empty():
			for ally in allies:
				if ally.alive and ally.grid_row == caster.grid_row:
					ally.shield += 130.0
					_call_cb(callbacks, "on_floating_text", [ally, "🛡️ +130 BARRIER", Color(0, 0.95, 0.83), false])
			_call_cb(callbacks, "on_log", ["   ⚡ [b]%s[/b] channels socket power, shielding row allies for 130!" % u_name])
		return

	# Specialized boss abilities
	if u_id.begins_with("boss_"):
		if u_id == "boss_nemesis_synthetic" or u_id == "boss_machine_prophet":
			var aoe_dmg = 140.0 + (caster.ability_power * 1.6)
			for d in defenders:
				if d.alive:
					apply_damage(d, aoe_dmg, caster, true, false, callbacks, defenders, allies)
			_call_cb(callbacks, "on_log", ["   💥 %s unleashes a catastrophic team-wide burst!" % u_name])
			return
		elif u_id == "boss_ai_prime_overmind" or u_id == "boss_transit_warden" or u_id == "boss_highway_reaper":
			var count = 0
			for d in defenders:
				if d.alive and count < 2:
					var multi_dmg = 120.0 + (caster.ability_power * 1.8)
					apply_damage(d, multi_dmg, caster, true, false, callbacks, defenders, allies)
					d.current_mana = maxf(d.current_mana - 25.0, 0.0)
					_call_cb(callbacks, "on_floating_text", [d, "⚡ EMP -25 MANA!", Color(0.8, 0.2, 1.0), true])
					count += 1
			_call_cb(callbacks, "on_log", ["   ⚡ %s discharges multi-target overload & EMP drain!" % u_name])
			return
		elif u_id == "boss_corp_commander" or u_id == "boss_railmaster" or u_id == "boss_director_panopticon":
			var weakest = find_weakest_target(defenders)
			if weakest:
				var pierce_dmg = (caster.attack_damage * 2.5) + (caster.ability_power * 1.5)
				apply_damage(weakest, pierce_dmg, caster, true, true, callbacks, defenders, allies)
				_call_cb(callbacks, "on_log", ["   🎯 %s locks on for a high-caliber execution strike!" % u_name])
			return
			
	# Standard ability mechanics by role
	var role = caster.unit.unit_resource.role if caster.unit else Enums.UnitRole.TANK
	match role:
		Enums.UnitRole.TANK:
			var added_shield = 180.0 + (caster.ability_power * 1.5)
			caster.shield += added_shield
			_call_cb(callbacks, "on_floating_text", [caster, "🛡 +%.0f SHIELD" % added_shield, Color(0.2, 0.75, 1.0)])
			_call_cb(callbacks, "on_log", ["   🛡 %s generates a %.0f kinetic barrier!" % [u_name, caster.shield]])
			for ally in allies:
				if ally != caster and ally.alive and abs(ally.grid_row - caster.grid_row) + abs(ally.grid_col - caster.grid_col) == 1:
					ally.shield += 80.0
					_call_cb(callbacks, "on_floating_text", [ally, "🛡 +80 SHIELD", Color(0.2, 0.75, 1.0), false])
		Enums.UnitRole.HACKER:
			var target = find_tactical_target(caster, defenders)
			if target:
				var ap_dmg = 120.0 + (caster.ability_power * 2.2)
				apply_damage(target, ap_dmg, caster, true, false, callbacks, defenders, allies)
		Enums.UnitRole.SNIPER:
			var weakest = find_weakest_target(defenders)
			if weakest:
				var crit_dmg = (caster.attack_damage * 2.2) + caster.ability_power
				apply_damage(weakest, crit_dmg, caster, true, true, callbacks, defenders, allies)
		Enums.UnitRole.FIXER:
			var h_mult = caster.healing_mult
			var healed = minf((150.0 + caster.ability_power) * h_mult, caster.max_hp - caster.current_hp)
			caster.current_hp = minf(caster.current_hp + healed, caster.max_hp)
			_call_cb(callbacks, "on_floating_text", [caster, "💉 +%.0f HP" % healed, Color(0.2, 1.0, 0.5)])
			_call_cb(callbacks, "on_log", ["   💉 %s repairs systems, recovering health!" % u_name])
			for ally in allies:
				if ally != caster and ally.alive and abs(ally.grid_row - caster.grid_row) + abs(ally.grid_col - caster.grid_col) == 1:
					var a_healed = minf((100.0 + (caster.ability_power * 0.5)) * ally.healing_mult, ally.max_hp - ally.current_hp)
					ally.current_hp = minf(ally.current_hp + a_healed, ally.max_hp)
					_call_cb(callbacks, "on_floating_text", [ally, "💉 +%.0f HP" % a_healed, Color(0.2, 1.0, 0.5), false])
		_:
			var target = find_tactical_target(caster, defenders)
			if target:
				apply_damage(target, caster.attack_damage * 1.5, caster, true, false, callbacks, defenders, allies)


static func apply_damage(target: CombatantState, raw_dmg: float, attacker: CombatantState = null, is_ability: bool = false, is_crit: bool = false, callbacks: Dictionary = {}, defenders: Array[CombatantState] = [], allies: Array[CombatantState] = []) -> void:
	var remaining_dmg = raw_dmg
	
	if target.shield > 0:
		if target.shield >= remaining_dmg:
			target.shield -= remaining_dmg
			remaining_dmg = 0
		else:
			remaining_dmg -= target.shield
			target.shield = 0
			
	target.current_hp = maxf(target.current_hp - remaining_dmg, 0.0)
	target.current_mana = minf(target.current_mana + 10.0, 100.0)
	
	# Spawn Visuals / Numbers
	if is_crit:
		_call_cb(callbacks, "on_sfx", ["play_combat_crit"])
		_call_cb(callbacks, "on_floating_text", [target, "⚡ CRIT -%.0f!" % raw_dmg, Color(1.0, 0.88, 0.2), true])
		_call_cb(callbacks, "on_flash", [target, Color(2.0, 0.8, 0.2), 0.2])
	elif is_ability:
		_call_cb(callbacks, "on_floating_text", [target, "💥 -%.0f AP" % raw_dmg, Color(1.0, 0.2, 0.7), true])
		_call_cb(callbacks, "on_flash", [target, Color(1.8, 0.2, 0.8), 0.2])
	else:
		_call_cb(callbacks, "on_sfx", ["play_combat_hit"])
		var dmg_col = Color(0.9, 0.95, 1.0) if (attacker and attacker.is_player) else Color(1.0, 0.45, 0.45)
		_call_cb(callbacks, "on_floating_text", [target, "-%.0f" % raw_dmg, dmg_col, false])
		_call_cb(callbacks, "on_flash", [target, Color(1.3, 0.4, 0.4), 0.15])
		
	_call_cb(callbacks, "on_damage_dealt", [attacker, target, raw_dmg])

	# Arc Discharge Coil: Frontline Retaliation when struck
	if target.active_conduit_id == "conduit_arc_discharge" and target.retaliation_icd <= 0.0 and target.alive:
		target.retaliation_icd = 1.5
		var retal_dmg = 35.0
		var shocked = false
		for opp in allies: # attackers of target
			if opp.alive and opp.grid_row == 1:
				apply_damage(opp, retal_dmg, target, true, false, callbacks, allies, defenders)
				_call_cb(callbacks, "on_floating_text", [opp, "⚡ ZAP -35", Color(0, 0.95, 0.83), true])
				shocked = true
		if shocked:
			_call_cb(callbacks, "on_log", ["   ⚡ [b]%s[/b]'s Arc Discharge Coil shocks attackers for 35!" % (target.unit.unit_resource.display_name if target.unit else "Operative")])
		
	# Boss Enrage Trigger below 50% HP
	var t_id = target.unit.unit_resource.id if target.unit else ""
	if (t_id.begins_with("boss_") or target.has_enrage) and target.alive and not target.enraged:
		if target.current_hp <= target.max_hp * 0.5 and target.current_hp > 0:
			target.enraged = true
			target.shield += 200.0
			target.attack_speed *= 1.35
			target.attack_damage *= 1.30
			_call_cb(callbacks, "on_flash", [target, Color(2.5, 0.2, 0.2), 0.5])
			_call_cb(callbacks, "on_floating_text", [target, "💥 BOSS ENRAGE ACTIVATED!", Color(1.0, 0.15, 0.3), true])
			_call_cb(callbacks, "on_log", ["[b][color=#ff0055]⚠️ %s triggers ENRAGE OVERCLOCK! Shield +200, row-cleave shockwave unleashed![/color][/b]" % (target.unit.unit_resource.display_name if target.unit else "Boss")])
			for opp in allies:
				if opp.alive and opp.grid_row == 1:
					apply_damage(opp, 120.0, target, true, false, callbacks, allies, defenders)
		
	# Target Neutralization
	if target.current_hp <= 0 and target.alive:
		target.alive = false
		var t_name = target.unit.unit_resource.display_name if target.unit else "Target"
		_call_cb(callbacks, "on_log", ["[color=#ff0055]💀 %s has been neutralized![/color]" % t_name])
		_call_cb(callbacks, "on_death", [target, attacker])
		
		# Legendary Viral Pandemic Strain On-Kill Proc
		if attacker and attacker.unit:
			for aug in attacker.unit.get_equipped_augments():
				if aug and (aug.id == "legendary_viral_pandemic" or aug.trigger_effect_id == "viral_pandemic"):
					for opp in defenders:
						if opp.alive:
							opp.attack_speed *= 0.75
							_call_cb(callbacks, "on_floating_text", [opp, "☣ -25% ATK SPEED", Color(0.2, 1.0, 0.4), true])
					_call_cb(callbacks, "on_log", ["   ☣ [b]%s[/b]'s Pandemic Daemon spreads contagion! -25%% Attack Speed to remaining enemies!" % (attacker.unit.unit_resource.display_name if attacker.unit else "Operative")])
					break


# --- TARGETING ---------------------------------------------------------------

static func find_tactical_target(attacker: CombatantState, defenders: Array[CombatantState]) -> CombatantState:
	# 1. Look for Frontline (Row 1) defenders first
	var front_alive: Array[CombatantState] = []
	var back_alive: Array[CombatantState] = []
	
	for d in defenders:
		if d.alive:
			if d.grid_row == 1:
				front_alive.append(d)
			else:
				back_alive.append(d)
				
	if not front_alive.is_empty():
		var best_target: CombatantState = null
		var min_dist = 999
		for d in front_alive:
			var dist = abs(d.grid_col - attacker.grid_col)
			if dist < min_dist:
				min_dist = dist
				best_target = d
		return best_target
		
	# 2. If Frontline is breached, target Backline (Row 0)
	if not back_alive.is_empty():
		var best_target: CombatantState = null
		var min_dist = 999
		for d in back_alive:
			var dist = abs(d.grid_col - attacker.grid_col)
			if dist < min_dist:
				min_dist = dist
				best_target = d
		return best_target
		
	# Fallback
	for d in defenders:
		if d.alive:
			return d
	return null

static func find_weakest_target(defenders: Array[CombatantState]) -> CombatantState:
	var lowest: CombatantState = null
	var min_hp = 99999.0
	for d in defenders:
		if d.alive:
			if d.current_hp < min_hp:
				min_hp = d.current_hp
				lowest = d
	return lowest


# --- HEADLESS BATTLE SIMULATION (60 FPS FRAME-DIFFERENTIAL TIMESTEP) ----------

static func simulate_battle(player_squad: Array, enemy_squad: Array, district_id: int = 1, is_boss: bool = false, formation_bonuses: Dictionary = {}, dt: float = 1.0 / 60.0, max_time: float = 60.0, synergy_report: SynergyReport = null) -> Dictionary:
	var player_states: Array[CombatantState] = []
	var enemy_states: Array[CombatantState] = []
	
	# Instantiate player states
	for i in range(player_squad.size()):
		var unit = player_squad[i] as UnitInstance
		if unit != null:
			var slot_idx = unit.grid_slot if unit.grid_slot >= 0 else i
			player_states.append(create_combatant(unit, true, slot_idx, formation_bonuses, district_id, false, synergy_report))
			
	# Instantiate enemy states
	for i in range(enemy_squad.size()):
		var unit = enemy_squad[i] as UnitInstance
		if unit != null:
			var slot_idx = unit.grid_slot if unit.grid_slot >= 0 else i
			enemy_states.append(create_combatant(unit, false, slot_idx, {}, district_id, is_boss))
			
	# Apply formations & district hazards
	apply_start_of_combat_formations(player_states)
	apply_start_of_combat_formations(enemy_states)
	apply_district_environmental_hazards(player_states, enemy_states, district_id)
	
	var time = 0.0
	while time < max_time:
		time += dt
		
		# Step player squad & enemy squad
		tick_squad(player_states, enemy_states, player_states, dt)
		tick_squad(enemy_states, player_states, enemy_states, dt)
		
		# Check victory condition
		var living_players = 0
		for p in player_states:
			if p.alive: living_players += 1
			
		var living_enemies = 0
		for e in enemy_states:
			if e.alive: living_enemies += 1
			
		if living_enemies == 0:
			return {
				"victory": true,
				"duration": time,
				"survivors": living_players,
				"player_hp_frac": squad_hp_fraction(player_states),
				"enemy_hp_frac": squad_hp_fraction(enemy_states)
			}
		if living_players == 0:
			return {
				"victory": false,
				"duration": time,
				"survivors": 0,
				"player_hp_frac": squad_hp_fraction(player_states),
				"enemy_hp_frac": squad_hp_fraction(enemy_states)
			}
			
	# Timeout
	var survivors = 0
	for p in player_states:
		if p.alive: survivors += 1
	return {
		"victory": false,
		"duration": max_time,
		"survivors": survivors,
		"player_hp_frac": squad_hp_fraction(player_states),
		"enemy_hp_frac": squad_hp_fraction(enemy_states)
	}

static func squad_hp_fraction(squad: Array[CombatantState]) -> float:
	var current := 0.0
	var maximum := 0.0
	for c in squad:
		current += maxf(0.0, c.current_hp)
		maximum += maxf(1.0, c.max_hp)
	return clampf(current / maxf(maximum, 1.0), 0.0, 1.0)


# --- INTERNAL UTILITY --------------------------------------------------------

static func _call_cb(callbacks: Dictionary, key: String, args: Array) -> void:
	if callbacks.has(key):
		var cb = callbacks[key]
		if cb is Callable and cb.is_valid():
			cb.callv(args)
