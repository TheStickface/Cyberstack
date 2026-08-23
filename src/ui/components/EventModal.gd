class_name EventModal
extends PanelContainer

## Holographic popup dialog for resolving narrative vignettes

signal event_resolved(outcome: Dictionary)

var event_resource: NarrativeEventResource = null
var shop_mgr: ShopManager = null
var crew_mgr: CrewManager = null

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var story_label: Label = $VBox/StoryLabel
@onready var choices_container: VBoxContainer = $VBox/ChoicesContainer
@onready var outcome_container: VBoxContainer = $VBox/OutcomeContainer
@onready var outcome_label: Label = $VBox/OutcomeContainer/OutcomeLabel
@onready var continue_btn: Button = $VBox/OutcomeContainer/ContinueBtn

var latest_outcome: Dictionary = {}

func setup(ev_res: NarrativeEventResource, p_shop: ShopManager, p_crew: CrewManager) -> void:
	event_resource = ev_res
	shop_mgr = p_shop
	crew_mgr = p_crew
	_show_event()

func _show_event() -> void:
	if event_resource == null:
		visible = false
		return
		
	visible = true
	if outcome_container:
		outcome_container.visible = false
	if choices_container:
		choices_container.visible = true
		
	if title_label:
		title_label.text = event_resource.title.to_upper()
		title_label.add_theme_color_override("font_color", event_resource.theme_color)
	if story_label:
		story_label.text = event_resource.story_text
		
	_populate_choices()

func _populate_choices() -> void:
	if not choices_container:
		return
		
	for c in choices_container.get_children():
		c.queue_free()
		
	var player_gold = shop_mgr.gold if shop_mgr else 0
	var crew = crew_mgr.fielded_units if crew_mgr else []
	
	for i in range(event_resource.choices.size()):
		var choice = event_resource.choices[i]
		var is_avail = choice.is_available(player_gold, crew)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "  ▶ %s" % choice.text
		btn.disabled = not is_avail
		
		if is_avail:
			btn.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		else:
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
			
		var choice_idx = i
		btn.pressed.connect(func(): _on_choice_selected(choice_idx))
		choices_container.add_child(btn)

func _on_choice_selected(choice_idx: int) -> void:
	var choice = event_resource.choices[choice_idx]
	latest_outcome = EventManager.execute_choice(choice, shop_mgr, crew_mgr)
	
	if choices_container:
		choices_container.visible = false
	if outcome_container:
		outcome_container.visible = true
		outcome_label.text = latest_outcome.get("description", "Event concluded.")

func _on_continue_pressed() -> void:
	visible = false
	event_resolved.emit(latest_outcome)
