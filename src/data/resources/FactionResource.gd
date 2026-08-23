class_name FactionResource
extends Resource

## Data Resource for a Cyberstack Faction (Street Runners, Corp Enforcers, Rogue AIs, Fixers)

@export var faction_type: Enums.Faction = Enums.Faction.NONE
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var theme_color: Color = Color.WHITE
@export var icon: Texture2D = null

## Threshold bonuses (typically 2, 4, 6)
## Array of SynergyBonus objects configured for 2, 4, 6 unit milestones
@export var threshold_bonuses: Array[SynergyBonus] = []

func get_bonus_for_count(unit_count: int) -> Array[SynergyBonus]:
	var active_bonuses: Array[SynergyBonus] = []
	for bonus in threshold_bonuses:
		if bonus and unit_count >= bonus.required_count:
			active_bonuses.append(bonus)
	return active_bonuses

func get_highest_bonus_for_count(unit_count: int) -> SynergyBonus:
	var highest: SynergyBonus = null
	for bonus in threshold_bonuses:
		if bonus and unit_count >= bonus.required_count:
			if highest == null or bonus.required_count > highest.required_count:
				highest = bonus
	return highest
