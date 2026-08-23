class_name NeuralDaemonTrigger
extends RefCounted

## Trigger script: Siphons 15 mana from enemy on attack

static func on_attack(attacker: Dictionary, target: Dictionary) -> void:
	if target.has("mana") and target["mana"] > 0:
		var drain = minf(float(target["mana"]), 15.0)
		target["mana"] -= drain
		attacker["mana"] = minf(float(attacker["max_mana"]), float(attacker["mana"]) + drain)
