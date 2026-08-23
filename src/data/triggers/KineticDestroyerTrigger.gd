class_name KineticDestroyerTrigger
extends RefCounted

## Trigger script: Deals 50% overkill damage to all remaining enemies on kill

static func on_kill(attacker_stats: Dictionary, dead_target: Dictionary, enemies: Array) -> void:
	var overkill = maxf(20.0, float(attacker_stats.get("attack_damage", 30.0)) * 0.5)
	for opp in enemies:
		if opp is Dictionary and opp.get("hp", 0.0) > 0.0:
			opp["hp"] = maxf(0.0, opp["hp"] - overkill)
