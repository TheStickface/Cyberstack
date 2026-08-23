extends Node

## Centralized Event Dispatcher for Cyberstack
## Provides decoupled communication across prep, economy, run progression, and combat.

# Crew & Inventory Signals
signal crew_updated(fielded_units: Array)
signal synergies_calculated(report: RefCounted) # SynergyReport
signal unit_recruited(unit: RefCounted)
signal unit_sold(unit: RefCounted)
signal augment_equipped(unit: RefCounted, slot_index: int, augment: Resource)
signal augment_unequipped(unit: RefCounted, slot_index: int, augment: Resource)
signal augment_purchased(augment: Resource)
signal augment_sold(augment: Resource)
signal augment_drag_started(augment_res: Resource)
signal augment_drag_ended()

# Economy Signals
signal gold_changed(new_amount: int, delta: int)
signal shop_rerolled(cost: int)

# Run Progression & District Signals
signal run_started()
signal district_started(district_id: int)
signal district_advanced(district_id: int, district_res: Resource)
signal encounter_node_reached(node_data: Dictionary)
signal narrative_event_triggered(event_res: Resource)
signal narrative_event_resolved(choice_res: Resource, outcome: Dictionary)
signal run_completed(victory: bool, run_summary: Dictionary)

# Combat Coordination Signals
signal prep_phase_locked(crew_payload: Array)
signal combat_started()
signal combat_finished(victory: bool, battle_stats: Dictionary)
