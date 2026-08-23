class_name ViralPandemicTrigger
extends RefCounted

## Trigger script: Spreads viral infection reducing all enemy attack speeds by 25% on kill

static func on_kill(attacker: Dictionary, enemies: Array) -> void:
	for opp in enemies:
		if opp is Dictionary and opp.get("hp", 0.0) > 0.0:
			opp["attack_speed"] = maxf(0.3, float(opp.get("attack_speed", 1.0)) * 0.75)
