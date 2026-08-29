class_name DistrictMapScreen
extends Control

## Visual overview map displaying district node progression and routing encounters

const DistrictNodeWidgetScene = preload("res://src/ui/components/DistrictNodeWidget.tscn")
const DataRepoScript = preload("res://src/systems/DataRepository.gd")

var repo: Object = null
var run_mgr: RunManager = null

@onready var district_title: Label = $Margin/VBox/TopBar/DistrictTitle
@onready var crew_count_label: Label = $Margin/VBox/TopBar/CrewCountLabel
@onready var gold_label: Label = $Margin/VBox/TopBar/GoldLabel
@onready var nodes_container: HBoxContainer = $Margin/VBox/CenterArea/MapScroll/NodesContainer
@onready var action_btn: Button = $Margin/VBox/BottomBar/ActionBtn
@onready var status_label: Label = $Margin/VBox/BottomBar/StatusLabel
@onready var event_modal: EventModal = $EventModal

func _ready() -> void:
	if get_node_or_null("/root/GameManager") and get_node("/root/GameManager").active_run_manager:
		var gm = get_node("/root/GameManager")
		run_mgr = gm.active_run_manager
		repo = run_mgr._repo if run_mgr._repo else DataRepoScript.new()
	else:
		repo = DataRepoScript.new()
		repo.load_all_data("res://data")
		run_mgr = RunManager.new(repo)
		run_mgr.start_new_run()
	
	if event_modal:
		event_modal.visible = false
		event_modal.event_resolved.connect(_on_event_resolved)
		
	_refresh_map()

func _refresh_map() -> void:
	_refresh_header()
	_refresh_nodes()
	_refresh_action_button()

func _refresh_header() -> void:
	if district_title and run_mgr.current_district:
		var sub_suffix = " (APPROACH)" if run_mgr.current_subdistrict_index == 1 else " (STRONGHOLD)"
		district_title.text = "%s: %s%s" % [run_mgr.get_stage_string(), run_mgr.current_district.display_name.to_upper(), sub_suffix]
		district_title.add_theme_color_override("font_color", run_mgr.current_district.theme_color)
	if crew_count_label:
		crew_count_label.text = "CREW: %d / %d" % [run_mgr.crew_mgr.fielded_units.size(), run_mgr.crew_mgr.get_max_field_units()]
	if gold_label:
		gold_label.text = "%s: %d" % [Constants.CURRENCY_NAME.to_upper(), run_mgr.shop_mgr.gold]
	if status_label and run_mgr.current_district:
		status_label.text = "★ %s | %s" % [run_mgr.current_district.display_name, run_mgr.current_district.get_perk_description()]

func _refresh_nodes() -> void:
	if not nodes_container:
		return
		
	for c in nodes_container.get_children():
		c.queue_free()
		
	for node in run_mgr.district_nodes:
		var widget: DistrictNodeWidget = DistrictNodeWidgetScene.instantiate()
		nodes_container.add_child(widget)
		widget.setup(
			node["index"],
			node["type"],
			node["visited"],
			node["current"]
		)
		widget.node_clicked.connect(_on_node_clicked)

func _refresh_action_button() -> void:
	if not action_btn:
		return
		
	var enc_type = run_mgr.get_current_encounter_type()
	match enc_type:
		Enums.EncounterType.FIGHT:
			action_btn.text = "ENTER COMBAT [⚔ FIGHT]"
			action_btn.add_theme_color_override("font_color", Color(1, 0.2, 0.4))
		Enums.EncounterType.SHOP:
			action_btn.text = "OPEN SHOP / PREP PHASE [$]"
			action_btn.add_theme_color_override("font_color", Color(1, 0.85, 0))
		Enums.EncounterType.EVENT:
			action_btn.text = "INVESTIGATE SIGNAL [? EVENT]"
			action_btn.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		Enums.EncounterType.BOSS:
			if run_mgr.current_subdistrict_index == 1:
				action_btn.text = "ENGAGE SECURITY CAPTAIN [★ MINI-BOSS]"
			else:
				action_btn.text = "ENGAGE DISTRICT OVERLORD [☠ FINAL BOSS]"
			action_btn.add_theme_color_override("font_color", Color(1, 0.1, 0.2))

func _on_manage_crew_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").open_prep_phase()

func _on_action_btn_pressed() -> void:
	var enc_type = run_mgr.get_current_encounter_type()
	match enc_type:
		Enums.EncounterType.FIGHT:
			if get_node_or_null("/root/GameManager"):
				get_node("/root/GameManager").start_combat_encounter(false, repo)
			else:
				_complete_current_encounter(true)
		Enums.EncounterType.BOSS:
			if get_node_or_null("/root/GameManager"):
				get_node("/root/GameManager").start_combat_encounter(true, repo)
			else:
				_complete_current_encounter(true)
		Enums.EncounterType.SHOP:
			if get_node_or_null("/root/GameManager"):
				get_node("/root/GameManager").open_prep_phase()
			else:
				_complete_current_encounter(true)
		Enums.EncounterType.EVENT:
			var random_ev = repo.get_random_event()
			if random_ev and event_modal:
				event_modal.setup(random_ev, run_mgr.shop_mgr, run_mgr.crew_mgr)
			else:
				_complete_current_encounter(true)

func _on_event_resolved(outcome: Dictionary) -> void:
	if outcome.get("triggers_combat", false):
		status_label.text = "Event triggered combat encounter!"
		if get_node_or_null("/root/GameManager"):
			get_node("/root/GameManager").start_combat_encounter(false, repo)
	else:
		status_label.text = "Event concluded. Moving forward."
		_complete_current_encounter(true)

func _complete_current_encounter(victory: bool = true) -> void:
	var result = run_mgr.complete_encounter(victory)
	var status = result.get("status", "")
	
	if status == "district_advanced":
		status_label.text = "DISTRICT CLEARED! Advanced to %s. Crew cap increased to %d." % [
			result.get("stage", ""),
			result.get("new_crew_cap", 2)
		]
	elif status == "subdistrict_advanced":
		status_label.text = "PERIMETER CLEARED! Advancing to Stronghold (%s)." % result.get("stage", "")
	elif status == "victory":
		status_label.text = "VICTORY! All 4 city districts conquered!"
	elif status == "game_over":
		status_label.text = "MISSION FAILED. Run terminated."
		
	if get_node_or_null("/root/SaveManager") and run_mgr:
		SaveManager.save_active_run(run_mgr)
		
	_refresh_map()

func _on_abandon_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").abandon_run()

func _on_node_clicked(node_idx: int) -> void:
	pass
