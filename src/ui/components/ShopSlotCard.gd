class_name ShopSlotCard
extends PanelContainer

## Shop offering shelf card for purchasing units or augments

signal buy_requested(slot_index: int)
signal card_mouse_entered(resource: Resource, card_pos: Vector2)
signal card_mouse_exited()

var slot_index: int = 0
var slot_data: Dictionary = {}

@onready var type_label: Label = $Margin/VBox/Header/TypeLabel
@onready var cost_label: Label = $Margin/VBox/Header/CostLabel
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var details_label: Label = $Margin/VBox/DetailsLabel
@onready var buy_btn: Button = $Margin/VBox/BuyBtn

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_set_mouse_filter_recursive(self)

func _set_mouse_filter_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			_set_mouse_filter_recursive(child)

func setup(p_index: int, p_data: Dictionary, player_gold: int) -> void:
	slot_index = p_index
	slot_data = p_data
	_update_ui(player_gold)

func _update_ui(player_gold: int) -> void:
	var is_bought = slot_data.get("is_bought", false)
	var item_type = slot_data.get("type", "none")
	var cost = slot_data.get("cost", 0)
	var res = slot_data.get("resource", null)
	
	if is_bought or res == null:
		if buy_btn:
			buy_btn.text = "[SOLD]"
			buy_btn.disabled = true
		if name_label:
			name_label.text = "--- SOLD ---"
		if details_label:
			details_label.text = ""
		return
		
	if type_label:
		type_label.text = item_type.to_upper()
	if cost_label:
		cost_label.text = Constants.format_cost(cost)
		cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0) if player_gold >= cost else Color(0.9, 0.2, 0.2))
		
	if item_type == "unit":
		var unit_res = res as UnitResource
		if name_label:
			name_label.text = unit_res.display_name
			name_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		if details_label:
			details_label.text = "[%s | %s]\nHP: %.0f | AD: %.0f\n%s" % [
				unit_res.get_role_name(),
				unit_res.get_faction_name(),
				unit_res.base_max_health,
				unit_res.base_attack_damage,
				unit_res.ability_name
			]
	elif item_type == "augment":
		var aug_res = res as AugmentResource
		if name_label:
			name_label.text = aug_res.display_name
			name_label.add_theme_color_override("font_color", Color(aug_res.get_tier_color_hex()))
		if details_label:
			var tag_names: Array[String] = []
			for t in aug_res.tags:
				tag_names.append(Enums.tag_to_string(t))
			details_label.text = "[%s Tier | %s]\nTags: %s\n%s" % [
				aug_res.get_tier_name(),
				Enums.role_to_string(aug_res.slot_type as int as Enums.UnitRole),
				", ".join(tag_names),
				aug_res.description
			]
			
	if buy_btn:
		buy_btn.text = "BUY (%s)" % Constants.format_currency(cost, true)
		buy_btn.disabled = (player_gold < cost)

func _on_buy_btn_pressed() -> void:
	buy_requested.emit(slot_index)

func _on_mouse_entered() -> void:
	var res = slot_data.get("resource", null)
	if res and not slot_data.get("is_bought", false):
		card_mouse_entered.emit(res, global_position)

func _on_mouse_exited() -> void:
	card_mouse_exited.emit()
