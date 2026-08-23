class_name CombatMockArena
extends Control

## Visual Combat Arena & Adapter Simulator connecting RunManager to Combat Loop

@onready var district_label: Label = $VBox/TopBar/DistrictLabel
@onready var combat_type_label: Label = $VBox/TopBar/CombatTypeLabel
@onready var player_container: HBoxContainer = $VBox/Arena/PlayerSide/PlayerContainer
@onready var enemy_container: HBoxContainer = $VBox/Arena/EnemySide/EnemyContainer
@onready var combat_log: RichTextLabel = $VBox/BottomBar/CombatLog
@onready var auto_resolve_timer: Timer = $AutoResolveTimer

var combat_payload: Dictionary = {}

func _ready() -> void:
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		combat_payload = gm.active_combat_payload
	_setup_arena()

func _setup_arena() -> void:
	if combat_payload.is_empty():
		return
		
	var dist_id = combat_payload.get("district_id", 1)
	var is_boss = combat_payload.get("is_boss", false)
	
	if district_label:
		district_label.text = "DISTRICT %d COMBAT ARENA" % dist_id
	if combat_type_label:
		combat_type_label.text = "★ DISTRICT BOSS FIGHT" if is_boss else "⚔ SECURITY PATROL CLASH"
		combat_type_label.add_theme_color_override("font_color", Color(1, 0.1, 0.2) if is_boss else Color(1, 0.3, 0.5))
		
	_populate_player_squad()
	_populate_enemy_squad()
	
	if combat_log:
		combat_log.text = "[color=#00f5d4][SYSTEM][/color] Combat subroutines initialized. Auto-battler loop engaged.\n"

func _populate_player_squad() -> void:
	if not player_container:
		return
	for c in player_container.get_children():
		c.queue_free()
		
	var crew: Array = combat_payload.get("player_crew", [])
	for unit in crew:
		var panel = _create_unit_box(unit as UnitInstance, true)
		player_container.add_child(panel)

func _populate_enemy_squad() -> void:
	if not enemy_container:
		return
	for c in enemy_container.get_children():
		c.queue_free()
		
	var enemies: Array = combat_payload.get("enemy_squad", [])
	for unit in enemies:
		var panel = _create_unit_box(unit as UnitInstance, false)
		enemy_container.add_child(panel)

func _create_unit_box(unit: UnitInstance, is_player: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 140)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	
	var name_lbl = Label.new()
	name_lbl.text = unit.unit_resource.display_name if (unit and unit.unit_resource) else "Enemy"
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0, 0.95, 0.83) if is_player else Color(1, 0.2, 0.4))
	vbox.add_child(name_lbl)
	
	var role_lbl = Label.new()
	role_lbl.text = unit.unit_resource.get_role_name().to_upper() if (unit and unit.unit_resource) else "TANK"
	role_lbl.add_theme_font_size_override("font_size", 9)
	role_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(role_lbl)
	
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 10)
	hp_bar.value = 100
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)
	
	var mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(0, 6)
	mana_bar.value = 35
	mana_bar.show_percentage = false
	vbox.add_child(mana_bar)
	
	var tags_lbl = Label.new()
	var tag_names: Array[String] = []
	if unit:
		for t in unit.get_all_tags():
			tag_names.append(Enums.tag_to_string(t))
	tags_lbl.text = "Tags: %s" % (", ".join(tag_names) if not tag_names.is_empty() else "None")
	tags_lbl.add_theme_font_size_override("font_size", 8)
	tags_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 1.0))
	vbox.add_child(tags_lbl)
	
	panel.add_child(vbox)
	return panel

func _on_resolve_victory_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").finish_combat_encounter(true, {"duration": 12.4, "damage_dealt": 1420})

func _on_resolve_defeat_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").finish_combat_encounter(false, {"duration": 8.1, "damage_dealt": 320})
