class_name GridUnlockModal
extends Control

## Holographic popup dialog for choosing which grid slot to unlock and calibrating its intrinsic doctrine

signal grid_unlocked(slot_idx: int, doctrine_id: String)

var crew_mgr: CrewManager = null
var selected_slot: int = -1
var selected_doctrine: String = ""

@onready var title_label: Label = $CenterContainer/DialogPanel/Margin/VBox/Header/TitleLabel
@onready var desc_label: Label = $CenterContainer/DialogPanel/Margin/VBox/DescLabel
@onready var slots_container: HBoxContainer = $CenterContainer/DialogPanel/Margin/VBox/SlotsContainer
@onready var doctrines_container: VBoxContainer = $CenterContainer/DialogPanel/Margin/VBox/DoctrinesContainer
@onready var confirm_btn: Button = $CenterContainer/DialogPanel/Margin/VBox/ConfirmBtn

const SLOT_NAMES = {
	3: "▲ BACKLINE LEFT (SLOT 3)",
	4: "▲ BACKLINE CENTER (SLOT 4)",
	5: "▲ BACKLINE RIGHT (SLOT 5)"
}

func setup(p_crew: CrewManager) -> void:
	crew_mgr = p_crew
	selected_slot = -1
	selected_doctrine = ""
	visible = true
	_refresh_ui()

func _refresh_ui() -> void:
	if crew_mgr == null:
		return
		
	if title_label:
		title_label.text = "GRID EXPANSION PROTOCOL — DISTRICT %d" % crew_mgr.current_district
	if desc_label:
		desc_label.text = "Squad capacity expanded to %d. Select a locked matrix slot to activate and calibrate its permanent intrinsic doctrine." % crew_mgr.get_max_field_units()
		
	# Find locked slots among 3, 4, 5
	var locked_slots: Array[int] = []
	for s in [4, 3, 5]:
		if not crew_mgr.is_slot_unlocked(s):
			locked_slots.append(s)
			
	if locked_slots.is_empty():
		visible = false
		return
		
	if selected_slot == -1 or not locked_slots.has(selected_slot):
		selected_slot = locked_slots[0]
		
	# Populate slot buttons
	if slots_container:
		for c in slots_container.get_children():
			c.queue_free()
			
		for s in locked_slots:
			var btn = Button.new()
			btn.text = SLOT_NAMES.get(s, "SLOT %d" % s)
			btn.custom_minimum_size = Vector2(160, 36)
			if s == selected_slot:
				btn.add_theme_color_override("font_color", Color(0.0, 0.95, 0.83))
			else:
				btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
			btn.pressed.connect(_on_slot_selected.bind(s))
			slots_container.add_child(btn)
			
	# Populate doctrine choices
	if doctrines_container:
		for c in doctrines_container.get_children():
			c.queue_free()
			
		var doctrines = [
			"overwatch_perch",
			"neural_relay",
			"fortified_aegis",
			"phase_vent"
		]
		
		if selected_doctrine.is_empty():
			selected_doctrine = doctrines[0]
			
		for doc_id in doctrines:
			var doc = CrewManager.DOCTRINES.get(doc_id, {})
			var btn = Button.new()
			btn.text = "%s — %s" % [doc.get("name", ""), doc.get("description", "")]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.custom_minimum_size = Vector2(0, 32)
			if doc_id == selected_doctrine:
				btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			else:
				btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
			btn.pressed.connect(_on_doctrine_selected.bind(doc_id))
			doctrines_container.add_child(btn)
			
	_refresh_confirm_btn()

func _on_slot_selected(s: int) -> void:
	selected_slot = s
	_refresh_ui()

func _on_doctrine_selected(doc_id: String) -> void:
	selected_doctrine = doc_id
	_refresh_ui()

func _refresh_confirm_btn() -> void:
	if confirm_btn:
		confirm_btn.disabled = (selected_slot == -1 or selected_doctrine.is_empty())
		if not confirm_btn.disabled:
			confirm_btn.text = "CALIBRATE & UNLOCK MATRIX SLOT [CONFIRM]"
			confirm_btn.add_theme_color_override("font_color", Color(0.0, 0.95, 0.83))
		else:
			confirm_btn.text = "SELECT SLOT AND DOCTRINE"

func _on_confirm_btn_pressed() -> void:
	if selected_slot == -1 or selected_doctrine.is_empty() or crew_mgr == null:
		return
	crew_mgr.unlock_slot(selected_slot, selected_doctrine)
	visible = false
	grid_unlocked.emit(selected_slot, selected_doctrine)
