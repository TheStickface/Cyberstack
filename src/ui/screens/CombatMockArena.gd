class_name CombatMockArena
extends Control

## Real-Time Autobattler Combat Arena & Simulation Engine

class CombatantState:
	var unit: UnitInstance
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
	var attack_timer: float = 0.0
	var alive: bool = true
	
	var box_panel: PanelContainer = null
	var hp_bar: ProgressBar = null
	var hp_label: Label = null
	var mana_bar: ProgressBar = null
	var status_label: Label = null
	var formation_label: Label = null

@onready var district_label: Label = $Margin/VBox/TopBar/DistrictLabel
@onready var combat_type_label: Label = $Margin/VBox/TopBar/CombatTypeLabel
@onready var timer_label: Label = $Margin/VBox/TopBar/TimerLabel
@onready var speed_btn: Button = $Margin/VBox/TopBar/SpeedBtn
@onready var skip_btn: Button = $Margin/VBox/TopBar/SkipBtn

@onready var player_container: HBoxContainer = $Margin/VBox/Arena/PlayerSide/PlayerScroll/PlayerContainer
@onready var enemy_container: HBoxContainer = $Margin/VBox/Arena/EnemySide/EnemyScroll/EnemyContainer
@onready var combat_log: RichTextLabel = $Margin/VBox/BottomBar/CombatLog

@onready var result_overlay: ColorRect = $ResultOverlay
@onready var result_title: Label = $ResultOverlay/Center/DialogPanel/Margin/VBox/ResultTitle
@onready var result_stats: Label = $ResultOverlay/Center/DialogPanel/Margin/VBox/ResultStats
@onready var finish_btn: Button = $ResultOverlay/Center/DialogPanel/Margin/VBox/FinishBtn

var combat_payload: Dictionary = {}
var player_states: Array[CombatantState] = []
var enemy_states: Array[CombatantState] = []

var battle_time: float = 0.0
var battle_active: bool = false
var battle_resolved: bool = false
var is_victory: bool = false
var speed_multiplier: float = 1.0
var total_player_damage: float = 0.0
var total_enemy_damage: float = 0.0

func _ready() -> void:
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		combat_payload = gm.active_combat_payload
	
	if result_overlay:
		result_overlay.visible = false
		
	_setup_arena()

const TacticalTetherOverlayScript = preload("res://src/ui/components/TacticalTetherOverlay.gd")
const CombatTelemetryHUDScript = preload("res://src/ui/components/CombatTelemetryHUD.gd")

var player_tether_overlay: Control = null
var enemy_tether_overlay: Control = null
var telemetry_hud: Control = null

func _setup_arena() -> void:
	if combat_payload.is_empty():
		return
		
	var dist_id = combat_payload.get("district_id", 1)
	var is_boss = combat_payload.get("is_boss", false)
	var dist_name = combat_payload.get("district_name", "DISTRICT %d" % dist_id)
	
	if district_label:
		district_label.text = "%s TACTICAL ARENA" % dist_name.to_upper()
	if combat_type_label:
		combat_type_label.text = "★ DISTRICT BOSS CLASH" if is_boss else "⚔ SECURITY PATROL ENCOUNTER"
		combat_type_label.add_theme_color_override("font_color", Color(1, 0.1, 0.2) if is_boss else Color(1, 0.3, 0.5))
		
	var crew_size = combat_payload.get("player_crew", []).size()
	var max_cap = Constants.DISTRICT_CREW_LIMITS.get(dist_id, 2)
	var player_header: Label = get_node_or_null("Margin/VBox/Arena/PlayerSide/PlayerHeader")
	if player_header:
		player_header.text = "PLAYER FORMATION (%d / %d CREW DEPLOYED):" % [crew_size, max_cap]
		
	_initialize_squads()
	_apply_start_of_combat_formations(player_states, true)
	_apply_start_of_combat_formations(enemy_states, false)
	
	# Create holographic tether overlays for battle cards
	if player_container and (player_tether_overlay == null or not is_instance_valid(player_tether_overlay)):
		player_tether_overlay = TacticalTetherOverlayScript.new()
		player_tether_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		player_container.get_parent().add_child(player_tether_overlay)
		
	if enemy_container and (enemy_tether_overlay == null or not is_instance_valid(enemy_tether_overlay)):
		enemy_tether_overlay = TacticalTetherOverlayScript.new()
		enemy_tether_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		enemy_container.get_parent().add_child(enemy_tether_overlay)
		
	if telemetry_hud == null or not is_instance_valid(telemetry_hud):
		telemetry_hud = CombatTelemetryHUDScript.new(self)
		add_child(telemetry_hud)
		
	call_deferred("_update_combat_tethers")

	
	battle_time = 0.0
	battle_active = true
	battle_resolved = false
	
	_log("[color=#00f5d4][SYSTEM][/color] Tactical deployment initialized. Formation auras active.")

func _update_combat_tethers() -> void:
	if player_tether_overlay:
		_draw_squad_tethers(player_states, player_tether_overlay)
	if enemy_tether_overlay:
		_draw_squad_tethers(enemy_states, enemy_tether_overlay)

func _draw_squad_tethers(squad: Array[CombatantState], overlay: Control) -> void:
	overlay.clear_tethers()
	var state_pos: Dictionary = {}
	for st in squad:
		if st.box_panel and st.alive:
			state_pos[st] = overlay.to_local(st.box_panel.global_position + st.box_panel.size * 0.5)
			
	for st in squad:
		if not st.alive or not state_pos.has(st) or not st.unit or not st.unit.unit_resource:
			continue
		var p1 = state_pos[st]
		var role = st.unit.unit_resource.role
		var row = st.grid_row
		var col = st.grid_col
		
		# 1. Tank Lateral Guards
		if role == Enums.UnitRole.TANK:
			for other in squad:
				if other != st and other.alive and other.grid_row == row and abs(other.grid_col - col) == 1:
					if state_pos.has(other):
						overlay.add_tether(p1, state_pos[other], TacticalTetherOverlayScript.COLOR_TANK_GUARD, "Guard")
						
		# 2. Hacker Row Uplinks
		if role == Enums.UnitRole.HACKER:
			for other in squad:
				if other != st and other.alive and other.grid_row == row:
					if state_pos.has(other):
						overlay.add_tether(p1, state_pos[other], TacticalTetherOverlayScript.COLOR_HACKER_UPLINK, "Uplink")
						
		# 3. Fixer Adjacent Bio-Links
		if role == Enums.UnitRole.FIXER:
			for other in squad:
				if other != st and other.alive and ((other.grid_row == row and abs(other.grid_col - col) == 1) or (other.grid_col == col and abs(other.grid_row - row) == 1)):
					if state_pos.has(other):
						overlay.add_tether(p1, state_pos[other], TacticalTetherOverlayScript.COLOR_FIXER_LINK, "Bio-Link")



func _initialize_squads() -> void:
	player_states.clear()
	enemy_states.clear()
	
	if player_container:
		for c in player_container.get_children():
			c.queue_free()
	if enemy_container:
		for c in enemy_container.get_children():
			c.queue_free()
			
	# Initialize Player 2x3 Grid
	var player_grid: Array = combat_payload.get("player_grid", [])
	if player_grid.is_empty():
		player_grid = combat_payload.get("player_crew", [])
		
	for i in range(player_grid.size()):
		var unit = player_grid[i] as UnitInstance
		if unit != null:
			var slot_idx = unit.grid_slot if unit.grid_slot >= 0 else i
			var state = _create_combatant(unit, true, slot_idx)
			player_states.append(state)
			if player_container:
				player_container.add_child(state.box_panel)
				
	# Initialize Enemy 2x3 Grid
	var enemy_grid: Array = combat_payload.get("enemy_grid", [])
	if enemy_grid.is_empty():
		enemy_grid = combat_payload.get("enemy_squad", [])
		
	for i in range(enemy_grid.size()):
		var unit = enemy_grid[i] as UnitInstance
		if unit != null:
			var slot_idx = unit.grid_slot if unit.grid_slot >= 0 else i
			var state = _create_combatant(unit, false, slot_idx)
			enemy_states.append(state)
			if enemy_container:
				enemy_container.add_child(state.box_panel)

func _create_combatant(unit: UnitInstance, is_player: bool, slot_idx: int = 0) -> CombatantState:
	var state = CombatantState.new()
	state.unit = unit
	state.is_player = is_player
	state.grid_slot = slot_idx
	state.grid_row = slot_idx / 3
	state.grid_col = slot_idx % 3
	
	if unit:
		state.max_hp = unit.calculate_effective_stat(Enums.StatType.MAX_HEALTH)
		state.current_hp = state.max_hp
		state.attack_damage = unit.calculate_effective_stat(Enums.StatType.ATTACK_DAMAGE)
		state.ability_power = unit.calculate_effective_stat(Enums.StatType.ABILITY_POWER)
		var spd = unit.calculate_effective_stat(Enums.StatType.SPEED)
		state.attack_speed = clampf(spd / 50.0, 0.6, 2.5)
		state.crit_chance = unit.calculate_effective_stat(Enums.StatType.CRIT_CHANCE)
	else:
		state.max_hp = 450.0
		state.current_hp = 450.0
		state.attack_damage = 35.0
		state.ability_power = 20.0
		state.attack_speed = 1.0
		state.crit_chance = 0.05

		
	# Scale enemy combatants by district progression and boss tier
	if not is_player:
		var dist_id = combat_payload.get("district_id", 1)
		var scaling = Constants.DISTRICT_ENEMY_SCALING.get(dist_id, {"hp_mult": 1.0, "dmg_mult": 1.0})
		state.max_hp *= scaling.get("hp_mult", 1.0)
		state.current_hp = state.max_hp
		state.attack_damage *= scaling.get("dmg_mult", 1.0)
		state.ability_power *= scaling.get("dmg_mult", 1.0)
		if combat_payload.get("is_boss", false):
			state.max_hp *= 1.35
			state.current_hp = state.max_hp
			state.attack_damage *= 1.20
		
	state.attack_timer = randf_range(0.0, 0.4) # Slight desync for natural flow
	
	# UI Box
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 170)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.12, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0, 0.85, 0.75, 0.7) if is_player else Color(1, 0.2, 0.4, 0.7)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	
	var name_lbl = Label.new()
	var stars = unit.get_star_string() if (unit and unit.star_level > 1) else ""
	var disp_name = unit.unit_resource.display_name if (unit and unit.unit_resource) else "Enforcer"
	name_lbl.text = "%s %s" % [stars, disp_name] if not stars.is_empty() else disp_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	if is_player:
		name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.1) if (unit and unit.star_level == 2) else (Color(1, 0.2, 0.8) if (unit and unit.star_level >= 3) else Color(0, 0.95, 0.83)))
	else:
		name_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.5))
	name_lbl.clip_text = true
	vbox.add_child(name_lbl)
	
	var role_lbl = Label.new()
	role_lbl.text = unit.unit_resource.get_role_name().to_upper() if (unit and unit.unit_resource) else "TANK"
	role_lbl.add_theme_font_size_override("font_size", 8)
	role_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(role_lbl)
	
	var hp_lbl = Label.new()
	hp_lbl.text = "HP: %.0f / %.0f" % [state.current_hp, state.max_hp]
	hp_lbl.add_theme_font_size_override("font_size", 8)
	hp_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(hp_lbl)
	state.hp_label = hp_lbl
	
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 10)
	hp_bar.max_value = state.max_hp
	hp_bar.value = state.current_hp
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)
	state.hp_bar = hp_bar
	
	var mana_lbl = Label.new()
	mana_lbl.text = "MANA (100 for Ability)"
	mana_lbl.add_theme_font_size_override("font_size", 7)
	mana_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	vbox.add_child(mana_lbl)
	
	var mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(0, 8)
	mana_bar.max_value = 100
	mana_bar.value = 0
	mana_bar.show_percentage = false
	vbox.add_child(mana_bar)
	state.mana_bar = mana_bar
	
	var stat_summary = Label.new()
	stat_summary.text = "AD: %.0f | AP: %.0f" % [state.attack_damage, state.ability_power]
	stat_summary.add_theme_font_size_override("font_size", 8)
	stat_summary.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(stat_summary)
	
	var status_lbl = Label.new()
	status_lbl.text = "READY"
	status_lbl.add_theme_font_size_override("font_size", 8)
	status_lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83) if is_player else Color(1, 0.4, 0.4))
	vbox.add_child(status_lbl)
	state.status_label = status_lbl
	
	state.box_panel = panel
	return state

func _process(delta: float) -> void:
	if not battle_active or battle_resolved:
		return
		
	var effective_delta = delta * speed_multiplier
	battle_time += effective_delta
	
	if timer_label:
		var mins = int(battle_time) / 60
		var secs = int(battle_time) % 60
		timer_label.text = "TIME: %02d:%02d" % [mins, secs]
		
	# Tick all combatants
	_tick_squad(player_states, enemy_states, effective_delta)
	_tick_squad(enemy_states, player_states, effective_delta)
	
	# Update UI Bars
	_update_all_bars()
	
	# Check Win / Loss
	_check_battle_end()

func _tick_squad(attackers: Array[CombatantState], defenders: Array[CombatantState], delta: float) -> void:
	for att in attackers:
		if not att.alive:
			continue
			
		att.attack_timer += delta
		var req_time = 1.0 / maxf(att.attack_speed, 0.1)
		
		if att.attack_timer >= req_time:
			att.attack_timer -= req_time
			_perform_auto_attack(att, defenders)

func _apply_start_of_combat_formations(squad: Array[CombatantState], is_player: bool) -> void:
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
					_spawn_floating_combat_text(state, "🛡️ GUARD +120", Color(0.2, 0.85, 1.0), false)
					_log("   🛡️ [b]%s[/b] receives +120 kinetic shield from adjacent Tank %s!" % [u_name, other.unit.unit_resource.display_name])
					
		# 2. Hacker Row Uplink (+15 Mana & +15% Speed)
		for other in squad:
			if other != state and other.unit and other.unit.unit_resource:
				if other.unit.unit_resource.role == Enums.UnitRole.HACKER and other.grid_row == row:
					state.current_mana = minf(state.current_mana + 15.0, 100.0)
					state.attack_speed *= 1.15
					_spawn_floating_combat_text(state, "⚡ UPLINK +15M", Color(0.0, 1.0, 0.85), false)
					_log("   ⚡ [b]%s[/b] boosted by Hacker Row Uplink (+15 Mana, +15%% Haste)!" % u_name)
					
		# 3. Sniper Backline Spotter (+25% Crit in Row 0)
		if row == 0 and role == Enums.UnitRole.SNIPER:
			state.crit_chance += 0.25
			_spawn_floating_combat_text(state, "🎯 OVERWATCH +25%", Color(1.0, 0.85, 0.1), false)
			_log("   🎯 [b]%s[/b] secures elevated Backline Overwatch (+25%% Crit Chance)!" % u_name)
			
		# 4. Operative-Specific Directional Formation Passives
		var u_res = state.unit.unit_resource
		if u_res and u_res.directional_target != Enums.GridDirection.NONE:
			_apply_combat_directional_mods(state, squad, u_res.directional_target, u_res.directional_modifiers, u_res.directional_passive_description)
			
		# 5. Equipped Augment Directional Formation Modifiers
		for aug in state.unit.equipped_augments:
			if aug and aug.directional_target != Enums.GridDirection.NONE:
				_apply_combat_directional_mods(state, squad, aug.directional_target, aug.directional_modifiers, "%s Synergy" % aug.display_name)

func _apply_combat_directional_mods(source: CombatantState, squad: Array[CombatantState], dir: Enums.GridDirection, mods: Dictionary, desc: String) -> void:
	var s_row = source.grid_row
	var s_col = source.grid_col
	
	if dir == Enums.GridDirection.FRONTLINE:
		if s_row == 1:
			_apply_mods_to_combat_state(source, mods, desc)
		return
	elif dir == Enums.GridDirection.BACKLINE:
		if s_row == 0:
			_apply_mods_to_combat_state(source, mods, desc)
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
			_apply_mods_to_combat_state(other, mods, desc)

func _apply_mods_to_combat_state(target: CombatantState, mods: Dictionary, desc: String) -> void:
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
	if not desc.is_empty():
		_log("   ✨ [b]%s[/b] receives formation effect: %s" % [target.unit.unit_resource.display_name, desc])


func _perform_auto_attack(att: CombatantState, defenders: Array[CombatantState]) -> void:
	var target = _find_tactical_target(att, defenders)
	if target == null:
		return
		
	var crit_chance = att.crit_chance
	var is_crit = randf() < crit_chance
	var mult = 1.5 if is_crit else 1.0
	var dmg = att.attack_damage * randf_range(0.9, 1.1) * mult
	
	_apply_damage(target, dmg, att, false, is_crit)
	
	# Gain Mana on attack
	att.current_mana = minf(att.current_mana + 20.0, 100.0)
	if att.current_mana >= 100.0:
		_cast_ability(att, defenders)

func _cast_ability(caster: CombatantState, defenders: Array[CombatantState]) -> void:
	caster.current_mana = 0.0
	var u_name = caster.unit.unit_resource.display_name if caster.unit else "Operative"
	var ab_name = caster.unit.unit_resource.ability_name if caster.unit else "Overclock Strike"
	var u_id = caster.unit.unit_resource.id if caster.unit else ""
	
	_log("[b][color=%s]⚡ %s triggers %s![/color][/b]" % [
		"#00f5d4" if caster.is_player else "#ff3366",
		u_name,
		ab_name
	])
	
	_play_sfx("play_ability_cast")
	_flash_card(caster.box_panel, Color(2.0, 1.8, 0.5), 0.35)
	_spawn_floating_combat_text(caster, "⚡ " + ab_name + "!", Color(0, 1, 0.9) if caster.is_player else Color(1, 0.2, 0.6), true)
	
	# Check if unit is a specialized boss with bespoke mechanics
	if u_id.begins_with("boss_"):
		if u_id == "boss_nemesis_synthetic" or u_id == "boss_machine_prophet":
			var aoe_dmg = 140.0 + (caster.ability_power * 1.6)
			for d in defenders:
				if d.alive:
					_apply_damage(d, aoe_dmg, caster, true, false)
			_log("   💥 %s unleashes a catastrophic team-wide burst!" % u_name)
			return
		elif u_id == "boss_ai_prime_overmind" or u_id == "boss_transit_warden" or u_id == "boss_highway_reaper":
			var count = 0
			for d in defenders:
				if d.alive and count < 2:
					var multi_dmg = 120.0 + (caster.ability_power * 1.8)
					_apply_damage(d, multi_dmg, caster, true, false)
					d.current_mana = maxf(d.current_mana - 25.0, 0.0)
					count += 1
			_log("   ⚡ %s discharges multi-target overload!" % u_name)
			return
		elif u_id == "boss_corp_commander" or u_id == "boss_railmaster" or u_id == "boss_director_panopticon":
			var weakest = _find_weakest_target(defenders)
			if weakest:
				var pierce_dmg = (caster.attack_damage * 2.5) + (caster.ability_power * 1.5)
				_apply_damage(weakest, pierce_dmg, caster, true, true)
				_log("   🎯 %s locks on for a high-caliber execution strike!" % u_name)
			return
			
	# Standard ability mechanics by role
	var role = caster.unit.unit_resource.role if caster.unit else Enums.UnitRole.TANK
	var allies = player_states if caster.is_player else enemy_states
	
	match role:
		Enums.UnitRole.TANK:
			var added_shield = 180.0 + (caster.ability_power * 1.5)
			caster.shield += added_shield
			_spawn_floating_combat_text(caster, "🛡 +%.0f SHIELD" % added_shield, Color(0.2, 0.75, 1.0))
			_log("   🛡 %s generates a %.0f kinetic barrier!" % [u_name, caster.shield])
			# Tank pulses shield to adjacent allies on cast
			for ally in allies:
				if ally != caster and ally.alive and abs(ally.grid_row - caster.grid_row) + abs(ally.grid_col - caster.grid_col) == 1:
					ally.shield += 80.0
					_spawn_floating_combat_text(ally, "🛡 +80 SHIELD", Color(0.2, 0.75, 1.0), false)
		Enums.UnitRole.HACKER:
			var target = _find_tactical_target(caster, defenders)
			if target:
				var ap_dmg = 120.0 + (caster.ability_power * 2.2)
				_apply_damage(target, ap_dmg, caster, true, false)
		Enums.UnitRole.SNIPER:
			var weakest = _find_weakest_target(defenders)
			if weakest:
				var crit_dmg = (caster.attack_damage * 2.2) + caster.ability_power
				_apply_damage(weakest, crit_dmg, caster, true, true)
		Enums.UnitRole.FIXER:
			var healed = minf(150.0 + caster.ability_power, caster.max_hp - caster.current_hp)
			caster.current_hp = minf(caster.current_hp + 150.0 + caster.ability_power, caster.max_hp)
			_spawn_floating_combat_text(caster, "💉 +%.0f HP" % healed, Color(0.2, 1.0, 0.5))
			_log("   💉 %s repairs systems, recovering health!" % u_name)
			# Fixer heals adjacent allies on cast (Bio-Link Relay)
			for ally in allies:
				if ally != caster and ally.alive and abs(ally.grid_row - caster.grid_row) + abs(ally.grid_col - caster.grid_col) == 1:
					var a_healed = minf(100.0 + (caster.ability_power * 0.5), ally.max_hp - ally.current_hp)
					ally.current_hp = minf(ally.current_hp + a_healed, ally.max_hp)
					_spawn_floating_combat_text(ally, "💉 +%.0f HP" % a_healed, Color(0.2, 1.0, 0.5), false)
		_:
			var target = _find_tactical_target(caster, defenders)
			if target:
				_apply_damage(target, caster.attack_damage * 1.5, caster, true, false)

func _find_tactical_target(attacker: CombatantState, defenders: Array[CombatantState]) -> CombatantState:
	# 1. Look for Frontline (Row 0) defenders first
	var front_alive: Array[CombatantState] = []
	var back_alive: Array[CombatantState] = []
	
	for d in defenders:
		if d.alive:
			if d.grid_row == 0:
				front_alive.append(d)
			else:
				back_alive.append(d)
				
	if not front_alive.is_empty():
		# Try to target matching or closest column in Frontline
		var best_target: CombatantState = null
		var min_dist = 999
		for d in front_alive:
			var dist = abs(d.grid_col - attacker.grid_col)
			if dist < min_dist:
				min_dist = dist
				best_target = d
		return best_target
		
	# 2. If Frontline is breached, target Backline (Row 1)
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

func _find_target(defenders: Array[CombatantState]) -> CombatantState:
	for d in defenders:
		if d.alive:
			return d
	return null


func _apply_damage(target: CombatantState, raw_dmg: float, attacker: CombatantState, is_ability: bool = false, is_crit: bool = false) -> void:
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
	
	# Spawn Floating Numbers & Visual Flash
	if is_crit:
		_play_sfx("play_combat_crit")
		_spawn_floating_combat_text(target, "⚡ CRIT -%.0f!" % raw_dmg, Color(1.0, 0.88, 0.2), true)
		_flash_card(target.box_panel, Color(2.0, 0.8, 0.2), 0.2)
	elif is_ability:
		_spawn_floating_combat_text(target, "💥 -%.0f AP" % raw_dmg, Color(1.0, 0.2, 0.7), true)
		_flash_card(target.box_panel, Color(1.8, 0.2, 0.8), 0.2)
	else:
		_play_sfx("play_combat_hit")
		var dmg_col = Color(0.9, 0.95, 1.0) if attacker.is_player else Color(1.0, 0.45, 0.45)
		_spawn_floating_combat_text(target, "-%.0f" % raw_dmg, dmg_col, false)
		_flash_card(target.box_panel, Color(1.3, 0.4, 0.4), 0.15)
	
	if attacker.is_player:
		total_player_damage += raw_dmg
	else:
		total_enemy_damage += raw_dmg
		
	if target.current_hp <= 0 and target.alive:
		target.alive = false
		target.status_label.text = "✖ DOWN"
		target.status_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		target.box_panel.modulate = Color(0.4, 0.4, 0.4, 0.7)
		var t_name = target.unit.unit_resource.display_name if target.unit else "Target"
		_log("[color=#ff0055]💀 %s has been neutralized![/color]" % t_name)

func _spawn_floating_combat_text(target: CombatantState, text: String, color: Color, is_big: bool = false) -> void:
	if target == null or target.box_panel == null or not is_instance_valid(target.box_panel):
		return
		
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13 if is_big else 10)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.top_level = true
	
	var pos = target.box_panel.global_position + Vector2(randf_range(15, 65), randf_range(20, 50))
	lbl.global_position = pos
	add_child(lbl)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "global_position", pos + Vector2(randf_range(-10, 10), -35), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	if is_big:
		lbl.scale = Vector2(1.25, 1.25)
		tween.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(lbl.queue_free)

func _flash_card(panel: PanelContainer, flash_color: Color, duration: float = 0.2) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var orig_mod = panel.modulate
	panel.modulate = flash_color
	var tween = create_tween()
	tween.tween_property(panel, "modulate", orig_mod, duration)

func _find_weakest_target(defenders: Array[CombatantState]) -> CombatantState:

	var lowest: CombatantState = null
	for d in defenders:
		if d.alive:
			if lowest == null or d.current_hp < lowest.current_hp:
				lowest = d
	return lowest

func _update_all_bars() -> void:
	for state in player_states + enemy_states:
		if state.hp_bar:
			state.hp_bar.value = state.current_hp
		if state.hp_label:
			state.hp_label.text = "HP: %.0f/%.0f %s" % [
				state.current_hp,
				state.max_hp,
				"(+%.0f S)" % state.shield if state.shield > 0 else ""
			]
		if state.mana_bar:
			state.mana_bar.value = state.current_mana

func _check_battle_end() -> void:
	var players_alive = false
	for p in player_states:
		if p.alive:
			players_alive = true
			break
			
	var enemies_alive = false
	for e in enemy_states:
		if e.alive:
			enemies_alive = true
			break
			
	if not enemies_alive:
		_end_battle(true)
	elif not players_alive:
		_end_battle(false)

func _end_battle(victory: bool) -> void:
	battle_active = false
	battle_resolved = true
	is_victory = victory
	
	var dist_id = combat_payload.get("district_id", 1)
	var payout = Constants.DISTRICT_ENCOUNTER_PAYOUTS.get(dist_id, 4)
	
	if result_overlay:
		result_overlay.visible = true
		if victory:
			result_title.text = "COMBAT VICTORY ACHIEVED"
			result_title.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
			result_stats.text = "Combat Duration: %.1fs\nSquad Damage Dealt: %.0f\nEncounter Reward: +%s" % [
				battle_time,
				total_player_damage,
				Constants.format_currency(payout)
			]
			finish_btn.text = "CLAIM REWARDS & CONTINUE ▶"
		else:
			result_title.text = "SQUAD DEFEATED"
			result_title.add_theme_color_override("font_color", Color(1, 0.15, 0.3))
			result_stats.text = "Operatives were overwhelmed in District %d.\nCombat Duration: %.1fs\nDamage Dealt: %.0f" % [
				dist_id,
				battle_time,
				total_player_damage
			]
			finish_btn.text = "TERMINATE MISSION ▶"

func _log(msg: String) -> void:
	if combat_log:
		combat_log.append_text(msg + "\n")

func _on_speed_btn_pressed() -> void:
	if speed_multiplier == 1.0:
		speed_multiplier = 2.0
		speed_btn.text = "SPEED: 2x"
	elif speed_multiplier == 2.0:
		speed_multiplier = 4.0
		speed_btn.text = "SPEED: 4x"
	else:
		speed_multiplier = 1.0
		speed_btn.text = "SPEED: 1x"

func _on_skip_btn_pressed() -> void:
	# Run simulation to immediate conclusion
	while battle_active and not battle_resolved:
		_process(0.2)

func _on_finish_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").finish_combat_encounter(
			is_victory,
			{
				"duration": battle_time,
				"damage_dealt": total_player_damage,
				"damage_taken": total_enemy_damage
			}
		)

func _play_sfx(method_name: String) -> void:
	if get_node_or_null("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method(method_name):
			am.call(method_name)
