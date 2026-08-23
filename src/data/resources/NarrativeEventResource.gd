class_name NarrativeEventResource
extends Resource

## Narrative story vignette offering binary/branching risk-reward choices

@export var id: String = ""
@export var title: String = ""
@export_multiline var story_text: String = ""
@export var theme_color: Color = Color("#00f5d4")
@export var image: Texture2D = null

@export var choices: Array[EventChoiceResource] = []

func get_available_choices(player_gold: int, crew: Array[UnitInstance]) -> Array[EventChoiceResource]:
	var available: Array[EventChoiceResource] = []
	for choice in choices:
		if choice and choice.is_available(player_gold, crew):
			available.append(choice)
	return available
