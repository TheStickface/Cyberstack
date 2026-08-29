class_name AugmentResource
extends Resource

## Data Resource for an Augment Item that can be slotted into an operative

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var tier: Enums.AugmentTier = Enums.AugmentTier.COMMON
@export var slot_type: Enums.SlotType = Enums.SlotType.PASSIVE
@export var tags: Array[Enums.AugmentTag] = []
@export var base_cost: int = 3
@export var icon: Texture2D = null

## Stat boosts provided by this augment directly to the equipped unit
## Dictionary of Enums.StatType (int) -> float
@export var stat_modifiers: Dictionary = {}

## Directional formation synergy (e.g. grants buffs to adjacent units, same row, or backline)
@export var directional_target: Enums.GridDirection = Enums.GridDirection.NONE
@export var directional_modifiers: Dictionary = {}

## Trigger configuration for Rare and Legendary augments
@export var trigger_type: Enums.TriggerType = Enums.TriggerType.PASSIVE_STAT
@export var trigger_effect_id: String = ""
@export var trigger_params: Dictionary = {}


func has_tag(tag: Enums.AugmentTag) -> bool:
	return tags.has(tag)

func can_equip_in_slot(target_slot_type: Enums.SlotType) -> bool:
	if slot_type == Enums.SlotType.FLEX or target_slot_type == Enums.SlotType.FLEX:
		return true
	return slot_type == target_slot_type

func get_tier_color_hex() -> String:
	return Enums.tier_to_color_hex(tier)

func get_tier_name() -> String:
	return Enums.tier_to_string(tier)

## Stat readout in canonical StatType-ordinal order (not .tres authoring order),
## so every surface lists a given augment's stats identically. e.g.
## ["+12 Attack Damage", "+15% Crit Chance"]
func get_stat_lines() -> Array[String]:
	return Enums.format_stat_dict(stat_modifiers)

func has_directional() -> bool:
	return directional_target != Enums.GridDirection.NONE

## e.g. "ADJACENT" / "FRONTLINE" / "SAME ROW". Empty when this augment grants
## no positional bonus.
func get_directional_header() -> String:
	if not has_directional():
		return ""
	return Enums.grid_direction_to_string(directional_target).to_upper()

## Stat readout for the positional bonus (directional_modifiers), same
## canonical ordering and formatting as get_stat_lines().
func get_directional_stat_lines() -> Array[String]:
	if not has_directional():
		return []
	return Enums.format_stat_dict(directional_modifiers)

func get_formation_symbol() -> String:
	return Enums.grid_direction_to_symbol(directional_target)

## Short badge text for card display, e.g. "⯎ +15% CRIT"
func get_formation_badge_text() -> String:
	if not has_directional():
		return ""
	var sym = get_formation_symbol()
	var compact_stats = ", ".join(Enums.format_stat_dict_compact(directional_modifiers))
	return ("%s %s" % [sym, compact_stats]).strip_edges()

## Full 1-line summary for shop cards and tooltips
func get_formation_full_summary() -> String:
	if not has_directional():
		return ""
	var sym = get_formation_symbol()
	var header = get_directional_header()
	var stats = ", ".join(get_directional_stat_lines())
	return "%s %s AURA: %s" % [sym, header, stats]

func has_proc() -> bool:
	return trigger_type != Enums.TriggerType.PASSIVE_STAT

func get_proc_header() -> String:
	if not has_proc():
		return ""
	return Enums.trigger_to_string(trigger_type).to_upper()

## Terse proc effect fragment. Formatted from trigger_params when the known
## keys are present (the authoritative source); falls back to the literal
## `description` string for procs with no numeric magnitude in the data.
## Empty when this augment has no proc at all.
func get_proc_fragment() -> String:
	if not has_proc():
		return ""
	if trigger_params.has("armor_pierce_pct"):
		return "Pierce %d%% target armor" % roundi(float(trigger_params["armor_pierce_pct"]) * 100.0)
	if trigger_params.has("armor_melt_pct"):
		return "Melt %d%% target armor" % roundi(float(trigger_params["armor_melt_pct"]) * 100.0)
	if trigger_params.has("mana_drain"):
		return "Drain %s mana from enemy" % _trim_trailing_zero(trigger_params["mana_drain"])
	if trigger_params.has("attack_speed_bonus") and trigger_params.has("duration"):
		return "+%d%% Attack Speed for %ss" % [
			roundi(float(trigger_params["attack_speed_bonus"]) * 100.0),
			_trim_trailing_zero(trigger_params["duration"])
		]
	if trigger_params.has("enemy_attack_speed_pct"):
		return "%d%% enemy Attack Speed" % roundi(float(trigger_params["enemy_attack_speed_pct"]) * 100.0)
	if trigger_params.has("shared_mana_pct"):
		return "Share %d%% mana pool crew-wide" % roundi(float(trigger_params["shared_mana_pct"]) * 100.0)
	return description

static func _trim_trailing_zero(value) -> String:
	var f := float(value)
	if f == int(f):
		return str(int(f))
	return str(f)
