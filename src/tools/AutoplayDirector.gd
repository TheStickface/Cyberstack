class_name AutoplayDirector
extends Node

## Live spectator "autoplay" bot — drives an entire real game run end-to-end
## (shop buys/rerolls/placement/equips, map navigation, event choices, and
## combat hand-off) through the ACTUAL GameManager/ShopManager/CrewManager/
## RunManager, at a human-watchable pace (one action every `tick_seconds`).
##
## Each new run, it picks one strategy at random from the top 5 measured
## winrate archetypes in data/strategy_metrics.json (falling back to the
## curated StrategyArchetypes.ARCHETYPES list if that file doesn't exist
## yet — see StrategyMetricsSimulator). A persistent overlay names the
## active strategy; a second overlay shows what it wants to buy next, so its
## logic can be visually confirmed against what actually gets bought.
##
## Engaged by src/ui/screens/Main.gd when launched with --autoplay
## (see Launch_Cyberstack_Autoplay.bat). Not wired into any normal menu —
## this is a dev/spectator tool, not shipped gameplay.

const DataRepoScript = preload("res://src/systems/DataRepository.gd")
const METRICS_PATH := "res://data/strategy_metrics.json"
const TOP_N := 5
const MAX_REROLLS_PER_VISIT := 2
const MIN_WORTH_TO_BUY := 2.5  ## below this score, prefer a reroll over a purchase
const STUCK_TICK_LIMIT := 15   ## ~30s of no progress in a shop visit forces a lock-in
const COMBAT_POLL_LIMIT := 200 ## ~60s of an unresolved fight triggers the abandon safety valve

# GameManager.GameState ordinals (GameManager.gd has no class_name, so the
# enum isn't reachable by type name from here — Main.gd's own
# _show_screen_for_state already matches on these same raw ints).
const ST_TITLE := 0
const ST_MAP := 1
const ST_PREP := 2
const ST_COMBAT := 3
const ST_RUN_END := 4

var tick_seconds: float = 2.0
var repo: Object = null
var gm: Node = null
var strategy: Dictionary = {}

var _reroll_count_this_visit: int = 0
var _stuck_ticks: int = 0
var _held_conduit: ConduitResource = null

# Overlay (built in code — a dev/spectator tool, no .tscn authoring needed).
var _overlay_layer: CanvasLayer
var _headline_label: RichTextLabel
var _status_label: RichTextLabel
var _wants_label: RichTextLabel

func engage(p_tick_seconds: float = 2.0) -> void:
	tick_seconds = p_tick_seconds
	gm = get_node("/root/GameManager")
	repo = DataRepoScript.new()
	repo.load_all_data("res://data")

	_build_overlay()
	_start_new_run()
	_run_loop()

func _start_new_run() -> void:
	strategy = _pick_strategy()
	var starter = _pick_starter(strategy)
	_reroll_count_this_visit = 0
	_stuck_ticks = 0
	_held_conduit = null
	_set_headline(strategy)
	_set_status("Starting a new run as %s..." % starter)
	gm.start_new_game(starter)

func _run_loop() -> void:
	while true:
		match gm.current_state:
			ST_PREP:
				await _drive_prep_tick()
			ST_MAP:
				await _drive_map_tick()
			ST_COMBAT:
				await _drive_combat_watch()
			ST_RUN_END:
				await _drive_run_end()
			_:
				await get_tree().create_timer(0.5).timeout

# --- PREP (shop) ---------------------------------------------------------

func _drive_prep_tick() -> void:
	var run_mgr = gm.active_run_manager
	if run_mgr == null:
		await get_tree().create_timer(0.5).timeout
		return
	var shop: ShopManager = run_mgr.shop_mgr
	var crew: CrewManager = run_mgr.crew_mgr

	_refresh_wants(crew)

	var action := ""
	if _held_conduit != null:
		action = _install_held_conduit(crew)
	if action == "":
		action = _place_one_benched_unit(crew)
	if action == "":
		action = _equip_one_inventory_augment(crew)
	if action == "":
		action = _buy_best_shop_slot(shop, crew)
	if action == "" and shop.gold >= shop.get_reroll_cost() and _reroll_count_this_visit < MAX_REROLLS_PER_VISIT:
		shop.reroll_shop(repo)
		_reroll_count_this_visit += 1
		action = "Rerolled the shop (%d/%d this visit)." % [_reroll_count_this_visit, MAX_REROLLS_PER_VISIT]

	if action != "":
		_stuck_ticks = 0
		_set_status(action)
	else:
		_stuck_ticks += 1
		var forced = _stuck_ticks > STUCK_TICK_LIMIT
		_lock_in(run_mgr, crew, forced)

	# The real PrepScreen is only (re)built when GameManager.state_changed
	# fires, which happens once on entering PREP — not again for the many
	# buy/reroll/equip/place ticks that follow within the same shop visit.
	# Without this, the bot's data mutations are real but the screen the
	# player is looking at never redraws to show them, which reads as "it
	# says it bought something but nothing happened" (or, worse, a reroll
	# silently invalidates what's still on screen so a later purchase names
	# a unit that looks unavailable in the now-stale card grid).
	_refresh_prep_screen_ui()

	await get_tree().create_timer(tick_seconds).timeout

## Forces the currently-displayed PrepScreen (if that's what's on screen) to
## redraw from the live shop_mgr/crew_mgr state. Pure display refresh, no
## side effects — safe to call every tick regardless of what changed.
func _refresh_prep_screen_ui() -> void:
	var main = get_parent()
	if main == null:
		return
	var screen = main.current_screen_node as PrepScreen
	if screen != null:
		screen._refresh_all()

func _install_held_conduit(crew: CrewManager) -> String:
	var conduit_name = _held_conduit.display_name
	for s in range(6):
		if crew.is_slot_unlocked(s) and not crew.slot_conduits.has(s):
			var coords = UnitInstance.slot_to_coords(s)
			if _held_conduit.can_install_on_row(coords.x):
				var installed = crew.install_conduit(s, _held_conduit)
				if installed:
					_held_conduit = null
					return "Installed conduit: %s." % conduit_name
				# Failed on this slot (e.g. lost the race to another
				# mutation) — keep holding it and try again next tick
				# rather than reporting success that didn't happen.
				return "Tried to install %s — slot %d rejected it, retrying next tick." % [conduit_name, s]
	_held_conduit = null
	return "No valid grid slot for conduit %s — discarded." % conduit_name

func _place_one_benched_unit(crew: CrewManager) -> String:
	for u in crew.benched_units:
		if u == null:
			continue
		var bench_size_before = crew.benched_units.size()
		# Reuses BalanceSimulator's role-based frontline/backline placement
		# heuristic verbatim — same placement logic the offline metrics run
		# was measured with.
		BalanceSimulator._place_unit_tactically(crew, u, crew.current_district)
		if crew.benched_units.size() < bench_size_before:
			return "Placed %s on the tactical grid." % u.unit_resource.display_name
	return ""

func _equip_one_inventory_augment(crew: CrewManager) -> String:
	for inv_idx in range(crew.augment_inventory.size()):
		var aug = crew.augment_inventory[inv_idx]
		if aug == null:
			continue
		var best_unit: UnitInstance = null
		var best_slot := -1
		var best_score := -1.0
		for u in crew.fielded_units:
			for s_idx in range(u.equipped_augments.size()):
				if u.equipped_augments[s_idx] == null and u.can_equip_augment(s_idx, aug):
					var sc = StrategyArchetypes.score_augment(aug, strategy)
					if sc > best_score:
						best_score = sc
						best_unit = u
						best_slot = s_idx
		if best_unit != null:
			var equipped = crew.equip_augment_from_inventory(best_unit, best_slot, inv_idx)
			if equipped:
				return "Equipped %s onto %s." % [aug.display_name, best_unit.unit_resource.display_name]
			return "Tried to equip %s onto %s — failed." % [aug.display_name, best_unit.unit_resource.display_name]
	return ""

func _buy_best_shop_slot(shop: ShopManager, crew: CrewManager) -> String:
	var existing_ids: Dictionary = {}
	for u in crew.fielded_units:
		if u and u.unit_resource:
			existing_ids[u.unit_resource.id] = true
	for u in crew.benched_units:
		if u and u.unit_resource:
			existing_ids[u.unit_resource.id] = true

	var best_kind := ""
	var best_index := -1
	var best_score := -1.0

	for i in range(shop.unit_slots.size()):
		var slot = shop.unit_slots[i]
		if slot.get("is_bought", true) or slot.get("resource", null) == null:
			continue
		if slot["cost"] > shop.gold:
			continue
		var sc = StrategyArchetypes.score_unit(slot["resource"], strategy, {"existing_ids": existing_ids})
		if sc > best_score:
			best_score = sc
			best_kind = "unit"
			best_index = i

	for i in range(shop.augment_slots.size()):
		var slot = shop.augment_slots[i]
		if slot.get("is_bought", true) or slot.get("resource", null) == null:
			continue
		if slot["cost"] > shop.gold:
			continue
		var wearable := false
		for u in crew.fielded_units:
			for s_idx in range(u.equipped_augments.size()):
				if u.equipped_augments[s_idx] == null and u.can_equip_augment(s_idx, slot["resource"]):
					wearable = true
					break
			if wearable:
				break
		if not wearable:
			continue
		var sc = StrategyArchetypes.score_augment(slot["resource"], strategy)
		if sc > best_score:
			best_score = sc
			best_kind = "augment"
			best_index = i

	for i in range(shop.conduit_slots.size()):
		var slot = shop.conduit_slots[i]
		if slot.get("is_bought", true) or slot.get("resource", null) == null:
			continue
		if slot["cost"] > shop.gold:
			continue
		var cond_res: ConduitResource = slot["resource"]
		var has_open_slot := false
		for s in range(6):
			if crew.is_slot_unlocked(s) and not crew.slot_conduits.has(s) and cond_res.can_install_on_row(UnitInstance.slot_to_coords(s).x):
				has_open_slot = true
				break
		if not has_open_slot:
			continue
		var sc = 2.0  # flat conduit worth — archetypes don't carry a conduit preference
		if sc > best_score:
			best_score = sc
			best_kind = "conduit"
			best_index = i

	if best_kind == "" or best_score < MIN_WORTH_TO_BUY:
		return ""

	# Name the target BEFORE buying — buy_*_slot mutates the slot in place
	# (marks it is_bought), so if anything downstream reports failure we
	# still know exactly what was attempted rather than guessing from a
	# possibly-already-mutated slot.
	match best_kind:
		"unit":
			var target_name: String = shop.unit_slots[best_index]["resource"].display_name
			var res = shop.buy_unit_slot(best_index, crew)
			if res.get("success", false):
				return "Bought %s (-%dg)." % [target_name, shop.unit_slots[best_index]["cost"]]
			return "Tried to buy %s — failed (%s)." % [target_name, res.get("error", "unknown reason")]
		"augment":
			var target_name: String = shop.augment_slots[best_index]["resource"].display_name
			var res = shop.buy_augment_slot(best_index, crew)
			if res.get("success", false):
				return "Bought augment: %s (-%dg)." % [target_name, shop.augment_slots[best_index]["cost"]]
			return "Tried to buy augment %s — failed (%s)." % [target_name, res.get("error", "unknown reason")]
		"conduit":
			var target_name: String = shop.conduit_slots[best_index]["resource"].display_name
			var res = shop.buy_conduit_slot(best_index, crew)
			if res.get("success", false):
				_held_conduit = res["item"] as ConduitResource
				return "Bought conduit: %s (-%dg)." % [target_name, shop.conduit_slots[best_index]["cost"]]
			return "Tried to buy conduit %s — failed (%s)." % [target_name, res.get("error", "unknown reason")]
	return ""

func _lock_in(run_mgr: RunManager, crew: CrewManager, force: bool = false) -> void:
	var result = CrewValidator.validate_crew(crew.fielded_units, crew.current_district)
	if not result.valid and not force:
		_set_status("Crew not deployment-ready yet (%s)." % ", ".join(result.errors))
		return
	if force and not result.valid:
		_set_status("Nothing left to do after a stuck shop visit — forcing lock-in.")
	else:
		_set_status("Locking in and returning to the map...")
	if run_mgr.get_current_encounter_type() == Enums.EncounterType.SHOP:
		run_mgr.complete_encounter(true)
	SaveManager.save_active_run(run_mgr)
	gm.open_map()
	_reroll_count_this_visit = 0
	_stuck_ticks = 0

# --- MAP (navigation) ------------------------------------------------------

func _drive_map_tick() -> void:
	await get_tree().create_timer(tick_seconds).timeout
	var run_mgr = gm.active_run_manager
	if run_mgr == null:
		return
	match run_mgr.get_current_encounter_type():
		Enums.EncounterType.FIGHT:
			_set_status("Advancing to the next fight...")
			gm.start_combat_encounter(false, repo)
		Enums.EncounterType.BOSS:
			_set_status("Advancing to the district boss...")
			gm.start_combat_encounter(true, repo)
		Enums.EncounterType.SHOP:
			_set_status("Opening the shop...")
			gm.open_prep_phase()
		Enums.EncounterType.EVENT:
			_resolve_event(run_mgr)

func _resolve_event(run_mgr: RunManager) -> void:
	var ev: NarrativeEventResource = repo.get_random_event()
	if ev == null or ev.choices.is_empty():
		run_mgr.complete_encounter(true)
		gm.open_map()
		return
	var best_choice: EventChoiceResource = BalanceSimulator._pick_best_event_choice(ev, run_mgr.shop_mgr.gold, run_mgr.crew_mgr.fielded_units)
	if best_choice == null:
		best_choice = ev.choices[0]
	var outcome = EventManager.execute_choice(best_choice, run_mgr.shop_mgr, run_mgr.crew_mgr)
	_set_status("Event '%s': chose \"%s\"." % [ev.title, best_choice.text])
	if outcome.get("combat_triggered", false):
		gm.start_combat_encounter(false, repo)
	else:
		run_mgr.complete_encounter(true)
		gm.open_map()

# --- COMBAT (watch and hand off) ------------------------------------------

func _drive_combat_watch() -> void:
	_set_status("Watching the fight play out...")
	var main = get_parent()
	var arena: CombatMockArena = null
	var waited := 0
	while true:
		await get_tree().create_timer(0.3).timeout
		waited += 1
		if gm.current_state != ST_COMBAT:
			return
		arena = main.current_screen_node as CombatMockArena
		if arena != null and arena.battle_resolved:
			break
		if waited > COMBAT_POLL_LIMIT:
			_set_status("Combat didn't resolve in time — abandoning this run.")
			gm.abandon_run()
			return
	await get_tree().create_timer(tick_seconds).timeout  # let the viewer see the result screen
	_set_status("Fight %s. Continuing..." % ("won" if arena.is_victory else "lost"))
	gm.finish_combat_encounter(arena.is_victory, {
		"duration": arena.battle_time,
		"damage_dealt": arena.total_player_damage,
		"damage_taken": arena.total_enemy_damage
	})

# --- RUN_END (loop into a fresh run) --------------------------------------

func _drive_run_end() -> void:
	var victory = gm.last_run_summary.get("victory", false)
	_set_status("Run complete (%s). Starting a fresh run with a new strategy..." % ("VICTORY" if victory else "defeat"))
	await get_tree().create_timer(tick_seconds * 2.0).timeout
	_start_new_run()

# --- Strategy selection ----------------------------------------------------

func _pick_strategy() -> Dictionary:
	var pool: Array = _load_top_metrics()
	if pool.is_empty():
		_set_status("No measured strategy_metrics.json found — run StrategyMetricsSimulator; using curated archetypes for now.")
		pool = StrategyArchetypes.ARCHETYPES.duplicate()
	var top = pool.slice(0, mini(TOP_N, pool.size()))
	return top[randi() % top.size()]

func _load_top_metrics() -> Array:
	if not FileAccess.file_exists(METRICS_PATH):
		return []
	var file = FileAccess.open(METRICS_PATH, FileAccess.READ)
	if file == null:
		return []
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("archetypes"):
		return []
	var archetypes: Array = parsed["archetypes"]
	archetypes.sort_custom(func(a, b): return a.get("winrate", 0.0) > b.get("winrate", 0.0))
	return archetypes

func _pick_starter(p_strategy: Dictionary) -> String:
	var starters: Array = p_strategy.get("preferred_starters", [])
	if starters is Array and not starters.is_empty():
		return starters[randi() % starters.size()]
	return StrategyArchetypes.ALL_STARTER_IDS[randi() % StrategyArchetypes.ALL_STARTER_IDS.size()]

# --- Overlay ----------------------------------------------------------------

func _build_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 100
	get_parent().add_child(_overlay_layer)

	_headline_label = _make_label_panel(Vector2(0, 0), Vector2(0, 56), 18, Color(0.05, 0.95, 0.85))
	_status_label = _make_label_panel(Vector2(0, 56), Vector2(0, 32), 13, Color(0.9, 0.9, 0.95))
	_wants_label = _make_label_panel(Vector2(12, 0), Vector2(420, 130), 13, Color(1.0, 0.85, 0.0))

	_reflow_overlay()
	get_viewport().size_changed.connect(_reflow_overlay)

func _reflow_overlay() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	if _headline_label:
		_headline_label.get_parent().size = Vector2(vp_size.x, 56)
	if _status_label:
		_status_label.get_parent().size = Vector2(vp_size.x, 32)
	if _wants_label:
		_wants_label.get_parent().position = Vector2(12, vp_size.y - 142)

func _make_label_panel(pos: Vector2, sz: Vector2, font_size: int, font_color: Color) -> RichTextLabel:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = sz
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.82)
	style.set_border_width_all(2)
	style.border_color = Color(0.0, 0.9, 0.83, 0.55)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	_overlay_layer.add_child(panel)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.fit_content = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", font_color)
	label.custom_minimum_size = sz
	label.size = sz
	panel.add_child(label)
	return label

func _set_headline(s: Dictionary) -> void:
	if _headline_label:
		_headline_label.text = "[b]🤖 AUTOPLAY — %s[/b]\n%s" % [s.get("name", "?"), s.get("description", "")]

func _set_status(msg: String) -> void:
	print("[Autoplay] %s" % msg)
	if _status_label:
		_status_label.text = msg

func _refresh_wants(crew: CrewManager) -> void:
	if _wants_label == null:
		return
	var lines = StrategyArchetypes.describe_wants(strategy, crew)
	_wants_label.text = "[b]Wants Next:[/b]\n• " + "\n• ".join(lines)
