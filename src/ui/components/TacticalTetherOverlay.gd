class_name TacticalTetherOverlay
extends Control

## Holographic Energy Tether Overlay for 2x3 Tactical Grid
## Renders animated bezier energy beams, directional particle pulses, and formation link brackets

var active_tethers: Array[Dictionary] = []
var hovered_slot: int = -1
var hovered_unit: UnitInstance = null
var anim_phase: float = 0.0

# Colors for formation connection types
const COLOR_TANK_GUARD = Color(0.0, 0.75, 1.0, 0.85)     # Electric Blue
const COLOR_HACKER_UPLINK = Color(0.0, 0.95, 0.83, 0.85) # Neon Cyan
const COLOR_SNIPER_PERCH = Color(1.0, 0.85, 0.1, 0.85)   # Amber Gold
const COLOR_FIXER_LINK = Color(0.1, 0.95, 0.45, 0.85)    # Emerald Green
const COLOR_GENERIC_LINK = Color(0.75, 0.4, 1.0, 0.85)   # Plasma Purple

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	anim_phase = fmod(anim_phase + delta * 2.0, 1.0)
	if not active_tethers.is_empty():
		queue_redraw()

func clear_tethers() -> void:
	active_tethers.clear()
	hovered_slot = -1
	hovered_unit = null
	queue_redraw()

func set_active_tethers(tethers: Array[Dictionary]) -> void:
	active_tethers = tethers
	queue_redraw()

func add_tether(from_pos: Vector2, to_pos: Vector2, color: Color, label: String = "") -> void:
	active_tethers.append({
		"from": from_pos,
		"to": to_pos,
		"color": color,
		"label": label
	})
	queue_redraw()

func _draw() -> void:
	if active_tethers.is_empty():
		return
		
	for tether in active_tethers:
		var p1: Vector2 = tether["from"]
		var p2: Vector2 = tether["to"]
		var col: Color = tether["color"]
		
		# 1. Background Glow Beam
		var bg_col = col
		bg_col.a = 0.25
		draw_line(p1, p2, bg_col, 8.0, true)
		
		# 2. Main Laser Core
		var core_col = Color(1.0, 1.0, 1.0, 0.9)
		draw_line(p1, p2, col, 3.0, true)
		draw_line(p1, p2, core_col, 1.0, true)
		
		# 3. Animated Energy Particle Pulses moving along tether
		var dist = p1.distance_to(p2)
		if dist > 5.0:
			var dir = (p2 - p1).normalized()
			var pulse_count = 2
			for i in range(pulse_count):
				var pulse_t = fmod(anim_phase + float(i) / float(pulse_count), 1.0)
				var pulse_pos = p1.lerp(p2, pulse_t)
				
				draw_circle(pulse_pos, 4.5, col)
				draw_circle(pulse_pos, 2.0, Color.WHITE)
				
		# 4. Connection Endpoints Rings
		draw_arc(p1, 14.0, 0, TAU, 16, col, 2.0, true)
		draw_arc(p2, 14.0, 0, TAU, 16, col, 2.0, true)
		draw_circle(p1, 4.0, col)
		draw_circle(p2, 4.0, col)
