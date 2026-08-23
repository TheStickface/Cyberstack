extends Node

## Master Game Flow Coordinator and State Machine Singleton

enum GameState {
	TITLE,
	MAP,
	PREP,
	COMBAT,
	RUN_END,
	CODEX,
	METRICS
}

signal state_changed(new_state: GameState)

var current_state: GameState = GameState.TITLE
var active_profile: MetaProfile = null
var active_run_manager: RunManager = null
var active_combat_payload: Dictionary = {}
var last_run_summary: Dictionary = {}
var last_meta_rewards: Dictionary = {}

func _ready() -> void:
	active_profile = SaveManager.load_profile()

func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func start_new_game(starter_unit_id: String = "runner_blitz", repo_instance: Object = null) -> void:
	active_run_manager = RunManager.new(repo_instance)
	active_run_manager.start_new_run(starter_unit_id)
	active_run_manager.shop_mgr.generate_shop_offerings(1, active_run_manager._repo)
	SaveManager.save_active_run(active_run_manager)
	change_state(GameState.PREP)

func resume_active_run(repo_instance: Object = null) -> bool:
	if not SaveManager.has_active_run():
		return false
	var loaded_run = SaveManager.load_active_run(repo_instance)
	if loaded_run == null:
		return false
	active_run_manager = loaded_run
	change_state(GameState.MAP)
	return true

func open_map() -> void:
	if active_run_manager:
		SaveManager.save_active_run(active_run_manager)
	change_state(GameState.MAP)

func open_prep_phase() -> void:
	change_state(GameState.PREP)

func open_codex() -> void:
	change_state(GameState.CODEX)

func open_metrics() -> void:
	change_state(GameState.METRICS)

func start_combat_encounter(is_boss: bool = false, repo_instance: Object = null) -> void:
	if active_run_manager == null:
		return
		
	var crew = active_run_manager.crew_mgr.fielded_units
	var synergies = active_run_manager.crew_mgr.active_synergy_report
	var district_id = active_run_manager.current_district_index
	
	active_combat_payload = CombatBridge.package_combat_payload(
		crew,
		synergies,
		district_id,
		is_boss,
		repo_instance
	)
	
	change_state(GameState.COMBAT)

func finish_combat_encounter(victory: bool, battle_stats: Dictionary = {}) -> Dictionary:
	if active_run_manager == null:
		return {"status": "error"}
		
	var result = active_run_manager.complete_encounter(victory, battle_stats)
	var status = result.get("status", "")
	
	if status == "game_over" or status == "victory":
		last_run_summary = {
			"victory": (status == "victory"),
			"district": active_run_manager.current_district_index,
			"fights_won": active_run_manager.fights_won,
			"bosses_defeated": active_run_manager.bosses_defeated,
			"gold_earned": active_run_manager.total_gold_earned
		}
		
		# Record Telemetry Event
		TelemetryManager.record_run_summary(
			last_run_summary,
			active_run_manager.crew_mgr.fielded_units
		)
		
		# Process Meta Reputation & Unlocks
		if active_profile == null:
			active_profile = SaveManager.load_profile()
		last_meta_rewards = MetaManager.process_run_end(
			active_profile,
			last_run_summary,
			active_run_manager.crew_mgr.fielded_units
		)
		
		change_state(GameState.RUN_END)
	else:
		# Next node or district advanced -> save run and route appropriately
		SaveManager.save_active_run(active_run_manager)
		var next_type = active_run_manager.get_current_encounter_type()
		if next_type == Enums.EncounterType.SHOP or status == "district_advanced":
			change_state(GameState.PREP)
		else:
			change_state(GameState.MAP)
		
	return result

func return_to_title() -> void:
	active_run_manager = null
	active_combat_payload.clear()
	change_state(GameState.TITLE)
