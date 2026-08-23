class_name TagResource
extends Resource

## Data Resource for an Augment Tag (Viral, Thermal, Neural, Kinetic)

@export var tag_type: Enums.AugmentTag = Enums.AugmentTag.NONE
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var theme_color: Color = Color.WHITE
@export var icon: Texture2D = null

## Chain bonuses unlocked when equipping multiple augments with this tag across the crew
## Usually triggers at 2, 4, 6 total tag counts
@export var chain_bonuses: Array[SynergyBonus] = []

func get_active_chain_bonuses(tag_count: int) -> Array[SynergyBonus]:
	var active: Array[SynergyBonus] = []
	for bonus in chain_bonuses:
		if bonus and tag_count >= bonus.required_count:
			active.append(bonus)
	return active

func get_highest_chain_bonus(tag_count: int) -> SynergyBonus:
	var highest: SynergyBonus = null
	for bonus in chain_bonuses:
		if bonus and tag_count >= bonus.required_count:
			if highest == null or bonus.required_count > highest.required_count:
				highest = bonus
	return highest
