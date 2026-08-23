class_name DebugConsoleUI
extends CanvasLayer

## In-game Quake-style drop-down debug console interface

var engine: DebugConsole = null
var history: Array[String] = []
var history_index: int = -1

@onready var panel: PanelContainer = $ConsolePanel
@onready var log_output: RichTextLabel = $ConsolePanel/VBox/OutputLog
@onready var cmd_input: LineEdit = $ConsolePanel/VBox/InputBar/CmdInput
@onready var exec_btn: Button = $ConsolePanel/VBox/InputBar/ExecBtn

func _ready() -> void:
	engine = DebugConsole.new()
	panel.visible = false
	_print_output("[color=#00f5d4][SYSTEM][/color] Cyberstack Debug Console Ready. Type [color=#ffd166]/help[/color] for commands.\n")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F12:
			toggle_console()
			get_viewport().set_input_as_handled()
		elif panel.visible:
			if event.keycode == KEY_UP:
				_navigate_history(-1)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_DOWN:
				_navigate_history(1)
				get_viewport().set_input_as_handled()

func toggle_console() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		cmd_input.grab_focus()

func _on_cmd_input_submitted(new_text: String) -> void:
	_execute_text(new_text)

func _on_exec_btn_pressed() -> void:
	_execute_text(cmd_input.text)

func _execute_text(text: String) -> void:
	var trimmed = text.strip_edges()
	if trimmed.is_empty():
		return
		
	history.append(trimmed)
	history_index = history.size()
	cmd_input.clear()
	
	_print_output("[color=#6e00ff]>[/color] %s" % trimmed)
	
	var gm = null
	if get_node_or_null("/root/GameManager"):
		gm = get_node("/root/GameManager")
		
	var main_node = get_parent()
	var result = engine.execute_command(trimmed, gm, main_node)
	
	if result.success:
		if not result.message.is_empty():
			_print_output("[color=#00f5d4]%s[/color]" % result.message)
	else:
		_print_output("[color=#ff006e][ERROR] %s[/color]" % result.message)

func _print_output(text: String) -> void:
	if log_output:
		log_output.append_text(text + "\n")

func _navigate_history(delta: int) -> void:
	if history.is_empty():
		return
	history_index = clampi(history_index + delta, 0, history.size())
	if history_index < history.size():
		cmd_input.text = history[history_index]
		cmd_input.caret_column = cmd_input.text.length()
	else:
		cmd_input.clear()

# Quick Buttons
func _on_quick_gold_pressed() -> void:
	_execute_text("/gold 15")

func _on_quick_d2_pressed() -> void:
	_execute_text("/district 2")

func _on_quick_d4_pressed() -> void:
	_execute_text("/district 4")

func _on_quick_unlock_pressed() -> void:
	_execute_text("/unlock_all")

func _on_quick_crt_pressed() -> void:
	_execute_text("/crt")

func _on_quick_inspect_pressed() -> void:
	_execute_text("/inspect")

func _on_quick_hover_pressed() -> void:
	_execute_text("/hoverdebug")
