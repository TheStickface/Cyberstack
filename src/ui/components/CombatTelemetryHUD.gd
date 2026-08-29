class_name CombatTelemetryHUD
extends PanelContainer

## Real-Time In-Game Diagnostic & Combat Telemetry HUD
## Provides live DPS tracking, damage mitigation meters, active DoT inspectors, and speed controls

var arena: Object = null # Reference to CombatMockArena
var is_active: bool = false
var is_paused: bool = false

# UI References
var dps_label: Label = null
var stats_label: Label = null
var dot_tracker_label: Label = null
var speed_btn_group: HBoxContainer = null

func _init(p_arena: Object = null) -> void:
	arena = p_arena
	_build_ui()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(-380, 45)
	size = Vector2(360, 260)
	visible = false

func _build_ui() -> void:
	custom_minimum_size = Vector2(360, 240)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.95, 0.83, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "⚡ COMBAT TELEMETRY & DPS INSPECTOR [F3]"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.0, 0.95, 0.83))
	vbox.add_child(header)
	
	# Speed / Stepper Control Row
	var ctrl_row = HBoxContainer.new()
	ctrl_row.add_theme_constant_override("separation", 4)
	vbox.add_child(ctrl_row)
	
	var pause_btn = Button.new()
	pause_btn.text = "⏸ PAUSE"
	pause_btn.add_theme_font_size_override("font_size", 8)
	pause_btn.pressed.connect(_on_toggle_pause)
	ctrl_row.add_child(pause_btn)
	
	var step_btn = Button.new()
	step_btn.text = "⏯ STEP"
	step_btn.add_theme_font_size_override("font_size", 8)
	step_btn.pressed.connect(_on_step_frame)
	ctrl_row.add_child(step_btn)
	
	var speeds = [0.2, 1.0, 2.0, 4.0]
	for spd in speeds:
		var btn = Button.new()
		btn.text = "%.1fx" % spd
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(func(): _set_combat_speed(spd))
		ctrl_row.add_child(btn)
		
	# Live Meters
	dps_label = Label.new()
	dps_label.text = "PLAYER DPS: 0.0 | ENEMY DPS: 0.0"
	dps_label.add_theme_font_size_override("font_size", 9)
	dps_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(dps_label)
	
	stats_label = Label.new()
	stats_label.text = "Damage: 0 Physical / 0 Spell\nMitigation: 0 Shields Absorbed"
	stats_label.add_theme_font_size_override("font_size", 8)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vbox.add_child(stats_label)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Active Buffs & Debuffs Monitor
	dot_tracker_label = Label.new()
	dot_tracker_label.text = "ACTIVE FORMATION EFFECTS:\n- Tank Kinetic Guards: Active\n- Hacker Mesh Uplinks: Active"
	dot_tracker_label.add_theme_font_size_override("font_size", 8)
	dot_tracker_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	vbox.add_child(dot_tracker_label)

func toggle_visibility() -> bool:
	visible = not visible
	is_active = visible
	return visible

func _process(_delta: float) -> void:
	if not visible or arena == null:
		return
	_update_telemetry_data()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			toggle_visibility()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_SPACE:
			_on_toggle_pause()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_PERIOD:
			_on_step_frame()
			get_viewport().set_input_as_handled()

func _update_telemetry_data() -> void:
	if arena == null:
		return
		
	var b_time = maxf(0.1, arena.battle_time)
	var p_dmg = arena.player_total_damage_dealt if "player_total_damage_dealt" in arena else 0.0
	var e_dmg = arena.enemy_total_damage_dealt if "enemy_total_damage_dealt" in arena else 0.0
	
	if dps_label:
		dps_label.text = "PLAYER DPS: %.1f | ENEMY DPS: %.1f (Time: %.1fs)" % [
			p_dmg / b_time, e_dmg / b_time, b_time
		]
		
	if stats_label:
		var p_alive = 0
		for p in arena.player_states:
			if p.alive: p_alive += 1
		var e_alive = 0
		for e in arena.enemy_states:
			if e.alive: e_alive += 1
			
		stats_label.text = "Surviving Operatives: %d Player vs %d Enemy\nSpeed: %.1fx | Status: %s" % [
			p_alive, e_alive, arena.speed_multiplier if "speed_multiplier" in arena else 1.0,
			"PAUSED" if is_paused else "RUNNING"
		]
		
	if dot_tracker_label and "player_tether_overlay" in arena and arena.player_tether_overlay:
		var t_count = arena.player_tether_overlay.active_tethers.size()
		dot_tracker_label.text = "ACTIVE FORMATION TETHERS: %d Active Links\n- Tank Kinetic Guards\n- Hacker Row Uplinks\n- Fixer Adjacent Bio-Links" % t_count

func _on_toggle_pause() -> void:
	if arena == null: return
	is_paused = not is_paused
	if is_paused:
		arena.speed_multiplier = 0.0
	else:
		arena.speed_multiplier = 1.0

func _on_step_frame() -> void:
	if arena == null: return
	if "battle_active" in arena and arena.battle_active:
		arena._tick_squad(arena.player_states, arena.enemy_states, 0.1)
		arena._tick_squad(arena.enemy_states, arena.player_states, 0.1)
		arena._update_all_bars()
		arena._check_battle_end()

func _set_combat_speed(spd: float) -> void:
	if arena == null: return
	is_paused = false
	arena.speed_multiplier = spd
