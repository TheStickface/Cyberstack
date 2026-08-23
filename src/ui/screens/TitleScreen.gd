class_name TitleScreen
extends Control

## Cyberpunk Title Screen and Start Menu with Continue & Codex access

@onready var title_label: Label = $VBox/CenterContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/CenterContainer/VBox/SubtitleLabel
@onready var continue_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/ContinueBtn
@onready var start_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/StartBtn
@onready var codex_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/CodexBtn
@onready var quit_btn: Button = $VBox/CenterContainer/VBox/MenuButtons/QuitBtn

func _ready() -> void:
	if continue_btn:
		continue_btn.visible = SaveManager.has_active_run()

func _on_continue_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").resume_active_run()

func _on_start_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").start_new_game()

func _on_codex_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").open_codex()

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
