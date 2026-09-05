class_name ConduitResource
extends Resource

## Data Resource for a temporary Tactical Conduit (Hex Overclock) installed on a grid slot

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 3
@export var max_charges: int = 3
@export var allowed_rows: Enums.GridDirection = Enums.GridDirection.NONE
@export var stat_modifiers: Dictionary = {}
@export var theme_color: Color = Color(0.0, 0.95, 0.83)
@export var icon_code: String = "⚡"
@export var icon: Texture2D = null

func can_install_on_row(row_idx: int) -> bool:
	if allowed_rows == Enums.GridDirection.NONE:
		return true
	if allowed_rows == Enums.GridDirection.FRONTLINE and row_idx == 1:
		return true
	if allowed_rows == Enums.GridDirection.BACKLINE and row_idx == 0:
		return true
	return false

func get_summary_text() -> String:
	var parts: Array[String] = []
	for stat_key in stat_modifiers:
		var stat_type = int(stat_key)
		var val = stat_modifiers[stat_key]
		var stat_name = Enums.stat_to_string(stat_type)
		if Enums.is_percent_stat(stat_type as Enums.StatType):
			parts.append("+%.0f%% %s" % [val * 100.0, stat_name])
		else:
			parts.append("+%.0f %s" % [val, stat_name])
	return ", ".join(parts)
