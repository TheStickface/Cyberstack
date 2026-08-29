class_name TitleScreen
extends Control

## Cyberpunk Title Screen and Start Menu with Continue & Codex access

@onready var title_label: Label = $VBox/CenterContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/CenterContainer/VBox/SubtitleLabel
@onready var continue_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/ContinueBtn
@onready var start_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/StartBtn
@onready var codex_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/CodexBtn
@onready var quit_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/QuitBtn
@onready var starter_label: Label = get_node_or_null("VBox/CenterContainer/VBox/MenuButtons/StarterContainer/StarterLabel")

const STARTERS = [
	{"id": "runner_blitz", "name": "Blitz (Street Runner)", "color": Color(0, 0.95, 0.83)},
	{"id": "corp_sentinel", "name": "Sentinel-09 (Corp)", "color": Color(0.2, 0.75, 1.0)},
	{"id": "ai_glitch", "name": "GLITCH.exe (Rogue AI)", "color": Color(1.0, 0.2, 0.7)},
	{"id": "fixer_broker", "name": "Madame Vane (Fixer)", "color": Color(1.0, 0.85, 0.0)}
]
var current_starter_index: int = 0

func _ready() -> void:
	if continue_btn:
		continue_btn.visible = SaveManager.has_active_run()
	_update_starter_display()

func _update_starter_display() -> void:
	if starter_label and current_starter_index >= 0 and current_starter_index < STARTERS.size():
		var s = STARTERS[current_starter_index]
		starter_label.text = s["name"]
		starter_label.add_theme_color_override("font_color", s["color"])

func _on_prev_starter_btn_pressed() -> void:
	current_starter_index = (current_starter_index - 1 + STARTERS.size()) % STARTERS.size()
	_update_starter_display()

func _on_next_starter_btn_pressed() -> void:
	current_starter_index = (current_starter_index + 1) % STARTERS.size()
	_update_starter_display()

func _on_continue_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").resume_active_run()

func _on_start_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		var chosen_id = STARTERS[current_starter_index]["id"]
		get_node("/root/GameManager").start_new_game(chosen_id)

func _on_codex_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").open_codex()

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
