class_name ShopSlotCard
extends PanelContainer

## Shop offering shelf card for purchasing units or augments

signal buy_requested(slot_index: int)
signal card_mouse_entered(resource: Resource, card_pos: Vector2)
signal card_mouse_exited()

const SynergyTooltipScript = preload("res://src/ui/components/SynergyTooltip.gd")

var slot_index: int = 0
var slot_data: Dictionary = {}

@onready var type_label: Label = $Margin/VBox/Header/TypeLabel
@onready var cost_label: Label = $Margin/VBox/Header/CostLabel
@onready var icon_rect: TextureRect = $Margin/VBox/NameRow/IconRect
@onready var name_label: Label = $Margin/VBox/NameRow/NameLabel
@onready var details_label: Label = $Margin/VBox/DetailsLabel
@onready var buy_btn: Button = $Margin/VBox/BuyBtn

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_set_mouse_filter_recursive(self)
	
	if icon_rect:
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _set_mouse_filter_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not child is Button:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			_set_mouse_filter_recursive(child)

func _make_custom_tooltip(_for_text: String) -> Object:
	var is_bought = slot_data.get("is_bought", false)
	var res = slot_data.get("resource", null)
	if is_bought or res == null:
		return null
	if res is UnitResource:
		return SynergyTooltipScript.create_custom_tooltip_node(res as UnitResource, {}, 1)
	elif res is AugmentResource:
		return SynergyTooltipScript.create_augment_tooltip_node(res as AugmentResource)
	elif res is ConduitResource:
		var cond = res as ConduitResource
		var tip = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 6)
		tip.add_child(margin)
		var lbl = Label.new()
		lbl.text = "%s %s\nCharges: %d Combats\nStats: %s\n%s" % [
			cond.icon_code, cond.display_name, cond.max_charges, cond.get_summary_text(), cond.description
		]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", cond.theme_color)
		margin.add_child(lbl)
		return tip
	return null

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
		tooltip_text = ""
		if buy_btn:
			buy_btn.text = "[SOLD]"
			buy_btn.disabled = true
		if name_label:
			name_label.text = "--- SOLD ---"
		if details_label:
			details_label.text = ""
		if icon_rect:
			icon_rect.visible = false
		return
		
	tooltip_text = "Offering Details"
		
	if type_label:
		type_label.text = item_type.to_upper()
	if cost_label:
		cost_label.text = Constants.format_cost(cost)
		cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0) if player_gold >= cost else Color(0.9, 0.2, 0.2))
		
	if item_type == "unit":
		custom_minimum_size = Vector2(130, 118)
		var unit_res = res as UnitResource
		if icon_rect:
			icon_rect.texture = unit_res.portrait
			icon_rect.visible = unit_res.portrait != null
		if name_label:
			name_label.text = unit_res.display_name
			name_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		if details_label:
			var formation_str = unit_res.get_formation_badge_text()
			var formation_line = ("\n⚡ Aura: " + formation_str) if not formation_str.is_empty() else ""
			details_label.text = "[%s | %s] HP:%.0f AD:%.0f\n%s%s" % [
				unit_res.get_role_name(),
				unit_res.get_faction_name(),
				unit_res.base_max_health,
				unit_res.base_attack_damage,
				unit_res.ability_name,
				formation_line
			]
	elif item_type == "augment":
		custom_minimum_size = Vector2(102, 88)
		var aug_res = res as AugmentResource
		if icon_rect:
			icon_rect.texture = aug_res.icon
			icon_rect.visible = aug_res.icon != null
		if name_label:
			name_label.text = aug_res.display_name
			name_label.add_theme_color_override("font_color", Color(aug_res.get_tier_color_hex()))
		if details_label:
			var tag_names: Array[String] = []
			for t in aug_res.tags:
				tag_names.append(Enums.tag_to_string(t))
			var formation_str = aug_res.get_formation_badge_text()
			var aura_line = ("\n⚡ Aura: " + formation_str) if not formation_str.is_empty() else ""
			details_label.text = "[%s | %s]\n%s" % [
				aug_res.get_tier_name(),
				", ".join(tag_names),
				" · ".join(aug_res.get_stat_lines())
			]
	elif item_type == "conduit":
		custom_minimum_size = Vector2(102, 88)
		var cond_res = res as ConduitResource
		if icon_rect:
			icon_rect.texture = cond_res.icon
			icon_rect.visible = cond_res.icon != null
		if name_label:
			name_label.text = cond_res.display_name
			name_label.add_theme_color_override("font_color", cond_res.theme_color)
		if details_label:
			details_label.text = "⚡ %d Combats\n%s" % [cond_res.max_charges, cond_res.get_summary_text()]
		_apply_border_color(cond_res.theme_color)
			
	if buy_btn:
		buy_btn.text = "BUY (%s)" % Constants.format_currency(cost, true)
		buy_btn.disabled = (player_gold < cost)

## Recolors the card's border/panel to match an item's theme color (used by
## conduits, which don't have a tier system to key off of like augments do).
func _apply_border_color(color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.12, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	add_theme_stylebox_override("panel", style)

func _on_buy_btn_pressed() -> void:
	buy_requested.emit(slot_index)

func _on_mouse_entered() -> void:
	var res = slot_data.get("resource", null)
	if res and not slot_data.get("is_bought", false):
		card_mouse_entered.emit(res, global_position)

func _on_mouse_exited() -> void:
	card_mouse_exited.emit()
