class_name AugmentChip
extends PanelContainer

## Visual UI widget for an Augment item chip with tier coloring and tags

signal chip_clicked(augment_res: AugmentResource, inventory_idx: int)
signal chip_selected(chip: AugmentChip)
signal card_mouse_entered(augment_res: AugmentResource, card_pos: Vector2)
signal card_mouse_exited()

@export var augment_resource: AugmentResource = null
var inventory_index: int = -1
var is_selected: bool = false

@onready var name_label: Label = $VBox/NameLabel
@onready var slot_type_label: Label = $VBox/HBox/SlotTypeLabel
@onready var tag_label: Label = $VBox/HBox/TagLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_chip_mouse_entered)
	mouse_exited.connect(_on_chip_mouse_exited)
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_chip_mouse_entered() -> void:
	if augment_resource:
		card_mouse_entered.emit(augment_resource, global_position)

func _on_chip_mouse_exited() -> void:
	card_mouse_exited.emit()

func setup(aug: AugmentResource, inv_idx: int = -1) -> void:
	augment_resource = aug
	inventory_index = inv_idx
	_update_ui()

func _update_ui() -> void:
	if augment_resource == null:
		visible = false
		return
		
	visible = true
	if name_label:
		name_label.text = augment_resource.display_name
		
	if slot_type_label:
		slot_type_label.text = "[%s]" % Enums.role_to_string(augment_resource.slot_type as int as Enums.UnitRole)
		
	if tag_label:
		var tag_names: Array[String] = []
		for t in augment_resource.tags:
			tag_names.append(Enums.tag_to_string(t))
		tag_label.text = " · ".join(tag_names)
		
	# Setup Tooltip
	tooltip_text = "%s (%s Tier)\n%s\n\n%s" % [
		augment_resource.display_name,
		augment_resource.get_tier_name(),
		augment_resource.description,
		_format_stats(augment_resource.stat_modifiers)
	]
	
	# Apply Tier Styling
	var tier_color = Color(augment_resource.get_tier_color_hex())
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.12, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.8, 1.0) if is_selected else tier_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	add_theme_stylebox_override("panel", style)

func _format_stats(stats: Dictionary) -> String:
	if stats.is_empty():
		return ""
	var lines: Array[String] = ["Stats:"]
	for k in stats.keys():
		var val = float(stats[k])
		var sign_str = "+" if val > 0 else ""
		lines.append("  %s %s" % [sign_str, str(val)])
	return "\n".join(lines)

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_ui()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		chip_clicked.emit(augment_resource, inventory_index)
		chip_selected.emit(self)
