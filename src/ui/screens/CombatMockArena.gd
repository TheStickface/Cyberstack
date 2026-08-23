class_name CombatMockArena
extends Control

## Real-Time Autobattler Combat Arena & Simulation Engine

class CombatantState:
	var unit: UnitInstance
	var is_player: bool = true
	var max_hp: float = 500.0
	var current_hp: float = 500.0
	var shield: float = 0.0
	var max_mana: float = 100.0
	var current_mana: float = 0.0
	var attack_damage: float = 40.0
	var ability_power: float = 20.0
	var attack_speed: float = 1.0 # Attacks per second
	var attack_timer: float = 0.0
	var alive: bool = true
	
	var box_panel: PanelContainer = null
	var hp_bar: ProgressBar = null
	var hp_label: Label = null
	var mana_bar: ProgressBar = null
	var status_label: Label = null

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

func _setup_arena() -> void:
	if combat_payload.is_empty():
		return
		
	var dist_id = combat_payload.get("district_id", 1)
	var is_boss = combat_payload.get("is_boss", false)
	
	if district_label:
		district_label.text = "DISTRICT %d COMBAT ARENA" % dist_id
	if combat_type_label:
		combat_type_label.text = "★ DISTRICT BOSS CLASH" if is_boss else "⚔ SECURITY PATROL ENCOUNTER"
		combat_type_label.add_theme_color_override("font_color", Color(1, 0.1, 0.2) if is_boss else Color(1, 0.3, 0.5))
		
	var crew_size = combat_payload.get("player_crew", []).size()
	var max_cap = Constants.DISTRICT_CREW_LIMITS.get(dist_id, 2)
	var player_header: Label = get_node_or_null("Margin/VBox/Arena/PlayerSide/PlayerHeader")
	if player_header:
		player_header.text = "PLAYER SQUAD (%d / %d FIELDED IN COMBAT):" % [crew_size, max_cap]
		
	_initialize_squads()
	battle_time = 0.0
	battle_active = true
	battle_resolved = false
	
	_log("[color=#00f5d4][SYSTEM][/color] Combat loop initiated. Both squads armed and deployed.")

func _initialize_squads() -> void:
	player_states.clear()
	enemy_states.clear()
	
	if player_container:
		for c in player_container.get_children():
			c.queue_free()
	if enemy_container:
		for c in enemy_container.get_children():
			c.queue_free()
			
	var player_crew: Array = combat_payload.get("player_crew", [])
	for unit in player_crew:
		var state = _create_combatant(unit as UnitInstance, true)
		player_states.append(state)
		if player_container:
			player_container.add_child(state.box_panel)
			
	var enemy_squad: Array = combat_payload.get("enemy_squad", [])
	for unit in enemy_squad:
		var state = _create_combatant(unit as UnitInstance, false)
		enemy_states.append(state)
		if enemy_container:
			enemy_container.add_child(state.box_panel)

func _create_combatant(unit: UnitInstance, is_player: bool) -> CombatantState:
	var state = CombatantState.new()
	state.unit = unit
	state.is_player = is_player
	
	if unit:
		state.max_hp = unit.calculate_effective_stat(Enums.StatType.MAX_HEALTH)
		state.current_hp = state.max_hp
		state.attack_damage = unit.calculate_effective_stat(Enums.StatType.ATTACK_DAMAGE)
		state.ability_power = unit.calculate_effective_stat(Enums.StatType.ABILITY_POWER)
		var spd = unit.calculate_effective_stat(Enums.StatType.SPEED)
		state.attack_speed = clampf(spd / 50.0, 0.6, 2.5)
	else:
		state.max_hp = 450.0
		state.current_hp = 450.0
		state.attack_damage = 35.0
		state.ability_power = 20.0
		state.attack_speed = 1.0
		
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

func _perform_auto_attack(att: CombatantState, defenders: Array[CombatantState]) -> void:
	var target = _find_target(defenders)
	if target == null:
		return
		
	var dmg = att.attack_damage * randf_range(0.9, 1.1)
	_apply_damage(target, dmg, att)
	
	# Gain Mana on attack
	att.current_mana = minf(att.current_mana + 20.0, 100.0)
	if att.current_mana >= 100.0:
		_cast_ability(att, defenders)

func _cast_ability(caster: CombatantState, defenders: Array[CombatantState]) -> void:
	caster.current_mana = 0.0
	var u_name = caster.unit.unit_resource.display_name if caster.unit else "Operative"
	var ab_name = caster.unit.unit_resource.ability_name if caster.unit else "Overclock Strike"
	
	_log("[b][color=%s]⚡ %s triggers %s![/color][/b]" % [
		"#00f5d4" if caster.is_player else "#ff3366",
		u_name,
		ab_name
	])
	
	# Ability mechanics by role
	var role = caster.unit.unit_resource.role if caster.unit else Enums.UnitRole.TANK
	match role:
		Enums.UnitRole.TANK:
			caster.shield += 180.0 + (caster.ability_power * 1.5)
			_log("   🛡 %s generates a %.0f kinetic barrier!" % [u_name, caster.shield])
		Enums.UnitRole.HACKER:
			var target = _find_target(defenders)
			if target:
				var ap_dmg = 120.0 + (caster.ability_power * 2.2)
				_apply_damage(target, ap_dmg, caster, true)
		Enums.UnitRole.SNIPER:
			var weakest = _find_weakest_target(defenders)
			if weakest:
				var crit_dmg = (caster.attack_damage * 2.2) + caster.ability_power
				_apply_damage(weakest, crit_dmg, caster, true)
		Enums.UnitRole.FIXER:
			caster.current_hp = minf(caster.current_hp + 150.0 + caster.ability_power, caster.max_hp)
			_log("   💉 %s repairs systems, recovering health!" % u_name)
		_:
			var target = _find_target(defenders)
			if target:
				_apply_damage(target, caster.attack_damage * 1.5, caster, true)

func _apply_damage(target: CombatantState, raw_dmg: float, attacker: CombatantState, is_ability: bool = false) -> void:
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

func _find_target(defenders: Array[CombatantState]) -> CombatantState:
	for d in defenders:
		if d.alive:
			return d
	return null

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
