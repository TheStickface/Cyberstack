class_name Main
extends Control

## Root Viewport Router that swaps screens based on GameManager state

const TitleScreenScene = preload("res://src/ui/screens/TitleScreen.tscn")
const DistrictMapScene = preload("res://src/ui/screens/DistrictMapScreen.tscn")
const PrepScreenScene = preload("res://src/ui/screens/PrepScreen.tscn")
const CombatArenaScene = preload("res://src/ui/screens/CombatMockArena.tscn")
const RunEndScene = preload("res://src/ui/screens/RunEndScreen.tscn")
const CodexScene = preload("res://src/ui/screens/CodexScreen.tscn")
const MetricsScene = preload("res://src/ui/screens/MetricsDashboard.tscn")

@onready var screen_container: Control = $ScreenContainer

var current_screen_node: Node = null

func _ready() -> void:
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.state_changed.connect(_on_game_state_changed)
		_show_screen_for_state(gm.current_state)
	else:
		_show_title_screen()

func _on_game_state_changed(new_state: int) -> void:
	_show_screen_for_state(new_state)

func _show_screen_for_state(state: int) -> void:
	if current_screen_node:
		current_screen_node.queue_free()
		current_screen_node = null
		
	match state:
		0: # TITLE
			_show_title_screen()
		1: # MAP
			_show_map_screen()
		2: # PREP
			_show_prep_screen()
		3: # COMBAT
			_show_combat_screen()
		4: # RUN_END
			_show_run_end_screen()
		5: # CODEX
			_show_codex_screen()
		6: # METRICS
			_show_metrics_screen()

func _show_title_screen() -> void:
	var screen = TitleScreenScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen

func _show_map_screen() -> void:
	var screen: DistrictMapScreen = DistrictMapScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen
	
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.active_run_manager:
			screen.run_mgr = gm.active_run_manager
			screen._refresh_map()

func _show_prep_screen() -> void:
	var screen: PrepScreen = PrepScreenScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen
	
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.active_run_manager:
			screen.shop_mgr = gm.active_run_manager.shop_mgr
			screen.crew_mgr = gm.active_run_manager.crew_mgr
			screen._refresh_all()

func _show_combat_screen() -> void:
	var screen: CombatMockArena = CombatArenaScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen

func _show_run_end_screen() -> void:
	var screen: RunEndScreen = RunEndScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen
	
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		screen.setup(gm.last_run_summary)

func _show_codex_screen() -> void:
	var screen: CodexScreen = CodexScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen

func _show_metrics_screen() -> void:
	var screen: MetricsDashboard = MetricsScene.instantiate()
	screen_container.add_child(screen)
	current_screen_node = screen
