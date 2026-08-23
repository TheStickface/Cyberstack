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

@export var boss_unit_id: String = ""

func get_node_count() -> int:
	return node_sequence.size()

func get_encounter_at(index: int) -> Enums.EncounterType:
	if index >= 0 and index < node_sequence.size():
		return node_sequence[index]
	return Enums.EncounterType.FIGHT
