class_name CombatMockArena
extends Control

## Real-Time Autobattler Combat Arena & Simulation Engine

const CombatEngineScript = preload("res://src/systems/CombatEngine.gd")
const CombatantState = CombatEngineScript.CombatantState

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
	CombatEngineScript.apply_district_environmental_hazards(player_states, enemy_states, dist_id, _get_engine_callbacks())
	
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
	var dist_id = combat_payload.get("district_id", 1)
	var is_boss = combat_payload.get("is_boss", false)
	var form_bonuses: Dictionary = combat_payload.get("formation_bonuses", {})
	var synergies: SynergyReport = combat_payload.get("player_synergies", null)
	
	var state = CombatEngineScript.create_combatant(unit, is_player, slot_idx, form_bonuses, dist_id, is_boss, synergies)
	
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
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(header_hbox)
	
	if unit and unit.unit_resource and unit.unit_resource.portrait:
		var portrait_rect = TextureRect.new()
		portrait_rect.texture = unit.unit_resource.portrait
		portrait_rect.custom_minimum_size = Vector2(28, 28)
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header_hbox.add_child(portrait_rect)
		
	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 0)
	header_hbox.add_child(title_vbox)
	
	var name_lbl = Label.new()
	var stars = unit.get_star_string() if (unit and unit.star_level > 1) else ""
	var disp_name = unit.unit_resource.display_name if (unit and unit.unit_resource) else "Enforcer"
	name_lbl.text = "%s %s" % [stars, disp_name] if not stars.is_empty() else disp_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	if is_player:
		name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.1) if (unit and unit.star_level == 2) else (Color(1, 0.2, 0.8) if (unit and unit.star_level >= 3) else Color(0, 0.95, 0.83)))
	else:
		name_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.5))
	name_lbl.clip_text = true
	title_vbox.add_child(name_lbl)
	
	var role_lbl = Label.new()
	role_lbl.text = unit.unit_resource.get_role_name().to_upper() if (unit and unit.unit_resource) else "TANK"
	role_lbl.add_theme_font_size_override("font_size", 8)
	role_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	title_vbox.add_child(role_lbl)
	
	if not state.active_conduit_id.is_empty():
		var cond_path = "res://assets/icons/conduits/%s.png" % state.active_conduit_id
		if ResourceLoader.exists(cond_path):
			var cond_rect = TextureRect.new()
			cond_rect.texture = load(cond_path)
			cond_rect.custom_minimum_size = Vector2(24, 24)
			cond_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cond_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cond_rect.tooltip_text = "Tactical Conduit: %s" % state.active_conduit_id
			header_hbox.add_child(cond_rect)

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
	var allies = player_states if (attackers.size() > 0 and attackers[0].is_player) else enemy_states
	CombatEngineScript.tick_squad(attackers, defenders, allies, delta, _get_engine_callbacks())

func _apply_start_of_combat_formations(squad: Array[CombatantState], _is_player: bool) -> void:
	CombatEngineScript.apply_start_of_combat_formations(squad, _get_engine_callbacks())

func _perform_auto_attack(att: CombatantState, defenders: Array[CombatantState]) -> void:
	var allies = player_states if att.is_player else enemy_states
	CombatEngineScript.perform_auto_attack(att, defenders, allies, _get_engine_callbacks())

func _cast_ability(caster: CombatantState, defenders: Array[CombatantState]) -> void:
	var allies = player_states if caster.is_player else enemy_states
	CombatEngineScript.cast_ability(caster, defenders, allies, _get_engine_callbacks())

func _apply_damage(target: CombatantState, raw_dmg: float, attacker: CombatantState, is_ability: bool = false, is_crit: bool = false) -> void:
	var defenders = enemy_states if (attacker and attacker.is_player) else player_states
	var allies = player_states if (attacker and attacker.is_player) else enemy_states
	CombatEngineScript.apply_damage(target, raw_dmg, attacker, is_ability, is_crit, _get_engine_callbacks(), defenders, allies)

func _find_tactical_target(attacker: CombatantState, defenders: Array[CombatantState]) -> CombatantState:
	return CombatEngineScript.find_tactical_target(attacker, defenders)

func _find_weakest_target(defenders: Array[CombatantState]) -> CombatantState:
	return CombatEngineScript.find_weakest_target(defenders)

func _apply_mods_to_combat_state(target: CombatantState, mods: Dictionary, desc: String) -> void:
	CombatEngineScript._apply_mods_to_combat_state(target, mods, desc, _get_engine_callbacks())

func _get_engine_callbacks() -> Dictionary:
	return {
		"on_log": Callable(self, "_log"),
		"on_floating_text": Callable(self, "_spawn_floating_combat_text"),
		"on_flash": Callable(self, "_flash_card_by_combatant"),
		"on_sfx": Callable(self, "_play_sfx"),
		"on_damage_dealt": Callable(self, "_on_engine_damage_dealt"),
		"on_death": Callable(self, "_on_engine_unit_death")
	}

func _flash_card_by_combatant(c: CombatantState, color: Color, duration: float) -> void:
	if c and c.box_panel:
		_flash_card(c.box_panel, color, duration)

func _on_engine_damage_dealt(attacker: CombatantState, _target: CombatantState, dmg: float) -> void:
	if attacker and attacker.is_player:
		total_player_damage += dmg
	else:
		total_enemy_damage += dmg

func _on_engine_unit_death(target: CombatantState, _attacker: CombatantState) -> void:
	if target.status_label:
		target.status_label.text = "✖ DOWN"
		target.status_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	if target.box_panel:
		target.box_panel.modulate = Color(0.4, 0.4, 0.4, 0.7)

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
	if is_equal_approx(speed_multiplier, 1.0):
		speed_multiplier = 2.0
		speed_btn.text = "SPEED: 2x ⏩"
	elif is_equal_approx(speed_multiplier, 2.0):
		speed_multiplier = 3.0
		speed_btn.text = "SPEED: 3x ⏩⏩"
	elif is_equal_approx(speed_multiplier, 3.0):
		speed_multiplier = 5.0
		speed_btn.text = "TURBO: 5x ⚡"
	else:
		speed_multiplier = 1.0
		speed_btn.text = "SPEED: 1x ▶"

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
