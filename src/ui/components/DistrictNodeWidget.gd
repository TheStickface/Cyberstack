class_name DistrictNodeWidget
extends PanelContainer

## Visual Node Widget representing an encounter step on the district map

signal node_clicked(node_index: int)

var node_index: int = 0
var encounter_type: Enums.EncounterType = Enums.EncounterType.FIGHT
var is_visited: bool = false
var is_current: bool = false

@onready var icon_label: Label = $VBox/IconLabel
@onready var type_label: Label = $VBox/TypeLabel
@onready var status_label: Label = $VBox/StatusLabel

func setup(p_index: int, p_type: Enums.EncounterType, p_visited: bool, p_current: bool) -> void:
	node_index = p_index
	encounter_type = p_type
	is_visited = p_visited
	is_current = p_current
	_update_ui()

func _update_ui() -> void:
	if not icon_label:
		return
		
	match encounter_type:
		Enums.EncounterType.FIGHT:
			icon_label.text = "⚔"
			type_label.text = "FIGHT"
			icon_label.add_theme_color_override("font_color", Color(1, 0.2, 0.4))
		Enums.EncounterType.SHOP:
			icon_label.text = "$"
			type_label.text = "SHOP"
			icon_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
		Enums.EncounterType.EVENT:
			icon_label.text = "?"
			type_label.text = "EVENT"
			icon_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		Enums.EncounterType.BOSS:
			icon_label.text = "★"
			type_label.text = "BOSS"
			icon_label.add_theme_color_override("font_color", Color(1, 0.1, 0.2))
			
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	if is_current:
		status_label.text = "▶ CURRENT"
		status_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		style.bg_color = Color(0.1, 0.08, 0.25, 0.95)
		style.border_color = Color(0, 0.95, 0.83)
	elif is_visited:
		status_label.text = "✓ CLEARED"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		style.bg_color = Color(0.04, 0.03, 0.08, 0.7)
		style.border_color = Color(0.2, 0.2, 0.3)
	else:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
		style.bg_color = Color(0.05, 0.04, 0.12, 0.8)
		style.border_color = Color(0.3, 0.2, 0.4)
		
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		node_clicked.emit(node_index)
