class_name DistrictResource
extends Resource

## Configuration template for a city district theme (identity, node sequence, boss).
## Crew size and augment slot totals are NOT stored here — they are derived from the
## district's position within a run via Constants.DISTRICT_CREW_LIMITS, since the same
## theme can be drawn into different run positions across different runs.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var theme_color: Color = Color.WHITE

## True for districts that may only appear as the final district of a run
## (e.g. Black Site). False for the general theme pool drawn into earlier positions.
@export var is_final_boss: bool = false

## Default sequence of encounters in this district (FIGHT = 0, SHOP = 1, EVENT = 2, BOSS = 3)
@export var node_sequence: Array[Enums.EncounterType] = [
	Enums.EncounterType.FIGHT,
	Enums.EncounterType.SHOP,
	Enums.EncounterType.FIGHT,
	Enums.EncounterType.EVENT,
	Enums.EncounterType.SHOP,
	Enums.EncounterType.BOSS
]

## Subdistrict 1: Approach / Perimeter Infiltration (4 nodes: Fight, Shop, Event, Mini-Boss)
@export var subdistrict_1_sequence: Array[Enums.EncounterType] = [
	Enums.EncounterType.FIGHT,
	Enums.EncounterType.SHOP,
	Enums.EncounterType.EVENT,
	Enums.EncounterType.BOSS
]

## Subdistrict 2: District Stronghold / Climax (6 nodes: Fight, Shop, Fight, Event, Shop, Overlord Boss)
@export var subdistrict_2_sequence: Array[Enums.EncounterType] = [
	Enums.EncounterType.FIGHT,
	Enums.EncounterType.SHOP,
	Enums.EncounterType.FIGHT,
	Enums.EncounterType.EVENT,
	Enums.EncounterType.SHOP,
	Enums.EncounterType.BOSS
]

@export var boss_unit_id: String = ""

## Thematic District Modifiers
@export var preferred_tag: Enums.AugmentTag = Enums.AugmentTag.NONE
@export var reroll_cost_override: int = -1 # -1 means use default BASE_REROLL_COST
@export var bonus_crew_slots: int = 0 # e.g. +1 in Slum Market
@export var bonus_augment_slots: int = 0 # e.g. +1 in Server Vault
@export var scrap_refund_bonus: int = 0 # e.g. +1 CR in Kinetic Yards
@export var payout_bonus: int = 0 # e.g. +2 CR corporate dividend in Corp Arcology

func get_subdistrict_sequence(subdistrict_index: int) -> Array[Enums.EncounterType]:
	if subdistrict_index == 1 and not subdistrict_1_sequence.is_empty():
		return subdistrict_1_sequence
	elif subdistrict_index == 2 and not subdistrict_2_sequence.is_empty():
		return subdistrict_2_sequence
	return node_sequence

func get_node_count() -> int:
	return node_sequence.size()

func get_encounter_at(index: int) -> Enums.EncounterType:
	if index >= 0 and index < node_sequence.size():
		return node_sequence[index]
	return Enums.EncounterType.FIGHT

func get_perk_description() -> String:
	var perks: Array[String] = []
	if preferred_tag != Enums.AugmentTag.NONE:
		perks.append("⚡ %s Augment Bias" % Enums.tag_to_string(preferred_tag))
	if reroll_cost_override >= 0:
		perks.append("🎰 %d CR Rerolls" % reroll_cost_override)
	if bonus_crew_slots > 0:
		perks.append("👥 +%d Recruit Slot" % bonus_crew_slots)
	if bonus_augment_slots > 0:
		perks.append("📦 +%d Armory Slot" % bonus_augment_slots)
	if scrap_refund_bonus > 0:
		perks.append("💰 +%d CR Scrap Bonus" % scrap_refund_bonus)
	if payout_bonus > 0:
		perks.append("📈 +%d CR Payout Dividend" % payout_bonus)
	return " • ".join(perks) if not perks.is_empty() else "Standard District Protocols"
