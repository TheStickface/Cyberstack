class_name RunEndScreen
extends Control

## Victory / Game Over summary screen at the conclusion of a run

@onready var title_label: Label = $VBox/Center/VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/Center/VBox/SubtitleLabel
@onready var stats_label: Label = $VBox/Center/VBox/StatsLabel
@onready var quick_retry_btn: Button = get_node_or_null("VBox/Center/VBox/ButtonsRow/QuickRetryBtn")
@onready var return_btn: Button = get_node_or_null("VBox/Center/VBox/ButtonsRow/ReturnBtn")

func _ready() -> void:
	if get_node_or_null("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		setup(gm.last_run_summary)

func setup(summary: Dictionary) -> void:
	var victory = summary.get("victory", false)
	var district = summary.get("district", 1)
	var fights = summary.get("fights_won", 0)
	var gold = summary.get("gold_earned", 0)
	var bosses = summary.get("bosses_defeated", 0)
	var abandoned = summary.get("abandoned", false)
	
	if title_label:
		if victory:
			title_label.text = "MISSION ACCOMPLISHED"
			title_label.add_theme_color_override("font_color", Color(0, 0.95, 0.83))
		elif abandoned:
			title_label.text = "MISSION ABANDONED"
			title_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
		else:
			title_label.text = "OPERATION TERMINATED"
			title_label.add_theme_color_override("font_color", Color(1, 0.15, 0.3))
		
	if subtitle_label:
		if victory:
			subtitle_label.text = "All city districts breached and secured."
		elif abandoned:
			subtitle_label.text = "Tactical retreat executed in District %d." % district
		else:
			subtitle_label.text = "Operative link severed in District %d." % district
		
	if stats_label:
		stats_label.text = "Districts Cleared: %d / 4\nFights Won: %d\nBosses Defeated: %d\nTotal %s Earned: %d" % [
			district if victory else district - 1,
			fights,
			bosses,
			Constants.CURRENCY_NAME,
			gold
		]

func _on_quick_retry_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").quick_retry()

func _on_return_btn_pressed() -> void:
	if get_node_or_null("/root/GameManager"):
		get_node("/root/GameManager").return_to_title()
