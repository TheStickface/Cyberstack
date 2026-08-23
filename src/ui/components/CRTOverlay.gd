class_name CRTOverlay
extends ColorRect

## Toggles and manages the screen-space CRT terminal shader

@export var enabled: bool = false:
	set(val):
		enabled = val
		visible = val

func _ready() -> void:
	visible = false
	enabled = false

func toggle_crt() -> bool:
	enabled = not enabled
	return enabled
