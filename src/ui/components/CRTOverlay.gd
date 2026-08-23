class_name CRTOverlay
extends ColorRect

## Toggles and manages the screen-space CRT terminal shader

@export var enabled: bool = true:
	set(val):
		enabled = val
		visible = val

func toggle_crt() -> bool:
	enabled = not enabled
	return enabled
